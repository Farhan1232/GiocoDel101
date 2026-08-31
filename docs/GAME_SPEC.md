# Gioco del 101 — Game Specification

The single written source of truth for the rules. Anything that contradicts
this file is a bug; anything not in this file must not be assumed by UI code.

Every adjustable rule is expressed once, in
`lib/features/game/domain/game_rules.dart` (`GameRules`). Legality is decided
once, in `lib/features/game/domain/engine/card_rule_resolver.dart`. Scoring is
computed once, in `lib/features/game/domain/engine/score_policy.dart`
(`ScorePolicy`). Turn processing happens once, in
`lib/features/game/domain/engine/game_engine.dart` (`GameEngine`, pure and
deterministic — see `docs/GAME_ENGINE.md`). No rule may be re-derived inside a
widget, a controller or a bot.

Items marked **`NEEDS_FINAL_RULE_CONFIRMATION`** are genuinely ambiguous or not
yet agreed with the client. They are listed with what the code does today so
nobody has to guess. **No scoring value has been invented.**

---

## 1. The deck

A traditional Neapolitan deck of **40 cards**: four suits × ten ranks. No
jokers, no duplicates.

**Suits** (`CardSuit`, order is meaningful — it drives the suit selector and
the deterministic deck build):

| Suit | English |
|---|---|
| Denari | Coins |
| Coppe | Cups |
| Spade | Swords |
| Bastoni | Clubs |

**Ranks** (`CardRank`, named in Italian in code — `asso, due, tre, quattro,
cinque, sei, sette, fante, cavallo, re` — with the numeric value used by both
matching and scoring):

| Rank | Key | Value |
|---|---|---|
| Asso | `asso` | 1 |
| 2 | `due` | 2 |
| 3 | `tre` | 3 |
| 4 | `quattro` | 4 |
| 5 | `cinque` | 5 |
| 6 | `sei` | 6 |
| 7 | `sette` | 7 |
| Fante | `fante` | 8 |
| Cavallo | `cavallo` | 9 |
| Re | `re` | 10 |

A card's stable id is `<suit>_<rank>` (`denari_asso`, `spade_cavallo`).

> **Naming note.** The brief refers to the suit-changing card as "9". In a
> Neapolitan deck there is no pip 9 — the ninth rank is the **Cavallo**.
> Throughout the code the Cavallo *is* the 9 (`CardRank.cavallo.value == 9`).
> Read "9" and "Cavallo" as the same card everywhere below.

## 2. Players

2 to 4. Offline the seats can be bots or pass-and-play humans. Online the same
range applies (`RoomConfig.playerCount`).

## 3. The deal

Each player is dealt **5** cards (`startingHandSize`). One card is turned up to
start the discard pile; the rest form the draw pile.

### 3a. If the opening card is an action card — `NEEDS_FINAL_RULE_CONFIRMATION`

Not specified. Provisional (`starterCardPolicy = avoidActionCards`): the
engine turns up the nearest non-action card so the first player never owes
a penalty nobody played. `anyCard` is also implemented (the card's effect is
simply not applied). Nothing else has been invented.

## 4. Playing a card

A card may be played if **any** of these holds:

1. it matches the **active suit**, or
2. it matches the **rank** of the top discard, or
3. it is a **Cavallo** and `wildNineCanAlwaysPlay` is on (default: on).

The active suit is normally the suit of the top discard. After a Cavallo it is
whatever the player named.

**Exception — while a +2 chain is pending:** only another **2** may be played.
See §6.

## 5. Asso — skip

Playing an **Asso** makes the next player lose their turn.

With two players the turn returns immediately to the player who played it.

## 6. 2 — draw two, and the chain

Playing a **2** adds `drawTwoPenalty` (default **2**) to a pending penalty and
passes the turn.

The next player may answer with another **2** if `stackDrawTwos` is on
(default: on), which adds another 2 to the total and passes it on again:
+2 → +4 → +6 → +8. There is no cap other than the four 2s in the deck.

A player who cannot or will not answer **draws the whole pending total**. The
penalty then resets to zero — but the turn does not pass. See §6b.

### 6a. Can a Cavallo block a pending +2? — `NEEDS_FINAL_RULE_CONFIRMATION`

The brief states the 9 "can also block a pending +2 attack according to the
client's requested rules". Session 2 **implemented every candidate behind one
switch** so the answer is a one-line config change, not a code change:

| `GameRules.nineBlockMode` | Behaviour |
|---|---|
| `disabled` | Cavallo is not playable into a live chain (Session 1 behaviour) |
| `cancel` — **provisional default** | Cavallo wipes the pending total; nobody draws; the blocker then names the suit as usual |
| `passOn` | Cavallo forwards the pending total unchanged; the next player may stack a 2, block again, or draw it |

Plus `nineBlockChangesSuit` (default **true**): whether a blocking Cavallo
still opens the suit choice. When false the previous active suit stands.

Still to confirm with the client:

- cancel or pass on? (`nineBlockMode`)
- does the blocker still change the suit? (`nineBlockChangesSuit`)
- may a 2 restart the chain after a block? (under `cancel` the next 2 simply
  starts a fresh +2; under `passOn` it stacks — both fall out of the modes
  above, no extra flag)
- does a blocked chain count toward the "Catena" achievement? (currently
  `longestChain` is recorded when the 2s are played, so yes)

`CardRuleResolver.canPlay` and `GameEngine._play` are the only places this
lives. Tests cover all three modes (`test/engine/nove_test.dart`,
conformance fixtures `nove_blocks_chain_*`).

### 6b. After paying a chain, the same player plays on — **CONFIRMED 2026-08-31**

Client instruction, 2026-08-31:

> "When a player is forced to draw two cards because of a Due/+2 penalty,
> drawing the required two cards must NOT automatically end their turn. After
> receiving the required penalty cards, that SAME player must still be allowed
> to play ONE legal card during that turn."

So the sequence is:

```
A plays Due  ->  +2 to B
B cannot (or will not) block or stack
B draws the whole pending total
    the penalty is settled           pendingDrawCount -> 0, chainLength -> 0
    the TURN is not                  B is still the player to act
B may now play ONE ordinary legal card
    ...then, and only then, the turn advances
```

This applies to **whatever the chain was worth** — +2, +4, +6, +8. Nothing is
special-cased to two cards.

What the continuation is *allowed* to be is decided by the engine, not by the
table: `GameEngine.getPlayableCards` and `validateAction` answer exactly as
they would on any other turn. In particular:

- an illegal card is still refused (`GameFailure.illegalCard`);
- the player may **not** draw again — paying the chain sets `hasDrawnThisTurn`,
  so a second draw is refused (`GameFailure.drawNotAllowed`);
- with nothing legal to play, the player **passes** out of the turn, exactly as
  §8 already allows after any draw. A paid chain can therefore never stall the
  table;
- a Cavallo **block** is unaffected (§6a). Blocking is not drawing: it settles
  the chain and passes the turn on as it always did. The continuation is only
  granted to a player who actually *paid*.

State: `GameState.penaltyResolvedThisTurn` is set while the player holds this
continuation, and cleared by the next turn change and by every deal. It is
public information and travels in the online snapshot.

Turn clock (§14.4): resolving a chain opens a **new action window** — the
continuation gets a fresh `turnStartedAt` / `turnDeadlineAt`. Without that, a
player who was attacked late in their turn would inherit a deadline with
nothing left on it. The global timeout and forfeit policy is otherwise
unchanged; a seat that has stopped responding still draws and then passes
(`planTimeout`, `supabase/functions/match/timeout.ts`), so the extra window
costs a live table nothing.

Accounting: the penalty draw is **not** a turn of its own. `turnNumber` moves
once for the whole play, `drawsByPlayer` counts the penalty cards once, and
the 2 that opened the chain is still credited once to whoever played it. In the
event stream a paid chain emits `CardsDrawnEvent(isPenalty: true)` and
`ChainResolvedEvent` and **no** `TurnChangedEvent` — the absence of the turn
change is what distinguishes "penalty resolved" from "turn completed".

## 7. Cavallo — change the suit

A **Cavallo** may be played at any time (see §4.3) and its player then names
the new **active suit** from the four. The Cavallo does not itself set the
active suit to its own suit.

If the Cavallo is the card that empties a player's hand, no suit is named —
the round is already over (`requiresSuitChoice(..., endedRound: true)`).

## 8. Drawing and passing

- A player with no legal card **draws** from the draw pile.
- If the drawn card is legal it may be played immediately
  (`playDrawnCardImmediately`, default: on).
- A player holding a legal card may still choose to draw
  (`allowVoluntaryDraw`, default: on).
- A turn cannot end without either playing or drawing
  (`mustDrawBeforePassing`, default: on).
- After drawing a legal card, any legal card may be played, not only the
  drawn one (`restrictPlayToDrawnCard`, default: off) —
  `NEEDS_FINAL_RULE_CONFIRMATION`, provisional.

## 9. Reshuffling the draw pile

When the draw pile empties, the discard pile is recycled: the **top card
stays**, everything beneath it is shuffled and becomes the new draw pile
(`_recycleDiscard`).

If the discard pile holds one card or fewer there is nothing to recycle. The
engine then stops drawing rather than looping — a draw simply yields fewer
cards than requested. This is the safe-reshuffle guarantee the brief asks for;
`test/engine/draw_pile_test.dart` and `test/edge_cases_test.dart` cover it,
including the 40-card conservation invariant across a reshuffle.

The reshuffle is deterministic: it is seeded from the match seed and the
state version (see `docs/GAME_ENGINE.md` §8).

## 10. Ending a round

A round ends the moment one player's hand is empty. That player is the round
winner and scores nothing.

Every other player scores **penalty points equal to the printed value of every
card still in their hand**, using the table in §1 (Asso 1 … Re 10). These are
`GameRules.defaultScoreValues`; they are configurable but not invented.

### 10a. An unresolved +2 when the round ends

`pendingPenaltyAppliesAfterWin` — default **false**: the round simply stops and
the pending penalty is discarded. When true, the next player draws it first.

## 11. The 101

Penalty points accumulate across rounds toward **101**
(`targetScore`).

- **Exactly 101** → that player's score **resets to 0**
  (`exact101ResetsToZero`, default: on). This is the signature rule.
- **Over 101** → that player is **eliminated**
  (`eliminateAbove101`, default: on).

With `eliminateAbove101` off, the match instead ends as soon as anyone
overshoots, and the **lowest** score wins.

## 12. Winning the match

Rounds continue until **one player remains**. That player wins.

**The player who closed the previous round leads the next one** — CONFIRMED
2026-08-31:

> "The player who starts by playing the first card should not be chosen
> clockwise; it should be the player who finished/closed the previous round."

A round can only be closed by emptying a hand, so the closer *is* the round
winner: `roundStarterPolicy = previousRoundWinner`, which is the active preset
in the default `GameRules` every mode is built from. The lead is explicitly
**not** the clockwise successor of anybody, not the dealer, not seat 0 and not
the host. (`seatAfterPreviousWinner` remains implemented as an alternative but
is not used.) If the closer has since been eliminated, the lead falls to the
next live seat. Eliminated seats are not dealt in and are skipped in turn
order.

### 12a. The dealer rotates clockwise — **CONFIRMED 2026-08-31**

Client instruction, 2026-08-31:

> "The player who deals the cards should rotate clockwise, so a different
> player deals each round."

`GameState.dealerSeat` names the seat that dealt the current round. Seat 0 (the
opening seat) deals round 1; at every new deal the dealer moves **one live seat
clockwise**, wrapping at the end of the table and passing over anyone who has
been eliminated:

| seats | rotation |
|---|---|
| 2 | 0 → 1 → 0 |
| 3 | 0 → 1 → 2 → 0 |
| 4 | 0 → 1 → 2 → 3 → 0 |

**The dealer is independent of who leads.** They answer two different
questions and usually differ:

```
Round 1:  dealer A     closer C
Round 2:  dealer B     first to act C
Round 3:  dealer C     first to act = whoever closed round 2
```

`dealerSeat` is part of the canonical state: it is serialised, it survives
save/resume, it is present in the online public snapshot (the redaction is a
blacklist, so no migration was needed), and it is asserted in the conformance
fixtures shared by the Dart VM and the compiled server engine. A save written
before dealers existed loads with `dealerSeat = 0`, which is what dealt round 1
of every match anyway; an out-of-range value is treated the same way rather
than refused, so a corrupt dealer can never cost a player their saved match.

At the table the deal is shown starting from the seat to the dealer's left and
running round to the dealer last — the order a dealer actually deals in — and
the dealing seat carries a small `MAZZIERE` / `DEALER` badge. Which cards a
seat receives is fixed by the engine and does not depend on that order.

### 12b. What happens if everyone would be eliminated at once
— `NEEDS_FINAL_RULE_CONFIRMATION`

Not specified by the client. The engine keeps the last surviving player list
non-empty rather than ending with no winner; the exact tie-break has not been
agreed. Covered defensively in `test/edge_cases_test.dart`.

### 12c. Online scoring — `NEEDS_FINAL_RULE_CONFIRMATION`

Whether an online match awards ranking points, and how many, is undefined. The
leaderboard model exists (`LeaderboardEntry.points`) but **no points formula
has been invented**. Session 3 must get this from the client before the
leaderboard can show anything.

## 12d. Forfeit — leaving a match for good (Session 4)

A seat may **forfeit** at any moment of a live match (`ForfeitAction`): on
or off turn, between rounds, while a suit is pending. Online this is what
"leave the table", abandonment and the third consecutive turn timeout all
resolve to; offline it is not used yet.

- The seat is **eliminated** for the rest of the match and its cards go to
  the bottom of the draw pile (the 40-card invariant holds).
- A pending +2 chain aimed at it dies; an unnamed suit stays whatever was
  active before the Cavallo.
- If it was that seat's turn, play moves to the next live seat.
- If only one seat is left standing the match ends and that seat wins.

Turn-timer expiry (§14.4) is still undefined by the client; the online
server applies the documented policy in `docs/ONLINE_MULTIPLAYER.md`
("The turn clock and timeouts") — a server-made safe move, forfeit on the
third strike — without changing any rule here.

## 13. Configurable rules summary

All in `GameRules`, all with the defaults above:

| Flag | Default | Confirmed? |
|---|---|---|
| `minPlayers` / `maxPlayers` | 2 / 4 | yes |
| `startingHandSize` | 5 | yes |
| `allowVoluntaryDraw` | true | yes |
| `playDrawnCardImmediately` | true | yes |
| `restrictPlayToDrawnCard` | false | **provisional** |
| `stackDrawTwos` | true | yes |
| `wildNineCanAlwaysPlay` | true | yes |
| `nineBlockMode` | `cancel` | **provisional** (§6a) |
| `nineBlockChangesSuit` | true | **provisional** (§6a) |
| `exact101ResetsToZero` | true | yes |
| `eliminateAbove101` | true | yes |
| `targetScore` | 101 | yes |
| `mustDrawBeforePassing` | true | yes |
| `drawTwoPenalty` | 2 | yes |
| `pendingPenaltyAppliesAfterWin` | false | provisional (§10a) |
| `starterCardPolicy` | `avoidActionCards` | **provisional** (§3a) |
| `roundStarterPolicy` | `previousRoundWinner` | **CONFIRMED 2026-08-31** (§12) |
| `initialDirection` | `clockwise` | n/a — no reversing card |
| `turnTimeLimitSeconds` | null | **undefined** (§14.4) |
| `scoreValues` | Asso 1 … Re 10 | yes |

A room carries its own `GameRules` (`RoomConfig.rules`), so the house rules a
host picks travel with the match rather than living in the UI.

## 14. Open questions for the client

1. **§6a** — the exact behaviour of the Cavallo against a pending +2. *No
   longer blocking: all candidates are implemented behind `nineBlockMode`;
   the client only has to pick one.*
2. **§12c** — the online points formula. *Blocks the leaderboard in Session 3.*
3. **§12b** — simultaneous elimination tie-break.
4. Whether the turn timer (`RoomConfig.turnTimer`) auto-plays, auto-draws or
   forfeits when it expires. The UI reserves the ring and the engine stamps
   `turnDeadlineAt`; the behaviour on expiry is undefined and not implemented.
5. **§3a** — what to do when the opening discard is an action card.
6. **§8** — after drawing a playable card, may the player play a *different*
   legal card instead? (provisional: yes)
7. **§12a** — who deals round 1. The deal rotates clockwise from there, as
   asked; the client did not say where it starts, so seat 0 (the opening seat,
   which is the host online) deals the first round. If the intent was the
   traditional "dealer deals, the player to their left leads", that is a
   one-line change in `GameEngine.createGame`.
8. **§18 / cards** — the printed Napoletane faces carry no corner indices,
   because a traditional Neapolitan deck has none. The engraved deck the app
   shipped with did have them. Confirm this is wanted; if a rank index is
   preferred for readability it can be overlaid without touching the artwork.

Answered on 2026-08-31 (was: who leads a new round): **§12** — the player who
closed the previous round leads the next one.
