# Gioco del 101

A premium, fully offline Neapolitan card game for Android and iOS, built with Flutter.

Forty cards, four suits, one number. Empty your hand before anyone else; whatever
your opponents are still holding becomes penalty points. Cross **101** and you are
out. Land on **101 exactly** and your score resets to zero.

Everything runs on the device. No accounts, no backend, no database, no analytics,
no ads, no network calls of any kind.

---

## 1. Project structure

```
lib/
├── main.dart                Boot: storage, licences, orientation, bindings
├── app/                     The shell — everything global
│   ├── app.dart             GetMaterialApp, locale, lifecycle hooks
│   ├── bindings/            Dependency wiring (run from main, pre-runApp)
│   ├── localization/        Strings facade over gen_l10n
│   ├── router/              AppRoutes + AppPages, one file
│   └── theme/               Colours, typography, table themes, card backs
├── core/                    Shared, feature-agnostic
│   ├── constants/           Spacing, radii, card metrics, durations
│   ├── services/            Audio, haptics
│   ├── storage/             SharedPreferences wrappers + resumable snapshot
│   ├── utils/               Motion scaling, glow
│   └── widgets/             Buttons, panels, fields, the icon set, the deck
├── features/
│   ├── game/
│   │   ├── domain/          Models + engine + AI  ← no Flutter imports
│   │   ├── application/     GameController, TableCue, MatchLauncher
│   │   └── presentation/    Table, setup, results, how-to-play
│   ├── splash/  onboarding/  auth/  home/
│   ├── online/  rooms/       profile/  leaderboard/
│   └── achievements/  rewards/  settings/
└── l10n/                    app_it.arb (template), app_en.arb, gen/
```

Each feature holds up to three layers: `domain/` (no Flutter, no I/O),
`application/` (state, no widgets), `presentation/` (renders state, decides
nothing). `core/` never imports a feature.

**The important boundary:** `lib/features/game/domain/engine/` imports nothing from Flutter. The
engine owns the rules and emits `GameEvent`s; `GameController` turns those into
animations, sound and haptics. That separation is what makes the rules testable
and what would make networking possible later (§10 below).

---

## 2. How to run

The game runs fully offline with no configuration. To connect it to the
Supabase development project (accounts, guests, profiles, rooms,
leaderboards) pass the two public values with a git-ignored define file —
see `docs/SUPABASE_SETUP.md`:

```bash
cp env/supabase.dev.json.example env/supabase.dev.json
flutter run --dart-define-from-file=env/supabase.dev.json
```

Requires Flutter 3.44 or newer.

```bash
flutter pub get
flutter gen-l10n     # only after editing lib/l10n/*.arb
flutter run
```

Deeper documentation lives in `docs/`:

| File | What it covers |
|---|---|
| `docs/GAME_SPEC.md` | Every rule, and the open questions for the client |
| `docs/ARCHITECTURE.md` | Layers, state management, the backend seam |
| `docs/ASSET_INVENTORY.md` | Cards, fonts, audio, icons — what exists and why |
| `docs/ROADMAP.md` | The six sessions |
| `docs/SESSION_HANDOFF.md` | What the last session changed and what is next |

Run the tests:

```bash
flutter test
```

118 tests, about twelve seconds. They fall into three groups:

- **Rules** (`deck_test`, `rules_test`, `scoring_test`, `edge_cases_test`) —
  the deck, every matching rule, the Ace, the +2 chain, the Cavallo, scoring,
  the exact-101 reset, elimination, deck recycling, corrupt saves and
  save/restore. Includes a fuzz test that plays 40 complete random matches and
  asserts they always terminate, never lose a card and never deadlock.
- **AI** (`bot_test`) — every difficulty is checked for legal play across 25
  seeded matches, Hard is checked to beat Easy over 40 matches, and a fairness
  test proves a bot's decision does not change when the opponents' hidden hands
  change but the public table does not.
- **Interface** (`widget_smoke_test`, `gameplay_widget_test`) — every screen and
  every signature effect is rendered at three sizes (390×844, 360×640,
  834×1112) under all three table themes and asserted clean; and the table is
  actually played through the real widgets: tap a card and the engine must have
  played it, tap an illegal one and it must stay in hand, play a Cavallo and the
  Suit Ritual must open and set the suit, take a +2 penalty and the cards must
  arrive.

### Rendering the preview sheets

`test/tools/render_previews.dart` draws contact sheets into `preview/`. It is a
tool rather than a test — it calls `exit` when it is done, so `flutter test`
reports the shell ending early. Run one sheet at a time:

```bash
PREVIEW=menus   flutter test test/tools/render_previews.dart
PREVIEW=table   flutter test test/tools/render_previews.dart
PREVIEW=results flutter test test/tools/render_previews.dart
PREVIEW=deck    flutter test test/tools/render_previews.dart
```

---

## 3. Building an Android APK / AAB

```bash
# Debug
flutter build apk --debug

# Release APK (sideloading, direct distribution)
flutter build apk --release

# Release App Bundle (Play Store)
flutter build appbundle --release
```

Output lands in `build/app/outputs/`.

For a Play Store release, add a signing config to `android/app/build.gradle.kts`
and a `android/key.properties`; the project currently builds release with the
default debug signing so it can be installed and tested immediately.

- Application id: `it.giocodel101.gioco_del_101`
- Label: **Gioco del 101**
- No permissions are declared beyond Flutter's defaults. The game asks for
  nothing: no internet, no storage, no location, no camera, no microphone.

---

## 4. Building for iOS

```bash
flutter build ios --release          # needs macOS + Xcode
open ios/Runner.xcworkspace          # then archive from Xcode
```

- Display name: **Gioco del 101**
- Portrait-only on iPhone (`Info.plist`), matching the `SystemChrome` call in
  `main.dart`. iPad keeps all four orientations.
- No capabilities or entitlements are required.

---

## 5. Where the game rules are configured

**One file: `lib/features/game/domain/game_rules.dart`.**

Nothing in the engine, the controllers or the widgets hardcodes a rule. Change a
value there and it takes effect everywhere.

| Field | Default | What it does |
|---|---|---|
| `startingHandSize` | `5` | Cards dealt to each player |
| `scoreValues` | Ace 1 … Re 10 | Penalty value of every rank |
| `eliminateAbove101` | `true` | Overshooting knocks a player out; when `false` the match ends on the first overshoot and the lowest score wins |
| `exact101ResetsToZero` | `true` | Landing on exactly the target wipes the score |
| `targetScore` | `101` | The number the game is named after |
| `stackDrawTwos` | `true` | 2s chain into +4 / +6 / +8 |
| `wildNineCanAlwaysPlay` | `true` | The Cavallo ignores the active suit |
| `allowVoluntaryDraw` | `true` | Drawing is allowed even with a playable card |
| `playDrawnCardImmediately` | `true` | A legal drawn card may be played at once |
| `mustDrawBeforePassing` | `true` | No unrestricted pass |
| `drawTwoPenalty` | `2` | Cards each 2 adds to the chain |
| `pendingPenaltyAppliesAfterWin` | `false` | Whether an unanswered chain still bites when the winning card ends the round |
| `nineBlockMode` | `cancel` | *Provisional* — how a Cavallo answers a pending +2: `disabled` / `cancel` / `passOn` |
| `nineBlockChangesSuit` | `true` | *Provisional* — whether a blocking Cavallo still names the suit |
| `restrictPlayToDrawnCard` | `false` | *Provisional* — after drawing, only the drawn card may be played |
| `starterCardPolicy` | `avoidActionCards` | *Provisional* — what may open the discard pile |
| `roundStarterPolicy` | `previousRoundWinner` | *Provisional* — who leads the next round |
| `turnTimeLimitSeconds` | `null` | Stamps `turnDeadlineAt`; expiry behaviour undefined |

The first three are the ones the brief flags as likely to change; they are
plain fields with no other copy anywhere in the codebase.

Players can also override most of these per match from the **Regole avanzate**
panel on the setup screen, which builds a `GameRules` in
`SetupController.buildRules()`.

---

## 6. Where the card assets are

**There are no card image files.** All forty faces and every card back are drawn
as vector art at paint time:

- `lib/core/widgets/cards/suit_art.dart` — the four suit emblems (coin, chalice,
  sword, cudgel), authored in a unit square and scaled to anything from a 14 px
  corner pip to a 90 px centrepiece.
- `lib/core/widgets/cards/figure_art.dart` — the three court figures, drawn full
  length in the Neapolitan woodcut manner: a page under a plumed cap (Fante),
  a rider on horseback (Cavallo), a crowned king (Re), each carrying the sign
  of its own suit. Each suit dresses its court in its own colours, so the
  twelve court cards stay tellable apart by cloth as well as by sign.
- `lib/core/widgets/cards/card_face_painter.dart` — stock, paper grain, bevel, double
  rule, corner indices, pip layouts.
- `lib/core/widgets/cards/card_back_painter.dart` — the four backs.
- `lib/core/widgets/cards/playing_card.dart` — the widget wrapper (thickness,
  shadow, tilt, flip).

This is deliberate. Vector art is crisp at every DPI, adds nothing to the bundle,
lets the deck respond to the theme and the high-contrast setting, and is
unambiguously original work — nothing is traced from a commercial deck.

Bundled assets are limited to:

- `assets/fonts/` — Cinzel and Manrope, both SIL Open Font License (the licences
  are bundled alongside them).
- `assets/audio/` — sixteen sound effects and one music loop, all synthesised
  from scratch (noise, damped sines, Karplus-Strong plucked strings). Original
  work; nothing sampled or licensed.

---

## 7. How local saves work

`SharedPreferences` with JSON, via `lib/core/storage/`. Keys live in
`storage_keys.dart`; there are five.

- **`gd101.match.v1`** — the resumable match. `GameState.toJson()` captures the
  deck order, both piles, every hand, scores, eliminations, the turn cursor, the
  active suit, the pending +2, the round number, the rule config and the recent
  action history. `GameController` writes it after every card played, card drawn
  and turn change, coalesced through a 350 ms timer so a +8 penalty writes once.
  It is written immediately when leaving the table or backgrounding the app, and
  deleted the moment a match finishes.
- **`gd101.settings.v1`**, **`gd101.statistics.v1`**, **`gd101.setup.v1`**,
  **`gd101.daily.v1`** — preferences, lifetime counters, remembered setup
  choices and daily-challenge state.

Every read is defensive. A corrupt or half-written value is discarded rather than
crashing the launch: `GameState.fromJson` throws `FormatException` on
structurally invalid data, and `GameStorageService.load()` catches it, clears the
key and returns null, so "Riprendi Partita" simply does not appear.

---

## 8. Adding a new table theme

1. Add a `TableTheme` const to `lib/app/theme/table_themes.dart` and put it in
   `TableThemes.all`. Set `unlockAchievementId` to `null` for an always-available
   theme, or to an achievement id to gate it.
2. Pick one of the three `TablePattern` motifs, or add a case to
   `BackdropPainter` and `_FeltPainter` for a new one.
3. Optionally add a matching `CardBackDesign` in `lib/app/theme/card_backs.dart` and
   point the theme's `cardBackId` at it.

Nothing else needs touching: the setup screen, the settings screen and every
painter read from `TableThemes.all`.

## 9. Adding a new bot personality

1. Add a value to `BotPersonality` in `lib/features/game/domain/player_type.dart`.
2. Give it weights in `BotWeights.forPersonality()`
   (`lib/features/game/domain/ai/bot_strategy.dart`). The knobs are `shedHigh`, `suitControl`,
   `action`, `holdCavallo`, `randomness` and `voidExploit`.
3. Add a `BotProfile` to `lib/features/game/domain/bot_roster.dart` with a name and a medallion.

Personalities only re-weight move selection and reaction frequency. They never
change what a bot is allowed to see — see below.

---

## 10. How online multiplayer could be added later

The engine is already independent of presentation and of time.

- `GameEngine` has no Flutter, no timers and no I/O. It is a pure state machine:
  you call `playCard` / `drawCard` / `chooseSuit`, and it emits `GameEvent`s.
- `PlayerType` already distinguishes `humanLocal` from `bot`. Adding
  `humanRemote` is a new enum value; the engine only ever asks whether a seat is
  driven locally.
- `GameState.toJson()` is already a complete, exact wire format — the same one
  used for local saves, and covered by a round-trip test.
- `GameController` is the only class that decides *when* a move happens. A
  networked build would replace its bot-driving loop with "wait for the remote
  seat's move", leaving the rules untouched.
- `BotViewFactory` is the single choke point that decides what a non-local seat
  is allowed to know, which is exactly the boundary a server would enforce.

No networking is implemented, and no placeholder online screens exist.

---

## 11. Design notes

- **Visual direction:** "Modern Napoli After Dark" — midnight navy, deep
  aubergine, warm ivory, antique gold, Mediterranean teal, terracotta coral.
  Deliberately not the primary-colour palette of the games this genre is
  associated with.
- **Signature moments**, in the order they earn the strongest effects:
  1. **101 Fate Ring** (`widgets/table/fate_ring.dart`) — the arc fills, a gold
     shockwave breaks it into shards, the shards spin back and the number turns
     to zero under **SALVO!**
  2. **Match victory** (`screens/match_result/victory_flourish.dart`).
  3. **Chain Storm** (`widgets/table/chain_storm.dart`) — the +2 chain around the
     stock, growing link by link with rising pitch and haptics.
  4. **Suit Ritual** (`widgets/table/suit_ritual.dart`) — the Cavallo's radial
     selector.
  5. **Ace skip** — a gold flash and a floating *TURNO SALTATO*.
- **Tavolo Vivo** (`widgets/table/table_surface.dart`) — the felt reacts to the
  active suit: a gold glimmer for Denari, a wine vignette for Coppe, a steel
  sweep for Spade, olive edge light for Bastoni, cross-fading over ~500 ms.
- **Performance:** the game paints no `MaskFilter.blur` anywhere. Soft light
  comes from radial gradients (`core/utils/glow.dart`), which costs a fraction
  as much and does not collapse on weak GPUs. The felt and the page backdrop are
  each split into a static layer that rasterises once and a small animated layer
  on top, so an idle table repaints almost nothing.
- **Accessibility:** every suit carries a distinct *shape* as well as a colour,
  so identification never depends on colour alone. Large-card mode, high
  contrast, Reduce Motion, and independent sound and haptic toggles are all in
  Settings, and `Motion` applies them globally.

## 12. Privacy

The game makes zero network calls. There is no analytics SDK, no advertising
SDK, no account system, no tracking, and no access to location, contacts, the
microphone or the camera. The only data stored is the local game state described
in section 7, on the device, in the app's own sandbox.
