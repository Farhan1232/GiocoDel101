# Session Handoff — Session 5 → Session 6

Date: 2026-08-30. Branch: `feature/session-1-ui-foundation` (continued; the
Session 5 checkpoint commit sits on top of Session 4's `6c9a1c6`).

Sessions 1–4 handoffs are in git history at their checkpoints; what still
matters from them is summarised in §7.

---

## 0. What Session 5 delivered

**The offline game, the bots, and the player-retention layer — on the same
engine, without touching how online play works.** Full narratives:
`docs/OFFLINE_MODE.md`, `docs/BOTS.md`, `docs/PROGRESSION.md`.

### Offline play (works with no network at all)
- 1 human + 1/2/3 bots and pass & play, all through `GameSession` →
  `GameEngine` — the one rule set (`docs/GAME_ENGINE.md`). No card rule is
  duplicated anywhere in the bots or the UI.
- **Pause / resume** (`TableController.pause()`; `PauseOverlay` with sound,
  music and vibration switches, the rules and exit): bots finish their
  "thinking" pause and then wait; input is refused; the app going to the
  background pauses the table and flushes the save (`app.dart`).
- **Continua partita**: the live `GameState` is saved (coalesced, 350 ms)
  after every state change and immediately on leaving; Home offers the
  card; `MatchLauncher.resume()` restores the canonical state. Fixed a real
  resume bug: a save taken while the Suit Ritual was open restored to a
  table that could not be played (`pendingSuitChoice` is now rebuilt in
  `GameController.onInit`; `test/session5_offline_test.dart`).
- Quit confirmation (offline: autosave; online: forfeit; tutorial: plain
  exit), round/match result, rematch, "Nuova partita".
- **Bot thinking delay** (420–900 ms, `AppDurations.botThinkMin/Max`,
  scaled by the speed setting / Reduce Motion) plus a visible "thinking"
  indicator on the active bot seat (`ThinkingDots`).
- **Deal animation** (`DealCue` → `GameScreen._animateDeal`): a fresh match
  and every new round are dealt round-robin from the stock; a resumed match
  simply appears. Draw / play / Asso skip / +2 Chain Storm / Cavallo Suit
  Ritual / victory were already there and are unchanged.
- **CENTOUNO!** — `CentounoFlourish`: the word in struck gold with one slow
  sheen, the Fate Ring completing and resetting, the score counting
  101 → 0. Shown full-stage on the round-result screen and in the tutorial.
  Static under Reduce Motion. No confetti.
- Reactions: the eight local lines, bubble animation, **2 s cooldown**
  (`GameController.reactionCooldown`, the same gap the server enforces),
  sound through the effects toggle.
- Audio: the project's own 17 synthesized assets (`docs/ASSET_INVENTORY.md`)
  — nothing downloaded. Music, effects and vibration toggles were already
  wired; they are now also on the pause sheet.

### Bots (`lib/features/game/domain/ai/`)
`BotStrategy` with `EasyBot` (random legal card, spots the winning card,
40 % random suit), `NormalBot` (weighted: shed high cards, suit control,
Asso/2 timed against the next seat's hand size, +2 answered, Cavallo held
until the endgame, suit = longest suit) and `HardBot` (Normal plus counting
the cards that went by, exploiting suits an opponent could not follow,
scarcity, danger/endgame weighting, pressure on a doomed opponent, keeping a
2 as an answer, aimed Asso/2 at a one-card hand). Personalities (Marco,
Sofia, Luca, Giulia) scale the weights. **No hidden information exists in
`BotView`**: no opponent hand, no stock order, no seed — cheating is
impossible to express (`test/bot_test.dart` proves two tables that differ
only in hidden cards yield the same move).

### Interactive tutorial (`lib/features/tutorial/`)
Eight lessons, each a fixed `GameState` the real engine plays on the real
table (`TutorialController` implements `TableController`; `TutorialScreen`
is `GameScreen` plus a lesson card): seme o valore → pescare (and play the
drawn card) → Asso → Due → catena di Due (+4) → Cavallo (and the Suit
Ritual) → Cavallo contro il 2 (block) → **Centouno!** (your last card puts
Marco on exactly 101). Only the asked-for card lights up; a wrong card is
refused with a hint; the scripted opponent is the Normal bot on a hand
chosen so its reply is the one the lesson wants to show. No statistics, no
saves, no results screen. `test/session5_tutorial_test.dart` proves every
lesson holds 40 distinct cards and that every asked-for move is legal and
has the described effect, then walks the whole course through the
controller.

### Rules screen
Ten illustrated pages as before, plus: opened from a table it shows
**"Regole di questa partita"** — the actual `GameRules` of that match and
its turn timer (`_ActiveRulesPanel`); opened from Home it offers the
tutorial.

### Statistics — two ledgers, never mixed
- Offline (`StatisticsModel`, local): matches, rounds, cards, chains,
  101s, streaks, achievements, **offline XP** (`xp`, 20 per match + 45 per
  win, plus offline mission rewards; migrated from the old derived number so
  nobody's level drops) and today's mission counters.
- Online (`profiles` / `player_stats`, server-owned): shown read-only on the
  Statistics tab under "ONLINE — PROFILO" and on the Profile screen.
- **Offline games never touch `profiles.rating`, the leaderboard, online XP
  or online achievements** — there is no code path from the local ledger to
  the server.

### Leaderboard
Real `public.leaderboard(scope, limit, offset)` in pages of 25 with "Carica
altri", weekly (`weekly_points`, ISO week Europe/Rome) and all-time
(`profiles.rating`), the player's row highlighted, and a pinned **"La tua
posizione"** row from `my_leaderboard_rank(scope)` when the player is not
on the loaded pages (or "not ranked yet"). No fake users. Errors show a
retry.

### Achievements — Prima Vittoria, Centouno!, Vendetta, Maestro del Nove, Imbattibile, Veterano (+ Catena, Mano Perfetta, Sfidante)
- Offline: `StatisticsService` as before, local only.
- **Online: server-validated.** Migration 8 adds `match_round_results`
  (written by `srv_commit_action` from the engine's `lastRoundResult` when a
  round ends) and `app_private.evaluate_achievements`, run by
  `settle_match` after `record_match_result` — the rules per badge are in
  `docs/PROGRESSION.md`. The client only reads `user_achievements`;
  `AchievementsScreen` shows the union, labelled "Sbloccato online" /
  "Sbloccato offline".

### Progression
Level ladder unchanged (120 + 40/level, identical in `LevelLadder` and
`app_private.level_for_xp`). Profile shows level, XP into the level, the
next level and the XP to go. Online XP moves only through
`app_private.grant_xp` (match results, mission claims).

### Daily missions — 7-day cycle
`MissionCatalog.rotation` (Dart) = `app_private.mission_rotation(isodow)`
(SQL): Mon–Sun, three missions a day — play 2/3 matches, win 1/2, play 3/4
Assi, play 3/4 twos, use 1–3 Cavalli, block a +2, complete 1–2 online
matches. Online: rows are materialised by the server for the Europe/Rome
day, progress is written **only** by `srv_commit_action` (the actor's own
accepted Asso / 2 / Cavallo / Cavallo-into-chain) and `settle_match`
(matches, wins, online matches), and `claim_mission_reward` re-checks the
date, completion and prior claim on the database clock before granting XP.
Offline: the same rotation, counted from the person's own plays at the local
table, rewarded with local XP only; `online_match` is shown as online-only.
`MissionsScreen` shows both halves; the Home "Missioni" card counts them.

### Settings
Italian/English, music, sound, vibration, reduce animation, large cards,
logout — and a **guest logout with a warning** that the account and its
online progress are lost for good (guests previously had no way out).

### Online resilience
Every online screen already handled "not configured" and "not signed in";
matchmaking now also shows a real "service unreachable" message with the
offline game one tap away. Nothing online can crash the offline game: the
backend seam is `BackendServices.none()` when Supabase is absent.

### "Continua contro CPU"
`MatchmakingScreen`: after 30 s in the queue with nobody else
(`cpuOfferAfterSeconds`) the screen offers an **offline** match against
bots for the same table size. It cancels the queue for real and launches
`MatchFactory.vsComputer`; the seats are the bot roster's, nothing is
ranked, and no bot is ever presented as a human
(`test/session5_screens_test.dart`).

### Server (migrations 8 and 9, applied to GiocoDel101-Dev)
`20260830120000_progression_missions.sql`, `20260830123000_claim_mission_fix.sql`
— see `docs/DATABASE_SCHEMA.md` and `docs/SECURITY.md`. The engine did
**not** change: `engine.js` is byte-identical, no redeploy of the `match`
function was needed, the 41 conformance fixtures and the 48 Deno tests are
untouched.

### Not done, deliberately
- No rating formula (§12b still unconfirmed — deltas remain 0).
- XP amounts (20/45, mission rewards) remain provisional placeholders.
- No online bots at online tables (the CPU offer is an offline match).
- No AdMob / IAP / publishing (as instructed).

---

## 1. Verification — exactly what ran

### Local gates

| Gate | Result |
|---|---|
| `dart format lib test tool` | clean |
| `flutter analyze` | **No issues found** |
| `flutter test` | **501/501 passed** (454 baseline + 47 new) |
| `deno test --allow-read supabase/functions/match/` | **48/48** (engine unchanged) |
| `dart run tool/bot_simulation.dart` | **270 matches (Easy/Normal/Hard × 2/3/4 players × 30), 90 796 actions, 0 invariant violations, 0 hangs, 0 illegal proposals, ~3.5 s.** Every combination exercised reshuffles, +2 chains up to length 4, Cavallo blocks, Asso skips and penalty draws; exact-101 resets occurred in 8 of the 9 combinations (none happened to fall in easy × 2 players on these seeds). Invariants checked after every step: exactly 40 cards, no duplicates, discard never empty, current seat live, no negative counts, every bot move accepted by the engine, termination, finished state stable (further actions refused, version unchanged), exactly one winner |
| `flutter build apk --debug` | **ok** — `build/app/outputs/flutter-apk/app-debug.apk` (Gradle `assembleDebug`, 520 s on this machine); not installed anywhere (no device) |

New tests this session: `test/bot_simulation_test.dart` (10),
`test/session5_tutorial_test.dart` (19), `test/session5_offline_test.dart`
(10), `test/session5_screens_test.dart` (8). Two existing tests were updated
for the explicit offline `xp` counter.

### Remote — GiocoDel101-Dev (`fnyllrjchbqfrzezfeso`)

**Online regression, `tool/online_matrix.dart`** (five independent
authenticated clients, the deployed `match` function, migrations 8–9 live):

| Run | Scope | Result |
|---|---|---|
| quick (`MATRIX_QUICK=1`, 733 s) | 2-player to 101 + every section except the 3/4-player games | **99/100** — every functional area PASS (private room, private hands 20/20, concurrency & attacks 12/12, 2-player, match result, rematch, reconnect, realtime, reactions, RLS, turn timer, forfeit/leave, quick match 15/15, 9 block). The one FAIL is the aggregate "draw pile recycled across the games (0×)": in quick mode only the 2-player game runs and that deal happened to finish without exhausting the stock — a luck-of-the-deal statistic, not a behaviour change |
| **full** (`MATRIX_SKIP_TIMEOUT=1`, 1711 s, after migrations 8–9) | **ALL PASS — 22/22 areas, 130/130 checks.** 2-player to 101 (384 actions, 12 rounds, 23 Assi, 20 Due, 29 Cavalli, max chain 3, 2 reshuffles), 3-player to 45 (227 actions, 8 rounds), 4-player to 45 with 8-card hands (245 actions, 5 rounds, max chain 4, 3 Cavallo blocks, 5 reshuffles); 0 app-engine moves refused by the server; match result 21/21 (placements, `is_winner`, XP 65/20, profiles moved server-side) |

**Progression, `tool/progression_smoke.dart`** (new; two fresh users play a
complete 2-player match through the function, then every Session 5 server
path is checked):

| Run | Result |
|---|---|
| 1 (migration 8 only) | 81 checks, **5 FAIL — a real bug**: `claim_mission_reward` failed with `column reference "mission_id" is ambiguous` (its `RETURNS TABLE` names shadowed the table columns). Everything else PASS: profiles +1 match / XP 65 & 20 / level; `match_round_results` 18 rows = 2 seats × 9 rounds with one round winner each, agreeing with every client-observed `lastRoundResult`; `prima_vittoria` for the winner only, `mano_perfetta` where the server saw a no-draw round win, `maestro_semi` for a winner who named all four suits, `rinascita`/`catena` correctly absent; missions `play_aces 3/3`, `use_nine 3/3` (capped), `online_match 1/2`; client writes to `user_daily_missions` / `daily_missions` refused (42501), `app_private.track_mission` unreachable; leaderboard pages 1..25 / 26.., own rank consistent with paging, weekly points = 65, legacy two-argument call still works |
| 2 (after migration 9, 582 s) | **81 checks, 0 failures.** Match: 330 actions, 11 rounds, winner A; 22 `match_round_results` rows (2 × 11) matching the 11 rounds both clients saw; XP 0 → 65 (winner) / 20; `play_aces` claim +25 XP (65 → 90, level consistent), second claim → `already_claimed` with XP unchanged, incomplete `online_match` (1/2) → `not_completed`, random id → `mission_expired`, progress untouched by the refused attempts; all Session 5 write-protection and leaderboard checks PASS again |

### Real app
No phone or emulator on this machine (§2). The Session 4 headless-Chrome
driver (`tool/ui_drive_web.ts`) was not re-run this session; the online
client code paths it exercised were not changed (see "Do not let offline
changes break online" below).

### Do not let offline changes break online — what was checked
- `OnlineMatchController` untouched except one added `DealCue` sound case
  in its cue switch (it never emits a `DealCue`).
- `TableController` gained defaults only (`paused`, `canPause`,
  `isTutorial`, `showsCoachMarks`); the online driver inherits them.
- `srv_commit_action` was re-created with the same contract plus the round
  record and mission ticks; the full matrix above is the regression.
- `test/session4_online_test.dart` (controller against the in-process fake
  server) still passes in the suite.

### Dev-project state left behind
Test accounts `s4-*@example.com`, `s5-prog-*@example.com`, their rooms,
finished matches, `match_round_results`, `user_achievements` and
`user_daily_missions` rows.

### Not verified
- Android / iOS on a device or emulator (none available).
- Missions keyed to weekdays other than the run day are covered by unit
  tests of the rotation, not by a server run on each weekday.

---

## 2. Blockers

1. **Rating formula (§12b)** — unchanged: `app_private.rating_deltas()`
   returns zeros.
2. **XP economy** — 20/45 per match/win and the mission rewards are
   placeholders; the client should confirm before release.
3. **No device or emulator on this machine** — the APK builds (see §1) but
   was not installed anywhere; the web build is the only runtime target
   here.
4. Session 3/4 production checklist unchanged: SMTP, leaked-password
   protection, CAPTCHA, per-user function rate limiting.

---

## 3. Files Session 6 must read

1. `docs/OFFLINE_MODE.md`, `docs/BOTS.md`, `docs/PROGRESSION.md` — this
   session's design.
2. `docs/ONLINE_MULTIPLAYER.md`, `docs/SECURITY.md` — still the online
   contract; §"Rounds, results, rematch" now mentions the settlement steps.
3. `supabase/migrations/20260830120000_progression_missions.sql` and
   `…123000_claim_mission_fix.sql`.
4. `lib/features/game/application/game_controller.dart` and
   `lib/features/tutorial/application/tutorial_controller.dart` — the two
   local drivers of `TableController`.
5. `tool/bot_simulation.dart`, `tool/progression_smoke.dart`,
   `tool/online_matrix.dart` — re-run all three after any change to the
   engine, the bots or the server.

---

## 4. Things Session 6 must know

1. **`GetxController.refresh()` exists** — never name a method `refresh` on
   a controller (`MissionsController.reload()`).
2. **Widget tests and fake time**: awaiting a controller method that plays
   cues (`playCard`, `chooseSuit`) inside `testWidgets` deadlocks — use
   `unawaited(...)` and pump the clock; and settle every pending timer
   (save coalescing, banners, bot pacing) before the test body ends.
3. `RETURNS TABLE` column names are PL/pgSQL variables: qualify every table
   reference or set `#variable_conflict use_column` (migration 9 lesson).
4. The mission rotation lives in two places on purpose (`MissionCatalog`
   in Dart for the offline table, `app_private.mission_rotation` in SQL for
   online); `test/session5_offline_test.dart` pins the Dart side, the smoke
   tool checks the SQL side against the day it runs. Change both together.
5. Every new public function needs an explicit `GRANT` (default privileges
   are revoked); every new table needs RLS + `GRANT SELECT`.
6. `flutter gen-l10n` after editing an ARB; the IT/EN identical-string test
   has an allow-list (`centounoTitle`, `missionsReward` were added).
7. `supabase db push < /dev/null` still works without a password prompt on
   the linked project; `supabase migration list` should show 9 = 9.

---

## 5. Client questions (carry-over + new)

| # | Question | Field / place | Provisional |
|---|---|---|---|
| 1 | Cavallo cancels or passes on a pending +2? | `GameRules.nineBlockMode` | `cancel` |
| 2 | Blocking Cavallo still changes suit? | `nineBlockChangesSuit` | `true` |
| 3 | Online points formula (§12b) | `app_private.rating_deltas` | zeros |
| 4 | XP per match / per win; mission XP | `record_match_result`, `mission_rotation` | 20 / 45; 20–50 per mission |
| 5 | Turn-timer expiry | `timeout.ts`, `srv_commit_action` | safe move; forfeit on 3rd strike; 90 s abandonment; 30 s auto-deal |
| 6 | Daily reward: guests allowed? | `claim_daily_reward` | permanent accounts only |
| 7 | Quick-match timer | `MatchmakingScreen._quickMatchTimerSeconds` | 30 s |
| 8 | Forfeited seat's cards to the stock or out? | `GameEngine._forfeit` | bottom of the stock |
| 9 | CPU offer after how long in the queue? | `MatchmakingScreen.cpuOfferAfterSeconds` | 30 s |
| 10 | Should offline missions exist at all, or online only? | `MissionsController` | both halves shown, offline pays local XP only |
| 11 | Bot difficulty default | `SettingsModel.defaultDifficulty` | Normal |

---

## 6. Commands

```bash
export PATH="$HOME/flutter-sdk/bin:$HOME/.deno/bin:$PATH"

flutter pub get && flutter analyze && flutter test
dart format lib test tool
flutter gen-l10n                                  # after editing an ARB

dart run tool/bot_simulation.dart                 # SIM_MATCHES=… to change the count
tool/build_engine_js.sh                           # after any engine change (none this session)
deno test --allow-read supabase/functions/match/
supabase db push < /dev/null                      # linked project
supabase migration list

SUPABASE_URL=… SUPABASE_PUBLISHABLE_KEY=… dart run tool/progression_smoke.dart
SUPABASE_URL=… SUPABASE_PUBLISHABLE_KEY=… MATRIX_QUICK=1 dart run tool/online_matrix.dart

flutter build apk --debug                         # ANDROID_HOME=$HOME/Android/Sdk
```

---

## 7. Still true from Sessions 1–4

- Feature-first layout; GetX only; `app_it.arb` is the template.
- `MatchLauncher` / `OnlineMatchLauncher` / `TutorialLauncher` register the
  `TableController`; `InitialBinding` runs before `runApp`.
- The engine is pure and deterministic; `seed` is private; after any
  engine change rebuild `engine.js`, run the Deno tests, redeploy.
- Two Realtime channels per match; policies may only call `public`
  functions; the online driver is `permanent: true`.
- `test/tools/*` are tools, not tests; `android/gradle.properties` heap
  stays lowered on this machine.
