# Client scoring correction — 2026-09-01

One change, and nothing else. The client clarified the hand scoring:

| Card | Rank | Hand score |
|---|---|---|
| Fante ("Jack") | 8 | **8** |
| Cavallo ("9") | 9 | **25** |
| Re ("King") | 10 | **10** |

On 2026-08-31 the request was read as pricing *both* figures at 25
(`docs/CLIENT_FINAL_CHANGE.md` §1). The clarification is that only the
Cavallo carries the 25. The Fante is back to its printed 8; the Re was
already 10 and was not touched.

---

## 1. The one table that prices a card

`ScorePolicy.handPenalty` sums `GameRules.valueOf(rank)` and is still the
only thing in the codebase that prices a card — no widget, controller, bot
or server path keeps its own copy. So the correction is one table:

```dart
// lib/features/game/domain/game_rules.dart
static const Map<CardRank, int> defaultScoreValues = {
  CardRank.asso: 1,    CardRank.due: 2,    CardRank.tre: 3,
  CardRank.quattro: 4, CardRank.cinque: 5, CardRank.sei: 6,
  CardRank.sette: 7,
  CardRank.fante: 8,                       // was figureScoreValue (25)
  CardRank.cavallo: cavalloScoreValue,     // 25
  CardRank.re: 10,
};

static const int cavalloScoreValue = 25;   // was figureScoreValue
```

`figureScoreValue` was renamed to `cavalloScoreValue` because it now prices
exactly one card; the name is private to this file (three references, all in
`game_rules.dart`).

**Nothing about gameplay moved.** `CardRank.fante.value` is still 8 and
`CardRank.cavallo.value` is still 9 — those are *ranks*, and the matching
rules read them. The Cavallo still ignores the active suit, still names a new
one (GAME_SPEC §7) and still blocks a chain (§6a). The Fante is still an
ordinary card matched by suit or rank (§4).

## 2. Saved matches

A saved `GameState` serialises its own `rules.scoreValues`, so a match started
before this patch would otherwise go on charging 25 for a Fante forever.

`GameState.schemaVersion` went 3 → **4**, `legacyScoreSchema` went 2 → **3**,
and `_migrateRules` now recognises *both* superseded default tables:

| Schema | Table it carries | On read |
|---|---|---|
| ≤ 2 | Fante 8, Cavallo 9 (printed) | dropped → current defaults |
| 3 | Fante 25, Cavallo 25 | dropped → current defaults |
| 4 | Fante 8, Cavallo 25 | kept as written |

The existing rule is unchanged: only a table matching a superseded default
*exactly* is dropped. A table the client genuinely customised survives — see
`engine/serialization_test.dart`, which proves both migrations, the untouched
custom table, and a current-schema save left alone.

## 3. Server and compiled JS

`supabase/functions/match/engine.js` is the Dart engine compiled with
dart2js, so the authoritative server prices cards with the same table by
construction. It was rebuilt with `tool/build_engine_js.sh` (127,616 bytes)
and replays all **62** conformance fixtures identically to the Dart VM.

The new fixture `round_end_figure_prices` is the direct proof: a hand of
Fante + Cavallo + Re at round end costs **43**, and a hand of two Fanti costs
**16**, on the VM and in the compiled JS.

## 4. Copy

`tutorialScoringBody` (EN + IT) still described the pre-2026-08-31 table —
"Fante 8, Cavallo 9". The Fante half was correct again after this patch; the
Cavallo half was not, so the sentence now reads "…Asso 1, Fante 8, Re 10 —
tranne il Cavallo, che vale 25". No other tutorial lesson was touched.

## 5. Verification

| Check | Result |
|---|---|
| `dart format --set-exit-if-changed .` | clean |
| `flutter analyze` | No issues found |
| `flutter test` | **753 passed**, 0 failed (baseline 746) |
| `deno test supabase/functions/match/` | **69 passed**, 0 failed |
| `deno test supabase/functions/verify-purchase/` | **6 passed**, 0 failed |
| `dart run tool/bot_simulation.dart` | 270 matches, **0 violations, 0 hangs** |
| Stability suites (`session9_*`, `session7_stability`, `long_session_performance`) | green — `audio_service.dart` untouched |
