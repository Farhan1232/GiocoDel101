# Architecture

## Shape

Feature-first. Three top-level zones, and the dependency rule that keeps them
apart:

```
lib/
  main.dart                 boot: storage, licences, orientation, bindings
  app/                      the shell — everything global
    app.dart                GetMaterialApp, locale, lifecycle hooks
    bindings/               the long-lived singletons
    localization/           Strings facade over gen_l10n
    router/app_router.dart  AppRoutes + AppPages, one file
    theme/                  colours, typography, table themes, card backs
  core/                     shared, feature-agnostic
    constants/  errors/  services/  storage/  utils/  widgets/
  features/
    achievements/  auth/  game/  home/  leaderboard/  onboarding/
    online/  profile/  rewards/  rooms/  settings/  splash/
  l10n/                     app_it.arb (template), app_en.arb, gen/
```

Inside a feature, up to three layers:

- `domain/` — models and rules. No Flutter, no GetX, no I/O.
- `application/` — controllers and services. State, no widgets.
- `presentation/` — screens and widgets. Renders state; decides nothing.

**Direction of dependency:** `features/` → `core/` → `app/theme`. `core/` never
imports a feature. A feature may import another feature's `domain/`, but not
its `application/` or `presentation/`.

### The rule that matters most

`features/game/domain/engine/` has **zero Flutter imports** and no knowledge
that a UI exists. `GameEngine` is a *pure* function library over an
immutable `GameState`: `validateAction` / `applyAction` / `getPlayableCards`.
It owns nothing and draws no randomness of its own (shuffles derive from the
state's seed and version), so `(state, action) → state'` is deterministic
and the same code will run inside the authoritative server. `GameSession`
is the one stateful handle: it holds the current `GameState`, forwards every
move as a `GameAction`, and fans the returned `GameEvent`s out.
`GameController` (application) turns those into an ordered `TableCue` queue
that the gameplay view animates and acknowledges. Bots receive a `BotView`
built from `GameState` that structurally cannot contain hidden information.
Full reference: `docs/GAME_ENGINE.md`.

This is why the table can be re-skinned, re-laid-out or driven by a server
later without touching a rule.

## State management — GetX

The project already used GetX consistently and cleanly, so per the brief's own
instruction it was kept rather than swapped for Riverpod. Mixing two solutions
would have been the worse outcome. There is exactly one state framework.

Long-lived controllers are registered in `app/bindings/initial_binding.dart`,
called from `main.dart` **before** `runApp` so the shell can read the chosen
language while it builds:

| Controller | Owns |
|---|---|
| `SettingsController` | preferences, locale, unlocked cosmetics |
| `StatsController` | lifetime counters, achievements |
| `HomeController` | saved-match presence, daily challenge |
| `GameController` | a live match (owns a `GameSession`) |
| `CreateRoomController` | a room being configured |
| `AuthController` | one auth form's submit state |

### A GetX trap worth knowing

`Get.put(..., permanent: false)` ties a controller's lifetime to the route that
was current when it was registered. Registering a `GameController` while
`/setup` is on top and then calling `Get.offNamed('/game')` disposes it the
instant the table appears — the screen renders but the controller is dead.
`MatchLauncher` therefore uses `permanent: true` and deletes explicitly.

## Navigation

One route table: `lib/app/router/app_router.dart`. `AppRoutes` holds the path
constants, `AppPages` the `GetPage` list. Every transition is authored
(`_DepthTransition`); none is the platform default.

Android back works through the normal `Navigator` stack. Screens that must
confirm before leaving pass `onBack` to `ScreenScaffold` (the room lobby) or
intercept themselves (the game table's `_confirmExit`).

Boot order: `splash` → `onboarding` on first run, otherwise → `home`.

## Localization

`gen_l10n`, configured in `l10n.yaml`. **`app_it.arb` is the template** — that
is what makes Italian primary: a key with no English translation falls back to
Italian, not the other way round. 301 keys in both files, and a test asserts
the two stay in step.

Widgets could use `AppLocalizations.of(context)`, but controllers and services
have no context and still need to name a card. So `Strings.s` holds the
resolved bundle and `SettingsController._apply()` swaps it whenever the locale
changes, with the whole tree rebuilt by an `Obx` around `GetMaterialApp`.

ARB has no list type, so `reactions8` is eight keys joined by an extension.

## The design system

Centralised in `app/theme/`:

- `AppColors` — surfaces, gold ramp, text, plus `CourtInks` and `CardBackInks`
- `SuitPalette` — colour **and** shape per suit, so colour is never the only
  differentiator
- `AppText` — Cinzel for display, Manrope for UI and every numeral
- `AppSpacing` / `AppRadii` / `CardMetrics` — including the card ratio (1.55)
  and corner ratio (0.075)
- `TableThemes`, `CardBacks`

Every value the brief specifies was already present and is now asserted in one
place. Screens never hard-code a colour.

## Reusable components (`core/widgets/`)

`ScreenScaffold` (backdrop + safe area + title bar + back), `PremiumButton`
(4 variants, 3 sizes, loading state), `AppPanel` / `SectionHeading`,
`AppTextField`, `AppDialog` / `PanelDivider`, `AvatarMedallion`,
`SegmentedControl`, `AppSwitch` / `SettingRow`, `IconPill`, `Logo101`,
`StatCard` / `StatCardGrid`, `XpBar`, `PlayerSlotTile`, `AchievementTile`,
`LoadingView` / `ErrorView` / `EmptyView`, `NetworkStatusBanner`,
`AppIconView`, and the card painters.

`core/widgets/` takes its copy as arguments — it never reaches for a
localization bundle, which is what keeps it feature-agnostic.

## Backend: Supabase, not yet present

No Supabase client, no networking, no credentials. What exists is the seam:

`features/online/domain/online_status.dart` holds one constant,
`OnlineStatus.availability`, hard-coded to `BackendAvailability.notConfigured`.
Every online surface reads it and states plainly that the service is not
connected. **An optimistic default here is what would turn a shell into a lie**,
so it stays a constant until there is something real behind it.

Session 3 replaces that constant with a real check and fills in:

| Seam | Becomes |
|---|---|
| `AuthController.submit()` | a Supabase auth call |
| `RoomConfig` → lobby | a row in a `rooms` table |
| `RoomLobbyState` | a realtime subscription |
| `LeaderboardBoard` | a query (needs the §12b formula first) |
| `ProfileSummary.fromLocal` | server-owned level/XP |
| `TableSessionStatus` | live connection + turn clock |
| `GameSession` state | replaced by server snapshots; actions posted instead of applied locally |

None of those requires a widget change. The engine's conformance fixtures
(`test/fixtures/game_conformance/`) are the acceptance test for the server.

## Testing

403 tests, ~32 s.

- `test/engine/` — the Session 2 engine suite: card model, game start, turn
  flow & validation, Asso, Due, Nove, draw pile, score policy, serialization,
  determinism, and the conformance-fixture replay
- Rules, scoring, deck, bots, edge cases — the pre-existing engine suite,
  now driving `GameSession`
- `session1_domain_test.dart` — validators, room codes, profile maths, reward
  ladder, ARB parity, locale resolution
- `session1_screens_test.dart` — all 16 new screens at three sizes in both
  languages, plus the assertions that keep the shell honest
- `widget_smoke_test.dart` — every original screen at three sizes under three
  themes, and the table played through real taps

The widget tests mount the **real route table**, so a screen that navigates
actually navigates. That is deliberate: the class of bug where a controller is
disposed by a route change is invisible to a test that renders a screen
directly.

`test/tools/render_previews.dart` is a tool, not a test — it writes contact
sheets into `preview/`.
