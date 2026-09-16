# Gioco del 101

A premium Neapolitan card game for Android and iOS, built with Flutter, that
plays **offline against bots or pass-and-play** and **online against real
people** through a server-authoritative Supabase backend.

Forty cards, four suits, one number. Empty your hand before anyone else;
whatever your opponents are still holding becomes penalty points. Cross
**101** and you are out. Land on **101 exactly** and your score resets to
zero. Asso skips, Due draws two (and chains), the Cavallo changes the suit.

| | |
|---|---|
| Flutter / Dart | **3.44.6 / 3.12.2** (stable channel; `sdk: ^3.12.0`) |
| State management | GetX (`get ^4.7`) — controllers, routing, reactive views |
| Persistence | `shared_preferences` (settings, statistics, resumable match) |
| Backend | Supabase (`supabase_flutter ^2.17`): Auth, Postgres + RLS, Realtime, one Edge Function |
| Localisation | `gen_l10n`, Italian template (`lib/l10n/app_it.arb`) + English |
| Package id | `it.giocodel101.gioco_del_101` |
| Tests | 796 Flutter tests, 75 Deno tests, bot simulation, a long-session stress harness, two real-backend regression tools |

Documentation for every part lives in `docs/`; the final state of the
project, with what was and was not verified, is
`docs/FINAL_VERIFICATION.md` and `docs/SESSION_HANDOFF.md`.

---

## 1. Project overview and layout

Feature-first. Each feature holds up to three layers: `domain/` (no
Flutter, no I/O), `application/` (state, no widgets), `presentation/`
(renders state, decides nothing). `core/` never imports a feature.

```
lib/
├── main.dart                     Boot: storage, licences, orientation, Supabase, bindings
├── app/
│   ├── app.dart                  GetMaterialApp, locale, lifecycle, session-expiry notice
│   ├── bindings/                 InitialBinding, BackendServices (the backend seam)
│   ├── localization/             Strings facade over gen_l10n
│   ├── router/                   AppRoutes + AppPages
│   └── theme/                    Palette, typography, table themes, card backs
├── core/
│   ├── config/                   SupabaseEnv (--dart-define values)
│   ├── constants/                Spacing, radii, card metrics, durations
│   ├── services/                 Audio, haptics, Supabase bootstrap
│   ├── storage/                  SharedPreferences wrappers, resumable snapshot
│   ├── utils/                    Motion, glow, Log
│   └── widgets/                  Buttons, panels, fields, icons, the card deck
├── features/
│   ├── game/                     domain/ (engine + AI), application/, presentation/
│   ├── tutorial/                 Eight scripted lessons on the real table
│   ├── online/                   OnlineMatchController, repositories, mode screen
│   ├── rooms/                    Create / join / lobby / quick match
│   ├── auth/  profile/  home/  splash/  onboarding/
│   ├── leaderboard/  achievements/  missions/  rewards/  settings/
└── l10n/                         app_it.arb (template), app_en.arb, gen/

supabase/
├── migrations/                   11 SQL migrations — the schema's source of truth
├── functions/match/              The authoritative match function (Deno) + engine.js
└── config.toml                   Auth settings for the linked project

tool/                             build_engine_js.sh, online_matrix, progression_smoke,
                                  bot_simulation, ui_drive_web (headless Chrome)
test/                             Flutter tests; fixtures/game_conformance/*.json
docs/                             Design, engine, schema, security, verification
```

| Document | What it covers |
|---|---|
| `docs/GAME_SPEC.md` | Every rule, and the open questions for the client |
| `docs/CLIENT_FINAL_CHANGE.md` | The final 2026-08-31 requests: Fante/Cavallo = 25, ULTIMA CARTA, large hands |
| `docs/CLIENT_SCORING_CORRECTION_2026_09_01.md` | The 2026-09-01 scoring correction: Fante 8, Cavallo 25, Re 10 |
| `docs/GAME_ENGINE.md` | The pure, deterministic rules engine |
| `docs/ARCHITECTURE.md` | Layers, state management, the backend seam |
| `docs/OFFLINE_MODE.md`, `docs/BOTS.md` | Bots, pause/resume, saves, tutorial, animations |
| `docs/ONLINE_MULTIPLAYER.md`, `docs/REALTIME.md` | Server-authoritative online play, the live feed |
| `docs/SECURITY.md`, `docs/SUPABASE_SECURITY.md` | Threat model, enforcement, the attacks that were run |
| `docs/DATABASE_SCHEMA.md`, `docs/SUPABASE_SETUP.md` | Tables, RPCs, migrations, linking the project |
| `docs/PROGRESSION.md` | XP, achievements, missions, leaderboard |
| `docs/ASSET_INVENTORY.md` | Cards, fonts, audio |
| `docs/FINAL_VERIFICATION.md` | Feature-by-feature verification matrix |
| `docs/SESSION_HANDOFF.md`, `docs/ROADMAP.md` | Latest session, what is next |

---

## 2. Architecture in one paragraph each

### Offline

`GameEngine` (`lib/features/game/domain/engine/`) is a pure, deterministic
state machine: `applyAction(state, action) → (state, events)` or a typed
failure. It has no clock, no I/O and no Flutter import. `GameSession` wraps
it; `GameController` (the offline driver) turns engine events into table
cues — animations, sound, haptics — and drives the bots
(`domain/ai/`: Easy / Normal / Hard, four personalities). A `BotView` holds
no hidden information, so a bot cannot cheat. The live state is saved after
every change (coalesced, 350 ms) and on backgrounding; Home offers
**Continua partita**. The tutorial (`features/tutorial/`) is eight fixed
states played on the same table. Offline statistics, XP, achievements and
missions live in a local ledger that never reaches the server.

### Online

**Flutter asks; the server decides; Postgres remembers; Realtime tells
everyone.** The same engine is compiled with `dart compile js`
(`tool/build_engine_js.sh` → `supabase/functions/match/engine.js`,
committed) and executed by the `match` Edge Function. Every commit goes
through `public.srv_*` SECURITY DEFINER functions (service_role only) with a
row lock, a version check and an idempotency receipt. The phone receives a
**redacted** snapshot (`handCount`, `drawPileCount`) plus its own hand; the
seed (52 bits) and the deck order never leave the database. Two Realtime
channels per match: `match-rows:<id>` for RLS-filtered row changes and the
private `match:<id>` for presence and server-sent reactions. Results, XP,
weekly points, achievements and missions are computed only by
`app_private.settle_match`. Rating deltas are still 0 (formula unconfirmed).

---

## 3. Supabase setup

The app runs fully offline with no configuration: without credentials
`BackendServices.none()` is wired and every online screen explains that the
service is not configured.

To connect it to the development project **GiocoDel101-Dev**
(`fnyllrjchbqfrzezfeso`, eu-central-1):

```bash
cp env/supabase.dev.json.example env/supabase.dev.json   # git-ignored
```

`env/supabase.dev.json` holds the two public values:

| Key | Meaning |
|---|---|
| `SUPABASE_URL` | `https://<project-ref>.supabase.co` |
| `SUPABASE_PUBLISHABLE_KEY` | the project's publishable (anon) key — public by design, RLS does the protecting |

They reach the app as compile-time defines (`SupabaseEnv`,
`lib/core/config/`). **No secret ever belongs in the repository**: the
service-role key exists only as an Edge Function environment variable on
Supabase; the database password and access tokens live in the CLI's own
store. `docs/SUPABASE_SETUP.md` has the full walk-through, the auth
settings (`supabase/config.toml`) and the production checklist (SMTP, leaked
password protection, CAPTCHA, per-user function rate limit).

Tools that talk to the real project read the same two values from the
environment, plus `UI_HOST_PASSWORD` for the headless-Chrome driver:

```bash
export SUPABASE_URL=https://fnyllrjchbqfrzezfeso.supabase.co
export SUPABASE_PUBLISHABLE_KEY=sb_publishable_…
```

### Migrations

`supabase/migrations/` (11 files) is the only source of truth for the
schema. Apply with the linked CLI or the Supabase MCP:

```bash
supabase db push < /dev/null     # apply pending local migrations
supabase migration list          # local vs remote — should be 11 = 11
supabase functions deploy match --use-api
```

Every new public function needs an explicit `GRANT` (default privileges are
revoked) and every new table needs RLS plus `GRANT SELECT`. The mission
rotation exists twice on purpose (`MissionCatalog` in Dart,
`app_private.mission_rotation` in SQL) — change both.

---

## 4. Run

```bash
export PATH="$HOME/flutter-sdk/bin:$PATH"           # if Flutter is not on PATH
flutter pub get
flutter gen-l10n                                     # only after editing an ARB

flutter run                                          # offline only
flutter run --dart-define-from-file=env/supabase.dev.json   # with the dev backend
flutter run -d chrome --dart-define-from-file=env/supabase.dev.json
```

## 5. Test

```bash
flutter analyze
flutter test                                         # 796 tests, ~125 s
dart run tool/bot_simulation.dart                    # bot matches, invariants (SIM_MATCHES=…)
deno test --allow-read supabase/functions/match/     # 61 conformance fixtures + timeout policy
deno test --allow-read --allow-env supabase/functions/verify-purchase/   # --allow-env is required
RULE_CHECK_SEATS=4 dart run tool/online_rule_check.dart   # §3/§6b/§12/§12a/§16, live

# Against the real dev project (five / two independent users):
MATRIX_QUICK=1 dart run tool/online_matrix.dart      # ~13 min; omit MATRIX_QUICK for 2/3/4-player games (~30 min)
dart run tool/progression_smoke.dart                 # results, achievements, missions, leaderboard (~10 min)

# The real web app in headless Chrome, one seat driven through semantics:
flutter build web --dart-define-from-file=env/supabase.dev.json
(cd build/web && python3 -m http.server 8787 --bind 127.0.0.1 &)
UI_HOST_PASSWORD=… deno run -A tool/ui_drive_web.ts <outDir>
```

`test/session9_long_session_stress_test.dart` is the long-session guard: it
drives the real route table for ~500 sound effects of continuous play **with
the audio path switched on** (`test/support/fake_audio_platform.dart` stands
the plugin up) and asserts nothing accumulates. That blind spot — no test had
ever executed one line of the sound path — is what hid the crash the client
reported; see docs/PERFORMANCE_CRASH_AUDIT.md.

`test/tools/*` are tools, not tests (`render_previews.dart` draws the
contact sheets in `preview/`; `generate_conformance_fixtures.dart`
regenerates the fixtures with `GENERATE_FIXTURES=1`).

After **any** change under `lib/features/game/domain/`: rebuild the engine
(`tool/build_engine_js.sh`), run the Deno tests, redeploy the function.

## 6. Build

```bash
export ANDROID_HOME=$HOME/Android/Sdk
D=--dart-define-from-file=env/supabase.dev.json

flutter build apk --debug $D
flutter build apk --release $D          # build/app/outputs/flutter-apk/app-release.apk
flutter build appbundle --release $D    # build/app/outputs/bundle/release/app-release.aab
```

- `android/app/src/main/AndroidManifest.xml` declares exactly one
  permission: `INTERNET` (online play). Nothing else is requested.
- Release signing: put `android/key.properties` (git-ignored) next to your
  upload keystore and the release build signs with it; without the file the
  build falls back to the debug key so it can still be installed for
  testing. The Play Store needs the signed one.
- iOS: `flutter build ios --release` needs macOS and Xcode; the project has
  the display name, portrait lock and no extra capabilities, but it has not
  been compiled on a Mac from this repository.

## 7. Where the rules live

One file: `lib/features/game/domain/game_rules.dart` (`GameRules`). Nothing
in the engine, the controllers or the widgets hardcodes a rule, and the
same object travels to the server as the room's house rules (validated key
by key by `app_private.sanitize_room_rules`). The provisional choices the
client still has to confirm are listed in `docs/GAME_SPEC.md` and in the
handoff's client-questions table.

## 8. Cards, fonts, audio

The forty card faces are **traditional Carte Napoletane** — public-domain
artwork, one WebP per card in `assets/cards/`, named by `GameCard.id`, licence
in `assets/cards/LICENSE.txt`. They are decoded at the size they are drawn, so
a table full of cards stays cheap. The engraved vector painters
(`lib/core/widgets/cards/`) remain as the fallback if an asset is missing or
has not decoded yet; the four card **backs** are still vector art painted at
runtime. Fonts are Cinzel and Manrope (SIL OFL, licences bundled and shown in
the licence page). The seventeen audio assets are synthesised, not sampled.
See `docs/ASSET_INVENTORY.md`.

## 9. Design notes

Palette: midnight navy `#0B1020`, surfaces `#141A2E` / `#1C2440`, ink
`#060911`, antique gold `#D9A441` / `#F6DFA6` / `#8A5F1C`, Mediterranean
teal `#2AA89B`, terracotta `#DF654B`, ivory `#F3E9D8`, muted `#B6AC9C`;
cards `#F7EEDC` / `#CBB68E`. Typography: Cinzel for titles, Manrope for
everything else. No Material defaults show through (explicit
`ColorScheme`, themed inputs, dialogs, snackbars).

Accessibility: every suit has a distinct shape as well as a colour; cards,
the discard pile and every icon button carry semantics labels; Reduce
Motion honours both the in-app switch and the platform flag; large-card
mode; text scaling is respected between 0.85× and 1.30×.

## 10. Privacy

Offline play makes no network call. Online play talks only to the Supabase
project: account e-mail (or an anonymous guest identity), nickname, avatar,
match records and progression. No analytics SDK, no advertising SDK, no
tracking, and no access to location, contacts, microphone or camera.
