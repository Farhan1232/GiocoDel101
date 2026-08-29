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

A player who cannot or will not answer **draws the whole pending total** and
loses their turn. The penalty then resets to zero.

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

The previous round's winner leads the next round
(`roundStarterPolicy = previousRoundWinner`, provisional;
`seatAfterPreviousWinner` is also implemented). Eliminated seats are not
dealt in and are skipped in turn order.

### 12a. What happens if everyone would be eliminated at once
— `NEEDS_FINAL_RULE_CONFIRMATION`

Not specified by the client. The engine keeps the last surviving player list
non-empty rather than ending with no winner; the exact tie-break has not been
agreed. Covered defensively in `test/edge_cases_test.dart`.

### 12b. Online scoring — `NEEDS_FINAL_RULE_CONFIRMATION`

Whether an online match awards ranking points, and how many, is undefined. The
leaderboard model exists (`LeaderboardEntry.points`) but **no points formula
has been invented**. Session 3 must get this from the client before the
leaderboard can show anything.

## 12c. Forfeit — leaving a match for good (Session 4)

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
| `roundStarterPolicy` | `previousRoundWinner` | **provisional** (§12) |
| `initialDirection` | `clockwise` | n/a — no reversing card |
| `turnTimeLimitSeconds` | null | **undefined** (§14.4) |
| `scoreValues` | Asso 1 … Re 10 | yes |

A room carries its own `GameRules` (`RoomConfig.rules`), so the house rules a
host picks travel with the match rather than living in the UI.

## 14. Open questions for the client

1. **§6a** — the exact behaviour of the Cavallo against a pending +2. *No
   longer blocking: all candidates are implemented behind `nineBlockMode`;
   the client only has to pick one.*
2. **§12b** — the online points formula. *Blocks the leaderboard in Session 3.*
3. **§12a** — simultaneous elimination tie-break.
4. Whether the turn timer (`RoomConfig.turnTimer`) auto-plays, auto-draws or
   forfeits when it expires. The UI reserves the ring and the engine stamps
   `turnDeadlineAt`; the behaviour on expiry is undefined and not implemented.
5. **§3a** — what to do when the opening discard is an action card.
6. **§12** — who leads a new round (previous winner is the provisional
   answer).
7. **§8** — after drawing a playable card, may the player play a *different*
   legal card instead? (provisional: yes)
