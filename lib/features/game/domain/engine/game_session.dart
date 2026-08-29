import '../card_suit.dart';
import '../game_action.dart';
import '../game_card.dart';
import '../game_player.dart';
import '../game_rules.dart';
import '../game_state.dart';
import '../round_result.dart';
import 'game_engine.dart';
import 'game_event.dart';
import 'game_failure.dart';

/// Result of a convenience move on [GameSession].
class MoveResult {
  const MoveResult.ok() : failure = null;
  const MoveResult.rejected(GameFailure this.failure);

  final GameFailure? failure;
  bool get accepted => failure == null;
}

/// A stateful handle on one local match.
///
/// This is the *only* mutable thing in the game domain, and it contains no
/// rules: every move becomes a [GameAction], goes through
/// [GameEngine.applyAction], and either replaces [state] or comes back as a
/// typed failure. Listeners receive the events the engine returned, in
/// order. An online client will hold the same kind of object fed by the
/// server instead of by the local engine.
class GameSession {
  GameSession(GameState state, {this.engine = const GameEngine()})
    : _state = state;

  /// Deals a brand new match. See [GameEngine.createGame].
  factory GameSession.newMatch({
    required String gameId,
    required List<GamePlayer> players,
    required GameMode mode,
    required int seed,
    GameRules rules = const GameRules(),
    int startingSeat = 0,
    bool isDailyChallenge = false,
    GameEngine engine = const GameEngine(),
  }) => GameSession(
    engine.createGame(
      gameId: gameId,
      players: players,
      mode: mode,
      seed: seed,
      rules: rules,
      startingSeat: startingSeat,
      isDailyChallenge: isDailyChallenge,
    ),
    engine: engine,
  );

  GameState _state;

  /// The pure rules engine this session drives.
  final GameEngine engine;
  final List<void Function(GameEvent)> _listeners = [];

  GameState get state => _state;
  GameRules get rules => _state.rules;
  GamePlayer get currentPlayer => _state.currentPlayer;
  RoundResult? get lastRoundResult => _state.lastRoundResult;

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
      engine.getPlayableCards(_state, player.id);

  bool canPlay(GameCard card) => engine.canPlay(_state, card);
  bool get canDraw => engine.canDraw(_state);
  bool get canEndTurn => engine.canPass(_state);
  bool get mustTakePenalty => engine.mustTakePenalty(_state);

  // ------------------------------------------------------------------ moves

  /// Applies any action. Accepted actions replace [state] and notify
  /// listeners; rejected ones leave it untouched.
  ActionResult apply(GameAction action, {int? now}) {
    final result = engine.applyAction(_state, action, now: now);
    switch (result) {
      case ActionAccepted(:final state, :final events):
        _state = state;
        for (final e in events) {
          _emit(e);
        }
      case ActionRejected(:final failure):
        if (action is PlayCardAction &&
            (failure == GameFailure.illegalCard ||
                failure == GameFailure.cardNotOwned)) {
          _emit(InvalidMoveEvent(action.card));
        }
    }
    return result;
  }

  MoveResult _move(GameAction action) {
    final result = apply(action);
    final failure = result.failure;
    return failure == null
        ? const MoveResult.ok()
        : MoveResult.rejected(failure);
  }

  MoveResult playCard(GameCard card, {CardSuit? chosenSuit}) => _move(
    PlayCardAction(
      playerId: _state.currentPlayerId,
      card: card,
      chosenSuit: chosenSuit,
    ),
  );

  MoveResult drawCard() =>
      _move(DrawCardAction(playerId: _state.currentPlayerId));

  MoveResult endTurn() => _move(PassAction(playerId: _state.currentPlayerId));

  MoveResult chooseSuit(CardSuit suit) =>
      _move(ChooseSuitAction(playerId: _state.currentPlayerId, suit: suit));

  MoveResult startNextRound() =>
      _move(const StartNextRoundAction(playerId: GameEngine.systemActorId));

  /// Replaces the state wholesale (a restored save, or a server snapshot).
  void restore(GameState state) => _state = state;
}
