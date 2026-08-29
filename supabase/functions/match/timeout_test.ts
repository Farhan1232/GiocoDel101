import { assert, assertEquals } from "jsr:@std/assert@1";
import { loadEngine } from "./engine.ts";
import { isOverdue, planTimeout, suitToName } from "./timeout.ts";

const engine = await loadEngine();
const here = new URL(".", import.meta.url).pathname;
const fixtures = `${here}../../../test/fixtures/game_conformance`;
const load = async (name: string) =>
  JSON.parse(await Deno.readTextFile(`${fixtures}/${name}.json`)).initialState;

Deno.test("suitToName picks the most-held suit, deck order on ties", () => {
  assertEquals(suitToName(["spade_re", "spade_tre", "coppe_asso"]), "spade");
  assertEquals(suitToName(["bastoni_re", "coppe_asso"]), "coppe");
  assertEquals(suitToName([]), "denari");
});

Deno.test("no draw yet: draw, and pass only if the turn stayed", async () => {
  const state = await load("draw_unplayable_passes_turn");
  const plan = planTimeout(state, 0, (s, a) => engine.applyAction(s, a, null));
  assertEquals(plan.kind, "timeout");
  assertEquals(plan.actions.map((a) => a.type), ["drawCard"]);
  const state2 = await load("draw_playable_keeps_turn");
  const plan2 = planTimeout(state2, 0, (s, a) => engine.applyAction(s, a, null));
  assertEquals(plan2.actions.map((a) => a.type), ["drawCard", "pass"]);
  // Every planned action is legal in sequence.
  let s = state2;
  for (const a of plan2.actions) {
    const r = engine.applyAction(s, a, null);
    assert(r.ok, `rejected ${a.type}`);
    s = r.state;
  }
  assertEquals(s.players[s.currentSeat].id !== "p0", true);
});

Deno.test("pending +4: the timed-out seat takes the penalty", async () => {
  const state = await load("due_draw_resolves_four");
  const plan = planTimeout(state, 1, (s, a) => engine.applyAction(s, a, null));
  assertEquals(plan.actions.map((a) => a.type), ["drawCard"]);
  const r = engine.applyAction(state, plan.actions[0], null);
  assert(r.ok);
  assertEquals(r.state.pendingDrawCount, 0);
});

Deno.test("suit pending: the server names a suit", async () => {
  const state = await load("nove_choose_suit");
  const plan = planTimeout(state, 0, (s, a) => engine.applyAction(s, a, null));
  assertEquals(plan.actions[0].type, "chooseSuit");
  assert(engine.applyAction(state, plan.actions[0], null).ok);
});

Deno.test("round over: the server deals the next round", async () => {
  const state = await load("start_next_round_previous_winner_leads");
  const plan = planTimeout(state, 0, (s, a) => engine.applyAction(s, a, null));
  assertEquals(plan.kind, "system");
  assert(engine.applyAction(state, plan.actions[0], null).ok);
});

Deno.test("third strike forfeits", async () => {
  const state = await load("play_same_suit");
  const plan = planTimeout(state, 2, (s, a) => engine.applyAction(s, a, null));
  assertEquals(plan.kind, "forfeit");
  const r = engine.applyAction(state, plan.actions[0], null);
  assert(r.ok);
  assertEquals(r.state.status, "finished"); // two players: the other wins
});

Deno.test("isOverdue: deadline, and the no-timer abandonment rule", () => {
  assert(isOverdue({ nowMs: 1000, deadlineMs: 1000, turnStartedMs: 0, currentLastSeenMs: 999, hasTimer: true }));
  assert(!isOverdue({ nowMs: 999, deadlineMs: 1000, turnStartedMs: 0, currentLastSeenMs: 0, hasTimer: true }));
  assert(!isOverdue({ nowMs: 100_000, deadlineMs: null, turnStartedMs: 0, currentLastSeenMs: 95_000, hasTimer: false }));
  assert(isOverdue({ nowMs: 100_000, deadlineMs: null, turnStartedMs: 0, currentLastSeenMs: 5_000, hasTimer: false }));
});
