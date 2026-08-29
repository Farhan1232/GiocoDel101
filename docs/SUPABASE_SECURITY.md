# Supabase Security Model

Session 3, 2026-08-29. What a client can and cannot do, how the database
enforces it, and how it was verified. Read with `docs/DATABASE_SCHEMA.md`.

## The principle

**The client is untrusted.** A phone can only ever:

1. authenticate (email/password, anonymous guest, password reset);
2. read what the API exposes to its role, filtered by RLS;
3. edit its own `nickname` and `avatar_id`;
4. call a short list of RPCs that validate every argument server-side.

Everything that has value — XP, level, wins, losses, rating, streaks,
achievements, coins, match results, other players' cards — is written only by
code running as `postgres`/`service_role` in the `app_private` schema, which
has no grant to any client role and is not in the exposed schema list.

## Three layers on `profiles`

| Layer | Mechanism | Stops |
|---|---|---|
| Privileges | `GRANT UPDATE (nickname, avatar_id)` only; no INSERT/DELETE | any write to another column fails with `42501` before RLS runs |
| RLS | `USING/WITH CHECK (auth.uid() = id)` on UPDATE; `SELECT … USING (true)` | editing someone else's row (0 rows affected) |
| Trigger | `profiles_protect_columns` raises when `current_user` is `anon`/`authenticated` and a server-owned column changed | a future over-broad grant |

`avatar_id` is a foreign key to `avatars`, so an id outside the built-in set is
refused by the database, not by the picker.

## Hidden information

Player A may know about player B: nickname, avatar, level, wins, rating,
online state (`profiles`), score and **card count** (`match_public_state`).

Player A can never receive B's cards, the deck order or the next card,
because those bytes are not in any row A can select:

- `match_private_state` — RLS `user_id = auth.uid()`; one row per seat.
- `app_private.match_engine_state` — the full `GameState` with `seed` and
  `drawPile`; no grant, no policy, schema not exposed.
- `match_public_state.state` is produced only by
  `app_private.redact_game_state`, which removes `seed`, `drawPile`,
  `drawnCard`, `history` and every `players[].hand` (replaced by `handCount`).

This is enforcement, not concealment: the UI never downloads a hand to hide it.

## Rooms

- `rooms`/`room_players` are readable only by members (`is_room_member`, a
  `SECURITY DEFINER` helper so the policy does not recurse) plus public
  lobbies. Private rooms are invisible until you join by code.
- No direct writes. `create_room`, `join_room`, `leave_room`, `set_ready`,
  `room_heartbeat` are `SECURITY DEFINER`, use `auth.uid()` for the actor,
  validate arguments, and return typed errors (`room_not_found`,
  `room_full`, `invalid_code`, `not_a_member`).

## Guests (anonymous users)

Guests are real `auth.users` rows with `is_anonymous = true`; they carry the
`authenticated` role, so **every** policy above applies to them unchanged.
Their JWT has `is_anonymous: true`; `public.is_permanent_user()` reads it.

Intended guest access: identical to a permanent player for profiles, rooms and
matches. One deliberate restriction: `claim_daily_reward()` requires a
permanent account (`guest_not_allowed`) so a reward cannot be farmed by
creating throw-away users, and the app tells the guest to create an account.

Rate limits: Supabase enforces 30 anonymous sign-ins per hour per IP; enable
CAPTCHA/Turnstile before production.

## Function policy

- Every function sets `search_path = ''` and references objects by schema.
- Client-callable RPCs live in `public`, have `REVOKE … FROM public, anon`
  and `GRANT EXECUTE … TO authenticated`, and check `auth.uid()`.
- Privileged functions live in `app_private` with no client grant.
- Default privileges on functions in `public` are revoked, so a new function
  is not callable until a migration grants it.
- The security advisor's `auth_allow_anonymous_sign_ins` warnings (one per
  table) are expected: guests are players, and no policy grants anything by
  role alone — every one is scoped by ownership (`auth.uid()`), membership
  (`is_room_member` / `is_match_member`) or is a public read of public data.
  Leaked-password protection is a paid-plan feature.
- The advisor's `authenticated_security_definer_function_executable`
  warnings list exactly the intended RPC set (`claim_daily_reward`,
  `create_room`, `join_room`, `leave_room`, `set_ready`, `room_heartbeat`,
  `touch_presence`, `is_room_member`, `is_match_member`). Each is reviewed
  above. `rls_enabled_no_policy` on `app_private.match_engine_state` is the
  intended "nobody" state.

## Auth configuration (dev project)

| Setting | Dev | Why |
|---|---|---|
| Email sign-up | on | |
| Confirm email | **off on dev** (`mailer_autoconfirm`) | lets sign-ups complete without SMTP; the app still handles "check your email" for environments where it is on; **on in production** |
| Anonymous sign-ins | **on** (pushed from `config.toml`) | guests |
| Manual identity linking | on | needed for guest → email upgrade via `updateUser` |
| Minimum password length | 8 | matches `AuthValidators.minPasswordLength` |
| Built-in mailer | rate-limited (a handful of emails/hour) | configure custom SMTP before any real testing of sign-up/reset |

## Client secrets

The app compiles in only the project URL and the **publishable** key via
`--dart-define-from-file=env/supabase.dev.json` (git-ignored). The
`service_role` key, database password, Management API token and MCP OAuth
credentials are never in the repo, the app, logs or these docs.

## Session 4

The online game adds its own threat model, enforcement table and attack
log: `docs/SECURITY.md`. Nothing above was weakened; the `srv_*` server
API is callable by `service_role` only, and every new client RPC validates
`auth.uid()` membership.

## Verification matrix

`tool/supabase_smoke.dart` runs the following against a real project with two
confirmed accounts A and B and the publishable key only:

| Check | Expected |
|---|---|
| anon key, no session: read `profiles`, call `leaderboard` | denied |
| guest sign-in | anonymous user + profile with `is_guest = true` |
| guest `claim_daily_reward` | `guest_not_allowed` |
| A reads own profile, B's public fields | allowed |
| A edits own nickname/avatar | allowed |
| A edits B's profile | 0 rows |
| A writes own `rating`, `xp`, `wins` | `42501` |
| A sets a non-whitelisted avatar | FK violation |
| A inserts a profile / writes `player_stats` / grants an achievement / inserts a match / inserts weekly points | denied |
| A creates a private room; B cannot see it; B joins by code; B sees both seats; missing code refused; direct writes to rooms/room_players denied; after leaving B sees nothing | as stated |
| A reads `match_private_state` | only rows with `user_id = A` |
| A reads reward status and both leaderboards | allowed |

Run against `GiocoDel101-Dev` on 2026-08-29: **33/33 PASS**. In addition,
with one match seeded server-side through `publish_match_state`, REST reads
as A and B each returned only their own `match_private_state` row, an
explicit filter for the other player's row returned `[]`, the public state
carried only `handCount`/`drawPileCount`, `app_private` was not an exposed
schema (`PGRST106`), a non-player guest saw nothing, and PATCH/POST attempts
on `matches`, `match_players` and `match_actions` were all `42501`. Full
table in `docs/SESSION_HANDOFF.md` §1.
