# Session Handoff — Session 2 → Session 3

Date: 2026-08-29. Branch: `feature/session-1-ui-foundation` (continued;
Session 2 checkpoint commit on top of Session 1's).

Session 1's handoff (project restore, lost Firebase work, restructure,
localization, GetX trap, Gradle heap) still applies — it is preserved in git
history at the Session 1 checkpoint and summarised in §6 below.

---

## 0. What Session 2 delivered

**One deterministic, immutable, fully tested Dart rules engine** that runs
the offline table now and *is* the specification of the online server.
Reference: **`docs/GAME_ENGINE.md`** — read it first.

- `GameState` (immutable, JSON round-trip, schema 2) replaced the mutable
  `MatchState` + `RoundState`.
- `GameRules` (was `GameRulesConfig`) now carries every open rule as a
  provisional, documented field — nothing is assumed inside a class.
- `GameAction` is a sealed command set: `PlayCard`, `DrawCard`, `ChooseSuit`,
  `Pass`, `StartNextRound`; each carries the actor and an optional
  `baseVersion` for idempotency.
- `GameEngine` is `const` and pure: `validateAction` / `applyAction` /
  `getPlayableCards` / `createGame`, returning typed `GameFailure`s.
  Shuffles derive from `seed ^ version`, so `(state, action) → state'` is a
  pure function — replays and server verification are byte-exact.
- `GameSession` is the single stateful handle the controller, bots and
  persistence use. It contains no rules.
- `ScorePolicy` (was `ScoreCalculator`) — only the client-confirmed §10/§11
  rules; nothing invented.
- `CardRank` is now Italian (`asso…re`); legacy English keys still parse.
- The Cavallo-blocks-+2 rule (§6a) is **implemented behind
  `GameRules.nineBlockMode`** (`disabled` / `cancel` / `passOn`) with a
  provisional default of `cancel`. The client picks; nobody rewrites code.
- 37 conformance fixtures in `test/fixtures/game_conformance/` — the
  acceptance tests for the Supabase authoritative function.
- The existing Game Table UI is wired to the real engine through
  `GameSession`; Pass & Play drives every seat manually. No screen was
  redesigned.

Not touched, deliberately: Supabase, networking, Firebase, monetization,
online multiplayer.

---

## 1. Verification — exactly what ran

| Gate | Result |
|---|---|
| `dart format lib test` | 167 files, **0 changed** |
| `flutter analyze` | **No issues found** |
| `flutter test` | **403/403 passed** (~32 s), up from 214 at session start |

Baseline before any edit: 214/214 (Session 1 doc said 210; a later commit
had added four).

### Rule test results (all green)

| Suite | Tests | Covers |
|---|---|---|
| `test/engine/card_model_test.dart` | 10 | 40 cards, 10/suit, 4/rank, unique, equality, ids, JSON, legacy keys, asset mapping |
| `test/engine/game_start_test.dart` | 15 | 2/3/4 players, reject 1 and 5, unique ids, hand sizes, non-action opener, `anyCard`, first player, seed-pure deal, clock stamp |
| `test/engine/turn_flow_test.dart` | 20 | turn order 2/3/4, direction, eliminated seats, wrong turn, ownership, suit/rank legality, unknown/eliminated/finished/roundOver actors, stale version, duplicate action, draw/pass discipline, immutability |
| `test/engine/asso_test.dart` | 9 | skip with 2, 3 (incl. wrap), 4 players, eliminated seat, counter-clockwise, legality, last-card Asso |
| `test/engine/due_test.dart` | 11 | +2, +4, +6, +8, draw resolution, only-2-under-chain, `stackDrawTwos=false`, penalty size, penalty reshuffle, chain at round end (both settings) |
| `test/engine/nove_test.dart` | 13 | wild, `wildNineCanAlwaysPlay=false`, mandatory selection, chosen suit controls play, all four suits, last-card Cavallo, block `disabled`/`cancel`/`passOn`, `nineBlockChangesSuit=false`, blocking last card |
| `test/engine/draw_pile_test.dart` | 8 | normal draw, drawn playable card, void tracking, exhaustion → reshuffle keeps top, 40-card invariant through real reshuffles, nothing-to-recycle, deterministic reshuffle, injected RNG |
| `test/engine/score_policy_test.dart` | 13 | penalties, exact 101 reset, over 101 elimination, match winner, `eliminateAbove101=false`, double elimination, comeback, next round dealing, starter policies, full match to a winner |
| `test/engine/serialization_test.dart` | 9 | Card, GameRules (fixed point), GameAction ×5, Player, mid-game GameState resume, finished state, legacy save, corrupt input |
| `test/engine/determinism_test.dart` | 6 | same state+action → same state, full-match replay from seed+log, byte-identical reruns, stale replay refused, restore-and-continue, stateless engine |
| `test/engine/conformance_fixture_test.dart` | 75 | 37 fixtures replayed + 37 scenario self-checks + file/catalogue parity |
| `test/rules_test.dart` | 19 | Session 1 rule suite, now on `GameSession` |
| `test/scoring_test.dart` | 20 | Session 1 scoring suite |
| `test/edge_cases_test.dart` | 13 | random-match termination, conservation, corrupt saves, resume |
| `test/bot_test.dart` | 10 | bots on the new engine; hidden-info guarantee |
| `test/deck_test.dart` | 6 | deck build |
| `test/gameplay_widget_test.dart` | 6 | the real table: taps → actions → engine |

**Game tests: 263.** Whole suite: 403.

Not verified: no device/emulator on this machine, so nothing ran on real
Android/iOS hardware. `flutter build apk --debug` was not re-run this
session (no native/gradle change was made).

---

## 2. Ambiguous client rules (all implemented, all switchable)

| # | Question | Field | Provisional default |
|---|---|---|---|
| 1 | Does a Cavallo cancel a pending +2 or pass it on? | `GameRules.nineBlockMode` | `cancel` |
| 2 | Does a blocking Cavallo still change the suit? | `nineBlockChangesSuit` | `true` |
| 3 | After drawing a playable card, may a *different* legal card be played? | `restrictPlayToDrawnCard` | `false` (any legal card) |
| 4 | Opening discard is an action card — what then? | `starterCardPolicy` | `avoidActionCards` |
| 5 | Who leads the next round? | `roundStarterPolicy` | `previousRoundWinner` |
| 6 | Unanswered +2 when the round ends? | `pendingPenaltyAppliesAfterWin` | `false` |
| 7 | Turn-timer expiry: auto-play, auto-draw, forfeit? | `turnTimeLimitSeconds` only stamps a deadline | **not implemented** |
| 8 | Everyone eliminated in one round (§12a)? | code fallback: lowest total | unreachable in practice |
| 9 | Online points formula (§12b) | none | **nothing invented** |

Get 1–2 answered before the online rules are frozen; the fixtures
`nove_blocks_chain_*` must be regenerated if the default changes.

---

## 3. Current blockers

- **None for the engine.** Everything in the brief is implemented and green.
- **For Session 3:** the client's answers to §2 rows 1, 2 and 9. Row 9
  blocks the leaderboard; rows 1–2 only need a default flipped.
- No physical device; iOS never built (no macOS toolchain here).

---

## 4. Files Session 3 must read

1. `docs/GAME_ENGINE.md` — the engine contract the server must honour.
2. `docs/GAME_SPEC.md` — rules, with every provisional flag marked.
3. `lib/features/game/domain/engine/game_engine.dart` — the pure engine.
4. `lib/features/game/domain/game_state.dart` — the wire format (`toJson`).
5. `lib/features/game/domain/game_action.dart` — what clients will POST.
6. `lib/features/game/domain/game_rules.dart` — what a room carries.
7. `test/fixtures/game_conformance/*.json` and
   `test/engine/conformance_fixture_test.dart` — run these against the
   Supabase function exactly as the Dart test runs them against `GameEngine`.
8. `lib/features/game/domain/engine/game_session.dart` — the seam an online
   client fills with server snapshots instead of local `applyAction`.
9. `lib/features/online/domain/online_status.dart` — still the hard-coded
   `notConfigured` constant; Session 3 replaces it.
10. `docs/ARCHITECTURE.md` §Backend — the seam table.

---

## 5. Things Session 3 must know

1. **The seed is private.** `GameState.seed` determines the stock order.
   The server must strip `seed` and `drawPile` (and other players' `hand`s)
   from anything sent to a client. `GameState` today is the *authoritative*
   shape; a redacted `PlayerView` is Session 3's to add.
2. **`baseVersion` is mandatory online.** Every action a client sends must
   carry the version it saw; the server rejects `staleState` and the client
   re-syncs. Locally it is optional.
3. **`StartNextRoundAction` may come from `system`.** The server can deal
   the next round itself with `playerId: GameEngine.systemActorId`.
4. **Time is injected.** `applyAction(state, action, now: epochMs)` stamps
   `turnStartedAt`/`turnDeadlineAt`. The engine never reads a clock; the
   server passes its own. Expiry behaviour is undefined (§2 row 7).
5. **Events are hints.** `ActionAccepted.events` exist for animation. The
   server only needs to persist the state; a client can rebuild the table
   from state alone (the controller already re-renders from `GameState`).
6. **Legacy saves load.** `GameState.fromJson` accepts pre-Session-2
   (`TurnPhase`, English rank keys) JSON. `HomeController` still gates on
   `GameStorageService.hasSavedMatch`.
7. **Fixture regeneration** is explicit:
   `GENERATE_FIXTURES=1 flutter test test/tools/generate_conformance_fixtures.dart`.
   Without the variable the file is inert. The `assertions` block is
   hand-written in `test/support/conformance_scenarios.dart` and is checked
   against *both* the fixture and a fresh run.
8. **Bots only ever see `BotView`** built from `GameState` in
   `BotViewFactory`. If online bots are needed, run them server-side with
   the same factory.
9. **GetX trap (Session 1)** still stands: `MatchLauncher` registers
   `GameController` and deletes it explicitly.
10. **`android/gradle.properties` heap** was lowered in Session 1 for this
    7.7 GB machine; don't raise it back here.

---

## 6. Session 1 notes that still apply

- The repo was restored from GitHub on 2026-08-29; five phases of earlier
  Firebase/online work are gone and unrecoverable from this machine.
- Feature-first layout; GetX is the only state framework.
- `app_it.arb` is the localization template (Italian primary); run
  `flutter gen-l10n` after editing an ARB.
- Nothing pretends to be online: `OnlineStatus.availability` is a constant.
- `test/tools/render_previews.dart` is a tool, not a test (it `exit(0)`s).

---

## 7. Commands

```bash
export PATH="$HOME/flutter-sdk/bin:$PATH"
export ANDROID_SDK_ROOT="$HOME/Android/Sdk" ANDROID_HOME="$HOME/Android/Sdk"

flutter pub get
flutter analyze
flutter test
flutter test test/engine                     # engine only, ~8 s
dart format lib test
GENERATE_FIXTURES=1 flutter test test/tools/generate_conformance_fixtures.dart
```

---

## 8. Where things are

| Looking for | Path |
|---|---|
| **The engine** | `lib/features/game/domain/engine/game_engine.dart` |
| **The state / wire format** | `lib/features/game/domain/game_state.dart` |
| **Actions** | `lib/features/game/domain/game_action.dart` |
| **Every game rule** | `lib/features/game/domain/game_rules.dart` |
| **Card legality** | `lib/features/game/domain/engine/card_rule_resolver.dart` |
| **Scoring** | `lib/features/game/domain/engine/score_policy.dart` |
| Stateful local handle | `lib/features/game/domain/engine/game_session.dart` |
| Conformance fixtures | `test/fixtures/game_conformance/` |
| Fixture catalogue | `test/support/conformance_scenarios.dart` |
| Test table builder | `test/support/engine_harness.dart` (`buildState`, `buildEngine`) |
| Routes | `lib/app/router/app_router.dart` |
| Copy | `lib/l10n/app_it.arb` (template), `app_en.arb` |
| Backend seam | `lib/features/online/domain/online_status.dart` |
