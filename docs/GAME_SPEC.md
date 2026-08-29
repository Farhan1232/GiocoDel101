# Gioco del 101 — Game Specification

The single written source of truth for the rules. Anything that contradicts
this file is a bug; anything not in this file must not be assumed by UI code.

Every adjustable rule is expressed once, in
`lib/features/game/domain/game_rules_config.dart`. Legality is decided once, in
`lib/features/game/domain/engine/card_rule_resolver.dart`. Scoring is computed
once, in `lib/features/game/domain/engine/score_calculator.dart`. No rule may
be re-derived inside a widget, a controller or a bot.

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

**Ranks** (`CardRank`, with the numeric value used by both matching and
scoring):

| Rank | Value |
|---|---|
| Asso | 1 |
| 2 | 2 |
| 3 | 3 |
| 4 | 4 |
| 5 | 5 |
| 6 | 6 |
| 7 | 7 |
| Fante | 8 |
| Cavallo | 9 |
| Re | 10 |

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
client's requested rules".

**This is not implemented.** `CardRuleResolver.canPlay` currently returns, for
a pending penalty, `rules.stackDrawTwos && card.isTwo` — so a Cavallo is
**not** playable into a live chain, and cannot block.

Before it can be built, the client has to answer:

- Does the Cavallo **cancel** the pending total outright, or **pass it on**
  unchanged to the next player?
- Does blocking still let the blocker **change the suit**?
- Can a Cavallo be answered by another 2, restarting the chain?
- Does a blocked chain count toward the "Catena" achievement?

Until those are answered, do not implement it. When they are, it becomes a new
flag on `GameRulesConfig` (a `nineBlocksDrawTwo`-style boolean) plus a case in
`CardRuleResolver`, and nowhere else.

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

## 9. Reshuffling the draw pile

When the draw pile empties, the discard pile is recycled: the **top card
stays**, everything beneath it is shuffled and becomes the new draw pile
(`_recycleDiscard`).

If the discard pile holds one card or fewer there is nothing to recycle. The
engine then stops drawing rather than looping — a draw simply yields fewer
cards than requested. This is the safe-reshuffle guarantee the brief asks for,
and `test/edge_cases_test.dart` covers it.

## 10. Ending a round

A round ends the moment one player's hand is empty. That player is the round
winner and scores nothing.

Every other player scores **penalty points equal to the printed value of every
card still in their hand**, using the table in §1 (Asso 1 … Re 10). These are
`GameRulesConfig.defaultScoreValues`; they are configurable but not invented.

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

## 13. Configurable rules summary

All in `GameRulesConfig`, all with the defaults above:

| Flag | Default |
|---|---|
| `startingHandSize` | 5 |
| `allowVoluntaryDraw` | true |
| `playDrawnCardImmediately` | true |
| `stackDrawTwos` | true |
| `wildNineCanAlwaysPlay` | true |
| `exact101ResetsToZero` | true |
| `eliminateAbove101` | true |
| `targetScore` | 101 |
| `mustDrawBeforePassing` | true |
| `drawTwoPenalty` | 2 |
| `pendingPenaltyAppliesAfterWin` | false |
| `scoreValues` | Asso 1 … Re 10 |

A room carries its own `GameRulesConfig` (`RoomConfig.rules`), so the house
rules a host picks travel with the match rather than living in the UI.

## 14. Open questions for the client

1. **§6a** — the exact behaviour of the Cavallo against a pending +2. *Blocks
   Session 2.*
2. **§12b** — the online points formula. *Blocks the leaderboard in Session 3.*
3. **§12a** — simultaneous elimination tie-break.
4. Whether the turn timer (`RoomConfig.turnTimer`) auto-plays, auto-draws or
   forfeits when it expires. The UI reserves the ring; the behaviour is
   undefined.
