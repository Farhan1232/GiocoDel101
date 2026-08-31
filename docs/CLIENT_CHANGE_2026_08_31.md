# Client change request — 2026-08-31

A scoped change to the finished game. Sessions 1–6 shipped; this touched only
what the client asked for. The five requests, what was actually built, how each
is proven, and what still needs an answer.

---

## The five requests

| # | Client's words | Status |
|---|---|---|
| 1 | "The player who starts by playing the first card … should be the player who finished/closed the previous round." | **Done** — was already the active preset; now confirmed, tested and documented |
| 2 | "Drawing the required two cards must NOT automatically end their turn … that SAME player must still be allowed to play ONE legal card." | **Done** — engine, server, bots, UI |
| 3 | "After playing for a while the game starts to slow down." | **Investigated and guarded** — see [Performance](#3--performance) |
| 4 | "Replace the current playing-card artwork with traditional Italian Neapolitan cards." | **Done** — 40/40, public domain |
| 5 | "The player who deals the cards should rotate clockwise." | **Done** — `dealerSeat`, plus the table's deal order and a dealer badge |

Nothing else was changed. No AdMob, no IAP, no store work, no new social
features, no new auth, no new progression, no new backend architecture, no new
dependencies, and **no Supabase migration** (see [Security](#security-rls-and-the-database)).

---

## 1 — The previous round's closer leads the next round

**GAME_SPEC §12.**

This was already the behaviour. `GameRules.roundStarterPolicy` has defaulted to
`previousRoundWinner` since Session 2, and `GameEngine._startNextRound` reads it
through the one centralised switch. Because a round can only end by a player
emptying their hand, the round *winner* and the round *closer* are the same
seat — so the client's rule was already the one in force.

What changed is that it is now **confirmed rather than provisional**, proven for
every table size, and explicitly proven *not* to be the clockwise successor:

- `test/client_change_2026_08_31_test.dart` — for 2, 3 and 4 players, every seat
  in turn closes a round and must lead the next one; for 3 and 4 players it also
  asserts the leader is **not** `(closer + 1)`, which is the distinction the
  client was asking for. Plus: the preset itself is asserted on the default
  `GameRules`, so a future change to the default breaks a test rather than a
  match; and an eliminated closer hands the lead to the next live seat.
- Conformance fixture `next_round_closer_leads_dealer_rotates` proves it in the
  compiled server engine too.

Every mode reaches the same code: offline, pass & play, bots, online,
rematch/next-round all deal through `GameEngine._startNextRound`. Nothing
duplicates the rule.

**No production code was changed for this request.** That is the honest answer,
and it is worth stating plainly rather than inventing a diff.

---

## 2 — After paying a chain, the same player plays on

**GAME_SPEC §6b.** The substantial change.

### Before

`GameEngine._draw`, penalty branch: take the pending total, clear the chain,
`_advanceTurn(next, 1, events)`. The victim's turn ended with the draw.

### After

Take the pending total, clear the chain, and **return without advancing**:

```dart
final next = afterDraw.copyWith(
  pendingDrawCount: 0,
  chainLength: 0,
  hasDrawnThisTurn: true,          // bars a second draw; permits a pass
  penaltyResolvedThisTurn: true,   // the continuation is live
  clearDrawnCard: true,
  status: GameStatus.awaitingAction,
);
```

The same seat is still to act and may play **one ordinary legal card**. This
holds for whatever the chain was worth — +2, +4, +6, +8. Nothing is hard-coded
to two cards; the code reads `state.pendingDrawCount`, exactly as it did before.

### Legality is the engine's, not the widget's

The continuation is not a special mode. `getPlayableCards`, `canPlay` and
`validateAction` answer exactly as they would on any other turn, so:

- an illegal card is still refused — `GameFailure.illegalCard`;
- a second draw is refused — `hasDrawnThisTurn` is set, so
  `GameFailure.drawNotAllowed`;
- with nothing legal, the player **passes** out of the turn. `PassAction` is
  permitted because `mustDrawBeforePassing` is satisfied by the penalty draw.
  A paid chain can therefore never stall the table, even when the stock ran
  dry and the chain could only be partly paid.

One subtlety worth naming. `restrictPlayToDrawnCard` (a non-default, still
provisional rule) confines a turn to the card just drawn. That is a consequence
of *choosing* to draw; penalty cards are taken under duress, so it must not
apply to the continuation. Rather than scatter that condition, `GameState`
gained one derived getter used by all three call sites:

```dart
bool get restrictsPlayToDrawnCard =>
    rules.restrictPlayToDrawnCard && hasDrawnThisTurn && !penaltyResolvedThisTurn;
```

### The Cavallo block is untouched

`nineBlockMode` was not rewritten. Blocking a chain with a Cavallo settles it
and passes the turn on exactly as before. **Only a seat that actually paid gets
the continuation** — a distinction the client drew explicitly, and one that has
its own test.

### Events and accounting

No new event type was added, because one already carried the meaning. A paid
chain emits `CardsDrawnEvent(isPenalty: true)` and `ChainResolvedEvent` — and,
now, **no `TurnChangedEvent`**. The absence of the turn change is precisely what
distinguishes "penalty resolved" from "turn completed", for any listener, on
both the client and the server.

Nothing is double-counted:

| Counter | Behaviour |
|---|---|
| `turnNumber` | moves **once** for the draw plus the continuation — a paid chain is one turn, not two |
| `drawsByPlayer` | the penalty cards, counted once, as before |
| `stats.twosPlayed` | credited to whoever *played* the 2; the victim's draw adds nothing |
| `stats.cardsPlayed` | +1 for the continuation, like any other play |
| missions / achievements | fed from the same events; unchanged |

`test/client_change_2026_08_31_test.dart` asserts each of these directly.

### The turn clock (client §10)

Resolving a chain keeps the seat but opens a **new action window**.
`GameEngine._stampClock` treats `penaltyResolvedThisTurn` going true as a clock
event and re-stamps `turnStartedAt` / `turnDeadlineAt`.

Without that, a player attacked with one second left on their turn would have
"kept the turn" in name only. The test pins the exact numbers: a 30 s timer, a
draw at t+29 s, and a fresh deadline at t+59 s.

The global timeout and forfeit policy is **otherwise unchanged**. A seat that
has genuinely stopped responding does not get a free extra window: the server's
`planTimeout` draws the penalty and, seeing the turn is still that seat's,
appends a pass in the same committed batch. That fell out of the existing
"still our turn? then pass" logic rather than needing new code — but it is now
pinned by a test, because it is the difference between a rule change and a way
to hold a table open.

### Server-authoritative, not client-only

The rule lives in the Dart engine compiled to
`supabase/functions/match/engine.js` (rebuilt via `tool/build_engine_js.sh`).
The server gained **no rule logic of its own**: after a `draw` it is the engine
that reports the same seat as current, the same private hand, the cleared
penalty, the new version and the new deadline, and the Edge Function publishes
what it is given.

VM = JS determinism is proven by five new shared conformance fixtures, replayed
on the Dart VM by `test/engine/conformance_fixture_test.dart` and on the
compiled JavaScript by `supabase/functions/match/engine_conformance_test.ts`:

`penalty_draw_keeps_the_turn`, `penalty_continuation_plays_a_legal_card`,
`penalty_continuation_rejects_an_illegal_card`,
`penalty_continuation_cannot_draw_again`,
`penalty_continuation_may_pass_with_nothing_legal`.

### Bots

A bot that pays a chain and then hands the turn away would defeat the point.
`GameController._takeBotTurn` now asks the bot to decide **again** when
`penaltyResolvedThisTurn` is set, through the same
`BotViewFactory.forCurrentPlayer` view every other decision uses — so the bot's
continuation is chosen by the engine's own legality, never by a rule written
into the driver. Both paths that can reach a penalty draw (`BotAction.draw` and
a bot that tried to end its turn while a chain was pending) were covered.

The loop's anti-stall guard changed with it. "Did the bot actually move?" was
`round.turnNumber == before`; since a bot can now legitimately move without the
turn number changing, that guard would have fired every time and forced the pass
the client asked us to stop doing. It is now `round.version == before`, which
asks the question that was always meant.

`tool/bot_simulation.dart`: **270 matches, 0 violations, 0 hangs, 0 illegal
proposals**, 95,849 actions, 4,219 penalty draws across easy/normal/hard × 2/3/4
players.

---

## 5 — The deal rotates clockwise

**GAME_SPEC §12a.**

`GameState.dealerSeat` is new. Seat 0 deals round 1; every deal moves it one
**live** seat clockwise, wrapping at the end of the table and passing over
eliminated seats (it reuses `_seatAfter`, so it follows `direction` and the
elimination rules already in force).

It is deliberately **independent of who leads**:

```
Round 1:  dealer A     closer C
Round 2:  dealer B     first to act C
Round 3:  dealer C     first to act = whoever closed round 2
```

Carried everywhere the canonical state goes: `GameState` field, `toJson` /
`fromJson`, the offline save file, the online public snapshot, and the
conformance fixtures. **Legacy saves keep loading**: a missing `dealerSeat`
reads back as seat 0 — which is what dealt round 1 of every match — and an
out-of-range value is treated the same way rather than throwing, because a
corrupt dealer must never cost somebody their saved match.

### At the table

- The deal is animated starting from the seat to the **dealer's left**, running
  round the table and finishing at the dealer — the order a dealer actually
  deals in. As `dealerSeat` moves, the deal visibly travels with it. This is
  presentation only: which cards a seat receives is fixed by the engine and does
  not depend on the animation order.
- The dealing seat carries a small `MAZZIERE` / `DEALER` badge, styled to match
  the existing card-count chip and placed opposite it so the two never collide.
  It is quieter than the count chip on purpose — the dealer is a fact about the
  round, not something to act on.
- Works for 2, 3 and 4 players; the premium Italian theme is untouched. The
  table was not redesigned.

The client's phrase was "the hand that deals the cards should rotate clockwise".
There is no dealer-hand animation in the app — cards fly from the stock, which
is where the deck physically is — so the rotation is expressed as the deal order
plus the badge. If an actual dealing hand is wanted, that is a new asset and a
new animation; say the word.

---

## 3 — Performance

Treated as a bug and **measured, not guessed**.

### What was found

The controllers are, on inspection, disciplined already:

| Suspected cause | Finding |
|---|---|
| Realtime subscriptions not disposed / duplicate channels | `OnlineMatchController` guards every callback with a `_subscriptionGeneration` and closes the old channel on resubscribe. Clean. |
| Polling after a finished match | `_poll`, `_heartbeat`, `_clockTimer`, `_reconnect`, `_bannerTimer` and every per-seat reaction timer are cancelled in `onClose`. |
| Timers recreated every turn | None are. They are armed once in `onInit`. |
| Duplicate GetX listeners | `session.listen` returns its own unsubscribe, called in `onClose`; the one `ever()` worker is disposed with the screen. |
| Audio players accumulating | A fixed pool of 5, allocated once in `AudioService.init`. Nothing per-effect. |
| Delayed futures accumulating | Cue playback is capped: `_present` times out after 3 s, so a stalled view can never wedge the queue. |
| Unbounded collections | `history` is capped at `GameState.historyLimit` (40); `playedCards`, `drawsByPlayer` and `voidSuits` reset on every deal. |
| Large card images decoded repeatedly | **This was a real risk introduced by request 4** — and is the main thing addressed below. |

### What was changed

The one change made for performance is in how the new card artwork is decoded,
because shipping 40 photographic faces naively is exactly the kind of thing that
makes a table get heavier the longer it is open.

`CardFaceImage` asks for a decode sized to the card's **layout width**, not the
asset's own resolution, and rounds that request up to a 64-px step. The step is
the important part: a card animating through dozens of intermediate widths would
otherwise decode a new bitmap per frame and thrash the image cache. With the
step, every card of a given rank and suit shares one cache entry, and the whole
deck settles at a bounded size instead of climbing.

Related, and deliberate: the assets are 360 × 558 WebP (~32 KB each, 1.3 MB for
the deck) rather than PNG. A 32-colour PNG was measurably worse at the same size
— visible banding on the Re's robe — and lossless WebP was 4.1 MB for no visible
gain.

### The regression guard

`test/long_session_performance_test.dart` is the repeatable long-session check
the request asked for. It drives the **real table widget** through many
consecutive rounds with every seat played by a bot, and after each round records:

- **`transientCallbackCount`** — registered animation frame callbacks, one per
  running `Ticker`. This is the clearest signature of a leaked
  `AnimationController`, and the test asserts it does not climb with the rounds
  and never exceeds a ceiling.
- **mounted element count** — a tree that never sheds what it builds grows every
  round; a healthy one oscillates.
- **image cache live count** — must stay at deck scale, which is what proves the
  decode-step above is doing its job.
- **`history` and `playedCards` lengths** — read off the authoritative state, so
  this also guards the save file and every server write.
- **wall clock per round** — compared as a coarse early-vs-late ratio, wide
  enough not to flake on a loaded machine but tight enough to catch an O(n²).

A second case tears the screen down mid-flight and asserts
`transientCallbackCount` returns to **zero** — that no card animation outlives
the screen that started it. A third runs thousands of engine actions with no
widgets at all and asserts the serialised state does not grow with the number of
rounds played.

Running it with `Motion.reduceMotion` on is deliberate: with animations
collapsed, anything still ticking after a round is something that should have
been disposed, so leaks get *louder*, not quieter.

### Limitations, stated plainly

This harness measures counts inside the Dart VM. It **cannot** see native heap
growth, GPU memory, or platform-channel objects — real audio players, real
Realtime websockets. Those were reviewed by reading the code (the table above)
rather than measured, because `flutter test` has no access to them. A profile
run on a physical device with DevTools is the honest way to close that gap, and
has not been done: there is no device attached to this environment.

**The client's report has not been reproduced first-hand.** No slowdown was
observed in these runs. What is delivered is: a set of measurements that would
catch the classes of accumulation described, a real fix for the one genuine risk
the new artwork introduced, and an accurate account of what remains unverified.
If the slowdown is still seen after this build, the most useful next step is a
DevTools timeline from the device it happens on.

### Transitions

Existing transitions were left alone; no animation package was added and no
animation quality was reduced globally. `Motion.reduceMotion` (Reduce Motion)
continues to be respected everywhere, including by the new card faces, which
carry no animation of their own.

---

## 4 — The cards

**Replaced.** 40/40 authentic traditional Carte Napoletane.

### Source and licence

| | |
|---|---|
| File | `Carte napoletane al completo.jpg`, Wikimedia Commons |
| URL | https://commons.wikimedia.org/wiki/File:Carte_napoletane_al_completo.jpg |
| Original | 3507 × 2398 JPEG, a 10 × 4 grid of all forty cards |
| Licence | **Public domain** (`{{PD-old}}`) |
| Commons metadata | `License = pd`, `Copyrighted = False`, `AttributionRequired = false`, `Restrictions = (none)` |

The artwork is the traditional Neapolitan pattern — an anonymous
nineteenth-century design, long out of copyright. A faithful photographic
reproduction of a two-dimensional public-domain work attracts no new copyright
of its own, so the scan carries no separate rights. **No attribution
requirement, no share-alike, usable in a commercial application.** The full
record travels with the assets in `assets/cards/LICENSE.txt`.

This was preferred over the other complete Neapolitan deck on Commons
(`Carte_da_gioco_napoletane_*.jpg`, one image per suit), which is **GFDL /
CC BY-SA** — copyleft, and a poor fit for a commercial client deliverable.

Nothing was taken from Google Images. The client's own reference images in
`~/Downloads/game/` (three files, largest 146 × 251) were checked first and are
far too small to ship; they remain untouched and are still credited as the style
reference for the engraved deck.

### What was done to it

Each card was extracted programmatically, not by hand-cropping:

1. The printed artwork of each grid cell was isolated by connected-component
   analysis, keyed on **stroke bulk** — a component that survives a 7 × 7 erosion
   is artwork; a 2–4 px card-edge line is not. That is what removes neighbouring
   cards' edges and scanner speckle without touching the woodcut detail.
2. Every card's artwork was composited, **at one common scale**, onto a white
   card of identical size (400 × 620 px, ratio 1.55, matching
   `CardMetrics.aspect`). Uniform scale matters: a coin on the Sette is the same
   size as a coin on the Due.
3. Resampled to 360 × 558 and encoded as WebP quality 92 — chosen after
   comparing against the master and a 32-colour PNG at real display size.

No artwork was redrawn, recoloured or restyled. These are the traditional
faces, not a UNO-style reinterpretation.

### Integration

- Named by `GameCard.id` — `assets/cards/<suit>_<rank>.webp` — through
  `CardAsset.imagePath`, which the codebase already had as the single
  identity → path mapping. **The card model, ids, rules and persistence format
  did not change at all.**
- `CardFaceImage` renders the face inside the existing `PlayingCard` frame, so
  the printed edge, contact shadow, corner radius, tilt, `dimmed` treatment and
  the gold "playable" hairline (§28) are all exactly as they were.
- Aspect is preserved: assets are authored at 1.55, drawn with `BoxFit.fill`, so
  nothing stretches at any size.
- **The engraved `CardFacePainter` was kept as a fallback.** If an asset is ever
  missing or has not decoded yet, the painter draws instead, so a card is never a
  blank rectangle. This is also why no existing painter test needed weakening.
- No 52-card package was added. `playing_cards`, `playing_cards_ui` and friends
  are still absent; the custom 40-card model stands.

### Verified

All 40 rendered and inspected: 4 suits × 10 ranks, correct rank, correct suit,
correct orientation, no duplicate, no missing card, no bleed from a neighbour.
`docs/ASSET_INVENTORY.md` carries the per-card table.

---

## Security, RLS and the database

**No migration. No policy change. No relaxation of anything.**

Both new state fields are public information, and
`app_private.redact_game_state` is a blacklist
(`state - 'seed' - 'drawPile' - 'drawnCard' - 'history'`), so `dealerSeat` and
`penaltyResolvedThisTurn` reach the public snapshot with no schema work.
`match_private_state` is untouched; private hands, `app_private` restrictions,
service-role-only APIs, RLS, idempotency receipts, state versions, reconnect and
the anti-farming rules are all exactly as Session 6 left them.

The Supabase project is the existing **GiocoDel101-Dev**
(`fnyllrjchbqfrzezfeso`). No project was created, no remote database was reset,
no unrelated project was touched.

The `match` Edge Function **was redeployed** (v5 → **v6**) so the online matrix
could exercise the new rule against the real backend — the rules live in
`engine.js`, so without it the server would still have been answering by the
old rule. That is the only change made to the deployment; rolling it back is a
redeploy from the previous commit.

---

## Verification — what actually ran

| Gate | Result |
|---|---|
| `dart format --output=none --set-exit-if-changed .` | clean |
| `flutter analyze` | **No issues found** |
| `flutter test` | **571 passed**, 0 failed (baseline before this change: 515) |
| `deno test supabase/functions/match/` | **58 passed**, 0 failed (baseline: 50) |
| `deno check supabase/functions/match/index.ts` | clean |
| Conformance fixtures | **51**, each replayed on the Dart VM *and* the compiled JavaScript (baseline: 43) |
| `dart run tool/bot_simulation.dart` | **270 matches, 0 violations, 0 hangs, 0 illegal proposals** — 95,849 actions, 4,219 penalty draws, easy/normal/hard × 2/3/4 players |
| `flutter build apk --debug` | `build/app/outputs/flutter-apk/app-debug.apk` |
| `flutter build apk --release` | `build/app/outputs/flutter-apk/app-release.apk` (61.4 MB) |
| Card deck | 40/40 files, all 360 × 558, ratio 1.55, 1282 KB; rendered and inspected in-app (`preview/napoletane_deck.png`) |
| `tool/online_rule_check.dart` (2/3/4 players) | **61 passed, 0 failed** against the deployed function |

New tests written for this change:

- `test/client_change_2026_08_31_test.dart` — 30 cases across the three rules:
  round starter for 2/3/4 players and "not the clockwise successor"; dealer
  rotation, wraparound, elimination skip, independence from the leader,
  serialisation and legacy-save loading; the penalty continuation at +2/+4/+6/+8,
  illegal-card refusal, no second draw, pass-when-nothing-legal, the Cavallo
  block staying as it was, the fresh deadline, and the no-double-counting audit;
  and a bot check that the continuation is offered and legal for every
  difficulty.
- `test/napoletane_deck_test.dart` — the deck ships, decodes, is one uniform
  size at 1.55, carries its licence, and all forty cards draw their printed
  face rather than the fallback.
- `test/long_session_performance_test.dart` — the long-session guard described
  above.
- Plus the new cases in `test/gameplay_widget_test.dart` (penalty continuation
  and the dealer badge through the real table) and the eight new conformance
  fixtures.

### Online, against the real backend — **61 checks, 0 failures**

The `match` Edge Function was redeployed to `GiocoDel101-Dev` (v5 → **v6**), so
the server is answering by the new engine, and the rules were then proven
against **its own authoritative state** with independent authenticated users:

| Table | Result |
|---|---|
| 2 players | **20 passed, 0 failed** |
| 3 players | **20 passed, 0 failed** |
| 4 players | **21 passed, 0 failed** |

What each run proves, live:

- **§6b** — a chain is paid and the server *still* reports the same seat as
  current, with `penaltyResolvedThisTurn` set and `pendingDrawCount` back to 0;
  the right number of cards actually moved; an off-suit card is **still
  refused** (`illegalCard`); the legal continuation is accepted; and only then
  does the turn move on. Observed at **+2 and at a stacked +4** (4 players:
  "+4 paid: the server still has p1 to act … 4 cards were actually taken"),
  and in the branch where the seat has nothing legal and **passes** instead —
  the case that proves a paid chain cannot stall a live table.
- **§12** — "the seat that closed round N leads round N+1", checked at each
  round change (e.g. `closer p1, leader p1`).
- **§12a** — the deal moved (`dealer 0 -> 1`, `1 -> 2`, `1 -> 0`) and is
  reported alongside the leader each time, so the two being independent is
  visible in the output rather than asserted in the abstract.

Two harnesses were used, deliberately:

- **`tool/online_rule_check.dart`** (new) — the focused driver that produced
  the results above. It rebuilds each client's view from the Edge Function's
  own reply (`publicState` + `hand`), exactly as the Flutter client does
  optimistically, so it costs **one HTTP request per action** instead of the
  four or more a full snapshot fan-out needs.
- **`tool/online_matrix.dart`** — the full regression sweep, which also gained
  §6b / §12 / §12a assertions inside its drive loop. Its setup, private-room,
  private-hand-security, RLS, concurrency, idempotency and receipt areas all
  pass (37–39 checks depending on how far it got), but **it did not complete a
  full match run in this environment**: four attempts each died partway through
  the game drive with a transport error (`Connection reset by peer`,
  `Network is unreachable`, `Broken pipe`) on `rest/v1/rpc/match_snapshot`.
  That is this sandbox's link, not the backend or the code — the focused
  driver, making a quarter of the requests, ran the same rules to completion
  three times. Re-run the full matrix from a normal network before shipping.

### Not verified

- **No physical or emulated Android device was used.** The APKs build; they
  were not installed or run. No claim is made about on-device behaviour.
- **`tool/online_matrix.dart` did not finish a full match** in this
  environment (transport errors, four attempts — see above). Everything it did
  reach passed. The headless-Chrome UI driver (`tool/ui_drive_web.ts`) was not
  run either: it needs a web build served locally plus `UI_HOST_PASSWORD`.
- **The reported slowdown was not reproduced**, so it cannot be claimed fixed —
  only that the classes of accumulation it would come from are now measured and
  guarded, and that the one real risk the new artwork introduced was addressed.
  See [Performance](#3--performance).
- Native heap, GPU memory and platform-channel objects (real audio players,
  real Realtime sockets) are outside what `flutter test` can measure; they were
  reviewed by reading the code, not profiled.

---

## Still needs the client

1. **Who deals round 1?** The deal rotates clockwise as asked, but the client
   did not say where it starts. Seat 0 (the opening seat, the host online) deals
   the first round. If the intent was the traditional "dealer deals, the player
   to their left leads", that is one line in `GameEngine.createGame`.
2. **Corner indices on the cards.** A traditional Neapolitan deck has none, and
   these authentic faces have none. The engraved deck the app shipped with *did*
   have small rank indices. Authenticity was chosen, since that is what was
   asked for — but a 6 and a 7 of Denari are told apart by counting pips. If a
   discreet index is preferred for readability, it can be overlaid without
   touching the artwork. **Please confirm.**
3. **A dealing-hand animation.** "The hand that deals the cards" is expressed as
   deal order plus a dealer badge, because no hand graphic exists in the app.
   Confirm whether an actual animated hand is wanted.
4. Everything already open in GAME_SPEC §14 is still open — chiefly §6a
   (`nineBlockMode`), which this change deliberately did not touch.
