// Loads the dart2js-compiled Gioco del 101 engine (supabase/functions/_shared/
// engine.js — built by tool/build_engine_js.sh from the Dart sources under
// lib/features/game/domain) and exposes it with typed JSON in/out.
//
// The engine is pure: no clock, no randomness of its own, no I/O. Every
// shuffle derives from the state's seed and version, so the server and the
// Flutter app compute byte-identical states from the same inputs.

export type GameStateJson = Record<string, any>;
export type GameActionJson = {
  type: "playCard" | "drawCard" | "chooseSuit" | "pass" | "startNextRound" | "forfeit";
  playerId: string;
  baseVersion?: number;
  card?: string;
  chosenSuit?: string;
  suit?: string;
};

export type ApplyResult =
  | { ok: true; state: GameStateJson; events: string[] }
  | { ok: false; failure: string; message?: string };

export type CreateResult =
  | { ok: true; state: GameStateJson }
  | { ok: false; failure: string; message?: string };

export interface Engine {
  createGame(params: {
    gameId: string;
    players: Array<{ id: string; name: string; type: string; avatarId: string }>;
    rules: Record<string, unknown>;
    seed: number;
    mode?: string;
    startingSeat?: number;
    now?: number;
  }): CreateResult;
  applyAction(state: GameStateJson, action: GameActionJson, now: number | null): ApplyResult;
  validate(state: GameStateJson, action: GameActionJson): string | null;
  playable(state: GameStateJson, playerId: string): {
    cards: string[];
    canDraw: boolean;
    canPass: boolean;
    mustTakePenalty: boolean;
  };
  version(): string;
}

type Raw = {
  gioco101CreateGame: (p: string) => string;
  gioco101ApplyAction: (s: string, a: string, now: number | null) => string;
  gioco101Validate: (s: string, a: string) => string;
  gioco101Playable: (s: string, p: string) => string;
  gioco101EngineVersion: () => string;
};

let cached: Engine | null = null;

// dart2js emits a classic script that installs its exports on `self`;
// importing it for its side effects is enough and keeps it inside the
// deployed bundle.
import "./engine.js";

export function loadEngine(): Promise<Engine> {
  return Promise.resolve(engineSync());
}

export function engineSync(): Engine {
  if (cached) return cached;
  const g = globalThis as unknown as Raw;
  if (typeof g.gioco101ApplyAction !== "function") {
    throw new Error("engine.js did not export gioco101ApplyAction");
  }
  cached = {
    createGame: (p) => JSON.parse(g.gioco101CreateGame(JSON.stringify(p))),
    applyAction: (s, a, now) =>
      JSON.parse(g.gioco101ApplyAction(JSON.stringify(s), JSON.stringify(a), now)),
    validate: (s, a) =>
      JSON.parse(g.gioco101Validate(JSON.stringify(s), JSON.stringify(a))).failure ?? null,
    playable: (s, p) => JSON.parse(g.gioco101Playable(JSON.stringify(s), p)),
    version: () => g.gioco101EngineVersion(),
  };
  return cached;
}
