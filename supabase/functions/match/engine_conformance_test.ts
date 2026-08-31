// Runs the shared conformance fixtures (test/fixtures/game_conformance) through
// the dart2js-compiled engine the Edge Function uses — the SAME files the
// Flutter test suite replays against the Dart VM engine.
//
//   deno test --allow-read supabase/functions/match/engine_conformance_test.ts
import { assertEquals } from "jsr:@std/assert@1";
import { loadEngine } from "./engine.ts";

const here = new URL(".", import.meta.url).pathname;
const fixtureDir = `${here}../../../test/fixtures/game_conformance`;

function canon(v: unknown): unknown {
  if (Array.isArray(v)) return v.map(canon);
  if (v && typeof v === "object") {
    const o: Record<string, unknown> = {};
    for (const k of Object.keys(v as object).sort()) {
      const x = (v as Record<string, unknown>)[k];
      if (x === null || x === undefined) continue;
      o[k] = canon(x);
    }
    return o;
  }
  return v;
}

const engine = await loadEngine();
const names: string[] = [];
for await (const e of Deno.readDir(fixtureDir)) {
  if (e.name.endsWith(".json")) names.push(e.name);
}
names.sort();
if (names.length < 51) throw new Error(`only ${names.length} fixtures found`);

for (const name of names) {
  Deno.test(`conformance ${name}`, async () => {
    const fx = JSON.parse(await Deno.readTextFile(`${fixtureDir}/${name}`));
    const out = engine.applyAction(fx.initialState, fx.action, null);
    if (fx.expectedFailure) {
      assertEquals(out.ok, false, "expected a rejection");
      if (!out.ok) assertEquals(out.failure, fx.expectedFailure);
      return;
    }
    assertEquals(out.ok, true, `rejected: ${out.ok ? "" : out.failure}`);
    if (!out.ok) return;
    assertEquals(canon(out.state), canon(fx.expectedState));
    assertEquals(out.events, fx.expectedEvents);
    // The hand-written assertions, checked here too.
    const st = out.state;
    for (const [key, expected] of Object.entries(fx.assertions ?? {})) {
      const actual = readAssertion(st, key);
      assertEquals(actual, expected, `${name}: ${key}`);
    }
  });
}

function readAssertion(st: any, key: string): unknown {
  const players = st.players as any[];
  const byId = (id: string) => players.find((p) => p.id === id);
  if (key.startsWith("handSize.")) return byId(key.slice(9)).hand.length;
  if (key.startsWith("score.")) return byId(key.slice(6)).score;
  if (key.startsWith("eliminated.")) return byId(key.slice(11)).eliminated;
  switch (key) {
    case "currentPlayerId": return players[st.currentSeat].id;
    // §12a — who dealt this round, as a seat and as an id.
    case "dealerId": return players[st.dealerSeat ?? 0].id;
    case "topCard": return st.discardPile[st.discardPile.length - 1];
    case "drawPileSize": return st.drawPile.length;
    case "discardPileSize": return st.discardPile.length;
    default: return st[key] ?? null;
  }
}
