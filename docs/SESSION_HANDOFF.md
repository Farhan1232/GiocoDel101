# Session Handoff — Session 3 → Session 4

Date: 2026-08-29. Branch: `feature/session-1-ui-foundation` (continued; the
Session 3 checkpoint commit sits on top of Session 2's).

Sessions 1 and 2 handoffs are preserved in git history at their checkpoints;
what still matters is summarised in §7.

---

## 0. What Session 3 delivered

**A real Supabase backend for identity, security and the data model — and a
client that never pretends.**

- **Development project** `GiocoDel101-Dev` (`fnyllrjchbqfrzezfeso`,
  eu-central-1, free plan) — found already created; inspected; it was empty.
  The unrelated `Farhan1232's Project` was not touched.
- **Five migrations** in `supabase/migrations/` (four schema files applied
  through the Supabase MCP and version-aligned with the filenames, plus
  `20260829162239_fk_covering_indexes.sql` pushed with the linked CLI —
  `supabase migration list` shows local and remote identical). Every table has RLS and an explicit grant; default privileges
  are revoked so exposure is opt-in; privileged code lives in `app_private`.
  Reference: `docs/DATABASE_SCHEMA.md`.
- **Security model** — column-level grant + RLS + trigger on `profiles`;
  split match state (`match_public_state` / `match_private_state` /
  `app_private.match_engine_state`) with a server-side redaction function;
  no client write path to XP, level, wins, rating, achievements, coins or
  results. Reference: `docs/SUPABASE_SECURITY.md`.
- **Auth in Flutter** with `supabase_flutter 2.17.2`: email sign-up (nickname
  + avatar travel as metadata to the profile trigger), email sign-in,
  sign-out, session restore before the first frame, anonymous guest
  sign-in (a real `auth.users` row), password-reset email. `AuthGateway`
  interface + `SupabaseAuthGateway` + `NoBackendAuthGateway`;
  `SessionController` owns the session; `BootRouter` decides splash →
  onboarding / account choice / home with a single navigation.
- **Screens connected**: login, sign-up, forgot password, account landing
  (guest = anonymous auth), profile (server row when signed in; rating
  card), edit profile (server write; "nickname taken" as a field error),
  leaderboard (real `leaderboard()` RPC, weekly + all-time), daily reward
  (server-decided ladder; guests told to create an account), settings
  account panel (who is signed in, sign in / sign out), online hub (sign-in
  required panel), create room / join room / lobby (real rooms with real
  codes, seats polled every 3 s, leave really leaves; Start disabled with
  honest copy), matchmaking (says the queue is not open).
- **Configuration**: `lib/core/config/supabase_env.dart` reads
  `SUPABASE_URL` / `SUPABASE_PUBLISHABLE_KEY` from `--dart-define`;
  `env/supabase.dev.json.example` is committed, `env/*.json` is ignored.
  No secret of any kind is in the repo. Reference: `docs/SUPABASE_SETUP.md`.
- **Tooling**: Supabase CLI 2.116.0 (npm), logged in and **linked** to
  `fnyllrjchbqfrzezfeso`; `supabase config push` applied the auth settings
  to the remote (anonymous sign-ins ON, manual linking ON, min password 8,
  email confirmations OFF for dev). `tool/supabase_smoke.dart` — a pure-Dart
  end-to-end auth + RLS matrix runner, run green against the dev project.
- **Tests**: +17 (`test/session3_auth_test.dart`): BootRouter matrix,
  OnlineStatus, no-backend gateway, SessionController, AuthController,
  Supabase error mapping, remote profile parsing, ladder parity.

Not done, deliberately: the authoritative match function, realtime, matchmaking
queue, any rating formula (all Session 4 or waiting on the client).

---

## 1. Verification — exactly what ran

### Local gates

| Gate | Result |
|---|---|
| `flutter pub get` | ok (`supabase_flutter 2.17.2`, `supabase 2.16.1`) |
| `dart format lib test tool` | clean |
| `flutter analyze` | **No issues found** |
| `flutter test` | **420/420 passed** (403 baseline + 17 new) |

### Remote — GiocoDel101-Dev, every line a real request

| Check | Result |
|---|---|
| CLI `supabase projects list` / `supabase link` | authenticated; linked to `fnyllrjchbqfrzezfeso` (no project created) |
| CLI `supabase migration list` | 5 local = 5 remote |
| CLI `supabase config push` | auth config applied; storage untouched (vector buckets are paid → 402, nothing changed) |
| `GET /auth/v1/settings` after push | `anonymous_users: true`, `mailer_autoconfirm: true` |
| MCP `get_advisors(security)` | WARN: the 9 intended SECURITY DEFINER RPCs; WARN `auth_allow_anonymous_sign_ins` on every table (expected — guests are players; every policy is scoped by ownership/membership, not by role); WARN leaked-password protection off (paid feature); INFO `app_private.match_engine_state` no policy (intended) |
| MCP `get_advisors(performance)` | unindexed FKs → fixed by migration 5; remaining INFO = unused indexes on an empty DB |
| **Anonymous sign-in** `POST /auth/v1/signup {}` | real user `is_anonymous: true`; trigger created `Ospite-364D` (`is_guest: true`, avatar `lucia`, stats row) |
| Guest `claim_daily_reward` | `42501 guest_not_allowed` |
| Guest logout | 204 |
| **Email sign-up** A (`Alpha`, `sofia`) and B (`Alpha`, `not-an-avatar`) | both created with sessions (autoconfirm); trigger gave B `Alpha-1` and fell back to `lucia` |
| **Login** A, wrong password, **refresh-token restore**, `GET /auth/v1/user`, duplicate sign-up, **logout**, reuse of the revoked refresh token | ok / `invalid_credentials` / same user / ok / `user_already_exists` / 204 / `refresh_token_not_found` |
| **Password reset** `POST /auth/v1/recover` | `email_address_invalid` for `@example.com` — the mailer refuses undeliverable domains; needs a real inbox or custom SMTP |
| **`tool/supabase_smoke.dart`** (two users + guest, publishable key only) | **33/33 PASS** — see `docs/SUPABASE_SECURITY.md` matrix |
| Seeded one dev match (A/B) via `app_private.publish_match_state`, then over REST: A `match_private_state` | only A's row, hand `["coppe_asso","coppe_re"]` |
| B `match_private_state` | only B's row, `["spade_tre"]` |
| A filters explicitly for B's row | `[]` |
| A `match_public_state` | `handCount` per player, `drawPileCount`, no `hand`/`seed`/`drawPile`/`drawnCard`/`history` |
| A reads `app_private` over REST | `PGRST106 Invalid schema` (not exposed) |
| Non-player guest reads that match / public / private state | `[]` / `[]` / `[]` |
| A PATCH `matches.winner_id`, POST `match_actions`, PATCH `match_players.is_winner/xp_awarded` | all `42501` |
| A `claim_daily_reward` twice | `{day_index: 1, amount: 10}` then `already_claimed`; `player_stats.coins = 10` |
| SQL role-simulation probes (column grant, `app_private`, anon, guest claim, redaction on a conformance fixture) | all as designed |

The seeded match was deleted afterwards. Dev accounts left in place:
`s3-alpha@example.com`, `s3-bravo@example.com` (passwords were session-local
and are gone — sign up fresh ones; autoconfirm is on) and three anonymous
guests.

### Not verified

- **Password-reset e-mail delivery** — the built-in mailer rejects
  undeliverable test domains and is rate-limited; needs custom SMTP or a real
  inbox.
- **Guest → permanent account upgrade** (`updateUser` with email) — not wired
  in the UI yet; manual linking is enabled for it.
- **Local Supabase** (`supabase start` / `db reset`) — no Docker on this
  machine.
- **On-device run** with the defines — no emulator/device here.

---

## 2. Blockers

1. **SMTP.** Sign-up works (autoconfirm on, dev only), but password reset
   and any confirmation e-mail need a custom SMTP provider; the built-in
   mailer only delivers to organisation members and is rate-limited.
   Production must turn confirmations back on.
2. **Client decisions still open** (unchanged from Session 2): the online
   points formula (§12b — `profiles.rating` exists, nothing moves it), the
   Cavallo-vs-+2 defaults (§6a), turn-timer expiry.
3. **Leaked-password protection** is a paid-plan feature; enable it when the
   production project is on Pro.

---

## 3. Files Session 4 must read

1. `docs/SUPABASE_SECURITY.md` — the access model; do not weaken it.
2. `docs/DATABASE_SCHEMA.md` — every table and RPC, and the split state.
3. `supabase/migrations/20260829135727_matches_state.sql` —
   `publish_match_state` is the seam the authoritative function calls.
4. `docs/GAME_ENGINE.md` + `test/fixtures/game_conformance/` — the engine
   the server must run byte-for-byte.
5. `lib/app/bindings/backend_services.dart` — where a new repository is
   wired.
6. `lib/features/rooms/presentation/room_lobby_screen.dart` — polling seam
   to replace with realtime.
7. `tool/supabase_smoke.dart` — extend with match checks.

---

## 4. Things Session 4 must know

1. **Where the engine runs.** Two options are open: a Deno edge function
   (port the pure Dart engine or run it via `dart2js`), or a Dart server.
   Either way it must: load `app_private.match_engine_state`, validate
   `baseVersion`, run `applyAction`, write `match_actions`, and call
   `app_private.publish_match_state`. Clients only ever `select`.
2. **Realtime.** Add `rooms`, `room_players`, `match_public_state`,
   `match_private_state` to `supabase_realtime` in a migration; RLS applies
   to the `authenticated` role on realtime too. Then replace the lobby's
   3-second poll.
3. **Rating.** `record_match_result(match_id, rating_deltas)` takes explicit
   deltas — put the formula in one place once the client confirms it.
4. **Guest → account.** `enable_manual_linking` must be on; the flow is
   `updateUser(email)` then `updateUser(password)`; the DB trigger flips
   `is_guest`. Not wired in the UI yet.
5. **Nickname collisions** are resolved by the trigger at sign-up
   (`Alpha-1`) and reported as `23505` on edit (the UI shows "taken").
6. **`ProfileController.reload()`** — not `refresh()`, which GetX already
   defines.
7. **Migrations only through files.** `supabase migration new …` (check the
   file is non-empty — the CLI's JSON output once left it blank), then
   `supabase db push` (the project is linked). If MCP `apply_migration` is
   used instead, align the version in `supabase_migrations.schema_migrations`
   with the filename, as Session 3 did for the first four.
8. **`supabase config push` in a non-TTY shell auto-confirms every
   service.** Review the diff first in a real terminal, or keep `config.toml`
   aligned with the remote (Session 3 did) so the diff is only what you mean.

---

## 5. Client questions (carry-over)

| # | Question | Field / place | Provisional |
|---|---|---|---|
| 1 | Cavallo cancels or passes on a pending +2? | `GameRules.nineBlockMode` | `cancel` |
| 2 | Blocking Cavallo still changes suit? | `nineBlockChangesSuit` | `true` |
| 3 | Online points formula (§12b) | `record_match_result` deltas | none — nothing invented |
| 4 | XP per match / per win | `app_private.record_match_result`, `LevelLadder` | 20 / 45, ladder 120+40 (the old local placeholder) |
| 5 | Turn-timer expiry | engine only stamps deadlines | not implemented |
| 6 | Daily reward: guests allowed? | `claim_daily_reward` | permanent accounts only |

---

## 6. Commands

```bash
export PATH="$HOME/flutter-sdk/bin:$PATH"
export ANDROID_SDK_ROOT="$HOME/Android/Sdk" ANDROID_HOME="$HOME/Android/Sdk"

flutter pub get && flutter analyze && flutter test
dart format lib test tool

cp env/supabase.dev.json.example env/supabase.dev.json
flutter run --dart-define-from-file=env/supabase.dev.json

supabase login                                   # once, browser
supabase link --project-ref fnyllrjchbqfrzezfeso
supabase migration list
supabase config push --dry-run                   # anonymous sign-ins etc.

SUPABASE_URL=… SUPABASE_PUBLISHABLE_KEY=… dart run tool/supabase_smoke.dart
```

---

## 7. Still true from Sessions 1–2

- Feature-first layout; GetX only; `app_it.arb` is the template — run
  `flutter gen-l10n` after editing an ARB (Session 3 added 33 keys).
- `MatchLauncher` uses `permanent: true`; `InitialBinding` runs before
  `runApp`.
- The engine is pure and deterministic; `seed` is private (now enforced by
  `redact_game_state`).
- `test/tools/render_previews.dart` is a tool, not a test.
- `android/gradle.properties` heap stays lowered on this machine.
