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
Definitions per date (`mission_key`, `target`, `reward_xp`, `reward_coins`)
and per-user progress. Client: `SELECT` (own progress). Server-written. No
missions are generated yet — the tables exist so the shape is fixed.

### `public.weekly_points`
PK `(user_id, week_start)`; `points`, `wins`, `matches`. Fed by
`record_match_result`; drives the weekly board. Client: `SELECT`.

### RPCs
| RPC | Security | Does |
|---|---|---|
| `claim_daily_reward()` | definer, permanent users only | one claim per Europe/Rome day; day = previous+1 if yesterday was claimed, else 1; amount from `[10,15,20,30,40,60,120]`; credits `player_stats.coins`; per-user advisory lock. Errors: `guest_not_allowed`, `already_claimed` |
| `my_daily_reward_status()` | invoker | `streak, claimed_today, can_claim, coins` |
| `leaderboard(scope, limit)` | invoker | `all_time` = `profiles.rating` desc, wins desc; `weekly` = current ISO week's `weekly_points` |

### Server-only API (`app_private`, no client grant)
| Function | Does |
|---|---|
| `level_for_xp(xp)` | the ladder (120 + 40/level) |
| `grant_xp(user, amount)` | adds XP, recomputes level |
| `unlock_achievement(user, id)` | idempotent |
| `record_match_result(match_id, rating_deltas jsonb)` | per seat: matches/wins/losses/streaks, XP (20 + 45 on a win — **provisional**), weekly points, `online_matches`, `prima_vittoria`. Rating changes only by the deltas passed in — **no formula lives here** |

---

## Types

`room_status`, `connection_state`, `match_status` enums.

## What is deliberately not here

- Realtime publication (`alter publication supabase_realtime add table …`) —
  Session 4, when the lobby and table subscribe.
- Storage buckets — avatars are built-in vector art; no upload exists.
- Any rating formula, turn-timer expiry rule or daily-mission generator —
  each waits on a client decision (see `docs/SESSION_HANDOFF.md`).
