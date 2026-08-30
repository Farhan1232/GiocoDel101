# Database Schema

Session 3, 2026-08-29. Postgres 17 on Supabase. Every object below is created
by a file in `supabase/migrations/` — there are **no dashboard-only changes**.

| Migration | Creates |
|---|---|
| `20260829135723_core_profiles.sql` | `app_private` schema, opt-in exposure, `avatars`, `profiles`, `player_stats`, auth triggers, `touch_presence()` |
| `20260829135725_rooms_lobby.sql` | `rooms`, `room_players`, lobby RPCs, room codes, stale-room sweep |
| `20260829135727_matches_state.sql` | `matches`, `match_players`, `match_public_state`, `match_private_state`, `match_actions`, `app_private.match_engine_state`, redaction + publish |
| `20260829135729_progression_rewards.sql` | `achievements`, `user_achievements`, `daily_rewards`, `daily_missions`, `user_daily_missions`, `weekly_points`, progression API, `claim_daily_reward()`, `leaderboard()` |
| `20260829162239_fk_covering_indexes.sql` | covering indexes for every foreign key the performance advisor flagged |
| `20260829202017_online_multiplayer.sql` | Session 4: `rooms.kind`, the turn clock on `matches`, `match_action_receipts`, `matchmaking_queue`, `reaction_presets`, Realtime publication + private-channel policies, `settle_match`, `rating_deltas`, the `srv_*` server API, queue/snapshot/heartbeat/reaction RPCs, `expire_stale_matches`, pg_cron |
| `20260829204500_realtime_topic_helper.sql` | `public.match_topic_id()` — the channel policy helper the `authenticated` role can execute |
| `20260830120000_progression_missions.sql` | Session 5: `leaderboard(scope, limit, offset)`, `my_leaderboard_rank`, `match_round_results`, `record_round_result`, `evaluate_achievements`, the daily-mission rotation + `track_mission` + `my_daily_missions()` + `claim_mission_reward()`, mission ticks inside `srv_commit_action`, achievements/missions inside `settle_match` |
| `20260830123000_claim_mission_fix.sql` | `claim_mission_reward()` with qualified column references (`#variable_conflict use_column`) — the first version was ambiguous against its own `RETURNS TABLE` names |

Two schemas:

- **`public`** — exposed through the Data API. Every table has RLS enabled and
  an explicit `GRANT`; nothing is reachable by accident. Default privileges
  for new tables/functions/sequences are **revoked**, so a future table is
  invisible to clients until a migration grants it.
- **`app_private`** — never exposed. Holds the authoritative engine state and
  every function that awards anything. No grant to `anon` or `authenticated`.

Legend for the "client" column: what the `authenticated` role (email users
**and** guests) can do through the API. Blank = nothing.

---

## Identity

### `public.avatars`
Whitelist of built-in avatar ids (`lucia … dario`), mirroring
`lib/features/profile/domain/avatars.dart`. `profiles.avatar_id` is a foreign
key to it, so the database — not the UI — rejects an unknown avatar.
Client: `SELECT`.

### `public.profiles`

| Column | Type | Owner | Notes |
|---|---|---|---|
| `id` | uuid PK → `auth.users` | server | cascade on user delete |
| `nickname` | text | **player** | 3–16 chars, trimmed, no control chars, unique case-insensitively |
| `avatar_id` | text → `avatars` | **player** | default `lucia` |
| `is_guest` | bool | server | true for anonymous users; flips to false when an email is linked |
| `level`, `xp` | int | server | ladder in `app_private.level_for_xp` (= `LevelLadder` in Dart) |
| `wins`, `losses`, `matches` | int | server | online results only |
| `rating` | int | server | default 1000; **no formula yet** (GAME_SPEC §12b unconfirmed) |
| `current_streak`, `best_streak` | int | server | |
| `last_seen_at` | timestamptz | server | moved only by `touch_presence()`; "online" = within 2 min |
| `created_at`, `updated_at` | timestamptz | server | trigger-maintained |

Client: `SELECT` every row (public identity: nickname, avatar, level, wins,
rating, online state). `UPDATE (nickname, avatar_id)` on own row only —
a **column-level grant**, plus RLS, plus the `profiles_protect_columns`
trigger that raises `42501` if a client role changes any other column.
No `INSERT`/`DELETE`.

Indexes: `lower(nickname)` unique; `(rating desc, wins desc, created_at)`
for the all-time board; `last_seen_at desc`.

### `public.player_stats`
One row per profile: `rounds_played`, `rounds_won`, `cards_played`,
`aces_played`, `twos_played`, `longest_chain`, `resets_101`,
`largest_comeback`, `daily_challenges_completed`, `online_matches`, `coins`.
Client: `SELECT` all rows. Written only by `app_private.*`.

### Auth triggers (`app_private`)
- `handle_new_user()` — `AFTER INSERT ON auth.users`: inserts `profiles` +
  `player_stats`. Nickname from `raw_user_meta_data.nickname` (the sign-up
  form) after sanitising; guests get `Ospite-XXXX`; collisions get a numeric
  suffix. Avatar from metadata if whitelisted, else `lucia`. **Flutter never
  inserts a profile.**
- `handle_user_upgraded()` — `AFTER UPDATE OF is_anonymous`: guest → permanent
  sets `is_guest = false`.

### `public.touch_presence()` (RPC)
`SECURITY DEFINER`; updates only `auth.uid()`'s `last_seen_at`.

---

## Rooms

### `public.rooms`

| Column | Notes |
|---|---|
| `id` uuid PK | |
| `code` text unique | 6 chars from `ABCDEFGHJKLMNPQRSTUVWXYZ23456789` (= `RoomCode.alphabet`) |
| `host_id` → profiles | |
| `name` text ≤ 24 | |
| `max_players` 2..4 | |
| `is_private` bool | public rooms in `lobby` are listable |
| `turn_timer_seconds` in (0,15,30,60) | = `TurnTimer` |
| `rules` jsonb | `GameRules.toJson()` verbatim — the room carries the house rules |
| `status` enum `room_status` | `lobby → starting → in_progress → finished`, or `cancelled` |
| `match_id` → matches | set when the match is dealt (Session 4) |
| `created_at`, `updated_at`, `last_activity_at` | |

### `public.room_players`
PK `(room_id, user_id)`, unique `(room_id, seat)`; `seat` 0..3, `is_host`,
`is_ready`, `connection` enum (`online/away/offline`), `joined_at`,
`last_seen_at`.

Client for both: `SELECT` where `is_room_member(room_id)` (or a public lobby
for `rooms`). **No direct writes.** All changes go through RPCs, each
`SECURITY DEFINER` with `auth.uid()` checks:

| RPC | Does |
|---|---|
| `create_room(name, max_players, is_private, turn_timer_seconds, rules)` | validates, leaves other lobbies, generates a code, seats the host at 0 (ready) |
| `join_room(code)` | normalises the code, finds an open lobby, lowest free seat; `room_not_found` / `room_full` |
| `leave_room(room_id)` | removes the seat; promotes the next seat to host or cancels an empty room |
| `set_ready(room_id, ready)` | |
| `room_heartbeat(room_id)` | `last_seen_at`, `connection = online` |

`app_private.expire_stale_rooms(interval)` cancels idle lobbies; schedule it
with pg_cron when needed.

---

## Matches — the split state model

```
                 ┌──────────────────────────────┐
  client  ──────▶│ match_public_state (public)   │  redacted GameState:
  (any seat)     │  counts, top card, turn, scores│  no seed, no drawPile,
                 └──────────────────────────────┘  no hands, no drawnCard
  client  ──────▶┌──────────────────────────────┐
  (own row only) │ match_private_state (public)  │  hand: ["denari_asso", …]
                 └──────────────────────────────┘
                 ┌──────────────────────────────┐
  server only    │ app_private.match_engine_state│  full GameState + seed
                 └──────────────────────────────┘
```

### `public.matches`
`id`, `room_id`, `status` enum `match_status` (`in_progress/finished/abandoned`),
`rules` jsonb, `player_count` 2..4, `winner_id`, `started_at`, `finished_at`.

### `public.match_players`
PK `(match_id, user_id)`; `seat`, `engine_player_id` (`p0`… — the id inside
`GameState.players`), `final_score`, `placement`, `is_winner`,
`rating_before/after`, `xp_awarded`, `connection`, `last_seen_at`, `left_at`.

### `public.match_public_state`
`match_id` PK, `version`, `state` jsonb (redacted), `updated_at`.

### `public.match_private_state`
PK `(match_id, user_id)`; `version`, `hand` jsonb. **RLS: `user_id = auth.uid()`.**

### `public.match_actions`
Append-only log: `version` (the state version targeted), `actor_id` (null =
system), `action` jsonb (`GameAction.toJson()`), `accepted`, `failure`.

### `app_private.match_engine_state`
`match_id` PK, `version`, `state` jsonb — the authoritative `GameState`
including `seed` and the ordered `drawPile`. No grant, no policy, not exposed.

Client for the four public tables: `SELECT` where `is_match_member(match_id)`
(private state: own row only). **No writes at all** — results, winners, XP and
rating are written by server code.

### Server-side helpers (`app_private`)
- `redact_game_state(jsonb)` — strips `seed`, `drawPile`, `drawnCard`,
  `history`; adds `drawPileCount`; replaces each `players[].hand` with
  `handCount`.
- `hand_of(state, engine_player_id)` — one player's hand.
- `publish_match_state(match_id, state)` — writes engine + public + private
  rows atomically; flips `matches.status` to `finished` when the state says so.
  **This is the seam Session 4's authoritative function calls after
  `GameEngine.applyAction`.**

---

## Progression and rewards

### `public.achievements` / `public.user_achievements`
Catalogue (ids = `AchievementsCatalog`, including the historic `rinascita`,
`maestro_semi`, `sfida_giorno`) and unlocks. Client: `SELECT` both (badges are
public). Unlocks written only by `app_private.unlock_achievement`.

### `public.daily_rewards`
PK `(user_id, claimed_on)`; `day_index` 1..7, `amount`. Client: `SELECT` own
rows. Written only by `claim_daily_reward()`.

### `public.daily_missions` / `public.user_daily_missions`
Definitions per date (`mission_key`, `target`, `reward_xp`, `reward_coins`,
`sort_order`) and per-user progress (`progress`, `completed_at`,
`claimed_at`). Client: `SELECT` (own progress). **Server-written only**:
rows for a day are materialised lazily by `app_private.ensure_daily_missions`
from the seven-day rotation in `app_private.mission_rotation(isodow)` (the
same table as `MissionCatalog` in Dart); progress moves only through
`app_private.track_mission`, called from `srv_commit_action` (an Asso, a 2,
a Cavallo, a Cavallo into a live chain — the actor's own accepted actions)
and from `evaluate_achievements` at settlement (`play_matches`,
`online_match`, `win_match`). Days are Europe/Rome on the database clock
(`app_private.today_rome()`).

### `public.match_round_results` (Session 5)
PK `(match_id, round, user_id)`; `won_round`, `hit_exact_101`, `eliminated`,
`perfect_hand`, `cards_left`, `penalty`, `new_score`. One row per seat per
finished round, written by `srv_commit_action` from the engine's
`lastRoundResult` the moment the state goes `roundOver`/`finished`. Client:
`SELECT` where `is_match_member(match_id)`. This is the evidence the
achievement judge reads — the phone reports nothing.

### `public.weekly_points`
PK `(user_id, week_start)`; `points`, `wins`, `matches`. Fed by
`record_match_result`; drives the weekly board. Client: `SELECT`.

### RPCs
| RPC | Security | Does |
|---|---|---|
| `claim_daily_reward()` | definer, permanent users only | one claim per Europe/Rome day; day = previous+1 if yesterday was claimed, else 1; amount from `[10,15,20,30,40,60,120]`; credits `player_stats.coins`; per-user advisory lock. Errors: `guest_not_allowed`, `already_claimed` |
| `my_daily_reward_status()` | invoker | `streak, claimed_today, can_claim, coins` |
| `leaderboard(scope, limit, offset)` | invoker | `all_time` = `profiles.rating` desc, wins desc; `weekly` = current ISO week's `weekly_points`; `limit` ≤ 200, `offset` for paging (the two-argument call still works) |
| `my_leaderboard_rank(scope)` | invoker | the caller's own row (rank, points) in that scope, or nothing when unranked |
| `my_daily_missions()` | definer | today's missions (materialised on demand) with the caller's progress/claim state, in rotation order |
| `claim_mission_reward(mission_id)` | definer | judged on the server clock: today's mission, `progress >= target`, not yet claimed; then `grant_xp` (+ coins). Errors: `mission_expired`, `not_completed`, `already_claimed`; per-user advisory lock |

### Server-only API (`app_private`, no client grant)
| Function | Does |
|---|---|
| `level_for_xp(xp)` | the ladder (120 + 40/level) |
| `grant_xp(user, amount)` | adds XP, recomputes level |
| `unlock_achievement(user, id)` | idempotent |
| `record_match_result(match_id, rating_deltas jsonb)` | per seat: matches/wins/losses/streaks, XP (20 + 45 on a win — **provisional**), weekly points, `online_matches`, `prima_vittoria`. Rating changes only by the deltas passed in — **no formula lives here** |
| `record_round_result(match_id, state)` | Session 5 — the `lastRoundResult` rows into `match_round_results` (idempotent) |
| `evaluate_achievements(match_id, state)` | Session 5 — after `record_match_result`: Prima Vittoria (winner), Centouno! (a round row with `hit_exact_101`), Vendetta (winner whose streak restarted at 1 with ≥ 2 matches), Maestro del Nove (winner with four `cavalloSuits` in the final state), Imbattibile (streak ≥ 5), Veterano (matches ≥ 25), Catena (`stats.longestChain` ≥ 3, every seat), Mano Perfetta (a round row with `perfect_hand`); plus the match missions |
| `mission_rotation(isodow)`, `today_rome()`, `ensure_daily_missions(date)`, `track_mission(user, key, inc)` | Session 5 — the mission machinery described above |

---

## Types

`room_status`, `connection_state`, `match_status` enums.

## Session 4 — online play

Full narrative in `docs/ONLINE_MULTIPLAYER.md`; the access model in
`docs/SECURITY.md`; the live feed in `docs/REALTIME.md`.

### New columns
- `rooms.kind` — `private` | `quick`.
- `matches.current_user_id`, `turn_started_at`, `turn_deadline_at`,
  `turn_timer_seconds`, `last_action_at`, `abandoned_by`, `rematch_of`.
- `match_players.consecutive_timeouts`, `forfeited_at`,
  `rematch_requested_at`, `last_reaction_at`.
- `match_private_state.drawn_card` — the seat on turn's own drawn card.

### New tables
| Table | Purpose | Client |
|---|---|---|
| `match_action_receipts` PK `(match_id, action_id)` | idempotency: what each client action id produced | `SELECT` own rows |
| `matchmaking_queue` PK `user_id` | one row per waiting player; `status` waiting/matched, `room_id` | `SELECT` own row |
| `reaction_presets` | the eight allowed reaction keys | `SELECT` |

### Client RPCs (authenticated)
| RPC | Does |
|---|---|
| `enqueue_quick_match(player_count, turn_timer)` | upsert own queue row; under an advisory lock, assemble a `quick` room when enough compatible players wait |
| `quick_match_heartbeat()` / `cancel_quick_match()` | keep the row alive / leave (and the assembled lobby) |
| `my_active_match()` | the in-progress match this user is seated at |
| `match_snapshot(match_id)` | one consistent read: public state, own hand, drawn card, clock, seats (RLS applies — runs as the caller) |
| `match_heartbeat(match_id)` | presence for the abandonment policy |
| `send_reaction(match_id, key)` | whitelist + 2 s gap, then `realtime.send()` on the private channel |
| `leave_room(room_id)` | now refuses during a live match (`match_in_progress`) |

### Server API (service_role only — the `match` Edge Function)
`srv_load_match`, `srv_find_receipt`, `srv_record_rejection`,
`srv_commit_action`, `srv_room_for_deal`, `srv_commit_match`,
`srv_rematch_vote`, `srv_remove_seat`. Each is `SECURITY DEFINER`, revoked
from `authenticated`/`anon`, and the commit ones lock their row
`FOR UPDATE`.

### Server-only helpers (`app_private`)
`settle_match(match_id, state)` (placements, winner, room → finished, then
`record_match_result`), `rating_deltas(match_id)` (all zeros until §12b is
confirmed), `epoch_ms_to_ts`, `expire_stale_matches(interval)`;
`publish_match_state` now also writes `drawn_card`.

### Realtime
Publication: `rooms`, `room_players`, `matches`, `match_public_state`,
`match_private_state`, `matchmaking_queue` (all `REPLICA IDENTITY FULL`).
`realtime.messages` policies for `match:<uuid>`: members receive
broadcast + presence; members may insert presence only.

### Scheduled
pg_cron: `gioco101-expire-stale-rooms` and `gioco101-expire-stale-matches`
every 10 minutes.

## What is deliberately not here

- Storage buckets — avatars are built-in vector art; no upload exists.
- Any rating formula — it waits on a client decision (see
  `docs/SESSION_HANDOFF.md`). The turn-timer expiry rule is implemented
  server-side under a documented provisional policy. Daily missions now have
  a generator (Session 5, the seven-day rotation); their XP amounts are as
  provisional as the match XP.
