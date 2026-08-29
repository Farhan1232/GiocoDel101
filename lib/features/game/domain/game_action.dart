import 'card_suit.dart';
import 'game_card.dart';

/// A command a player sends to the engine.
///
/// Actions are the *only* way a [GameState] changes. They are plain data:
/// serialisable, comparable, and identical whether they come from a tap on
/// the table, a bot, a replay, or — later — a client talking to the
/// authoritative server.
///
/// [playerId] is the actor. [baseVersion], when set, must equal the version
/// of the state the action is applied to; the engine rejects it with
/// `GameFailure.staleState` otherwise. Online clients should always set it,
/// so a duplicate or out-of-order submission cannot apply twice.
sealed class GameAction {
  const GameAction({required this.playerId, this.baseVersion});

  final String playerId;
  final int? baseVersion;

  String get type;

  Map<String, dynamic> toJson() => {
    'type': type,
    'playerId': playerId,
    if (baseVersion != null) 'baseVersion': baseVersion,
    ..._payload(),
  };

  Map<String, dynamic> _payload();

  factory GameAction.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    final playerId = json['playerId'] as String? ?? '';
    final baseVersion = (json['baseVersion'] as num?)?.toInt();
    switch (type) {
      case PlayCardAction.kind:
        return PlayCardAction(
          playerId: playerId,
          card: GameCard.fromJson(json['card']),
          chosenSuit: json['chosenSuit'] == null
              ? null
              : CardSuit.fromKey(json['chosenSuit'] as String),
          baseVersion: baseVersion,
        );
      case DrawCardAction.kind:
        return DrawCardAction(playerId: playerId, baseVersion: baseVersion);
      case ChooseSuitAction.kind:
        return ChooseSuitAction(
          playerId: playerId,
          suit: CardSuit.fromKey(json['suit'] as String),
          baseVersion: baseVersion,
        );
      case PassAction.kind:
        return PassAction(playerId: playerId, baseVersion: baseVersion);
      case StartNextRoundAction.kind:
        return StartNextRoundAction(
          playerId: playerId,
          baseVersion: baseVersion,
        );
      case ForfeitAction.kind:
        return ForfeitAction(playerId: playerId, baseVersion: baseVersion);
    }
    throw FormatException('Unknown action type: $type');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other.runtimeType == runtimeType &&
          other is GameAction &&
          other.playerId == playerId &&
          other.baseVersion == baseVersion &&
          _samePayload(other));

  bool _samePayload(GameAction other);

  @override
  int get hashCode => Object.hash(type, playerId, baseVersion, _payloadHash);

  int get _payloadHash;

  @override
  String toString() => toJson().toString();
}

/// Play [card] from the actor's hand. A Cavallo may name its suit in the
/// same step via [chosenSuit] (bots and restored saves do this); otherwise
/// the engine waits for a [ChooseSuitAction].
class PlayCardAction extends GameAction {
  const PlayCardAction({
    required super.playerId,
    required this.card,
    this.chosenSuit,
    super.baseVersion,
  });

  static const String kind = 'playCard';

  final GameCard card;
  final CardSuit? chosenSuit;

  @override
  String get type => kind;

  @override
  Map<String, dynamic> _payload() => {
    'card': card.id,
    if (chosenSuit != null) 'chosenSuit': chosenSuit!.key,
  };

  @override
  bool _samePayload(GameAction other) =>
      other is PlayCardAction &&
      other.card == card &&
      other.chosenSuit == chosenSuit;

  @override
  int get _payloadHash => Object.hash(card, chosenSuit);
}

/// Draw from the draw pile. While a +2 chain is pending this takes the whole
/// pending total and ends the turn; otherwise it draws one card.
class DrawCardAction extends GameAction {
  const DrawCardAction({required super.playerId, super.baseVersion});

  static const String kind = 'drawCard';

  @override
  String get type => kind;

  @override
  Map<String, dynamic> _payload() => const {};

  @override
  bool _samePayload(GameAction other) => other is DrawCardAction;

  @override
  int get _payloadHash => 0;
}

/// Name the active suit after a Cavallo.
class ChooseSuitAction extends GameAction {
  const ChooseSuitAction({
    required super.playerId,
    required this.suit,
    super.baseVersion,
  });

  static const String kind = 'chooseSuit';

  final CardSuit suit;

  @override
  String get type => kind;

  @override
  Map<String, dynamic> _payload() => {'suit': suit.key};

  @override
  bool _samePayload(GameAction other) =>
      other is ChooseSuitAction && other.suit == suit;

  @override
  int get _payloadHash => suit.hashCode;
}

/// End the turn without playing, after a draw that could not (or would not)
/// be used.
class PassAction extends GameAction {
  const PassAction({required super.playerId, super.baseVersion});

  static const String kind = 'pass';

  @override
  String get type => kind;

  @override
  Map<String, dynamic> _payload() => const {};

  @override
  bool _samePayload(GameAction other) => other is PassAction;

  @override
  int get _payloadHash => 0;
}

/// Deal the next round once the current one has been scored. Any seated
/// player (or the host/server) may send it; it is idempotent in effect
/// because it is only legal while the round is over.
class StartNextRoundAction extends GameAction {
  const StartNextRoundAction({required super.playerId, super.baseVersion});

  static const String kind = 'startNextRound';

  @override
  String get type => kind;

  @override
  Map<String, dynamic> _payload() => const {};

  @override
  bool _samePayload(GameAction other) => other is StartNextRoundAction;

  @override
  int get _payloadHash => 0;
}

/// The actor leaves the match for good and is eliminated (GAME_SPEC §15).
///
/// Sent by a player who surrenders, or by the server on behalf of a seat
/// that abandoned the table or ran out of turn time too many times. Legal at
/// any moment of a live match for any seat that is still in it.
class ForfeitAction extends GameAction {
  const ForfeitAction({required super.playerId, super.baseVersion});

  static const String kind = 'forfeit';

  @override
  String get type => kind;

  @override
  Map<String, dynamic> _payload() => const {};

  @override
  bool _samePayload(GameAction other) => other is ForfeitAction;

  @override
  int get _payloadHash => 0;
}
