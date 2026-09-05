# Bots

Session 5, 2026-08-30. The three computer opponents, what they are allowed
to know, how they are paced at the table, and the harness that proves they
never break the rules. Read with `docs/GAME_ENGINE.md` (the rules they play
by) and `docs/OFFLINE_MODE.md` (the table they sit at).

## The one sentence

**A bot sees the public table, proposes one move, and the engine judges it
like any other.** Nothing under `lib/features/game/domain/ai/` can read a
hidden card, and nothing there applies a rule.

```
domain/ai/
  bot_strategy.dart      BotStrategy (the contract), BotWeights (the knobs)
  bot_decision.dart      BotDecision: play(card, suit?) | draw | endTurn
  bot_view.dart          BotView + OpponentInfo — the ONLY input a bot gets
  bot_view_factory.dart  BotViewFactory — the one place a BotView is built
  easy_bot.dart          EasyBot
  normal_bot.dart        NormalBot (weighted scoring)
  hard_bot.dart          HardBot extends NormalBot (card counting)
  bot_factory.dart       BotFactory.create(difficulty, personality, random)
  bot_simulator.dart     BotSimulator — bot-vs-bot runs with invariant checks
domain/bot_roster.dart   Marco / Sofia / Luca / Giulia
```

## The contract — `BotStrategy`

```dart
abstract class BotStrategy {
  final BotPersonality? personality;
  final Random random;                 // injected: seeded in tests and sims
  BotDifficulty get difficulty;
  BotDecision decide(BotView view);    // this turn's move
  CardSuit chooseSuit(BotView view);   // §12 — after a Cavallo
  BotDecision? fallback(BotView view); // shared: nothing playable → draw / end turn
}
```

`BotDecision.play(card, suit:)` carries the suit when `card` is a Cavallo,
so the engine resolves the suit in the same step instead of opening the
Suit Ritual for a bot (`GameSession.playCard(card, chosenSuit:)`).

`fallback()` is what every bot calls first. With `playable` empty it
returns `draw` when a draw is allowed and not yet taken this turn, `draw`
again when a penalty is pending (that draw *is* the penalty), `endTurn`
when the engine allows a pass, and `draw` otherwise. With something
playable it returns null and the strategy decides.

## What a bot can see — `BotView`

`BotViewFactory.forCurrentPlayer(state)` is the single choke point between
the engine and the bots. If a bot ever needs to know something new it is
added there, in the open.

| Field | Content |
|---|---|
| `hand`, `playable` | own cards; the legal subset, computed by `GameEngine.getPlayableCards` |
| `topCard`, `activeSuit` | the visible discard and the suit to follow (differs only after a Cavallo) |
| `pendingPenalty`, `chainLength` | the live +2 chain |
| `playedCards` | every card played this round — the same list a person watched go by |
| `opponents` | `OpponentInfo` rows in turn order starting with the seat that plays next; eliminated seats omitted |
| `drawPileCount` | a number, not the cards |
| `myScore`, `rules` | own score; the `GameRules` in force (target, values, nine-block mode …) |
| `hasDrawnThisTurn`, `drawnCard`, `canDraw`, `canEndTurn` | §8 draw discipline, as the engine reports it |

`OpponentInfo` is `id`, `name`, `cardCount`, `score`, `eliminated`,
`voidSuits` (the suits that seat could not follow the last time it had to
draw — `GameState.voidSuits`, public information) and `seatsAway`.

What `BotView` **cannot express**: another seat's cards, the order of the
stock, the next card to be drawn, the shuffle seed, the history of hidden
draws. There is no field for any of them, so no strategy — present or
future — can be written to use them. Hidden-deck cheating is enforced by
absence, the same principle `docs/SECURITY.md` applies to the wire format.
`test/bot_test.dart` ("the same public state yields the same decision")
builds two tables identical from the bot's chair but with different
opponent hands and checks every difficulty makes the same move on both.

## Easy — `EasyBot`

- `fallback()` first.
- Holding one card: plays the first playable card (it does notice a win).
- Otherwise a uniformly random card from `playable`.
- `chooseSuit`: 40 % a random suit, 60 % `view.longestSuit`.

## Normal — `NormalBot`

Scores every playable card with `scoreCard` and plays the highest. The
terms, before personality scaling (`weights` below):

| Term | Score |
|---|---|
| going out | `handSize == 1` → 1000, nothing else considered |
| shed high | `+ shedHigh × value × 1.6` — expensive cards are liabilities when someone else goes out |
| suit control | `+ suitControl × (countInHand(suit) − 1) × 3` — play from the long suit |
| pressure | next opponent's `cardCount` ≤ 2 → 2.4, ≤ 4 → 1.2, else 0.7 |
| Asso | `+ action × (7 × pressure + 10 if only one opponent)` — heads-up, a skip is an extra turn |
| Due | `+ action × 9 × pressure`; `+ 60` when a penalty is pending (answer the chain rather than eat it) |
| Cavallo | `− holdCavallo × 14`; `+ 18` when `handSize ≤ 3`; `+ 12` when holding nothing in the active suit |
| noise | `+ random × randomness × 30` |

`chooseSuit`: `countInHand(suit) × 10` plus noise — the longest suit.

## Hard — `HardBot`

Extends `NormalBot`: same base score, then counts what has gone by.

- `unseenInSuit(suit)` = 10 − (cards of that suit in `playedCards`, the
  top card if it is not in that list, and own hand). `unseenOfRank(rank)`
  = 4 − seen. Both floor at 0.
- `inDanger` = `targetScore − myScore ≤ 20`.

Added terms:

| Situation | Score |
|---|---|
| next seat is void in this suit | `+ voidExploit × 9` if they could still match the rank (`unseenOfRank > 0`), else `+ voidExploit × 16` |
| scarcity | `+ (10 − unseenInSuit(suit)) × 1.1` — playing into a nearly spent suit leaves opponents stuck |
| in danger | `+ value × 2.2`, and `+ value × 1.4` more when own hand value > 25 |
| a doomed opponent (≥ 3 cards, headroom ≤ 18) | `+ value × 1.1` — end the round on them |
| Cavallo | `− holdCavallo × 8` unless it is the only playable card; `+ 25` when `handSize ≤ 2` |
| Due aimed at a 1-card opponent | `+ action × 22` |
| the last Due in hand, more still unseen, no penalty pending | `− action × 6` — keep one as an answer |
| Asso aimed at a 1-card opponent | `+ action × 20` |

`chooseSuit`: `countInHand × 12`, `+ 18` for a suit the next seat is void
in, `+ (10 − unseenInSuit) × 1.6`, `− 14` for a suit it holds nothing of,
plus noise.

`test/bot_test.dart` pins the counters (`unseenInSuit(denari) == 7`,
`unseenOfRank(due) == 3` on a constructed table), the +2 answer, the held
Cavallo, and that a suit choice always lands on a held suit.

## Personalities — `BotWeights`

Personalities scale weights; they never unlock information.
`NormalBot`/`HardBot` start from `BotWeights()` (all 1.0, randomness 0)
and `scaledBy(BotWeights.forPersonality(p))` — multiplicative except
`randomness`, which adds.

| Roster | Personality | action | holdCavallo | shedHigh | suitControl | randomness |
|---|---|---|---|---|---|---|
| Marco | `aggressive` | 1.6 | 0.6 | 1.15 | 1.0 | 0.05 |
| Sofia | `tactical` | 0.9 | 1.5 | 1.2 | 1.25 | 0 |
| Luca | `risky` | 1.25 | 0.8 | 1.0 | 1.0 | 0.35 |
| Giulia | `calm` (also the default) | 1.0 | 1.0 | 1.05 | 1.3 | 0 |

`BotRoster.pick(count, random)` seats distinct opponents in shuffled
order; `MatchFactory.vsComputer` uses it. `EasyBot` ignores the weights
(personality still steers its reactions).

## Legality

Three layers, none of which trusts the one above:

1. `fallback()` and the fact that strategies only choose from
   `view.playable` (engine-computed).
2. `GameController._takeBotTurn`: a rejected `playCard` is treated as a
   bug, not a stall — the bot draws or ends the turn instead. A stall guard
   in `_resumeFlow` (§52) draws or passes if a bot turn left `turnNumber`
   unchanged.
3. The engine validates every action regardless of who proposes it
   (`GameEngine.validateAction`); `BotSimulator` counts any refusal as an
   `illegalProposal` violation.

### +2, 9 and the block

Inside a live chain the engine's `playable` contains only the answers the
rules allow (2s, and a Cavallo when `nineBlockMode` is not `disabled`), so
a bot cannot be tempted by anything else. Normal and Hard put `+60` on a
2 in that spot; a Cavallo block is available to them only through the
ordinary Cavallo score, so a bot holding both answers with the 2. With no
answer, `fallback()` draws and the engine hands over the penalty cards
and the turn. The block's effect (cancel / pass on) and the suit change
are the engine's (`GameRules.nineBlockMode`, `nineBlockChangesSuit`).

### Drawing

A voluntary draw is one decision; the engine then either returns control
with `drawnCard` set (playable) or advances the turn itself
(unplayable). When `drawnCard` is set the controller asks the bot again
after a short pause and plays or passes. Reshuffling the discard into the
stock is the engine's (`DeckRecycledEvent`); bots only ever see
`drawPileCount` change.

## Pacing at the table — `GameController`

- `_pauseForBot()` waits a uniform random `AppDurations.botThinkMin`
  (420 ms) … `botThinkMax` (900 ms), halved for the follow-up decision
  after a draw, scaled by `Motion.scale` (animation speed, Reduce Motion).
  The seat shows the thinking indicator meanwhile (`OpponentSeat(thinking:)`,
  driven by `GamePlayer.isBot`, never by the engine).
- `_whilePaused()` runs after the think and before the move: a bot in the
  middle of "thinking" when the pause overlay opens finishes the pause and
  waits; it acts only after `resume()`. The same wait guards a bot's suit
  choice.
- Each bot gets its own `Random(p.id.hashCode ^ state.seed)` so a resumed
  match keeps the same temperaments.
- `_maybeBotReaction`: after an accepted play the bot may throw one of the
  eight preset lines — 42 % after a 2 ("Vai!"), 34 % after an Asso, 55 %
  when down to one card, 25 % when holding eight or more, 8 % otherwise;
  aggressive +12 points, calm −5. Bubbles last 1.8 s.

The tutorial (`TutorialController`) uses a plain `NormalBot` as its
scripted opponent, on hands chosen so its reply is the one the lesson
wants to show — see `docs/OFFLINE_MODE.md`.

## The simulation harness

`BotSimulator` (pure Dart) plays whole matches for every difficulty ×
player count {2, 3, 4}, every seat a bot of that difficulty with
personalities rotating across seats and matches, and checks after every
applied action:

| Kind | Invariant |
|---|---|
| `cardCount` | stock + discard + hands == 40 |
| `duplicateCard` | no card id appears twice |
| `emptyDiscard` | a visible top card at all times |
| `badSeat` | while play is live the seat to act exists and is not eliminated |
| `negativeCount` | `pendingDrawCount`, `chainLength`, scores never negative |
| `illegalProposal` | the engine accepted every bot move and suit choice |
| `hang` | the match finished inside the step cap (40 000) |
| `finishedUnstable` | after the finish, play/draw/pass/suit/next-round are all refused and `version` does not move |
| `noWinner` | a `winnerId` that is seated, or exactly one survivor |

Violations are counted, never thrown, so one bad seed cannot hide another.
Seeds are `comboIndex × 100000 + matchIndex`; a printed violation is
reproducible with `BotSimulator.playMatch(difficulty, players, seed: …)`.
Event counters (rounds, reshuffles, chains and the longest chain, Cavallo
blocks, Asso skips, exact-101 resets, penalty draws, wins by seat) say which
rules the run actually exercised.

```
export PATH="$HOME/flutter-sdk/bin:$PATH"
dart run tool/bot_simulation.dart              # 30 matches per combination
SIM_MATCHES=100 dart run tool/bot_simulation.dart
SIM_STEP_CAP=… (default 40000)
```

Exit code 1 on any violation or hang. `test/bot_simulation_test.dart`
runs the same code on 6 matches per combination inside the normal suite and
checks that seed 4242 replays identically.

### The run on 2026-08-30

`dart run tool/bot_simulation.dart`, defaults, on the development machine:

```
combination   matches  actions  rounds  reshuf  chains  maxCh  blocks  skips  x101  penDrw  viol  hang  wins by seat
easy/2p            30     8053     300      16     545      4      49    503     0     357     0     0  15/15
easy/3p            30     9454     330      20     680      4      55    590     2     438     0     0  8/15/7
easy/4p            30    10838     347      46     781      4      83    734     6     488     0     0  11/6/8/5
normal/2p          30     9559     373      15     665      4      74    691     4     433     0     0  19/11
normal/3p          30    11511     385      32     840      4      78    841     8     571     0     0  8/11/11
normal/4p          30    10501     338      38     858      4     111    732     4     543     0     0  5/9/6/10
hard/2p            30     9325     350      18     630      3      57    648     2     410     0     0  18/12
hard/3p            30    10525     384      21     773      4      63    726     8     489     0     0  6/13/11
hard/4p            30    11030     355      38     794      4      86    736     4     494     0     0  6/8/13/3

90796 actions in 5228ms (illegal proposals 0, unstable finishes 0)
RESULT: 270 matches, 0 violations, 0 hangs
```

Every combination exercised reshuffles, chains up to 4 (hard/2p topped at
3), Cavallo blocks, Asso skips and penalty draws; exact-101 resets occurred
in eight of the nine combinations (none in easy/2p on these seeds). The
seats in a combination are all the same difficulty, so "wins by seat" there
measures seat order and the deal, not strength.

### Strength

The committed measurement is `test/bot_test.dart` "Hard beats Easy over a
run of matches": 100 seeded heads-up matches, Hard in seat 0, asserting
Hard wins **more than 55**. It passed in the 2026-08-30 run of
`flutter test test/bot_test.dart` (together with `bot_simulation_test.dart`,
`session5_offline_test.dart` and `session5_tutorial_test.dart`: 49 tests,
all green).

An ad-hoc, uncommitted 200-match head-to-head using the same loop
(seat order alternating each match, no personalities) gave on the same day:
Hard vs Normal **112/200**, Hard vs Easy **119/200**, Normal vs Easy
**116/200**. Hard's edge is real but modest — a 40-card deck with five-card
hands decides a great deal, and Normal already knows what the action cards
do. Nobody should expect Hard to feel unbeatable; it should feel like an
opponent that remembers what you could not follow.

## Known limits

- Bots do not model the ordering of the stock after a recycle (they cannot:
  it is not in the view) and do not track individual opponents' rank
  counts beyond `voidSuits`.
- `holdCavallo` and the danger weights are hand-tuned, not fitted; the
  `BotWeights` knobs and the simulator exist so the client can ask for a
  different feel without touching the rules.
