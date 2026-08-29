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
- **Four migrations** in `supabase/migrations/` (1,263 lines), applied to the
  dev project through the Supabase MCP and version-aligned with the local
  filenames. Every table has RLS and an explicit grant; default privileges
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
- **Tooling**: Supabase CLI 2.116.0 installed (npm), `supabase init` done,
  `supabase/config.toml` prepared for local (anonymous sign-ins on, manual
  linking on, min password 8). `tool/supabase_smoke.dart` — a pure-Dart
  end-to-end auth + RLS matrix runner.
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
| MCP: list organisations / projects | ok — 1 org, 2 projects |
| MCP: `list_tables` before | `public` empty, no migrations |
| MCP: `apply_migration` ×4 | success; `list_migrations` shows 4; versions aligned to local filenames |
| MCP: `get_advisors(security)` | 9 WARN = the intended `SECURITY DEFINER` RPC list; 1 INFO = `app_private.match_engine_state` (intended); no ERROR |
| Data API, publishable key, no session: `POST /auth/v1/signup {}` | `422 anonymous_provider_disabled` — **anonymous sign-ins are OFF on the remote project** |
| `GET /auth/v1/settings` | `anonymous_users: false`, `email: true`, `mailer_autoconfirm: false` |
| Email sign-up attempts | `.test` addresses rejected as invalid; then `email rate limit exceeded` (built-in mailer) |
| SQL as `authenticated`: `update profiles set rating` | `42501 permission denied for table profiles` (column grant) ✔ |
| SQL as `authenticated`: `select … app_private.match_engine_state` | `42501 permission denied for schema app_private` ✔ |
| SQL as `authenticated`: `app_private.grant_xp(…)` | `42501` ✔ |
| SQL as `anon`: `select from profiles` | `42501` ✔ |
| SQL as `authenticated` + `is_anonymous:true`: `claim_daily_reward()` | `guest_not_allowed` ✔ |
| SQL as `authenticated`: `leaderboard('all_time',10)`, `is_permanent_user()` | callable, 0 rows, `true` ✔ |
| SQL: `redact_game_state(<conformance fixture>)` | no `seed`/`drawPile`/`drawnCard`/`history`; `drawPileCount 36`; players carry `handCount` only; `hand_of(s,'p1') = ["spade_tre"]`; no hidden card id in the output ✔ |

### Not verified

- **Real anonymous sign-in on the remote project** — blocked by the project
  setting (see §3). Local `config.toml` has it on.
- **Real email sign-up / login / password reset / session restore on the
  remote project** — no confirmed test account could be created: the
  built-in mailer is rate limited, `.test` domains are rejected, and
  seeding `auth.users` by SQL was declined by the environment's policy.
- **The two-user RLS matrix over REST** (`tool/supabase_smoke.dart`) — needs
  the two accounts above. The same policies were exercised by role
  simulation in SQL (table above).
- **Local Supabase** (`supabase start` / `db reset`) — no Docker on this
  machine.
- **On-device run** — no emulator/device here; the app was not launched
  with the defines. Everything on the Flutter side is covered by
  analyzer + 420 tests with the no-backend gateway.

---

## 2. Blockers

1. **One browser authorisation.** Enabling anonymous sign-ins (and, if
   wanted, pushing the rest of `config.toml`) needs a Management API token.
   Run `! supabase login` in this session; the rest (`supabase link
   --project-ref fnyllrjchbqfrzezfeso`, `supabase config push`, the smoke
   run) is scripted in `docs/SUPABASE_SETUP.md` and I can drive it. The
   dashboard toggle (Authentication → Providers → Anonymous) is the manual
   alternative.
2. **SMTP.** Sign-up/reset e-mails through the built-in mailer are limited
   to a few per hour and only reach org members. Configure a custom SMTP
   provider (or, for a private dev loop, disable confirmations remotely)
   before testing real sign-ups.
3. **Client decisions still open** (unchanged from Session 2): the online
   points formula (§12b — `profiles.rating` exists, nothing moves it), the
   Cavallo-vs-+2 defaults (§6a), turn-timer expiry.

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
7. **Migrations only through files.** `supabase migration new …`, then
   `apply_migration` (MCP) or `db push` (CLI). If MCP is used, align the
   version in `supabase_migrations.schema_migrations` with the filename, as
   Session 3 did.

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
