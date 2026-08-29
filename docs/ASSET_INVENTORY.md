# Asset Inventory

Audited 2026-08-29, Session 1.

## The headline: there are no card image files

The 40-card Neapolitan deck is **vector art drawn at runtime by
`CustomPainter`**, not a folder of PNGs. This is deliberate and predates this
session: it keeps the APK small, renders crisply at every size the fan and the
table need, and lets a suit or a court figure be restyled in one place.

Because of that, several questions the brief asks — "are all 40 cards present",
"is the naming consistent" — resolve differently than they would for an image
deck. They are answered below in terms of the painters.

### Card faces — complete, 40/40

| Piece | Where | Notes |
|---|---|---|
| Card frame, stock, edge, corner radius | `lib/core/widgets/cards/playing_card.dart` | Ratio and radius come from `CardMetrics` / `AppRadii` |
| Pip layouts (Asso–7) | `lib/core/widgets/cards/card_face_painter.dart` | Numeric ranks |
| Court figures (Fante, Cavallo, Re) | `lib/core/widgets/cards/figure_art.dart` | Woodcut style, 879 lines |
| Suit emblems | `lib/core/widgets/cards/suit_art.dart` | Authored in a unit square, scaled |

Coverage is enforced by tests rather than by a file listing:
`test/deck_test.dart` asserts the deck holds exactly 40 cards with 40 distinct
ids, and `test/deck_preview_test.dart` paints every one of them.

- **Suits (4/4):** Denari, Coppe, Spade, Bastoni — `CardSuit`
- **Ranks (10/10):** Asso, 2, 3, 4, 5, 6, 7, Fante, Cavallo, Re — `CardRank`
- 4 × 10 = **40 cards, all renderable.**

### Card backs — 4

`lib/app/theme/card_backs.dart`: `oro`, `cobalto`, `brace`, `notturno`.
Painted by `lib/core/widgets/cards/card_back_painter.dart`, on the
`#17233F → #0B1327` gradient with antique gold (`CardBackInks`).

`oro` ships unlocked; the other three are tied to achievements.

## Fonts — present, bundled, licensed

`assets/fonts/` — 8 `.ttf` files, 740 KB total.

| Family | Weights | Used for |
|---|---|---|
| Cinzel | 400, 600, 700 | Titles, logo, buttons |
| Manrope | 400, 500, 600, 700, 800 | UI, body, all numerals |

Exactly the two families the brief names. Licences travel with them
(`OFL.txt`, `OFL-Cinzel.txt`, `OFL-Manrope.txt`) and are registered into the
app at startup in `lib/main.dart`, so they appear in the licence page too.

## Audio — 17 files, 1.6 MB

`assets/audio/` — 16 effects plus `music_loop.wav`.

`ace`, `card_drop`, `card_pickup`, `card_slide`, `chain_1..4`, `click`,
`eliminate`, `invalid`, `reset_101`, `score_tick`, `shuffle`, `suit_select`,
`victory`, `music_loop`.

These were synthesized rather than sourced. Wired through
`lib/core/services/audio_service.dart`.

## Icons — vector, no icon font

`lib/core/widgets/app_icons.dart` defines a 33-glyph set on a 24×24 grid,
drawn by `AppIconPainter`. Material icons are not used anywhere in the
interface. Adding a glyph means adding an `AppIcon` enum value and a case.

## Launcher icons — present for both platforms

- Android: `android/app/src/main/res/mipmap-*/ic_launcher.png` plus
  `ic_launcher_foreground.png` and an adaptive-icon XML in `mipmap-anydpi-v26`.
- iOS: the full `AppIcon.appiconset`, 1024 down to 20pt.

## Table backdrops — painted, not imaged

Three dressings in `lib/app/theme/table_themes.dart` (`napoli_notte`,
`maiolica`, `vesuvio`), each a set of colours and a `TablePattern` painted by
`lib/core/widgets/app_background.dart`. No background images exist or are
needed.

## Client-supplied reference images — style guide only, not assets

`~/Downloads/game/` holds three images the client provided earlier:
`1000078229.jpg`, `1000078318.png`, `1000078330.png`. All are small (59×97 and
146×251) Re illustrations in the traditional Neapolitan woodcut style.

They are **too low-resolution to ship** and were never imported. They were
used as a visual reference for `figure_art.dart`. They are untouched and
remain the client's originals.

## Naming consistency

Nothing needed renaming. Assets are addressed by id (`CardSuit.key`,
`CardRank.key`, card-back and theme ids), never by a filename pattern, so
there is no naming scheme to drift. Storage keys are centralised in
`lib/core/storage/storage_keys.dart`.

## Not present

- No card image files (by design, see above)
- No video, no Lottie, no Rive
- No remote/CDN assets — the app loads nothing over the network
