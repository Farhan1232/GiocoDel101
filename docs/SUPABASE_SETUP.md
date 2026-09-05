# Supabase Setup

Session 3, 2026-08-29. How the app talks to Supabase, how to run it against
the development project, and how to create the production project later.

## The development project

| | |
|---|---|
| Name | **GiocoDel101-Dev** |
| Project ref | `fnyllrjchbqfrzezfeso` |
| URL | `https://fnyllrjchbqfrzezfeso.supabase.co` |
| Region | `eu-central-1` (Frankfurt) — nearest to the Italian audience; a region is permanent |
| Organisation | `Farhan1232's Org` (`arhqisyxgnkgqaphqvfy`), free plan, $0/month |
| Postgres | 17 |
| Purpose | **development only** — test accounts, throw-away data, no customer data |

The org has one other project (`Farhan1232's Project`, `ap-southeast-1`)
that is unrelated and must not be touched.

## How Flutter receives the URL and key

`lib/core/config/supabase_env.dart` reads two compile-time defines:

```
SUPABASE_URL
SUPABASE_PUBLISHABLE_KEY
```

Both are **public** values (the project URL and the `sb_publishable_…` key,
which is the modern replacement of the legacy `anon` JWT). They identify the
project; they grant nothing — every permission comes from RLS and the
signed-in user's JWT. They are safe to ship in an APK.

Without them the app boots in the honest offline mode: `OnlineStatus` stays
`notConfigured`, every online screen says the service is not connected, and
the widget tests run exactly like that.

Never compile in, commit or paste into a doc: the `service_role` / secret
key, the database password, a Management API access token, or the MCP OAuth
credentials. The app has no code path that could use them.

### Run against the dev project

```bash
cp env/supabase.dev.json.example env/supabase.dev.json   # git-ignored
export PATH="$HOME/flutter-sdk/bin:$PATH"
flutter run --dart-define-from-file=env/supabase.dev.json
flutter build apk --debug --dart-define-from-file=env/supabase.dev.json
```

Or inline: `--dart-define=SUPABASE_URL=… --dart-define=SUPABASE_PUBLISHABLE_KEY=…`.

The example file already contains the dev project's URL and publishable key
(read programmatically through the Supabase MCP). To rotate the key, generate
a new publishable key in the dashboard (Settings → API keys) and update the
example.

## Boot sequence (what the app does at start)

1. `SupabaseBootstrap.initialize()` — `Supabase.initialize(url, publishableKey,
   PKCE)`; the persisted session is restored **inside** this call.
2. `OnlineStatus.report(ready | notConfigured)`.
3. `InitialBinding` registers `SessionController` (reads the restored session
   synchronously) and `ProfileController` (loads `profiles` for it).
4. The splash animates, then `BootRouter.resolve()` picks exactly one route:
   onboarding → account choice (configured + logged out) → home (guest,
   signed in, or no backend). No intermediate route is ever pushed.

## Repository layout

```
supabase/
  config.toml           local stack config (anonymous sign-ins ON, manual
                        linking ON, min password 8, email confirmations OFF
                        locally for convenience)
  migrations/           the schema — the only source of truth
env/
  supabase.dev.json.example   committed; copy to supabase.dev.json (ignored)
tool/
  supabase_smoke.dart   real end-to-end auth + RLS checks (pure Dart)
docs/
  DATABASE_SCHEMA.md    every table/function
  SUPABASE_SECURITY.md  the access model and the verification matrix
```

## Migrations

Every schema change is a file in `supabase/migrations/`, created with:

```bash
supabase migration new <snake_case_name>     # writes <timestamp>_<name>.sql
```

Session 3 applied the first four migrations through the Supabase MCP
(`apply_migration`) and aligned the remote
`supabase_migrations.schema_migrations` versions with the local filenames;
the fifth (`fk_covering_indexes`) went through `supabase db push` on the
linked project; Sessions 4–5 pushed with the CLI; Session 6's
`release_hardening` and `receipt_scope` were applied through the MCP again
(their remote versions `20260830100111` / `20260830110458` are the MCP's
timestamps, and the local files are named to match). `supabase migration
list` shows 11 = 11. Prefer the CLI:

```bash
supabase db push            # apply pending local migrations to the linked project
supabase migration list     # compare local vs remote history
```

Never change the schema from the dashboard's table editor or SQL editor
without also committing the same SQL as a migration.

## Local Supabase (Docker)

Not available on this machine (no Docker), so `supabase start` was not run.
On a machine with Docker:

```bash
supabase start                  # local Postgres/Auth/PostgREST on 127.0.0.1:54321
supabase db reset               # drop + replay every migration + seed.sql
supabase status -o env          # prints API_URL and the local publishable/anon key
```

Point the app at it with a second define file, e.g. `env/supabase.local.json`
containing the local `API_URL` and `PUBLISHABLE_KEY`/`ANON_KEY` from
`supabase status`. Then run the smoke script (below) against it.

## Linking the project (another developer)

```bash
npm install -g supabase          # or brew install supabase/tap/supabase
supabase login                   # opens the browser; creates a personal access token
cd GiocoDel101
supabase link --project-ref fnyllrjchbqfrzezfeso
supabase migration list          # should show all four migrations applied
```

`supabase link` writes `supabase/.temp/` (ignored). The access token lives in
the CLI's own store, never in the repo.

### Auth settings that live outside migrations

Two settings are project configuration, not schema, and must be on in every
environment (dev and production):

| Setting | Dashboard path | `config.toml` key |
|---|---|---|
| Anonymous sign-ins | Authentication → Sign In / Providers → Anonymous | `[auth] enable_anonymous_sign_ins = true` |
| Manual identity linking | Authentication → Sign In / Providers → Manual linking | `[auth] enable_manual_linking = true` |

Session 3 pushed them from `config.toml` with `supabase config push`; the
dev project now has **anonymous sign-ins ON, manual linking ON, minimum
password 8, and email confirmations OFF** (`mailer_autoconfirm: true`).
Confirmations are off *for the dev loop only* — sign-ups return a session
immediately and need no SMTP. Production must keep them on.

`supabase config push` has no dry run in CLI 2.116 and, in a non-TTY shell,
**auto-confirms every service's diff** (auth, storage, …). Run it from a real
terminal and read each diff, and keep `config.toml` aligned with the remote
for everything you do not mean to change (the `[storage.vector]` section must
stay `enabled = false` on the free plan — the push fails with 402 otherwise,
harmlessly).

Configure a custom SMTP provider before testing password reset or
confirmation e-mails: the built-in mailer rejects undeliverable domains
(`email_address_invalid`), allows only a few messages per hour and delivers
only to organisation members.

## Edge Functions (Session 4)

`supabase/functions/match/` is the authoritative match function. It loads
the Dart engine compiled to JavaScript (`engine.js`, committed — rebuild
with `tool/build_engine_js.sh` after any engine change).

```bash
# tests (Deno 2.x, no Docker needed)
deno test --allow-read supabase/functions/match/

# deploy to the linked project (the API bundles it; Docker is not required)
supabase functions deploy match --use-api
```

The function needs no extra secrets: `SUPABASE_URL`, `SUPABASE_ANON_KEY`
and `SUPABASE_SERVICE_ROLE_KEY` are injected by the platform. `verify_jwt`
stays on. `tool/online_matrix.dart` (below) is the end-to-end check.

## Verifying a project

```bash
SUPABASE_URL=https://fnyllrjchbqfrzezfeso.supabase.co \
SUPABASE_PUBLISHABLE_KEY=sb_publishable_… \
SMOKE_EMAIL_A=… SMOKE_PASSWORD_A=… SMOKE_EMAIL_B=… SMOKE_PASSWORD_B=… \
dart run tool/supabase_smoke.dart
```

Prints PASS/FAIL per check (see `docs/SUPABASE_SECURITY.md` → Verification
matrix) and exits non-zero on any failure.

```bash
SUPABASE_URL=… SUPABASE_PUBLISHABLE_KEY=… dart run tool/online_matrix.dart
```

Signs up five fresh users and plays real 2/3/4-player matches through the
deployed function, Realtime and the RPCs, including every attack in
`docs/SECURITY.md`. Takes ~25 minutes (full games to 101); set
`MATRIX_SKIP_TIMEOUT=1` to skip the 16 s turn-timer wait. A and B must be two confirmed
email accounts on that project (with autoconfirm on, any fresh sign-up is
one). Without the `SMOKE_*` variables it runs only the anonymous-key and
guest checks. Session 3's run against the dev project: **33/33 PASS**.

## Creating the production project later

1. Same organisation (or a dedicated paid org), **new** project named
   `GiocoDel101-Prod`, region `eu-central-1`, a strong generated database
   password stored in a password manager — never in the repo.
2. `supabase link --project-ref <prod-ref>` then `supabase db push` to apply
   the same migrations. Do not create tables by hand.
3. Turn on anonymous sign-ins and manual linking; keep email confirmation
   **on**; set up custom SMTP; enable CAPTCHA/Turnstile for anonymous
   sign-ins; review rate limits.
4. Create `env/supabase.prod.json` locally (ignored) with the prod URL and
   its publishable key; build release with
   `--dart-define-from-file=env/supabase.prod.json`.
5. Run `tool/supabase_smoke.dart` against production **with test accounts
   only**, then delete them.
6. Point-in-time recovery and a backup policy are a plan decision — the free
   plan keeps daily backups for 7 days.

Development and production never share a project, a key or a database.
