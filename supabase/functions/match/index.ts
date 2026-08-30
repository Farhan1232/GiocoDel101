// Gioco del 101 — the authoritative match function.
//
// This is the ONLY code path that changes a live match. Flutter is untrusted:
// it may only *request* ("play card X", "draw", "I give up", "start the
// room", "rematch"). Everything is decided here and committed by Postgres
// in one transaction (public.srv_* functions, service_role only).
//
//   request ─▶ authenticate (JWT → auth.users.id)
//           ─▶ load authoritative state + caller's seat  (srv_load_match)
//           ─▶ idempotency: seen this action id?         (receipt)
//           ─▶ expected version == current version?
//           ─▶ GameEngine.applyAction (the Dart engine, compiled)
//           ─▶ srv_commit_action: FOR UPDATE, version check, log, publish,
//              clock, receipt, settlement — or `stale_version`
//           ─▶ respond; Realtime fans the new rows out to every seat
//
// Ops (POST JSON {op, ...}):
//   ping                       → {ok, engine}
//   start   {roomId}           → {ok, matchId, created}
//   action  {matchId, actionId, expectedVersion, action:{type, card?, chosenSuit?, suit?}}
//                              → {ok, accepted, version, failure?, duplicate?, publicState?, hand?, drawnCard?, events?}
//   timeout {matchId}          → the server moves for an overdue seat (policy in timeout.ts)
//   forfeit {matchId}          → the caller gives up
//   rematch {matchId}          → vote; deals a fresh match when every seat has voted
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient, type SupabaseClient } from "npm:@supabase/supabase-js@2.49.4";
import { engineSync, type GameActionJson, type GameStateJson } from "./engine.ts";
import { isOverdue, planTimeout } from "./timeout.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

class ApiError extends Error {
  constructor(readonly status: number, readonly code: string, detail?: string) {
    super(detail ?? code);
  }
}

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const CARD = /^(denari|coppe|spade|bastoni)_(asso|due|tre|quattro|cinque|sei|sette|fante|cavallo|re)$/;
const SUIT = /^(denari|coppe|spade|bastoni)$/;
const CLIENT_ACTIONS = new Set(["playCard", "drawCard", "chooseSuit", "pass", "startNextRound"]);

function uuid(v: unknown, what: string): string {
  if (typeof v !== "string" || !UUID.test(v)) throw new ApiError(400, "bad_request", `${what} must be a uuid`);
  return v.toLowerCase();
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS, "Content-Type": "application/json" },
  });
}

const admin: SupabaseClient = createClient(SUPABASE_URL, SERVICE_KEY, {
  auth: { persistSession: false, autoRefreshToken: false },
});

const KNOWN_DB_ERRORS = /^[a-z_]{3,40}$/;

async function rpc<T = any>(fn: string, args: Record<string, unknown>): Promise<T> {
  const { data, error } = await admin.rpc(fn, args);
  if (error) {
    // PostgREST surfaces `raise exception 'name'` as message = name. Anything
    // else (constraint text, SQL fragments) stays in the function log.
    const message = error.message ?? "";
    if (KNOWN_DB_ERRORS.test(message)) throw new ApiError(pgStatus(message), message);
    console.error(`match: ${fn} failed`, error);
    throw new ApiError(500, "internal");
  }
  return data as T;
}

function pgStatus(message: string | undefined): number {
  switch (message) {
    case "not_a_participant":
    case "not_a_member":
    case "not_the_host":
    case "already_in_match":
      return 403;
    case "match_not_found":
    case "room_not_found":
      return 404;
    case "stale_version":
    case "room_changed":
    case "room_not_startable":
    case "match_not_in_progress":
    case "match_not_finished":
    case "action_id_taken":
      return 409;
    default:
      return 500;
  }
}

async function authenticate(req: Request): Promise<string> {
  const auth = req.headers.get("Authorization") ?? "";
  if (!auth.toLowerCase().startsWith("bearer ")) throw new ApiError(401, "not_authenticated");
  const asUser = createClient(SUPABASE_URL, ANON_KEY, {
    global: { headers: { Authorization: auth } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data, error } = await asUser.auth.getUser();
  if (error || !data.user) throw new ApiError(401, "not_authenticated", error?.message);
  return data.user.id;
}

/** Mirrors app_private.redact_game_state exactly. */
function redact(state: GameStateJson): GameStateJson {
  const { seed: _s, drawPile, drawnCard: _d, history: _h, ...rest } = state;
  return {
    ...rest,
    drawPileCount: (drawPile as unknown[]).length,
    players: (state.players as any[]).map(({ hand, ...p }) => ({ ...p, handCount: hand.length })),
  };
}

function handOf(state: GameStateJson, enginePlayerId: string): string[] {
  return (state.players as any[]).find((p) => p.id === enginePlayerId)?.hand ?? [];
}

function ms(ts: string | null | undefined): number | null {
  if (!ts) return null;
  const t = Date.parse(ts);
  return Number.isNaN(t) ? null : t;
}

/** 52 random bits: wide enough that the deal cannot be brute-forced from a
 * dealt hand, and exact in the engine's number arithmetic (< 2^53). */
function seed52(): number {
  const buf = new Uint32Array(2);
  crypto.getRandomValues(buf);
  return (buf[0] & 0xfffff) * 0x100000000 + buf[1];
}

// ------------------------------------------------------------------ ops

type Ctx = {
  match: {
    id: string; roomId: string; status: string; version: number; currentUserId: string | null;
    turnTimerSeconds: number; turnStartedAt: string | null; turnDeadlineAt: string | null; now: string;
  };
  state: GameStateJson;
  me: { userId: string; seat: number; enginePlayerId: string; forfeitedAt: string | null };
  players: Array<{
    userId: string; seat: number; enginePlayerId: string; lastSeenAt: string;
    consecutiveTimeouts: number; forfeitedAt: string | null;
  }>;
};

async function opAction(userId: string, body: any) {
  const engine = engineSync();
  const matchId = uuid(body.matchId, "matchId");
  const actionId = uuid(body.actionId, "actionId");
  const expected = body.expectedVersion;
  if (!Number.isInteger(expected) || expected < 0) throw new ApiError(400, "bad_request", "expectedVersion");
  const a = body.action ?? {};
  if (typeof a.type !== "string" || !CLIENT_ACTIONS.has(a.type)) {
    throw new ApiError(400, "bad_request", "action.type");
  }
  if (a.type === "playCard" && (typeof a.card !== "string" || !CARD.test(a.card))) {
    throw new ApiError(400, "bad_request", "action.card");
  }
  if (a.chosenSuit !== undefined && a.chosenSuit !== null && !SUIT.test(String(a.chosenSuit))) {
    throw new ApiError(400, "bad_request", "action.chosenSuit");
  }
  if (a.type === "chooseSuit" && !SUIT.test(String(a.suit))) throw new ApiError(400, "bad_request", "action.suit");

  for (let attempt = 0; attempt < 3; attempt++) {
    // Membership first (not_a_participant), then the caller's own receipts.
    const ctx = await rpc<Ctx>("srv_load_match", { p_match_id: matchId, p_user_id: userId });
    const receipt = await rpc("srv_find_receipt", { p_match_id: matchId, p_action_id: actionId, p_user_id: userId });
    if (receipt) {
      return { ok: true, duplicate: true, accepted: receipt.accepted, failure: receipt.failure, version: receipt.version };
    }
    if (ctx.match.status !== "in_progress") {
      return { ok: false, accepted: false, failure: "gameFinished", version: ctx.match.version, status: ctx.match.status };
    }
    if (ctx.me.forfeitedAt) return { ok: false, accepted: false, failure: "invalidPlayer", version: ctx.match.version };
    if (expected !== ctx.match.version) {
      // A concurrent copy of THIS request may have just won the race between
      // our receipt lookup and our state load: answer with its receipt, not
      // with "stale", so a double tap never looks like a refusal.
      const late = await rpc("srv_find_receipt", { p_match_id: matchId, p_action_id: actionId, p_user_id: userId });
      if (late) {
        return { ok: true, duplicate: true, accepted: late.accepted, failure: late.failure, version: late.version };
      }
      return { ok: false, accepted: false, failure: "staleState", version: ctx.match.version };
    }

    // The actor is the CALLER's seat — never what the client claims.
    const engineAction: GameActionJson = {
      type: a.type,
      playerId: ctx.me.enginePlayerId,
      baseVersion: ctx.match.version,
      ...(a.type === "playCard" ? { card: a.card } : {}),
      ...(a.type === "playCard" && a.chosenSuit ? { chosenSuit: a.chosenSuit } : {}),
      ...(a.type === "chooseSuit" ? { suit: a.suit } : {}),
    };
    if (a.type === "startNextRound") engineAction.playerId = ctx.me.enginePlayerId;

    const result = engine.applyAction(ctx.state, engineAction, Date.now());
    if (!result.ok) {
      await rpc("srv_record_rejection", {
        p_match_id: matchId, p_user_id: userId, p_action_id: actionId,
        p_version: ctx.match.version, p_action: engineAction, p_failure: result.failure,
      });
      return { ok: false, accepted: false, failure: result.failure, version: ctx.match.version };
    }

    try {
      const commit = await rpc("srv_commit_action", {
        p_match_id: matchId, p_actor: userId, p_action_id: actionId,
        p_base_version: ctx.match.version, p_new_state: result.state,
        p_actions: [engineAction], p_kind: "action",
      });
      if (commit.duplicate) {
        return { ok: true, duplicate: true, accepted: commit.accepted, failure: commit.failure, version: commit.version };
      }
      return {
        ok: true,
        accepted: true,
        version: commit.version,
        status: commit.status,
        events: result.events,
        publicState: redact(result.state),
        hand: handOf(result.state, ctx.me.enginePlayerId),
        drawnCard: result.state.currentSeat === ctx.me.seat ? (result.state.drawnCard ?? null) : null,
        currentUserId: commit.currentUserId,
        turnDeadlineAt: commit.turnDeadlineAt,
      };
    } catch (e) {
      if (e instanceof ApiError && e.code === "stale_version") continue; // somebody committed first: re-judge
      throw e;
    }
  }
  throw new ApiError(409, "stale_version");
}

async function opTimeout(userId: string, body: any) {
  const engine = engineSync();
  const matchId = uuid(body.matchId, "matchId");
  const ctx = await rpc<Ctx>("srv_load_match", { p_match_id: matchId, p_user_id: userId });
  if (ctx.match.status !== "in_progress") {
    return { ok: false, failure: "gameFinished", version: ctx.match.version, status: ctx.match.status };
  }
  if (ctx.me.forfeitedAt) return { ok: false, failure: "invalidPlayer", version: ctx.match.version };
  const state = ctx.state;
  const nowMs = ms(ctx.match.now) ?? Date.now();          // the DATABASE clock
  const deadlineMs = ms(ctx.match.turnDeadlineAt);
  const seatPid = `p${state.currentSeat}`;
  const current = ctx.players.find((p) => p.enginePlayerId === seatPid);
  const overdue = state.status === "roundOver"
    ? deadlineMs !== null && nowMs >= deadlineMs
    : isOverdue({
      nowMs,
      deadlineMs,
      turnStartedMs: ms(ctx.match.turnStartedAt),
      currentLastSeenMs: ms(current?.lastSeenAt),
      hasTimer: ctx.match.turnTimerSeconds > 0,
    });
  if (!overdue) {
    return { ok: false, failure: "deadlineNotReached", version: ctx.match.version, turnDeadlineAt: ctx.match.turnDeadlineAt };
  }

  const plan = planTimeout(state, current?.consecutiveTimeouts ?? 0, (s, a) => engine.applyAction(s, a, Date.now()));
  let working = state;
  const applied: GameActionJson[] = [];
  let events: string[] = [];
  for (const action of plan.actions) {
    const r = engine.applyAction(working, action, Date.now());
    if (!r.ok) throw new ApiError(500, "timeout_plan_rejected", `${action.type}: ${r.failure}`);
    working = r.state;
    applied.push(action);
    events = events.concat(r.events);
  }
  try {
    const commit = await rpc("srv_commit_action", {
      p_match_id: matchId,
      p_actor: plan.kind === "system" ? null : current?.userId ?? null,
      p_action_id: null,
      p_base_version: ctx.match.version,
      p_new_state: working,
      p_actions: applied,
      p_kind: plan.kind,
    });
    if (plan.kind === "forfeit" && current) {
      // Like a voluntary forfeit: out of the room too, so a rematch vote
      // never waits on a seat that is no longer there.
      await rpc("srv_remove_seat", { p_room_id: ctx.match.roomId, p_user_id: current.userId });
    }
    return { ok: true, kind: plan.kind, version: commit.version, status: commit.status, events, turnDeadlineAt: commit.turnDeadlineAt };
  } catch (e) {
    if (e instanceof ApiError && e.code === "stale_version") {
      // The seat moved in the meantime: nothing to do.
      return { ok: false, failure: "staleState", version: ctx.match.version };
    }
    throw e;
  }
}

async function opForfeit(userId: string, body: any) {
  const engine = engineSync();
  const matchId = uuid(body.matchId, "matchId");
  const ctx = await rpc<Ctx>("srv_load_match", { p_match_id: matchId, p_user_id: userId });
  if (ctx.match.status !== "in_progress") {
    return { ok: false, failure: "gameFinished", version: ctx.match.version, status: ctx.match.status };
  }
  if (ctx.me.forfeitedAt) return { ok: true, alreadyForfeited: true, version: ctx.match.version };
  const action: GameActionJson = { type: "forfeit", playerId: ctx.me.enginePlayerId, baseVersion: ctx.match.version };
  const r = engine.applyAction(ctx.state, action, Date.now());
  if (!r.ok) return { ok: false, failure: r.failure, version: ctx.match.version };
  const commit = await rpc("srv_commit_action", {
    p_match_id: matchId, p_actor: userId, p_action_id: null,
    p_base_version: ctx.match.version, p_new_state: r.state, p_actions: [action], p_kind: "forfeit",
  });
  // Out of the match means out of the room too, so a rematch does not wait on them.
  await rpc("srv_remove_seat", { p_room_id: ctx.match.roomId, p_user_id: userId });
  return { ok: true, version: commit.version, status: commit.status, events: r.events };
}

type RoomInfo = {
  room: {
    id: string; code: string; hostId: string; kind: string; status: string; matchId: string | null;
    maxPlayers: number; turnTimerSeconds: number; rules: Record<string, unknown>;
  };
  seats: Array<{ userId: string; seat: number; isHost: boolean; isReady: boolean; nickname: string; avatarId: string }>;
};

/** Deals a brand-new match for the room's seats and commits it. */
async function dealAndCommit(
  userId: string,
  info: RoomInfo,
  expectedStatus: "lobby" | "finished",
  expectedMatch: string | null,
) {
  const engine = engineSync();
  const { room, seats } = info;
  if (seats.length !== room.maxPlayers) return { ok: false, failure: "room_not_full", seats: seats.length, needed: room.maxPlayers };
  if (seats.some((s) => !s.isReady && !s.isHost)) return { ok: false, failure: "not_everyone_ready" };

  const players = seats.map((s) => ({ id: `p${s.seat}`, name: s.nickname, type: "humanLocal", avatarId: s.avatarId }));
  const rules = {
    ...(room.rules && typeof room.rules === "object" ? room.rules : {}),
    turnTimeLimitSeconds: room.turnTimerSeconds > 0 ? room.turnTimerSeconds : null,
  };
  const matchId = crypto.randomUUID();
  const created = engine.createGame({
    gameId: matchId,
    players,
    rules,
    seed: seed52(),
    mode: "passAndPlay",
    startingSeat: seed52() % players.length,   // the server picks who opens
    now: Date.now(),
  });
  if (!created.ok) throw new ApiError(400, created.failure, created.message);

  const commit = await rpc("srv_commit_match", {
    p_room_id: room.id,
    p_user_id: userId,
    p_expected_status: expectedStatus,
    p_expected_match: expectedMatch,
    p_state: created.state,
    p_seats: seats.map((s) => ({ userId: s.userId, seat: s.seat, enginePlayerId: `p${s.seat}` })),
    p_rematch_of: expectedMatch,
    p_match_id: matchId,
  });
  return { ok: true, matchId: commit.matchId, created: commit.created };
}

async function opStart(userId: string, body: any) {
  const roomId = uuid(body.roomId, "roomId");
  for (let attempt = 0; attempt < 2; attempt++) {
    const info = await rpc<RoomInfo>("srv_room_for_deal", { p_room_id: roomId, p_user_id: userId });
    const { room } = info;
    if (room.status === "in_progress" && room.matchId) return { ok: true, matchId: room.matchId, created: false };
    if (room.status !== "lobby") throw new ApiError(409, "room_not_startable", room.status);
    if (room.kind === "private" && room.hostId !== userId) throw new ApiError(403, "not_the_host");
    try {
      return await dealAndCommit(userId, info, "lobby", null);
    } catch (e) {
      if (e instanceof ApiError && e.code === "room_changed" && attempt === 0) continue;
      throw e;
    }
  }
  throw new ApiError(409, "room_changed");
}

async function opRematch(userId: string, body: any) {
  const matchId = uuid(body.matchId, "matchId");
  const vote = await rpc("srv_rematch_vote", { p_match_id: matchId, p_user_id: userId });
  if (!vote.ready) return { ok: true, status: "waiting", votes: vote.votes, needed: vote.needed, roomId: vote.roomId };
  const info = await rpc<RoomInfo>("srv_room_for_deal", { p_room_id: vote.roomId, p_user_id: userId });
  if (info.room.status === "in_progress" && info.room.matchId && info.room.matchId !== matchId) {
    return { ok: true, status: "started", matchId: info.room.matchId, roomId: vote.roomId };
  }
  const dealt = await dealAndCommit(userId, info, "finished", matchId);
  if (!dealt.ok) return { ...dealt, status: "waiting", roomId: vote.roomId };
  return { ok: true, status: "started", matchId: dealt.matchId, roomId: vote.roomId, created: dealt.created };
}

// --------------------------------------------------------------- server

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") return json({ ok: false, error: "method_not_allowed" }, 405);
  try {
    const userId = await authenticate(req);
    let body: any;
    try {
      body = await req.json();
    } catch {
      throw new ApiError(400, "bad_request", "body must be JSON");
    }
    switch (body?.op) {
      case "ping":
        return json({ ok: true, engine: engineSync().version(), userId });
      case "start":
        return json(await opStart(userId, body));
      case "action":
        return json(await opAction(userId, body));
      case "timeout":
        return json(await opTimeout(userId, body));
      case "forfeit":
        return json(await opForfeit(userId, body));
      case "rematch":
        return json(await opRematch(userId, body));
      default:
        throw new ApiError(400, "bad_request", "unknown op");
    }
  } catch (e) {
    if (e instanceof ApiError) {
      return json({ ok: false, error: e.code, detail: e.message }, e.status);
    }
    console.error("match: unhandled", e);
    return json({ ok: false, error: "internal" }, 500);
  }
});
