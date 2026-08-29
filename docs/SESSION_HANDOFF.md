# Session Handoff — Session 1 → Session 2

Date: 2026-08-29. Branch: `feature/session-1-ui-foundation`.

---

## 0. Read this first: the project was not on disk

`~/GiocoDel101` had been **deleted** from this machine. It was restored by
cloning the client's GitHub repo (`Farhan1232/GiocoDel101`, `main` @
`411873d8`, pushed 2026-08-29). Everything below was built on that.

**A large body of earlier work is gone and is not recoverable from here.**
Project notes describe roughly five phases completed on 27–28 Aug — Italian/
English localization, Firebase core and accounts, online multiplayer with
Cloud Functions, premium/Stripe, a web emulator harness, ~344 tests. None of
it exists in:

- the GitHub repo (2 commits, both the offline game),
- the local backup bundle (`gh-backup-…/GiocoDel101.bundle`, 26 Aug, single
  commit, `main` only),
- the Trash (empty),
- anywhere else on the filesystem,
- any other remote branch or tag (there are none).

All of those were checked. **If a copy exists on another machine, say so
before Session 2 starts** — merging it after this restructure will be
painful.

Practical consequence: localization had to be rebuilt (it was, this session).
The Firebase half is moot — this brief targets **Supabase**, confirmed with
the user.

---

## 1. What this session changed

### Restructured to feature-first
94 of the 101 source files moved from `screens/` `controllers/` `models/`
`widgets/` into `app/` `core/` `features/`. Imports were rewritten
mechanically by script, not by hand. Zero behaviour change: the analyzer was
clean and all 120 pre-existing tests still passed immediately after.

The engine keeps its **zero-Flutter-imports** rule.

### Localization (Italian primary)
`gen_l10n`, `app_it.arb` as the **template** (that is what makes Italian
primary — an untranslated key falls back to Italian). 308 keys in each of the
two ARB files.

The 146 pre-existing Italian strings were extracted **programmatically** from
the old `AppStrings` class and carried over verbatim, so no copy was retyped
or lost. Keys kept the old getter names, so no existing call site changed.

`Strings.s` gives controllers context-free access; `SettingsController` swaps
the bundle and the tree rebuilds.

### 16 new screens
Onboarding, auth landing, login, signup, forgot password, online mode, create
room, join room, room lobby, matchmaking, profile, edit profile, leaderboard,
achievements, daily reward — plus Home reworked to the brief's layout.

### Reusable components
`ScreenScaffold`, `AppTextField`, `AppDialog`/`PanelDivider`, `StatCard`/
`StatCardGrid`, `XpBar`, `PlayerSlotTile`, `AchievementTile`, `LoadingView`/
`ErrorView`/`EmptyView`, `NetworkStatusBanner`, plus a `loading` state on
`PremiumButton` and two new icon glyphs (`eye`, `eyeOff`).

### Design system
Every value the brief specifies **already existed** and matched exactly. The
court inks and card-back gradient were lifted out of the painters into
`AppColors` (`CourtInks`, `CardBackInks`) so the whole system reads from one
file.

### Achievements
The catalogue now carries the brief's six (Prima Vittoria, Centouno!,
Vendetta, Maestro del Nove, Imbattibile, Veterano). Three older badges that
already unlock cosmetics were kept with **unchanged ids**, so nobody loses a
cosmetic they earned. Copy moved out of the catalogue into ARB — it had been
hardcoded Italian that would have shown in the English UI. The three new
badges are actually granted in `statistics_service.dart`; none is unearnable.

### Table shell
A rules button, a turn-timer ring and a connection dot, all rendered from
`TableSessionStatus`. No rule and no network code entered the presentation
layer.

---

## 2. Nothing pretends to be online

This was the constraint I held hardest. `OnlineStatus.availability` is a
single hard-coded `BackendAvailability.notConfigured`, and:

- Auth forms validate and run a real submit cycle, then say the service is
  not connected. `AuthController.submit()` **can only return false**.
- No room is created or joined; the lobby seats only the local player and the
  host's Start button is **disabled**.
- Matchmaking's elapsed counter is real (time actually spent on screen) and it
  never announces a found opponent — it shows 1 of 4.
- Both leaderboards are empty and say the feature arrives with online play.
- The daily reward cannot be claimed.
- Social sign-in buttons are drawn and explicitly inert.

Four widget tests assert these specific things, so a future change that
quietly fakes one will fail the suite.

---

## 3. Verification — what I actually ran

| Gate | Result |
|---|---|
| `dart format .` | 151 files, 0 changed on the final pass |
| `flutter pub get` | OK |
| `flutter analyze` | **No issues found** |
| `flutter test` | **210/210 passed** (~27 s), up from 120 |
| `flutter build apk --debug` | **Built**, 156 MB debug APK |

Visual check: contact sheets rendered and inspected via
`test/tools/render_previews.dart` — `preview/menus_gallery.png`,
`account_gallery.png`, `rooms_gallery.png`, `player_gallery.png`. Three
layout/copy defects were found this way and fixed (truncated button labels,
a truncated screen title, and wrong empty-seat copy).

**Not verified:** no physical device and no emulator exists on this machine
(`flutter devices` lists only Linux desktop and Chrome). Nothing here has been
run on real Android or iOS hardware. iOS has not been built at all — there is
no macOS toolchain here.

---

## 4. Things Session 2 must know

1. **`GAME_SPEC.md` §6a — the Cavallo cannot block a pending +2.** The brief
   says it should. It is **not implemented**: `CardRuleResolver.canPlay`
   allows only another 2 into a live chain. Four sub-questions must go to the
   client before it is built; they are listed in the spec. Do not guess.
2. **No online points formula exists** (§12b). The leaderboard cannot show
   anything real until the client supplies one. None was invented.
3. **Turn-timer expiry is undefined** — the ring is drawn, the behaviour is
   not decided.
4. **GetX lifetime trap.** `Get.put(..., permanent: false)` ties a controller
   to the route that was current when it was registered. This previously
   killed `GameController` the moment the table appeared. `MatchLauncher` uses
   `permanent: true`. The widget tests now mount the **real route table** so
   this class of bug is catchable.
5. **`InitialBinding` now runs in `main.dart`**, before `runApp`, not as
   `GetMaterialApp.initialBinding` — the shell has to read the locale while it
   builds. Don't move it back.
6. **`android/gradle.properties` heap was lowered** from `-Xmx8G`/`4G`
   metaspace to `2560m`/`768m`. The old value could not be honoured on this
   7.7 GB machine and the daemon was OOM-killed mid-build; the symptom is the
   misleading "Gradle build daemon disappeared unexpectedly". Do not raise it
   back on this hardware.
7. **`test/tools/render_previews.dart` is a tool, not a test.** It calls
   `exit(0)`, so `flutter test` reports a failure even when it succeeds — look
   for the `wrote preview/…` line. Run one sheet at a time via `PREVIEW=`.
8. Generated localizations in `lib/l10n/gen/` are **committed** deliberately,
   so the analyzer and any CI need no extra step. Re-run `flutter gen-l10n`
   after editing an ARB.
9. `ProfileSummary.fromLocal` is a **local placeholder** for level/XP, flagged
   by `isPlaceholderProgression`. Replace the factory, not the widgets.

---

## 5. Commands

```bash
export PATH="$HOME/flutter-sdk/bin:$PATH"
export ANDROID_SDK_ROOT="$HOME/Android/Sdk" ANDROID_HOME="$HOME/Android/Sdk"

flutter pub get
flutter gen-l10n                 # after editing lib/l10n/*.arb
flutter analyze
flutter test
dart format .
flutter build apk --debug

PREVIEW=menus   flutter test test/tools/render_previews.dart
PREVIEW=account flutter test test/tools/render_previews.dart
PREVIEW=rooms   flutter test test/tools/render_previews.dart
PREVIEW=player  flutter test test/tools/render_previews.dart
```

---

## 6. Where things are

| Looking for | Path |
|---|---|
| Routes | `lib/app/router/app_router.dart` |
| Design system | `lib/app/theme/` |
| Copy | `lib/l10n/app_it.arb` (template), `app_en.arb` |
| Locale plumbing | `lib/app/localization/app_strings.dart` |
| Shared widgets | `lib/core/widgets/` |
| **Every game rule** | `lib/features/game/domain/game_rules_config.dart` |
| **Card legality** | `lib/features/game/domain/engine/card_rule_resolver.dart` |
| Backend seam | `lib/features/online/domain/online_status.dart` |
| Singletons | `lib/app/bindings/initial_binding.dart` |

---

## 7. Not done, deliberately

No Supabase, no networking, no AdMob, no IAP, no store work. Session 1 built
the foundation those sit on and stopped there.
