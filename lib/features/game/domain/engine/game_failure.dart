import '../game_state.dart';
import 'game_event.dart';

/// Why an action was refused. Every rejection the engine can produce is a
/// value here, so callers (UI, bots, and later the server) branch on a type
/// rather than on a message.
enum GameFailure {
  /// The actor is seated but it is not their turn.
  notPlayersTurn,

  /// The card is not in the actor's hand.
  cardNotOwned,

  /// The card cannot legally be played on the current table.
  illegalCard,

  /// The turn cannot end (or the penalty cannot be ignored) without drawing.
  drawRequired,

  /// Drawing is not allowed right now (already drew, or voluntary draws are
  /// disabled while a legal card is held).
  drawNotAllowed,

  /// A Cavallo is waiting for its suit; nothing else may happen first.
  suitSelectionRequired,

  /// A suit was named but no Cavallo is waiting for one.
  suitSelectionNotPending,

  /// The actor is not seated at this table, or has been eliminated.
  invalidPlayer,

  /// The match already has a winner.
  gameFinished,

  /// The round is over; only `StartNextRoundAction` is legal.
  roundOver,

  /// `StartNextRoundAction` was sent while a round is still in play.
  roundNotOver,

  /// The action was built against a different state version.
  staleState,

  /// The state itself is inconsistent (should never happen for engine-built
  /// states; guards deserialised or hand-built ones).
  invalidState,

  /// §16 — the play would leave the actor holding one card and no "ULTIMA
  /// CARTA" has been declared for this turn. Nothing has changed: declare,
  /// then send the same play again.
  lastCardDeclarationRequired,

  /// §16 — "ULTIMA CARTA" was declared when it means nothing: the actor is
  /// not down to two cards, has no legal play to make with them, or has
  /// already declared for this turn.
  lastCardDeclarationNotAllowed,

  // -- match creation --

  invalidPlayerCount,
  duplicatePlayer,
  invalidRules;

  String get key => name;
}

/// The outcome of [GameEngine.applyAction].
sealed class ActionResult {
  const ActionResult();

  bool get accepted => this is ActionAccepted;

  GameFailure? get failure => switch (this) {
    ActionRejected(:final failure) => failure,
    ActionAccepted() => null,
  };
}

class ActionAccepted extends ActionResult {
  const ActionAccepted(this.state, this.events);

  /// The new immutable state.
  final GameState state;

  /// What happened while resolving the action, in order. The UI animates
  /// these; nothing in them is needed to reconstruct [state].
  final List<GameEvent> events;
}

class ActionRejected extends ActionResult {
  const ActionRejected(this.failure, [this.detail]);

  @override
  final GameFailure failure;
  final String? detail;

  @override
  String toString() =>
      'ActionRejected(${failure.key}${detail == null ? '' : ': $detail'})';
}

/// Thrown by [GameEngine.createGame] for an invalid table.
class GameSetupException implements Exception {
  const GameSetupException(this.failure, this.message);

  final GameFailure failure;
  final String message;

  @override
  String toString() => 'GameSetupException(${failure.key}): $message';
}
