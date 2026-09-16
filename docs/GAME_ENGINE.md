# Game Engine

Session 2, 2026-08-29. The deterministic rules engine that drives the offline
table today and specifies the authoritative online game for Session 3.

Everything described here lives under `lib/features/game/domain/` and has
**no Flutter import, no clock, no I/O and no randomness of its own**. It is
plain Dart and can be lifted into a server process unchanged.

```
domain/
  card_suit.dart        CardSuit           denari coppe spade bastoni
  card_rank.dart        CardRank           asso due tre … fante cavallo re
  game_card.dart        GameCard, CardAsset, Deck (the 40 cards)
  game_rules.dart       GameRules + the enums for every open rule
  game_player.dart      GamePlayer (immutable seat: hand, score, eliminated)
  game_action.dart      GameAction (sealed): PlayCard, DrawCard, ChooseSuit,
                        Pass, StartNextRound
  game_state.dart       GameState (immutable root), GameStatus, GameMode
  history_entry.dart    HistoryEntry — the replay log (not a command)
  match_stats.dart      MatchStats (immutable counters)
  round_result.dart     RoundResult / PlayerRoundResult
  match_factory.dart    seats a table and hands back a GameSession
  engine/
    game_engine.dart        GameEngine — pure: validate / apply / playable
    game_failure.dart       GameFailure, ActionResult, GameSetupException
    card_rule_resolver.dart CardRuleResolver — "is this card legal here?"
    score_policy.dart       ScorePolicy — §10/§11 scoring
    deck_factory.dart       DeckFactory — build + Fisher-Yates shuffle
    game_event.dart         GameEvent (sealed) — presentation hints
    game_session.dart       GameSession — the one stateful handle
```

---

## 1. Models

### Cards

`GameCard(suit, rank)` with value equality. `id` is `"<suit>_<rank>"`
(`denari_asso`, `spade_cavallo`) and is the wire form everywhere. Identity is
never an image filename: `CardAsset` maps identity → what the painters need
(`suitKey`, `rankKey`, `isFigure`, `pipCount`) and would be the single place
an image path is derived from if image assets ever appear.

`Deck.standard` is the 40 cards in enum order; `Deck.size == 40`;
`Deck.byId`. `CardRank.value` is 1..10 and **the Cavallo is the "9"**
(`CardRank.cavallo.value == 9`). Rank keys are Italian; the English keys
written by pre-Session-2 saves (`ace`, `two` … `seven`) are still parsed.

### Players

`GamePlayer` is immutable (`copyWith`). Per match: `id`, `name`, `type`
(`humanLocal` | `bot`), `avatarId`, bot `difficulty`/`personality`, `score`,
`eliminated`. Per round: `hand`. The engine never branches on `type`.

### GameState

The single serialisation root. Field list:

| Field | Meaning |
|---|---|
| `gameId` | stable match id (local token now, server row id later) |
| `mode` | `vsComputer` / `passAndPlay` |
| `rules` | the `GameRules` this match plays by |
| `players` | seat order; hands and scores live on each player |
| `round` | 1-based |
| `currentSeat` / `currentPlayerId` | whose turn |
| `dealerSeat` | §12a — the seat that dealt this round; +1 live seat clockwise at every deal, independent of `currentSeat` |
| `direction` | `clockwise` / `counterClockwise` |
| `drawPile` | face-down stock; **last element is the next card dealt** |
| `discardPile` | face-up; **last element is the visible top card** |
| `activeSuit` | suit to match; differs from the top card only after a Cavallo |
| `pendingDrawCount` / `chainLength` | live +2 chain |
| `status` | `awaitingAction` / `awaitingSuitChoice` / `roundOver` / `finished` |
| `winnerId` / `roundWinnerId` | match winner (finished) / last round winner |
| `turnNumber` | turns this round |
| `hasDrawnThisTurn` / `drawnCard` | §8 draw discipline |
| `penaltyResolvedThisTurn` | §6b — the seat to act has paid a chain and still holds its one legal continuation |
| `lastCardDeclaredBy` | §16 — the seat that has declared "ULTIMA CARTA" for the turn in progress, or null. Public information; cleared by every turn change, every deal, every draw, and by the declarer forfeiting |
| `lastAction` | the last accepted `GameAction` |
| `version` | +1 per accepted action; actions may pin `baseVersion` |
| `turnStartedAt` / `turnDeadlineAt` | epoch ms, set only when a caller supplies `now` |
| `seed` | shuffle seed — see Determinism |
| `stats`, `history`, `playedCards`, `drawsByPlayer`, `voidSuits` | bookkeeping for stats, replay and bots |
| `lastRoundResult` | filled while `roundOver` / `finished` |

Derived: `topCard`, `scores` (id → score), `hands`, `seatOrder`,
`isPenaltyPending`, `isRoundOver`, `isFinished`, `totalCards`, `handOf(id)`,
`playerById(id)`, `hasDeclaredLastCard(id)`, `dealingSeatOrder` /
`dealingOrder` (§3 — the clockwise lap the dealer serves, seats and ids).

All collections are unmodifiable. `copyWith` / `withPlayer` / `withHistory`
are the only ways to derive a new state.

---

## 2. Rules — `GameRules`

Every adjustable rule, once. Confirmed rules have the defaults GAME_SPEC
gives; anything GAME_SPEC marks `NEEDS_FINAL_RULE_CONFIRMATION` is a field
here with a **provisional** default, so nothing is assumed inside a class.

| Field | Default | Status |
|---|---|---|
| `minPlayers` / `maxPlayers` | 2 / 4 | confirmed (the engine hard-caps to 2–4 regardless) |
| `startingHandSize` | 5 | confirmed |
| `allowVoluntaryDraw` | true | confirmed |
| `playDrawnCardImmediately` | true | confirmed |
| `restrictPlayToDrawnCard` | false | **provisional** — after drawing, may any legal card be played or only the drawn one? |
| `stackDrawTwos` | true | confirmed |
| `wildNineCanAlwaysPlay` | true | confirmed |
| `nineBlockMode` | `cancel` | **provisional** (§6a) — `disabled` / `cancel` / `passOn` |
| `nineBlockChangesSuit` | true | **provisional** (§6a) |
| `exact101ResetsToZero` | true | confirmed |
| `eliminateAbove101` | true | confirmed |
| `targetScore` | 101 | confirmed |
| `mustDrawBeforePassing` | true | confirmed |
| `drawTwoPenalty` | 2 | confirmed |
| `pendingPenaltyAppliesAfterWin` | false | provisional (§10a) |
| `starterCardPolicy` | `avoidActionCards` | **provisional** — what if the first discard is an action card? |
| `roundStarterPolicy` | `previousRoundWinner` | **CONFIRMED 2026-08-31** — the seat that closed the previous round leads. `seatAfterPreviousWinner` is still implemented but unused |
| `initialDirection` | `clockwise` | no reversing card exists; carried for completeness |
| `turnTimeLimitSeconds` | null | **undefined** — the engine stamps deadlines, never enforces them |
| `scoreValues` | Asso 1 … Re 10 | confirmed |

`GameRules` has value equality and a fixed-point JSON form (encode → decode →
encode is byte-identical), which the conformance fixtures rely on.

---

## 3. Actions — `GameAction`

Sealed. Every one carries the actor's `playerId` and an optional
`baseVersion`.

| Action | Payload | Legal when |
|---|---|---|
| `PlayCardAction` | `card`, optional `chosenSuit` | own turn, card in hand, `CardRuleResolver.canPlay` |
| `DrawCardAction` | — | own turn; always under a pending chain; otherwise once per turn (and only with no legal card if `allowVoluntaryDraw` is off) |
| `ChooseSuitAction` | `suit` | own turn and `status == awaitingSuitChoice` |
| `PassAction` | — | own turn, no chain pending, drew this turn (unless `mustDrawBeforePassing` is off) |
| `StartNextRoundAction` | — | `status == roundOver`; any seated player or the `system` actor |
| `ForfeitAction` | — | any live seat, at any moment before `finished` (GAME_SPEC §15) |
| `DeclareLastCardAction` | — | §16 — own turn, `awaitingAction`, **exactly two** cards in hand, at least one of them legally playable, not already declared this turn |

JSON: `{"type": "playCard", "playerId": "p0", "card": "coppe_re",
"chosenSuit": "denari", "baseVersion": 12}`. Round-trips exactly.

**Duplicates and replays.** A second copy of an accepted action fails: with
`baseVersion` set it fails as `staleState`; without it, it fails on the
facts (wrong turn, card no longer owned, suit no longer pending). Online
clients must always set `baseVersion`.

---

## 4. Failures — `GameFailure`

`validateAction` returns `null` or exactly one of:

`notPlayersTurn` · `cardNotOwned` · `illegalCard` · `drawRequired` ·
`drawNotAllowed` · `suitSelectionRequired` · `suitSelectionNotPending` ·
`invalidPlayer` · `gameFinished` · `roundOver` · `roundNotOver` ·
`staleState` · `invalidState` · `lastCardDeclarationRequired` ·
`lastCardDeclarationNotAllowed`

The last two are §16. `lastCardDeclarationRequired` refuses a play that would
leave the actor one card while no "ULTIMA CARTA" stands — it is checked
**after** legality, so an illegal card is still reported as `illegalCard`.
`lastCardDeclarationNotAllowed` refuses an announcement that would mean
nothing (wrong hand size, nothing legal to play, already declared).

`createGame` throws `GameSetupException` with `invalidPlayerCount`,
`duplicatePlayer` or `invalidRules`.

`applyAction` returns `ActionResult`: `ActionAccepted(state, events)` or
`ActionRejected(failure)`. A rejected action never changes anything.

---

## 5. The engine — `GameEngine`

```dart
const engine = GameEngine();

GameState  createGame({gameId, players, mode, seed, rules, startingSeat, isDailyChallenge, now})
GameFailure? validateAction(GameState, GameAction)
ActionResult applyAction(GameState, GameAction, {int? now})
List<GameCard> getPlayableCards(GameState, String playerId)
bool canPlay / canDraw / canPass / mustTakePenalty
```

`GameEngine` is `const` and holds nothing. Two engines given the same state
and action produce byte-identical states.

### Turn lifecycle

Every accepted action goes through the same pipeline, in this order:

1. **Validate** — `validateAction`; a failure returns before anything else.
2. **Move cards** — hand → discard, or stock → hand (recycling the discard
   pile first if the stock is empty).
3. **Resolve the card's effect** — Asso marks a skip; 2 grows the chain;
   Cavallo either opens the suit choice, applies an inline suit, or blocks a
   chain per `nineBlockMode`.
4. **Score / win check** — if the hand emptied, the round is scored
   (`ScorePolicy`), eliminations applied, the match winner resolved, and the
   state goes `roundOver` or `finished`. Nothing else happens on that action.
5. **Next player** — `_advanceTurn` by 1 (or 2 after an Asso), skipping
   eliminated seats in the current `direction`; resets the draw flag and
   `penaltyResolvedThisTurn`; `turnNumber++`. Paying a +2 chain is the one
   action that deliberately does **not** reach this step (§6b).
6. **Stamp** — `version++`, `lastAction`, and the turn clock if `now` was
   given.
7. **Invariants** — asserted (see §9).

Every step returns a new state; the input is never touched.

### Special cards

**Asso (skip).** The next live seat loses its turn; play continues with the
one after. With two players the turn returns to the Asso's player. An Asso
that empties the hand ends the round and skips nobody.

**Due (+2 chain).** Adds `drawTwoPenalty` to `pendingDrawCount`,
`chainLength++`. While a chain is pending only a 2 (if `stackDrawTwos`) or a
Cavallo (if `nineBlockMode != disabled`) is legal; `PassAction` fails with
`drawRequired`; `DrawCardAction` takes the whole total and clears the chain.
Four 2s in the deck → +2 / +4 / +6 / +8.

**Paying a chain does not end the turn (§6b, confirmed 2026-08-31).** The
draw sets `pendingDrawCount = 0`, `chainLength = 0`, `hasDrawnThisTurn = true`
and `penaltyResolvedThisTurn = true`, and returns *without* calling
`_advanceTurn` — so the same seat is still to act and may play one ordinary
legal card, whatever the chain was worth. Consequences, all deliberate:

- `getPlayableCards` / `canPlay` / `validateAction` answer normally, so the
  continuation is neither wider nor narrower than any other turn;
- a second `DrawCardAction` is refused (`hasDrawnThisTurn`), and `PassAction`
  is allowed (`mustDrawBeforePassing` is satisfied), so a seat with nothing
  legal always has a way out and the table cannot stall;
- `restrictPlayToDrawnCard` does **not** apply — see
  `GameState.restrictsPlayToDrawnCard`. That rule is a consequence of choosing
  to draw; penalty cards are taken under duress;
- no `TurnChangedEvent` is emitted. A listener therefore reads
  `ChainResolvedEvent` without a following turn change as "penalty resolved",
  distinct from "turn completed";
- `turnNumber` does not move, so a paid chain plus its continuation is counted
  as the single turn it is;
- `_stampClock` treats the resolution as a new action window and re-stamps
  `turnStartedAt` / `turnDeadlineAt` (§6b, §14.4).

Blocking with a Cavallo is unaffected: it settles the chain and passes the
turn on exactly as before. Only a seat that actually *paid* gets the
continuation.

**Cavallo / "9" (change suit).** Playable on anything (`wildNineCanAlwaysPlay`).
Playing it without `chosenSuit` sets `status = awaitingSuitChoice` and keeps
the turn with the same player; every other action is `suitSelectionRequired`
until `ChooseSuitAction` names one of the four suits. The Cavallo's own suit
is never the active suit. As the last card it ends the round with no choice.

**Cavallo against a pending chain — PROVISIONAL (§6a).**
`nineBlockMode = cancel` (default): pending total wiped, `ChainBlockedEvent(cancelled: true)`,
then the normal suit choice. `passOn`: total forwarded unchanged; the next
player may stack a 2, block again, or draw it. `disabled`: not playable.
`nineBlockChangesSuit = false` skips the suit ritual after a block and leaves
the previous active suit standing. **The client has not confirmed any of
this.** The default was chosen because it is the most common reading of
"blocks"; flip one flag when the answer arrives.

### Draw pile

`_drawInto` pops from the end of `drawPile`. When it is empty, the discard
pile minus its top card is Fisher-Yates shuffled into a new stock, the top
card stays, `DeckRecycledEvent` fires and a `recycle` history entry is
written. If the discard pile holds one card or fewer there is nothing to
recycle: the draw returns fewer cards than asked (possibly none) and the
turn still moves on. Total cards never change.

### Start of a game / round

`createGame` validates (2–4 seats, unique non-empty ids, hand size fits the
deck, sane rules, starting seat exists), deals `startingHandSize` to every
live seat, turns up the opener per `starterCardPolicy`, and the rest is the
stock. `dealerSeat` starts at the opening seat.

**The deal order (§3).** `_deal` walks `GameState.dealingSeatOrder` —
one card to each live seat in turn, starting one place clockwise of
`dealerSeat` and wrapping so the dealer is served last — and repeats that lap
`startingHandSize` times. It is not a round-robin from seat 0: who deals
decides who is served first, which is the whole point of rotating the dealer.
The list lives on `GameState` rather than inside `_deal` because the table's
deal animation walks the same list, so the card a player receives and the card
they watch arrive cannot disagree.

`StartNextRoundAction` answers two independent questions:

- **who leads** — the seat that closed the previous round
  (`roundStarterPolicy = previousRoundWinner`), never an eliminated one;
- **who deals** — `dealerSeat` moves one live seat clockwise
  (`_seatAfter(s, s.dealerSeat, 1)`), wrapping at the end of the table and
  passing over eliminated seats; the deal itself then starts from the new
  dealer's left (§3), so the sequence moves with the badge.

Then `round++`, hands are cleared and the deck is dealt again. The two seats
are computed separately and coincide only by chance. Eliminated seats receive
no cards and are skipped in turn order.

---

## 6. Scoring — `ScorePolicy`

Confirmed by the client (GAME_SPEC §10–§11) and nothing more:

- round winner scores 0; everyone else adds the penalty value of each card
  still in hand (`GameRules.scoreValues`): pip cards at their printed rank,
  and — confirmed by the client on 2026-09-01 — **Cavallo 25** (the Fante is
  worth its printed 8);
- exactly `targetScore` → score resets to 0 (`Exact101Event`);
- above `targetScore` → eliminated (`PlayerEliminatedEvent`);
- one live player left → `finished`, `winnerId` set (`MatchEndedEvent`).

With `eliminateAbove101 = false` the match ends on the first overshoot and
the lowest total wins. If every remaining player were somehow eliminated at
once (§12a, unconfirmed) the lowest total wins — defensive only; it cannot
happen through the engine because the round winner never scores.

No online points formula exists (§12b). None was invented.

---

## 7. Events — `GameEvent`

Returned by `applyAction`, in the order things happened. They are
**presentation hints**; the state is complete without them and a client can
rebuild the table from state alone.

`CardPlayedEvent` · `CardsDrawnEvent(isPenalty)` · `TurnSkippedEvent` ·
`ChainGrewEvent` · `ChainResolvedEvent` · `ChainBlockedEvent(cancelled)` ·
`LastCardDeclaredEvent` · `SuitChoiceRequestedEvent` · `SuitChosenEvent` ·
`DeckRecycledEvent` ·
`TurnChangedEvent` · `RoundStartedEvent` · `RoundEndedEvent(result)` ·
`Exact101Event` · `PlayerEliminatedEvent` · `PlayerForfeitedEvent` ·
`MatchEndedEvent`. Each has a stable wire `name` (`GameEventName`) —
`runtimeType` is minified under dart2js, and the server reports events by
that name.
`InvalidMoveEvent` is emitted only by `GameSession` when a play is refused,
so the table can shake the card.

---

## 8. Determinism and randomness

The engine draws no randomness of its own. Every shuffle (the deal at
creation, every next-round deal, every discard recycle) uses
`Random((seed % 2³¹ ^ ((version * 0x9E3779B1) & 0x7FFFFFFF)) + (seed ~/ 2³¹) * 2³¹)`
— the XOR sees two operands below 2³¹ because dart2js truncates bitwise
operators to 32 bits and the online server runs this engine compiled to
JavaScript (Session 4); the high part of the seed is folded in with
arithmetic, exact below 2⁵³ on both runtimes, so the server can hand out
**52-bit seeds** (Session 6 — a 31-bit seed could be brute-forced from a
single dealt hand by a modified client). Seeds below 2³¹ mix exactly as
before; two conformance fixtures with wide seeds prove the VM and the
JavaScript build still agree. Since `version`
increments on every action, `(state, action) → state'` is a pure function:
replaying an action log from the same seed reproduces every intermediate
state byte-for-byte, on any device or server.

`GameEngine({RandomSource random})` lets tests substitute the source. The
seed is part of the state; an online server must treat it as **private**
(it reveals the stock order) and strip it from client-facing views.

`turnStartedAt` / `turnDeadlineAt` are stamped only when the caller passes
`now`. The engine never calls `DateTime.now()`. What happens when a deadline
passes is **undefined by the client** and not implemented.

---

### Redacted states (Session 4)

The server publishes `GameState.toJson()` minus `seed`, `drawPile`,
`drawnCard`, `history` and every `players[].hand`, adding `drawPileCount`
and `players[].handCount` (`app_private.redact_game_state`). Such a JSON
parses into a `GameState` with `isRedacted == true`,
`drawPileCount` reporting the stock size and `GamePlayer.concealedCount` /
`cardCount` reporting each hand's size. Merging the viewer's own hand
(`withPlayer(me.copyWith(hand: …))`) gives a view on which
`getPlayableCards`, `canDraw`, `canPass` and `mustTakePenalty` work exactly
as offline — that is what the online table highlights with. A real state
never emits the concealed keys (fixed-point tests unchanged).

## 9. Invariants

Asserted after every `createGame` and every accepted action:

- card **conservation**: `drawPile + discardPile + all hands` has the same
  count after an action as before (40 for an engine-created game);
- **no duplicate** card anywhere in play;
- the **discard pile is never empty**.

Also guaranteed by construction: `version` rises by exactly 1 per accepted
action; a rejected action leaves the state identical; `currentSeat` always
points at a live player while a round is in play; `pendingDrawCount == 0`
whenever `status` is `roundOver`/`finished`.

---

## 10. Serialization

`toJson` / `fromJson` on `GameCard`, `GameRules`, `GameAction`, `GamePlayer`,
`MatchStats`, `HistoryEntry`, `RoundResult` and `GameState` (`schema: 2`).
Encode → decode → encode is a fixed point for all of them, and a state
restored from JSON continues **identically** to the original under the same
actions (`test/engine/serialization_test.dart`, `determinism_test.dart`).

`GameState.fromJson` throws `FormatException` on structural corruption
(fewer than two seats, duplicate ids, empty discard, cursor out of range,
missing active suit, unparseable card) so a bad save is discarded, never
booted into. Pre-Session-2 saves (`TurnPhase` names, English rank keys)
still load.

---

## 11. `GameSession` — the only mutable object

```dart
final session = GameSession.newMatch(gameId:…, players:…, mode:…, seed:…);
session.listen((event) { … });
session.apply(PlayCardAction(playerId: 'p0', card: card));   // ActionResult
session.playCard(card) / drawCard() / endTurn() / chooseSuit(s) / startNextRound()
session.declareLastCard()          // §16 — what the ULTIMA CARTA button sends
session.autoPlayCard(card)         // §16 — declare-if-due, then play
session.state   // the current immutable GameState
```

It holds a `GameState`, forwards every move to `GameEngine.applyAction`,
swaps in the new state on success and fans the events out to listeners. It
contains no rules.

`autoPlayCard` is the move every **automated** seat makes — the offline bots,
the Pass & Play bots, the tutorial's opponent and `BotSimulator`. It asks
`GameEngine.canDeclareLastCard` and, when the answer is yes, sends a real
`DeclareLastCardAction` before the play. It is a convenience over the same two
actions a person's button tap and card tap produce, not a bypass: §16 has one
implementation and bots go through it. A person's tap still calls plain
`playCard`, so an undeclared play is refused and the UI asks for the button —
which is the feature the client asked for. `GameController` (application layer) owns one, the bots
read `BotViewFactory.forCurrentPlayer(session.state)`, persistence saves
`session.state.toJson()`. An online client will hold a `GameSession` whose
state is replaced by server snapshots instead of by the local engine.

---

## 12. UI contract

The gameplay view **renders `GameState` and sends `GameAction`s**. It asks
the engine what is legal (`getPlayableCards`, `canDraw`, `canPass`,
`mustTakePenalty`, `canDeclareLastCard`) to highlight and enable controls; it
never decides legality itself. The ULTIMA CARTA button is shown exactly when
`canDeclareLastCard` is true, so it can never offer a declaration the engine
would refuse. Pass & Play (several local humans on one device) exercises
the real engine end-to-end with manual control of every seat.

---

## 13. Conformance fixtures

`test/fixtures/game_conformance/*.json` — 41 cases (37 from Session 2 plus
four forfeit cases). Each holds:

```json
{
  "name": "...", "description": "...", "rulesNote": "GAME_SPEC §…",
  "actor": "p1",
  "action": { "type": "playCard", "playerId": "p1", "card": "spade_due" },
  "initialState": { …GameState… },
  "expectedFailure": null | "illegalCard" | …,
  "expectedState": { …GameState… },
  "expectedEvents": ["CardPlayedEvent", "ChainGrewEvent", "TurnChangedEvent"],
  "assertions": { "currentPlayerId": "p0", "pendingDrawCount": 4, … }
}
```

`expectedState` is generated by the engine (`GENERATE_FIXTURES=1 flutter test
test/tools/generate_conformance_fixtures.dart`); `assertions` are written by
hand in `test/support/conformance_scenarios.dart` and are checked against
*both* the fixture and a fresh run, so the engine cannot regenerate its own
approval unnoticed. Session 4 runs the same files against the compiled
engine the Edge Function executes
(`deno test --allow-read supabase/functions/match/engine_conformance_test.ts`):
feed `initialState` + `action`, expect `expectedState` /
`expectedFailure` / `expectedEvents` — 41/41 identical.

---

## 14. Tests

`test/engine/` — card model, game start, turn flow & validation, Asso, Due,
Nove, draw pile, score policy & rounds, serialization, determinism,
conformance fixtures. Plus the pre-existing rule, scoring, edge-case and bot
suites, now running on `GameSession`. Counts and the exact run are in
`docs/SESSION_HANDOFF.md`.
