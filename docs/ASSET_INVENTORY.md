# Asset Inventory

Audited 2026-08-29 (Session 1); card faces replaced 2026-08-31 at the client's
request — see `docs/CLIENT_CHANGE_2026_08_31.md`.

## Card faces — 40/40 traditional Carte Napoletane

The deck ships as **forty image files**, one per card:

```
assets/cards/<suit>_<rank>.webp        360 x 558 px, WebP q92
```

The name is `GameCard.id` exactly, derived through `CardAsset.imagePath` — the
one place a card's identity becomes a path. The identity never goes the other
way: nothing in persistence, on the wire, or in a widget key looks a card up by
filename.

| | |
|---|---|
| Files | **40** (verified: no missing card, no unexpected file) |
| Dimensions | **360 × 558** for all forty — ratio **1.55**, matching `CardMetrics.aspect` |
| Total size | **1282 KB** (~32 KB per card) |
| Format | WebP, quality 92 |
| Licence | **Public domain** — `assets/cards/LICENSE.txt` |

### Source and licence

Wikimedia Commons, [`Carte napoletane al completo.jpg`](https://commons.wikimedia.org/wiki/File:Carte_napoletane_al_completo.jpg)
— a 3507 × 2398 scan holding the whole deck in a 10 × 4 grid, released as
`{{PD-old}}`. Commons reports `License = pd`, `Copyrighted = False`,
`AttributionRequired = false`, `Restrictions = (none)`.

The artwork is the traditional Neapolitan pattern, an anonymous
nineteenth-century design long out of copyright; a faithful photographic
reproduction of a two-dimensional public-domain work attracts no new copyright
of its own. **No attribution requirement, no share-alike, free to use in this
commercial application.** Full record in `assets/cards/LICENSE.txt`.

Rejected alternative: `Carte_da_gioco_napoletane_{denari,coppe,spade,bastoni}.jpg`
on Commons is also a complete deck, but **GFDL / CC BY-SA** — copyleft, and a
poor fit for a commercial deliverable.

### How the forty files were made

Programmatically, from the one source image:

1. Each grid cell's printed artwork was isolated by connected-component
   analysis, keyed on **stroke bulk** — a component surviving a 7 × 7 erosion is
   artwork, a 2–4 px card-edge line is not. That drops neighbouring cards'
   edges and scanner speckle without touching the woodcut detail.
2. Each card's artwork was composited **at one common scale** onto a white card
   of identical size (400 × 620, ratio 1.55). Uniform scale matters: a coin on
   the Sette is the same size as a coin on the Due.
3. Resampled to 360 × 558 and encoded WebP q92 — chosen after comparing against
   the master and a 32-colour PNG at real display size (the PNG banded the Re's
   robe; lossless WebP cost 4.1 MB for no visible gain).

No artwork was redrawn, recoloured or restyled.

### Coverage — verified card by card

4 suits × 10 ranks = 40. Every file was rendered and inspected for correct
rank, correct suit, correct orientation, no duplicate and no bleed from a
neighbouring card.

| Suit | Asso | Due | Tre | Quattro | Cinque | Sei | Sette | Fante | Cavallo | Re |
|---|---|---|---|---|---|---|---|---|---|---|
| **Denari** | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| **Coppe** | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| **Bastoni** | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| **Spade** | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |

Enforced in code as well as by eye. `test/napoletane_deck_test.dart` is the
one that checks the artwork itself: every file is bundled and decodes, the
whole deck is one size at ratio 1.55, the licence ships with it, and — after
precaching — all forty cards draw their **printed face** rather than the
fallback painter. Run it with `RENDER_PREVIEWS=1` and it writes
`preview/napoletane_deck.png`, the deck exactly as the app draws it; that
image is the visual record of the 40/40 check above.

Alongside it: `test/deck_test.dart` asserts 40 cards with 40 distinct ids,
`test/engine/card_model_test.dart` pins the identity → path mapping, and
`test/deck_preview_test.dart` renders every face and every back.

> Note: `preview/deck_gallery.png` predates this change and still shows the
> engraved deck. `test/deck_preview_test.dart` and the `render_previews`
> tool capture a first frame, on which `Image.asset` has not decoded yet, so
> they legitimately show the fallback. Use `preview/napoletane_deck.png` for
> the printed deck.

### How they are drawn

`CardFaceImage` (`lib/core/widgets/cards/card_face_image.dart`) renders the
face inside the existing `PlayingCard` frame, so the printed edge, contact
shadow, corner radius, tilt, `dimmed` treatment and the gold "playable"
hairline (§28) are unchanged.

- `BoxFit.fill` — the assets are authored at exactly 1.55, so nothing stretches.
- **Decode is sized to the card's layout width, not the file's own
  resolution**, and rounded up to a 64-px step so a card animating through many
  intermediate widths shares one cache entry instead of decoding per frame.
  This is what keeps a long session from accumulating bitmaps.
- High contrast (§48) is a gentle contrast lift on the artwork, not a recolour.

### The engraved painters are kept as the fallback

`card_face_painter.dart`, `figure_art.dart` and `suit_art.dart` remain, and
`CardFaceImage` falls back to them if an asset is missing or has not decoded
yet — so a card is never a blank rectangle. They are no longer the primary
face. Card **backs** are still painted and were not part of this change.

### Client-supplied reference images — still reference only

`~/Downloads/game/` holds three images the client provided earlier
(`1000078229.jpg`, `1000078318.png`, `1000078330.png`), 146 × 251 and smaller.
Far too low-resolution to ship; untouched, still the client's originals, and
still the style reference the engraved court figures were drawn from.

### Card backs — 4

`lib/app/theme/card_backs.dart`: `oro`, `cobalto`, `brace`, `notturno`.
Painted by `lib/core/widgets/cards/card_back_painter.dart`, on the
`#17233F → #0B1327` gradient with antique gold (`CardBacks.oro`).

`oro` ships unlocked; the other three are tied to achievements.

## Fonts — present, bundled, licensed

`assets/fonts/` — 8 `.ttf` files, 740 KB total.

| Family | Weights | Used for |
|---|---|---|
| Cinzel | 400, 600, 700 | Titles, logo, buttons |
| Manrope | 400, 500, 600, 700, 800 | UI, body, all numerals |

Exactly the two families the brief names. Licences travel with them
(`OFL.txt`, `OFL-Cinzel.txt`, `OFL-Manrope.txt`); the two per-family files
are bundled and registered into the app at startup in `lib/main.dart`, so
they appear in the licence page too.

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
