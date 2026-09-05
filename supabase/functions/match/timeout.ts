// The documented turn-timeout / abandonment policy (docs/ONLINE_MULTIPLAYER.md
// §Timeouts). Pure: takes the authoritative state, returns the GameActions
// the server should apply on behalf of the seat whose time ran out. The
// engine still validates every one of them — this file never decides
// legality, it only picks the least harmful legal move.

import type { GameActionJson, GameStateJson } from "./engine.ts";

export const TIMEOUTS_BEFORE_FORFEIT = 3;
/** With no turn timer, a seat unseen for this long on its own turn is treated as timed out. */
export const ABANDON_AFTER_MS = 90_000;
/** Between rounds the server waits this long for a "next round" tap before dealing. */
export const ROUND_OVER_GRACE_MS = 30_000;

export type TimeoutPlan =
  | { kind: "system"; actions: GameActionJson[] }        // deal the next round
  | { kind: "timeout"; actions: GameActionJson[] }       // move for the seat
  | { kind: "forfeit"; actions: GameActionJson[] };      // third strike

const SUITS = ["denari", "coppe", "spade", "bastoni"];

/** Most-held suit in the hand; ties broken by deck order (GAME_SPEC §1). */
export function suitToName(hand: string[]): string {
  const counts = new Map<string, number>();
  for (const id of hand) {
    const suit = id.split("_")[0];
    counts.set(suit, (counts.get(suit) ?? 0) + 1);
  }
  let best = SUITS[0];
  let bestCount = -1;
  for (const suit of SUITS) {
    const n = counts.get(suit) ?? 0;
    if (n > bestCount) {
      best = suit;
      bestCount = n;
    }
  }
  return best;
}

/**
 * Plans the server's move for the current seat. `apply` is the engine step
 * (needed because "draw, then pass if the turn is still ours" depends on
 * what was drawn). Returns the actions in order; the caller commits them
 * atomically.
 */
export function planTimeout(
  state: GameStateJson,
  strikesSoFar: number,
  apply: (s: GameStateJson, a: GameActionJson) => { ok: true; state: GameStateJson } | { ok: false; failure: string },
): TimeoutPlan {
  const status = state.status as string;
  if (status === "roundOver") {
    return {
      kind: "system",
      actions: [{ type: "startNextRound", playerId: "system", baseVersion: state.version }],
    };
  }
  const seat = state.players[state.currentSeat];
  const pid = seat.id as string;

  if (strikesSoFar + 1 >= TIMEOUTS_BEFORE_FORFEIT) {
    return {
      kind: "forfeit",
      actions: [{ type: "forfeit", playerId: pid, baseVersion: state.version }],
    };
  }

  if (status === "awaitingSuitChoice") {
    return {
      kind: "timeout",
      actions: [{ type: "chooseSuit", playerId: pid, suit: suitToName(seat.hand), baseVersion: state.version }],
    };
  }

  const actions: GameActionJson[] = [];
  let current = state;
  if (state.pendingDrawCount > 0 || !state.hasDrawnThisTurn) {
    const draw: GameActionJson = { type: "drawCard", playerId: pid, baseVersion: current.version };
    const r = apply(current, draw);
    if (!r.ok) {
      // Should not happen (a draw is always legal on one's turn); fall back
      // to a pass so the table never stalls.
      return { kind: "timeout", actions: [{ type: "pass", playerId: pid, baseVersion: current.version }] };
    }
    actions.push(draw);
    current = r.state;
  }
  // Still our turn (the drawn card was playable, or we had already drawn):
  // decline to play it and pass.
  if (current.status === "awaitingAction" && current.players[current.currentSeat].id === pid) {
    actions.push({ type: "pass", playerId: pid, baseVersion: current.version });
  }
  return { kind: "timeout", actions };
}

/** Whether, per policy, the seat to act has run out of time. All times epoch ms, from the DATABASE clock. */
export function isOverdue(opts: {
  nowMs: number;
  deadlineMs: number | null;
  turnStartedMs: number | null;
  currentLastSeenMs: number | null;
  hasTimer: boolean;
}): boolean {
  if (opts.deadlineMs !== null && opts.nowMs >= opts.deadlineMs) return true;
  if (!opts.hasTimer) {
    const started = opts.turnStartedMs ?? 0;
    const seen = opts.currentLastSeenMs ?? 0;
    return opts.nowMs - started >= ABANDON_AFTER_MS && opts.nowMs - seen >= ABANDON_AFTER_MS;
  }
  return false;
}
