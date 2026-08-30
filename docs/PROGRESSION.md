# Progression

Session 5, 2026-08-30. XP, levels, achievements, daily missions, the
leaderboard and the daily reward — and, above all, which of two ledgers
each one lives in. Read with `docs/SECURITY.md` (what a client may write:
nothing here) and `docs/OFFLINE_MODE.md` (where the local numbers come
from).

## The two ledgers

| | Offline | Online |
|---|---|---|
| Record | `StatisticsModel` (`lib/features/profile/domain/statistics_model.dart`), one JSON blob on the device | `profiles`, `player_stats`, `user_achievements`, `user_daily_missions`, `weekly_points` — server-owned, RLS, no client grant on any counter |
| Written by | `StatsController` / `StatisticsService` after a local round or match | `app_private.settle_match` → `record_match_result` → `evaluate_achievements`, plus `srv_commit_action` for per-card mission ticks |
| Feeds | the local profile placeholder, offline achievements, offline missions, offline XP | level/XP on the profile, rating, weekly points, the leaderboard, online achievements and missions |
| Never | touches `rating`, the leaderboard or any server row | reads anything the phone reports; it re-derives every fact from the engine state it committed |

`RoundResultScreen` records locally only when `!c.isOnline`; online the
server is the only bookkeeper. `ProfileSummary.fromLocal` marks its level
bar `isPlaceholderProgression`; `fromRemote` shows `profiles.level` and
`LevelLadder.resolve(profiles.xp)`. The two never mix: an offline win
cannot complete an online mission, and a server badge is not copied into
the local list (screens show the union).

## XP and levels — provisional

`LevelLadder` (`lib/features/profile/domain/level_ladder.dart`) and
`app_private.level_for_xp` (migration `20260829135729_progression_rewards.sql`)
implement the same numbers so the bar reads identically from either source:

| Constant | Value |
|---|---|
| XP per match | 20 |
| XP per win | +45 |
| level 1 → 2 | 120 XP |
| each further level | +40 XP more than the previous |

`resolve(totalXp)` → `(level, xpIntoLevel, xpForLevel)`; the profile shows
"Livello N" and `xpIntoLevel / xpForLevel`. Online, `grant_xp` adds to
`profiles.xp` and recomputes `profiles.level`; `record_match_result` awards
`20 + 45 if winner` per seat and writes `match_players.xp_awarded`.
Offline, `StatisticsService.applyMatch` adds the same amounts to the local
`xp`; a record saved before offline XP existed is credited
`matches × 20 + wins × 45` on load so nobody's level drops.

**These amounts are placeholders** (GAME_SPEC §12b): the client has not
confirmed an online progression formula.

## Achievements — `lib/features/achievements/`

Nine badge ids. The six the UI brief names are `featured`; three older
ones stayed so nobody loses a cosmetic already earned (ids unchanged).
Titles live in the ARB files (`AchievementCopy`), never in the catalogue.

| Id | Shown as | Offline — `StatisticsService` | Online — `evaluate_achievements` (after `record_match_result`) |
|---|---|---|---|
| `prima_vittoria` | Prima Vittoria | match won and `matchesWon` was 0 | `is_winner` (also unlocked directly by `record_match_result`; idempotent) |
| `rinascita` | Centouno! | the human's round row `hitExact101` | a `match_round_results` row for this user in this match with `hit_exact_101` |
| `vendetta` | Vendetta | won with `currentStreak == 0` and `matchesPlayed > 0` | `is_winner` and `current_streak = 1` and `matches ≥ 2` |
| `maestro_semi` | Maestro del Nove | won having named all four suits with a Cavallo (`stats.cavalloSuits[human] ≥ 4`) | `is_winner` and `jsonb_array_length(stats.cavalloSuits[seat]) ≥ 4` in the final engine state |
| `imbattibile` | Imbattibile | streak reaches 5 | `current_streak ≥ 5` |
| `veterano` | Veterano | 25 matches | `matches ≥ 25` |
| `catena` | Catena (unlocks theme `vesuvio`, back `brace`) | `match.stats.longestChain ≥ 3` (checked per round and per match) | `stats.longestChain ≥ 3` — every seat at that table |
| `mano_perfetta` | Mano Perfetta | won the round with `drawsByPlayer[human] == 0` | a `match_round_results` row with `perfect_hand` (`won_round` and `drawsByPlayer[seat] = 0`, computed server-side when the round ended) |
| `sfida_giorno` | Sfidante | won the daily challenge | not evaluated online |

Cosmetic unlocks (`rinascita` → card back `notturno`; `maestro_semi` →
theme `maiolica` + back `cobalto`; `catena` → `vesuvio` + `brace`) are
applied by `StatsController._commit` → `SettingsController.unlock` for
offline badges. Online badges arrive through `ProfileController.achievements`
(`fetchAchievements`); the achievements screen shows `earnedAny` =
local ∪ remote. `ProfileController.newAchievements` collects badges that
appeared since the previous load; no screen drains it yet.

The online rules are judged from `match_round_results` (one row per seat
per finished round, written by `srv_commit_action` when the state it just
committed is `roundOver`/`finished`, and again by `settle_match`, `on
conflict do nothing`) and from the final engine state — the phone reports
nothing. There is no RPC that takes an achievement id.

## Daily missions — `lib/features/missions/`

### The seven-day cycle

`MissionCatalog.rotation` (Dart) and `app_private.mission_rotation(isodow)`
(migration `20260830120000_progression_missions.sql`) carry the same table
and must be edited together. Index = ISO weekday.

| Day | Mission 1 | Mission 2 | Mission 3 |
|---|---|---|---|
| Mon | play 2 matches — 30 XP | play 3 Assi — 25 XP | play 1 Cavallo — 20 XP |
| Tue | win 1 match — 40 XP | play 3 Due — 25 XP | play 1 online match — 30 XP |
| Wed | play 3 matches — 35 XP | block a +2 with a Cavallo — 30 XP | play 2 Cavalli — 25 XP |
| Thu | win 1 match — 40 XP | play 4 Assi — 30 XP | play 2 matches — 30 XP |
| Fri | play 4 Due — 30 XP | play 2 Cavalli — 25 XP | play 1 online match — 30 XP |
| Sat | play 3 matches — 35 XP | win 2 matches — 50 XP | block a +2 with a Cavallo — 30 XP |
| Sun | play 3 Assi — 25 XP | play 3 Cavalli — 30 XP | play 2 online matches — 45 XP |

Keys: `play_matches`, `win_match`, `play_aces`, `play_twos`, `use_nine`,
`block_two`, `online_match` (`MissionKey.isOnlineOnly`).

### Online half

- **Day** = `app_private.today_rome()`, the server's calendar day in
  Europe/Rome. The phone's clock is never consulted.
- `ensure_daily_missions(date)` materialises the day's three rows in
  `daily_missions` on first touch.
- **Progress** is written only by server code that watched the play:
  `srv_commit_action` ticks `play_aces` / `play_twos` / `use_nine` on an
  accepted `playCard` by the actor's own `action` (never a timeout move made
  on their behalf), and `block_two` when the card is a Cavallo and the
  previous state had a pending penalty; `evaluate_achievements` (inside
  `settle_match`) ticks `play_matches`, `online_match` and, for the winner,
  `win_match`. `track_mission` caps at the target, skips claimed rows and
  stamps `completed_at`.
- **Read**: `my_daily_missions()` — today's rows with the caller's
  progress, `completed_at`, `claimed_at`.
- **Claim**: `claim_mission_reward(p_mission_id)` under a per-user
  advisory lock: not today's mission → `mission_expired`; progress below
  target → `not_completed`; already claimed → `already_claimed`; otherwise
  `claimed_at = now()` and `grant_xp(reward_xp)` (coins if any). Migration
  `20260830123000_claim_mission_fix.sql` rewrote it with
  `#variable_conflict use_column` and qualified references: the
  `returns table (mission_id, …)` names had made the body's unqualified
  column references ambiguous and every claim failed — found by
  `tool/progression_smoke.dart`.
- No RPC takes a progress or unlock argument; `daily_missions` and
  `user_daily_missions` accept no client insert/update.

### Offline half

`StatsController` keeps `missionDateKey` (`yyyyMMdd`, local calendar),
`missionProgress` and `claimedMissions` in the `StatisticsModel`.
`noteMissionEvent` drops counters from an earlier day first, so a mission
never carries over; `onlineMatch` is ignored. Counters come from the
person's own plays at the local table — `GameController` calls
`noteCardPlayed` on the human's `CardPlayedEvent` (Asso, Due, Cavallo) and
`noteChainBlocked` on a human `ChainBlockedEvent`; `recordMatch` ticks
`play_matches` and `win_match`. `claimOfflineMission` adds `rewardXp` to the
local `xp` once. `MissionsController.visible` = the server rows when signed
in, plus the offline rows minus online-only ones; `claim()` routes each
row to its own ledger and reloads the profile after an online claim.

## Leaderboard — `lib/features/leaderboard/`

`public.leaderboard(p_scope, p_limit, p_offset)` (security invoker, reads
through RLS):

| Scope | Ordering | Points |
|---|---|---|
| `all_time` | `profiles.rating` desc, `wins` desc, `created_at` | `rating` |
| `weekly` | `weekly_points.points` desc, `wins` desc, `created_at` for `week_start = date_trunc('week', now() at time zone 'Europe/Rome')` | `points` — the XP earned in online matches this ISO week (`record_match_result` upserts `v_xp`) |

`p_limit` is clamped to 1…200, `p_offset` to 0…100 000; the 2-argument
form from Session 3 still resolves. `my_leaderboard_rank(p_scope)` returns
the caller's own row (empty when not ranked, e.g. no weekly points this
week). The screen (`leaderboard_screen.dart`) pages **25** at a time
(`hasMore` when a page came back full), pins the player's own row from
`my_leaderboard_rank`, tells an unranked player so rather than inventing a
row, and shows an error with a retry when the RPC fails. Without a backend
the board reports `isAvailable = false` — no fake users, ever.

## Daily reward — unchanged from Session 3

`claim_daily_reward()` (migration `…progression_rewards.sql`): permanent
accounts only (`guest_not_allowed` for anonymous users), one claim per
Europe/Rome day, ladder `[10, 15, 20, 30, 40, 60, 120]` coins; the day
index advances when yesterday was claimed and restarts at 1 otherwise, so
the ladder wraps after day 7. `my_daily_reward_status()` reports streak,
`claimed_today`, `can_claim`, coins. The Dart `DailyRewardCalendar.ladder`
is the same list, for display only.

## Verification — `tool/progression_smoke.dart`

```
SUPABASE_URL=… SUPABASE_PUBLISHABLE_KEY=… dart run tool/progression_smoke.dart
```

Two independent authenticated clients play a **real** 2-player match to
101 through the deployed `match` Edge Function (legality on each client
computed with the app's `GameEngine` over the redacted snapshot), then the
tool compares what the clients observed with what the server recorded.
Areas and checks:

| Area | Checks |
|---|---|
| SETUP | two distinct users; fresh profiles at matches 0, xp 0, level 1 |
| MISSIONS BEFORE | `my_daily_missions()` returns 3 rows, all 0 / unclaimed; date ≈ Rome; keys/targets/rewards equal `mission_rotation` for the server's ISO weekday; both users see the same ids |
| 2-PLAYER MATCH TO 101 | played to `finished`; no app-engine move refused by the server |
| PROFILES | matches 0 → 1; xp 0 → 65 (winner) / 20; level consistent; wins / streak |
| MATCH ROUND RESULTS | participants can read the rows; one row per seat per round; rounds 1..n; exactly one `won_round` per round; `won_round` / `hit_exact_101` agree with the `lastRoundResult` the clients saw; an outsider sees nothing; a participant cannot insert |
| ACHIEVEMENTS | `prima_vittoria` for the winner only; `rinascita`, `mano_perfetta`, `catena` present exactly when the clients saw the condition; no `vendetta` / `imbattibile` / `veterano` on a first match |
| MISSIONS AFTER | progress per key equals the client-observed count; `completed_at` consistent |
| CLAIM | a completed mission pays `reward_xp` into `profiles.xp`, level still consistent; second claim → `already_claimed`, xp unchanged; the other user (incomplete) → `not_completed`; random uuid → `mission_expired` |
| MISSION WRITE PROTECTION | no insert/update on `user_daily_missions` or `daily_missions`; `app_private.track_mission` not exposed, no public `track_mission`; progress unchanged afterwards |
| LEADERBOARD | page 1 ≤ 25 rows, ranks 1..n, sorted; page 2 starts at 26 with no overlap; `my_leaderboard_rank` matches the paged row and `profiles.rating`; weekly rank equals `weekly_points` and this match's XP; a user with no weekly points gets no weekly rank |

The run on 2026-08-30 against the dev project found the ambiguous-column
bug in `claim_mission_reward` (every claim failed); migration 9 fixes it.
The tool was not re-run for this document; the offline half is covered by
`test/session5_offline_test.dart` (rotation covers seven days × three,
own plays advance today's counters, a claim pays once and the next day
starts clean, a finished match awards offline XP and match missions) and
the screens by `test/session5_screens_test.dart`.

## Open with the client

- **§12b rating formula.** `profiles.rating` never moves:
  `app_private.rating_deltas(match)` returns a 0 for every seat, so the
  all-time board orders by a number that is still 0 for everyone (then by
  wins). That function is the single hook for the formula. Nothing was
  invented.
- **XP amounts and the level ladder** (20 / 45 / 120 + 40) are placeholders
  in both Dart and SQL; changing them means changing both.
- Whether the daily reward should open to guests (currently permanent
  accounts only), and whether `sfida_giorno` should exist online.
