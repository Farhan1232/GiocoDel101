# Client final change — 2026-08-31

The last three requests on top of `docs/CLIENT_CHANGE_2026_08_31.md`. All
three are delivered; nothing outside them was changed.

| # | The client asked for | Status |
|---|---|---|
| 1 | *"The 9 and the Jack should have a value of 25 points when they are in the hand."* | **Done** — Fante 25, Cavallo 25, penalty only |
| 2 | *"Add a button so a player must declare ULTIMA CARTA when they reach their last card."* | **Done** — a real engine rule, enforced by the server online |
| 3 | *"When a player has around ten cards, or draws many cards, not all cards are visible."* | **Done** — the hand is usable at 5, 10, 15, 20 and 25+ cards |

Everything else this game already did — the 2/3/4-player online multiplayer,
private rooms, quick match, reconnect, private hands, RLS, offline bots,
Pass & Play, the tutorial, achievements and missions, the Napoletane
artwork, the previous-round closer, the post-+2 continuation, the clockwise
dealer rotation — is untouched and re-verified.

---

## 1. Fante and Cavallo are worth 25

### What changed

One table, in one place:

```dart
// lib/features/game/domain/game_rules.dart
static const Map<CardRank, int> defaultScoreValues = {
  CardRank.asso: 1,   CardRank.due: 2,     CardRank.tre: 3,
  CardRank.quattro: 4, CardRank.cinque: 5, CardRank.sei: 6,
  CardRank.sette: 7,
  CardRank.fante: figureScoreValue,    // 25
  CardRank.cavallo: figureScoreValue,  // 25
  CardRank.re: 10,
};
```

`ScorePolicy.handPenalty` already summed `GameRules.valueOf(rank)` for every
card left in a hand, and it is the only thing in the codebase that prices a
card. No widget, controller, bot or server path has its own copy, so this is
the whole change to the scoring rule.

### Naming

In this deck the client's **"9" is the Cavallo** and the **"Jack" is the
Fante** — a Neapolitan deck has no pip 9 and no Jack. Both are figures.
`docs/GAME_SPEC.md` §1 has carried that mapping since Session 2.

### What did *not* change

`CardRank.cavallo.value` is still **9** and `CardRank.fante.value` is still
**8**: those are the *ranks*, and the matching rules read them. The 25 is a
**penalty**, applied only when a round ends with the card still in a hand.
Confirmed unchanged by test and by the live server:

- the Cavallo still ignores the active suit and may always be played (§4.3);
- the Cavallo still names the new active suit (§7);
- the Cavallo still blocks a pending +2 (§6a, `nineBlockMode`);
- the Fante is still an ordinary card matched by suit or rank (§4);
- turn order, legality, the +2 chain and online validation are all identical.

### Old saves

`GameState.schemaVersion` went 2 → **3**. A save written under schema ≤ 2
carries a `scoreValues` table that still says Fante 8 / Cavallo 9; resuming it
untouched would score at the old rate. `GameState._migrateRules` drops that
table when — and only when — it matches the *old printed defaults exactly*,
so the new values take over and a table the client customised is left alone.
Legacy saves still load.

### Worked example

A hand of Fante + Cavallo + Re at the end of a round is 25 + 25 + 10 = **60**.
Several figures accumulate normally (4 figures + a Re = 110). Under §11 that
makes a figure genuinely dangerous to be caught with, which is the point.

### Tests

`test/scoring_test.dart` and `test/engine/score_policy_test.dart`:

- a Fante in hand contributes 25; a Cavallo in hand contributes 25;
- Fante + Cavallo = 50;
- several of each accumulate (4 × 25 + 10 = 110);
- every other rank keeps its printed value (checked rank by rank);
- round scoring uses the new values (a real round scored through the engine);
- the 101 rules still behave — exact 101 resets, over 101 eliminates;
- a client-supplied value table still overrides the defaults.

Offline and online agree by construction: the server runs this same engine
compiled to JavaScript. VM/JS agreement is re-proven by all 59 conformance
fixtures, whose embedded rules now carry `fante: 25, cavallo: 25`, replayed on
the Dart VM (`test/engine/conformance_fixture_test.dart`) and on the compiled
JavaScript (`supabase/functions/match/engine_conformance_test.ts`). The live
server's own reply shows
`scoreValues: {…, fante: 25, cavallo: 25, re: 10}`.

### Tutorial

Lesson 8 ("Centouno") taught the signature rule with *92 + Cavallo(9) = 101*.
With the Cavallo now worth 25 the arithmetic is **76 + 25 = 101**; the lesson
and both localisations were updated. It now demonstrates the new value.

---

## 2. "ULTIMA CARTA"

### The rule (GAME_SPEC §16)

A play that would leave a player holding **exactly one card** — a play made
from a hand of **two** — is legal only if that player has already declared
ULTIMA CARTA for the turn in progress. Without it the engine refuses with
`GameFailure.lastCardDeclarationRequired`: **no card leaves the hand, nothing
is drawn, the turn does not move, the version does not change.** Declare, then
send the same play again and it is accepted.

**No penalty was invented.** The client did not ask for one. An undeclared
play is simply held back.

### Two to one, not one to zero

The announcement is about *becoming* a one-card player. Playing the final card
(1 → 0) wins the round and asks for no second announcement.

### Drawing never needs it

A player holding two cards may draw freely. Only an action that would leave
exactly one card is gated. And because a draw puts cards back in the hand, it
**clears** any declaration that was standing.

### When the button is offered

`GameEngine.canDeclareLastCard` is the single predicate the button, the bots
and the validator all read, so the button can never offer a declaration the
engine would refuse:

- the rule is on (`GameRules.requireLastCardDeclaration`, default true);
- the match is live and the round is not over;
- it is this seat's turn and no Cavallo is waiting for its suit;
- the seat holds **exactly two** cards;
- **at least one of them is legally playable**, so a play really could take
  the hand to one;
- the seat has not already declared this turn.

Declaring at five or ten cards, out of turn, for another player, with nothing
legal to play, or twice in a turn is refused
(`lastCardDeclarationNotAllowed`, or `notPlayersTurn` / `invalidPlayer` /
`roundOver` / `gameFinished` / `suitSelectionRequired`, whichever applies).

### The engine state

`GameState.lastCardDeclaredBy` — a seat id, or null. It is scoped to one turn
and cleared by:

| Event | Why |
|---|---|
| the turn moving on (`_advanceTurn`) | a declaration never travels to the next seat |
| a new deal | new hands |
| an ordinary draw | the hand grew; the seat is no longer about to reach its last card |
| a penalty draw (+2/+4/+6…) | same, under duress |
| the declarer forfeiting | the seat is gone |

### It is a rule, not a button

`DeclareLastCardAction` is a first-class engine action, so **the same code
enforces it offline and online**:

- **offline** — the local `GameEngine`;
- **online** — the *server*, running this very engine compiled to JavaScript
  (`supabase/functions/match/engine.js`). The Edge Function builds the action
  with the **caller's own seat** (the client's `playerId` is ignored, exactly
  as for `playCard`) and the engine re-decides hand size, turn ownership and
  whether the declaration stands.

A modified Flutter client can neither skip the announcement nor make one for
somebody else. Both are proven against a fake server in
`test/session4_online_test.dart` and against the live server below.

### What other players see

`lastCardDeclaredBy` is a seat id and nothing else. It survives redaction
(`app_private.redact_game_state` is a blacklist), so every seat can show
*"Stefano: ULTIMA CARTA!"* while hands stay private. **No card identity is
published by any part of this feature**, and no migration, private column,
policy or RLS rule was touched.

### Bots, Pass & Play, tutorial — one implementation

Automated seats go through `GameSession.autoPlayCard`, which asks the engine
whether the announcement is due and, if so, sends the very same
`DeclareLastCardAction` before the play. Bots do not bypass the engine and do
not get a private rule. Pass & Play is the person path for every seat.

### The UI

- A premium gold `ULTIMA CARTA` button leads the action row, in the existing
  gold/navy design. Italian primary; English **LAST CARD**.
- It is **hidden**, not disabled, unless the declaration is currently
  relevant — the row is empty of alternatives anyway, since a seat holding two
  playable cards can neither draw nor pass.
- On tap: a short scale-in, medium haptic, and it becomes a settled gold
  badge with a check and *"ULTIMA CARTA!"* for the rest of the turn.
- Every seat sees a banner *"{name}: ULTIMA CARTA!"* when anyone declares.
- Sound, vibration and Reduce Motion settings are respected
  (`Motion.scale`, `AudioService`, `HapticService`); no animation package was
  added.
- If the player taps a card first, the play is refused before the engine is
  touched and the table says *"Dichiara ULTIMA CARTA prima di giocare."* The
  card stays selected, so pressing the button and tapping once more plays it.
- The table itself was **not** redesigned.

### Save and resume

`lastCardDeclaredBy` is serialised with the rest of the state, so a pending
declaration survives a save. A save written before §16 restores with nobody
declared — always a playable position, because the seat to act can still press
the button. No restore can leave a player stuck.

### Tests

`test/ultima_carta_test.dart` (28 cases) plus fixtures and UI:

- 2 cards + no declaration + play → **rejected**, nothing changed;
- 2 cards + declaration + legal play → **accepted**, hand becomes exactly 1;
- an illegal card is still reported as `illegalCard`, not as a missing
  declaration;
- the declaration belongs to one player only; the wrong player cannot declare;
- cannot declare out of turn, with >2 cards, with nothing legal to play, while
  a suit is pending, after the round is over, or twice;
- the resets: turn change, new deal, ordinary draw, penalty draw, forfeit;
- drawing instead of playing does not trigger the requirement;
- the declaration survives a JSON round trip; a pre-§16 save loads and is not
  stuck; the rules flag defaults on for old saves;
- `GameSession.autoPlayCard` announces then plays (two real actions in the
  history), and a plain `playCard` is still refused;
- a full bot-vs-bot match per difficulty reaches a last card, declares, and
  never has a play refused;
- `test/gameplay_widget_test.dart` — the real screen: the button appears at
  two cards, the card cannot be played until it is pressed, and the play goes
  through afterwards; no button with a full hand;
- `test/session4_online_test.dart` — the request path, the public flag, and
  two tamper cases (declare out of turn → `notPlayersTurn`; play without
  declaring → `lastCardDeclarationRequired`);
- eight shared conformance fixtures (`ultima_carta_*`) replayed on the Dart VM
  **and** the compiled JavaScript.

---

## 3. Large hands stay usable

### What the client saw

Around ten cards the fan stopped being fully usable. Two separate defects, not
one:

1. **The tap landed on the wrong card.** Every card's gesture area was its
   whole rectangle, but a fanned card is only *visible* along the strip its
   right-hand neighbour does not cover. Tapping what looked like the third
   card selected the fourth. Invisible with five cards; obvious past nine.
2. **Selecting a card moved it the wrong way.** The comments said "selection
   lifts a card"; the code did `dy -= 26` against `Positioned(bottom:)`, which
   moves it *down*, further under its neighbours, and out of the strip's box.

The strip did already scroll, but with no visual cue that it did, and with a
fixed 48 px minimum step that forced scrolling early instead of using the
width available.

### What it does now

`HandFan` computes one `_FanGeometry` per build from three numbers — the width
actually available, the card width and the card count — and degrades in a
fixed order:

1. **comfortable spacing** while the fan fits;
2. **tightening overlap**, never below `minStepRatio` (0.42) of the card width
   or `minStepPixels` (34 px), whichever is larger;
3. **narrower cards**, down to `minReadableCardWidth` (46 px) and no further —
   and *only when narrowing actually avoids scrolling*, so a hand that must
   scroll keeps full-size, readable cards;
4. **horizontal scrolling**, with a soft gradient at each end so the player
   can see there is more hand, and the selected card scrolled into view.

There is no single fixed negative offset anywhere; every number is derived.

### Selection

A selected card now genuinely **rises** (16 % of the card height, into
headroom the geometry reserves so nothing is clipped) and is **painted last**,
so it is readable even in the middle of a long fan. It deliberately keeps its
*strip* as its tap target rather than claiming its whole face: because it is
painted last, its strip is on top of everything, so nothing can block the
second tap that plays it, while the card next to it stays reachable.

### Tap targets

Each overlapped card owns the strip its neighbour does not cover — at least
34 px wide by the full card height. The last card in the fan, and a card being
dragged, own their whole face. Tapping a card now selects *that* card.

### Performance

No new packages, no new decode work. Cards keep their stable per-card
`ValueKey`, so elements stay attached as the hand changes; the geometry is one
small arithmetic pass per build; the existing layout-sized image cache is
untouched.

### Tests

`test/large_hand_layout_test.dart` — 5, 10, 15, 20 and 25 cards, on a small
phone (320×568), a phone (390×844), a large phone (430×932) and a tablet
(834×1112):

- no exception and no overflow at any size;
- every card is laid out and reachable;
- the first, middle and last card can each be brought into view and selected;
- no card is drawn below the readable minimum;
- every card keeps a strip at least `minStepPixels` wide;
- a selected card is raised above its neighbour and a tap on it reaches it;
- five cards need no scroll view at all;
- 5 → 25 cards in a single rebuild (the "drew a whole chain" case) is clean.

---

## Verification — exactly what ran

### Local gates (final tree)

| Gate | Result |
|---|---|
| `dart format .` | clean |
| `flutter analyze` | **No issues found** |
| `flutter test` | **651** (571 before this change) |
| `deno test supabase/functions/match/` | **66** (58 before) — 59 conformance fixtures + 7 timeout |
| `deno check supabase/functions/match/index.ts` | clean |
| `tool/build_engine_js.sh` | rebuilt, byte-reproducible (`sha256 d238b0c747fbc29d`) |
| `dart run tool/bot_simulation.dart` (`SIM_MATCHES=60`) | **540 matches, 140 247 actions, 0 illegal proposals, 0 invariant violations, 0 hangs** |
| `flutter build apk --debug` | ok — `build/app/outputs/flutter-apk/app-debug.apk` (178 MB) |
| `flutter build apk --release` | ok — `app-release.apk` (61.4 MB), **debug-signed** (no `key.properties`) |

The 59 conformance fixtures replay identically on the Dart VM
(`test/engine/conformance_fixture_test.dart`) and on the compiled JavaScript
the server runs (`supabase/functions/match/engine_conformance_test.ts`), so
offline and online agree on the new scoring and on §16 by construction.

### Live — GiocoDel101-Dev (`fnyllrjchbqfrzezfeso`)

The `match` Edge Function was redeployed (v6 → **v7**). Only the function
changed: no migration, no schema, policy or RLS change, no database reset.
Rolling back is a redeploy from the previous commit.

`tool/online_rule_check.dart`, independent authenticated users per seat:

| Seats | Result |
|---|---|
| 2 | **28 passed, 0 failed** — 3 ULTIMA CARTA declarations |
| 3 | **34 passed, 0 failed** — 8 declarations |
| 4 | **24 passed, 0 failed** — 3 declarations |

Each run also re-proves §6b (a paid chain keeps the turn, at +2 and +4), §12
(the closer leads the next round) and §12a (the dealer moves), and shows
`lastCardDeclaredBy` in the **redacted public snapshot** while opponents stay
`handCount`-only.

**The rule is the server's, not the client's.** The first run after the deploy
failed with `FAIL server accepted playCard from p0 (lastCardDeclarationRequired)`
— the tool had not yet been taught to declare. That failure is the evidence.

`tool/online_matrix.dart`, five independent clients:

- the **short form** completed: **157 checks, every functional area green** —
  private hand security 20/20, concurrency & attacks 12/12, gameplay 20/20,
  match result, rematch, reconnect, realtime, reactions, RLS 9/9, hardening
  22/22, turn timer, forfeit/leave, quick match 15/15, plus live §16
  declarations accepted and published;
- the **full form did not finish in this environment** — see below.

## What was NOT verified

- **No physical device.** The large-hand evidence is four simulated sizes
  (320×568, 390×844, 430×932, 834×1112), not a phone in hand. Nothing here was
  installed or run on real hardware.
- **`tool/online_matrix.dart` never completed its full form here.** Its long
  run reached **200 checks with 0 failures** — through the complete 2-player
  game, match result, rematch, reconnect, realtime, reactions, RLS,
  concurrency, hardening, turn timer, forfeit and quick match, and into the
  3-player game — before the run was cut off by this environment's process
  limits; a full sweep takes well over half an hour of network round trips.
  Its two remaining assertions are **live-game coverage counters**, not rules:
  that a reshuffle and a Cavallo block each happened at least once across the
  games. Both rules are covered elsewhere — conformance fixtures
  `draw_reshuffles_when_exhausted`, `draw_reshuffles_wide_seed`,
  `nove_blocks_chain_cancel` and `nove_blocks_chain_pass_on`, replayed on the
  VM **and** on the compiled JavaScript the server runs, and the bot
  simulation's 63 reshuffles and 135 Cavallo blocks in a single
  difficulty/seat block. Re-run the full matrix from a normal shell to close
  the last line.
- `flutter build appbundle` and `tool/ui_drive_web.ts` were not re-run for
  this change.
- iOS was not compiled (no macOS here).

## What still needs the client's word

Nothing new was invented, and these carry over unchanged:

1. **No penalty for a missed ULTIMA CARTA.** The client asked for a
   declaration, not a punishment, so an undeclared play is refused rather than
   penalised. If they want the usual house penalty (the player who forgets
   draws two, or an opponent may call them out), say which and it is a small
   change in one place — the rule already has its own flag.
2. **The announcement is required from two cards to one only.** If they also
   want it repeated when the final card is played, that is a one-line change.
3. Carry-overs from the previous change: §6a (which Cavallo-block mode is
   canonical), §12c (the online points formula), §12b (simultaneous
   elimination), and what the turn timer should do on expiry.

---

# Follow-up — 2026-09-01: the clockwise sequential deal

One remaining complaint after the three changes above:

> "The sequential hand in clockwise order still doesn't work."

## What was actually wrong

`GameState.dealerSeat` rotated correctly, the dealer badge moved, and the
table's deal animation travelled round the table from the dealer's left. But
the engine underneath was dealing in **plain seat order**:

```dart
// lib/features/game/domain/engine/game_engine.dart — before
final seated = base.players.where((p) => !p.eliminated).toList();
for (var i = 0; i < rules.startingHandSize; i++) {
  for (final p in seated) {           // 0, 1, 2, 3 — always
    hands[p.id]!.add(deck.removeLast());
  }
}
```

`dealerSeat` was never read. Who dealt had **no effect whatsoever** on who got
which card: with four seats the cards went 0, 1, 2, 3, 0, 1, 2, 3 … in every
round of every match, whoever was dealing. The rotation the client had already
paid for was cosmetic — a badge and an animation over a deal that ignored both.

`DealCue`'s own doc comment admitted it: *"This is presentation only: which
cards a seat receives is fixed by the engine and does not depend on this
order."*

## The fix

The canonical sequence now lives on the state, as `GameState.dealingSeatOrder`:
every live seat, one step clockwise at a time, starting one place after
`dealerSeat` and wrapping so the dealer is served last.

`GameEngine._deal` deals by that list, one card per seat per lap, and
`dealingOrder(state)` in `table_cue.dart` — the list the animation walks — is
now a one-line delegation to it. They cannot drift, because there is only one
of them.

```
4 seats, dealer 0:  1, 2, 3, 0,  1, 2, 3, 0,  … five laps
4 seats, dealer 1:  2, 3, 0, 1,  …
3 seats, dealer 2:  0, 1, 2,     …
2 seats, dealer 0:  1, 0,        …
4 seats, seat 2 out, dealer 0:  1, 3, 0,  …
```

**Turn order is untouched.** §12 still gives the lead to the seat that closed
the previous round, wherever they sit; §12a still rotates the dealer. The deal
answers neither question — it only starts from the dealer's left.

## Scope

The only production change is `_deal`'s loop plus the new derived getters, and
`dealingOrder` becoming a delegation. No rule, no scoring, no §16, no layout,
no security, no schema and no wire format changed: `dealerSeat` was already
public, and the order is derived from it, so there is **no migration** and the
redaction, RLS and private hands are untouched.

What *does* change is which cards a given seed deals to a given seat — that is
the fix. The 61 conformance fixtures were regenerated for it; the hand-written
assertions in the scenario catalogue all still hold.

## Tests

`test/engine/dealing_order_test.dart` (32 cases) asserts the **engine's** order,
not the badge:

- the exact laps the client specified, for 2, 3 and 4 seats and every dealer;
- the cards themselves: the k-th card off the stock goes to the k-th seat of
  the lap, five laps, no card dealt twice, every hand full;
- the dealer is served last and their left is served first, at every size;
- eliminated seats skipped with the clockwise order of the rest preserved,
  including when the dealer itself is out;
- counter-clockwise tables deal the other way;
- multi-round rotation: dealer and deal order both advance every round, each
  lap checked against an expectation computed independently of the engine;
- the previous round's closer still leads while the deal starts elsewhere;
- determinism, a different dealer dealing the same shuffle to different seats,
  save/resume, and a pre-`dealerSeat` save falling back to seat 0;
- the deal cue equals `GameState.dealingOrder`, and each seat's hand is in the
  order that seat received its cards — which is what makes the animation
  truthful.

Two conformance fixtures pin it across runtimes, with the Deno side
recomputing `dealingSeatOrder` from the raw JSON instead of asking the engine:
`next_round_deal_goes_clockwise_from_the_dealers_left` and
`next_round_deal_skips_an_eliminated_seat_in_order`.

## Verified live

`tool/online_rule_check.dart` gained a §3 check that recomputes the expected
lap from the server's published `dealerSeat`. Against GiocoDel101-Dev, with
independent authenticated users:

| Seats | Result | Deals observed |
|---|---|---|
| 2 | **50 passed, 0 failed** | dealer 1 → `[0, 1]`, dealer 0 → `[1, 0]` |
| 3 | **36 passed, 0 failed** | dealer 1 → `[2, 0, 1]`, dealer 2 → `[0, 1, 2]` |
| 4 | **46 passed, 0 failed** | dealer 3 → `[0, 1, 2, 3]`, dealer 0 → `[1, 2, 3, 0]` |

Every one of those matches the client's stated sequence. Each run also
re-checks that the closer still leads and that every live seat was dealt a
full hand.

**What the live check cannot see, and why.** No single player can verify
*which card* went to another seat: hands are redacted by design, and weakening
that to prove the deal would be the wrong trade. That half is covered by the
conformance fixtures, which the Dart VM and the compiled JavaScript the server
runs both replay to byte-identical states.
