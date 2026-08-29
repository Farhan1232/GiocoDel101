import 'dart:math';

import '../card_suit.dart';
import '../game_action.dart';
import '../game_card.dart';
import '../game_player.dart';
import '../game_rules_config.dart';
import '../match_state.dart';
import '../round_result.dart';
import '../round_state.dart';
import 'card_rule_resolver.dart';
import 'deck_factory.dart';
import 'game_event.dart';
import 'score_calculator.dart';

/// Why an attempted move was rejected.
enum MoveRejection {
  none,
  notYourTurn,
  wrongPhase,
  cardNotInHand,
  illegalCard,
  mustDrawFirst,
  nothingToDraw,
}

class MoveResult {
  const MoveResult.ok() : rejection = MoveRejection.none;
  const MoveResult.rejected(this.rejection);

  final MoveRejection rejection;
  bool get accepted => rejection == MoveRejection.none;
}

/// The rules of Gioco del 101, expressed once, with no Flutter dependency.
///
/// The engine owns [MatchState] and is the only thing allowed to mutate it.
/// Callers observe progress through [listen]; nothing here reaches for a
/// widget, a timer or a platform channel (§20).
class GameEngine {
  GameEngine._(this._state, this._random)
    : _resolver = CardRuleResolver(_state.rules),
      _scorer = ScoreCalculator(_state.rules);

  /// Restores an engine around an existing (e.g. deserialised) match.
  factory GameEngine.fromState(MatchState state, {Random? random}) =>
      GameEngine._(state, random ?? Random());

  /// Deals a brand new match.
  factory GameEngine.newMatch({
    required List<GamePlayer> players,
    required GameMode mode,
    GameRulesConfig rules = const GameRulesConfig(),
    Random? random,
    int seed = 0,
    bool isDailyChallenge = false,
    int startingPlayerIndex = 0,
  }) {
    final rng = random ?? Random();
    final round = _dealRound(
      players: players,
      rules: rules,
      random: rng,
      startingPlayerIndex: startingPlayerIndex,
    );
    final state = MatchState(
      players: players,
      rules: rules,
      round: round,
      mode: mode,
      seed: seed,
      isDailyChallenge: isDailyChallenge,
    );
    return GameEngine._(state, rng);
  }

  final MatchState _state;
  final Random _random;
  final CardRuleResolver _resolver;
  final ScoreCalculator _scorer;

  final List<void Function(GameEvent)> _listeners = [];

  MatchState get state => _state;
  RoundState get round => _state.round;
  GameRulesConfig get rules => _state.rules;
  CardRuleResolver get resolver => _resolver;
  GamePlayer get currentPlayer => _state.currentPlayer;

  void Function() listen(void Function(GameEvent) listener) {
    _listeners.add(listener);
    return () => _listeners.remove(listener);
  }

  void _emit(GameEvent event) {
    // Iterate a copy: a listener may unsubscribe while handling an event.
    for (final l in List.of(_listeners)) {
      l(event);
    }
  }

  // ---------------------------------------------------------------- queries

  List<GameCard> playableCardsFor(GamePlayer player) =>
      _resolver.playableCards(player.hand, round);

  bool canPlay(GameCard card) => _resolver.canPlay(card, round);

  /// True when the current player has no legal answer to a live Chain Storm
  /// and simply has to take the cards (§10).
  bool get mustTakePenalty =>
      round.isPenaltyPending && playableCardsFor(currentPlayer).isEmpty;

  /// §8 — whether a "pass" is currently allowed at all.
  bool get canEndTurn =>
      round.phase == TurnPhase.awaitingAction &&
      !round.isPenaltyPending &&
      (round.hasDrawnThisTurn || !rules.mustDrawBeforePassing);

  /// §8 — a voluntary draw is only offered when the rules permit it.
  bool get canDraw {
    if (round.phase != TurnPhase.awaitingAction) return false;
    if (round.hasDrawnThisTurn && !round.isPenaltyPending) return false;
    if (round.isPenaltyPending) return true;
    if (!rules.allowVoluntaryDraw &&
        _resolver.hasPlayable(currentPlayer.hand, round)) {
      return false;
    }
    return true;
  }

  // ------------------------------------------------------------------ moves

  /// Plays [card] from the current player's hand.
  ///
  /// [chosenSuit] lets a caller that already knows its answer (a bot, or a
  /// restored save) name the Cavallo's suit in the same step.
  MoveResult playCard(GameCard card, {CardSuit? chosenSuit}) {
    if (round.phase != TurnPhase.awaitingAction) {
      return const MoveResult.rejected(MoveRejection.wrongPhase);
    }
    final player = currentPlayer;
    if (!player.hand.contains(card)) {
      return const MoveResult.rejected(MoveRejection.cardNotInHand);
    }
    if (!_resolver.canPlay(card, round)) {
      _emit(InvalidMoveEvent(card));
      return const MoveResult.rejected(MoveRejection.illegalCard);
    }

    player.hand.remove(card);
    round.discardPile.add(card);
    round.playedCards.add(card);
    round.clearVoid(player.id, card.suit);
    round.drawnCard = null;
    // A Cavallo keeps the previous active suit until its owner names one.
    if (!card.isCavallo) round.activeSuit = card.suit;

    _state.stats.cardsPlayed++;
    _state.stats.suitsPlayed.update(
      card.suit.key,
      (v) => v + 1,
      ifAbsent: () => 1,
    );
    _state.record(
      GameAction(type: GameActionType.play, playerId: player.id, card: card),
    );
    _emit(CardPlayedEvent(player.id, card));

    final emptied = player.hand.isEmpty;

    // §9/§10/§12 — apply the card's action before deciding who plays next.
    if (card.isAce) {
      _state.stats.acesPlayed++;
    } else if (card.isTwo) {
      _state.stats.twosPlayed++;
      round.pendingPenalty += rules.drawTwoPenalty;
      round.chainLength++;
      if (round.chainLength > _state.stats.longestChain) {
        _state.stats.longestChain = round.chainLength;
      }
      _emit(ChainGrewEvent(round.pendingPenalty, round.chainLength));
    }

    if (emptied) {
      _finishRound(player, winningCard: card);
      return const MoveResult.ok();
    }

    if (card.isCavallo) {
      if (chosenSuit != null) {
        _applySuitChoice(player, chosenSuit);
      } else {
        round.phase = TurnPhase.awaitingSuitChoice;
        _emit(SuitChoiceRequestedEvent(player.id, card));
      }
      return const MoveResult.ok();
    }

    if (card.isAce) {
      final skipped = _players[_seatAfter(round.currentIndex, 1)];
      // With two players left, skipping the opponent hands the turn straight
      // back to the player who dropped the Ace (§52).
      _state.record(
        GameAction(type: GameActionType.skip, playerId: skipped.id),
      );
      _emit(TurnSkippedEvent(skipped.id));
      _advanceTurn(2);
    } else {
      _advanceTurn(1);
    }
    return const MoveResult.ok();
  }

  /// §12 — names the active suit after a Cavallo.
  MoveResult chooseSuit(CardSuit suit) {
    if (round.phase != TurnPhase.awaitingSuitChoice) {
      return const MoveResult.rejected(MoveRejection.wrongPhase);
    }
    _applySuitChoice(currentPlayer, suit);
    return const MoveResult.ok();
  }

  void _applySuitChoice(GamePlayer player, CardSuit suit) {
    round.activeSuit = suit;
    round.phase = TurnPhase.awaitingAction;
    _state.stats.recordCavalloSuit(player.id, suit);
    _state.record(
      GameAction(
        type: GameActionType.suitChosen,
        playerId: player.id,
        suit: suit,
      ),
    );
    _emit(SuitChosenEvent(player.id, suit));
    _advanceTurn(1);
  }

  /// §8/§10 — draws. With a Chain Storm live this takes the whole penalty and
  /// ends the turn; otherwise it draws a single card.
  MoveResult drawCard() {
    if (round.phase != TurnPhase.awaitingAction) {
      return const MoveResult.rejected(MoveRejection.wrongPhase);
    }
    final player = currentPlayer;

    if (round.isPenaltyPending) {
      final owed = round.pendingPenalty;
      final chain = round.chainLength;
      final drawn = _drawInto(player, owed);
      round.pendingPenalty = 0;
      round.chainLength = 0;
      _state.record(
        GameAction(
          type: GameActionType.penaltyDraw,
          playerId: player.id,
          count: drawn.length,
        ),
      );
      _emit(CardsDrawnEvent(player.id, drawn, isPenalty: true));
      _emit(ChainResolvedEvent(player.id, owed, chain));
      _advanceTurn(1);
      return const MoveResult.ok();
    }

    if (round.hasDrawnThisTurn) {
      return const MoveResult.rejected(MoveRejection.wrongPhase);
    }
    if (!rules.allowVoluntaryDraw &&
        _resolver.hasPlayable(player.hand, round)) {
      return const MoveResult.rejected(MoveRejection.illegalCard);
    }

    // Drawing is normally an admission of having nothing to match with.
    if (!_resolver.hasPlayable(player.hand, round)) {
      round.noteVoid(player.id, round.activeSuit);
    }
    final drawn = _drawInto(player, 1);
    round.hasDrawnThisTurn = true;
    _state.record(
      GameAction(
        type: GameActionType.draw,
        playerId: player.id,
        count: drawn.length,
      ),
    );
    _emit(CardsDrawnEvent(player.id, drawn));

    if (drawn.isEmpty) {
      // §52 — nothing left anywhere to draw. Never stall: just move on.
      _advanceTurn(1);
      return const MoveResult.ok();
    }

    final card = drawn.first;
    if (rules.playDrawnCardImmediately && _resolver.canPlay(card, round)) {
      // §8 — hand control back so the player may use what they just drew.
      round.drawnCard = card;
    } else {
      _advanceTurn(1);
    }
    return const MoveResult.ok();
  }

  /// §8 — ends the turn after a draw that could not (or would not) be used.
  MoveResult endTurn() {
    if (!canEndTurn) {
      return const MoveResult.rejected(MoveRejection.mustDrawFirst);
    }
    _advanceTurn(1);
    return const MoveResult.ok();
  }

  // ------------------------------------------------------------- turn order

  List<GamePlayer> get _players => _state.players;

  /// Index of the seat [steps] places after [from], skipping players who are
  /// out of the match. Bounded so a corrupt state can never spin forever.
  int _seatAfter(int from, int steps) {
    var index = from;
    var moved = 0;
    var guard = 0;
    final limit = _players.length * (steps + 2);
    while (moved < steps && guard++ < limit) {
      index = (index + 1) % _players.length;
      if (!_players[index].eliminated) moved++;
    }
    return index;
  }

  void _advanceTurn(int steps) {
    if (round.phase == TurnPhase.roundOver ||
        round.phase == TurnPhase.matchOver) {
      return;
    }
    round.currentIndex = _seatAfter(round.currentIndex, steps);
    round.hasDrawnThisTurn = false;
    round.drawnCard = null;
    round.turnNumber++;
    round.phase = TurnPhase.awaitingAction;
    _emit(TurnChangedEvent(currentPlayer.id));
  }

  // ----------------------------------------------------------------- piles

  /// Moves up to [count] cards from the stock into [player]'s hand,
  /// recycling the discard pile when the stock runs dry (§18).
  List<GameCard> _drawInto(GamePlayer player, int count) {
    final drawn = <GameCard>[];
    for (var i = 0; i < count; i++) {
      if (round.drawPile.isEmpty && !_recycleDiscard()) {
        // §52 — every card is in somebody's hand. Draw what we can and stop.
        break;
      }
      if (round.drawPile.isEmpty) break;
      final card = round.drawPile.removeLast();
      player.hand.add(card);
      drawn.add(card);
    }
    if (drawn.isNotEmpty) {
      round.drawsByPlayer.update(
        player.id,
        (v) => v + drawn.length,
        ifAbsent: () => drawn.length,
      );
    }
    return drawn;
  }

  /// §18 — keeps the visible top card, shuffles everything beneath it back
  /// into the stock. Returns false when there is nothing to recycle.
  bool _recycleDiscard() {
    if (round.discardPile.length <= 1) return false;
    final top = round.discardPile.removeLast();
    final recycled = List<GameCard>.of(round.discardPile);
    round.discardPile
      ..clear()
      ..add(top);
    for (var i = recycled.length - 1; i > 0; i--) {
      final j = _random.nextInt(i + 1);
      final tmp = recycled[i];
      recycled[i] = recycled[j];
      recycled[j] = tmp;
    }
    round.drawPile.addAll(recycled);
    _state.record(
      GameAction(
        type: GameActionType.recycle,
        playerId: '',
        count: recycled.length,
      ),
    );
    _emit(DeckRecycledEvent(recycled.length));
    return true;
  }

  // ------------------------------------------------------------ round / match

  void _finishRound(GamePlayer winner, {GameCard? winningCard}) {
    // §52 — an unanswered chain normally dies with the round.
    if (round.isPenaltyPending) {
      if (rules.pendingPenaltyAppliesAfterWin) {
        final victim = _players[_seatAfter(round.currentIndex, 1)];
        final drawn = _drawInto(victim, round.pendingPenalty);
        _emit(CardsDrawnEvent(victim.id, drawn, isPenalty: true));
      }
      round.pendingPenalty = 0;
      round.chainLength = 0;
    }

    round.phase = TurnPhase.roundOver;
    round.roundWinnerId = winner.id;
    _state.stats.roundsWon.update(winner.id, (v) => v + 1, ifAbsent: () => 1);

    final rows = <PlayerRoundResult>[];
    final newlyEliminated = <String>[];

    for (final player in _players) {
      if (player.eliminated) continue;
      final penalty = player.id == winner.id
          ? 0
          : _scorer.handPenalty(player.hand);
      final outcome = _scorer.apply(
        previousScore: player.score,
        penalty: penalty,
      );
      player.score = outcome.newScore;
      if (outcome.hitExact101) {
        _state.stats.resets101++;
        _emit(Exact101Event(player.id));
      }
      if (outcome.eliminated) {
        player.eliminated = true;
        newlyEliminated.add(player.id);
      }
      rows.add(
        PlayerRoundResult(
          playerId: player.id,
          name: player.name,
          cardsLeft: player.hand.length,
          penalty: penalty,
          previousScore: outcome.previousScore,
          newScore: outcome.newScore,
          hitExact101: outcome.hitExact101,
          eliminated: outcome.eliminated,
        ),
      );
    }

    _updateComeback();

    for (final id in newlyEliminated) {
      _emit(PlayerEliminatedEvent(id));
    }

    final matchWinner = _resolveMatchWinner();
    if (matchWinner != null) {
      _state.matchOver = true;
      _state.matchWinnerId = matchWinner.id;
      round.phase = TurnPhase.matchOver;
    }

    final result = RoundResult(
      roundNumber: _state.roundNumber,
      winnerId: winner.id,
      winnerName: winner.name,
      rows: rows,
      matchOver: _state.matchOver,
      matchWinnerId: _state.matchWinnerId,
    );
    _state.record(
      GameAction(
        type: GameActionType.roundEnd,
        playerId: winner.id,
        card: winningCard,
      ),
    );
    _emit(RoundEndedEvent(result));
    if (_state.matchOver) {
      _emit(MatchEndedEvent(_state.matchWinnerId!));
    }
    _lastRoundResult = result;
  }

  RoundResult? _lastRoundResult;
  RoundResult? get lastRoundResult => _lastRoundResult;

  /// §37 — the winner's largest deficit. In a penalty game "behind" means a
  /// higher score than the best-placed rival.
  void _updateComeback() {
    for (final player in _players) {
      if (player.eliminated) continue;
      var bestRival = 1 << 30;
      for (final other in _players) {
        if (other.id == player.id || other.eliminated) continue;
        if (other.score < bestRival) bestRival = other.score;
      }
      if (bestRival == 1 << 30) continue;
      final deficit = player.score - bestRival;
      if (deficit > _state.stats.bestComeback) {
        _state.stats.bestComeback = deficit;
      }
    }
  }

  GamePlayer? _resolveMatchWinner() {
    if (rules.eliminateAbove101) {
      final alive = _players.where((p) => !p.eliminated).toList();
      if (alive.length == 1) return alive.first;
      if (alive.isEmpty) {
        // §52 — everybody overshot in the same round. Lowest total takes it.
        return _lowestScore(_players);
      }
      return null;
    }
    // Elimination disabled: the match ends the moment anyone passes the
    // target, and the lowest score wins.
    if (_players.any((p) => p.score > rules.targetScore)) {
      return _lowestScore(_players);
    }
    return null;
  }

  GamePlayer _lowestScore(List<GamePlayer> pool) {
    var best = pool.first;
    for (final p in pool) {
      if (p.score < best.score) best = p;
    }
    return best;
  }

  /// Deals the next round to whoever is still standing. The previous round's
  /// winner leads (§52 — an eliminated seat never gets dealt in again).
  void startNextRound() {
    if (_state.matchOver) return;
    final previousWinnerId = round.roundWinnerId;
    for (final p in _players) {
      p.hand.clear();
    }
    var startIndex = 0;
    final winner = previousWinnerId == null
        ? null
        : _state.playerById(previousWinnerId);
    if (winner != null && !winner.eliminated) {
      startIndex = _players.indexOf(winner);
    } else {
      startIndex = _players.indexWhere((p) => !p.eliminated);
      if (startIndex < 0) startIndex = 0;
    }
    _state.roundNumber++;
    _state.round = _dealRound(
      players: _players,
      rules: rules,
      random: _random,
      startingPlayerIndex: startIndex,
    );
    _lastRoundResult = null;
    _emit(TurnChangedEvent(currentPlayer.id));
  }

  // ------------------------------------------------------------------ dealing

  static RoundState _dealRound({
    required List<GamePlayer> players,
    required GameRulesConfig rules,
    required Random random,
    required int startingPlayerIndex,
  }) {
    final deck = DeckFactory.shuffled(random);
    final seated = players.where((p) => !p.eliminated).toList();
    for (final p in players) {
      p.hand.clear();
    }
    for (var i = 0; i < rules.startingHandSize; i++) {
      for (final p in seated) {
        if (deck.isEmpty) break;
        p.hand.add(deck.removeLast());
      }
    }

    // Turn over a plain card to open the round: starting on an action card
    // would leave the first player owing a penalty nobody played at them.
    var starterIndex = deck.lastIndexWhere((c) => !c.isAction);
    if (starterIndex < 0) starterIndex = deck.length - 1;
    final starter = deck.removeAt(starterIndex);

    var index = startingPlayerIndex;
    if (index < 0 || index >= players.length || players[index].eliminated) {
      index = players.indexWhere((p) => !p.eliminated);
      if (index < 0) index = 0;
    }

    return RoundState(
      drawPile: deck,
      discardPile: [starter],
      activeSuit: starter.suit,
      currentIndex: index,
    );
  }
}
