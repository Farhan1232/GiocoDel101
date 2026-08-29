import '../card_suit.dart';
import '../game_card.dart';
import '../round_result.dart';

/// Something the table should react to.
///
/// The engine never touches Flutter; it returns these alongside the new
/// state, and the controller turns them into animations, sound and haptics.
/// Events are presentation hints only — the state is complete without them.
sealed class GameEvent {
  const GameEvent();
}

class CardPlayedEvent extends GameEvent {
  const CardPlayedEvent(this.playerId, this.card);
  final String playerId;
  final GameCard card;
}

class CardsDrawnEvent extends GameEvent {
  const CardsDrawnEvent(this.playerId, this.cards, {this.isPenalty = false});
  final String playerId;
  final List<GameCard> cards;
  final bool isPenalty;
}

class TurnSkippedEvent extends GameEvent {
  const TurnSkippedEvent(this.playerId);
  final String playerId;
}

/// §6 — a 2 was played and the chain grew.
class ChainGrewEvent extends GameEvent {
  const ChainGrewEvent(this.total, this.chainLength);
  final int total;
  final int chainLength;
}

/// §6 — somebody took the whole chain on the chin.
class ChainResolvedEvent extends GameEvent {
  const ChainResolvedEvent(this.playerId, this.total, this.chainLength);
  final String playerId;
  final int total;
  final int chainLength;
}

/// §6a — a Cavallo was played into a live chain. [cancelled] is true when
/// the pending total was wiped, false when it was passed on unchanged.
class ChainBlockedEvent extends GameEvent {
  const ChainBlockedEvent(
    this.playerId,
    this.total,
    this.chainLength, {
    required this.cancelled,
  });
  final String playerId;
  final int total;
  final int chainLength;
  final bool cancelled;
}

class SuitChoiceRequestedEvent extends GameEvent {
  const SuitChoiceRequestedEvent(this.playerId, this.card);
  final String playerId;
  final GameCard card;
}

class SuitChosenEvent extends GameEvent {
  const SuitChosenEvent(this.playerId, this.suit);
  final String playerId;
  final CardSuit suit;
}

class DeckRecycledEvent extends GameEvent {
  const DeckRecycledEvent(this.count);
  final int count;
}

class TurnChangedEvent extends GameEvent {
  const TurnChangedEvent(this.playerId);
  final String playerId;
}

/// Emitted by [GameSession] (not the pure engine) when a play is refused as
/// illegal, so the table can shake the card.
class InvalidMoveEvent extends GameEvent {
  const InvalidMoveEvent(this.card);
  final GameCard card;
}

class RoundStartedEvent extends GameEvent {
  const RoundStartedEvent(this.round, this.firstPlayerId);
  final int round;
  final String firstPlayerId;
}

class RoundEndedEvent extends GameEvent {
  const RoundEndedEvent(this.result);
  final RoundResult result;
}

/// §11 — the signature moment.
class Exact101Event extends GameEvent {
  const Exact101Event(this.playerId);
  final String playerId;
}

class PlayerEliminatedEvent extends GameEvent {
  const PlayerEliminatedEvent(this.playerId);
  final String playerId;
}

class MatchEndedEvent extends GameEvent {
  const MatchEndedEvent(this.winnerId);
  final String winnerId;
}

/// A seat gave up (or was forfeited by the server) and is out of the match.
/// Always followed by a [PlayerEliminatedEvent] for the same seat.
class PlayerForfeitedEvent extends GameEvent {
  const PlayerForfeitedEvent(this.playerId);
  final String playerId;
}

/// Stable wire names for events. `runtimeType.toString()` is minified under
/// dart2js, and the conformance fixtures and the server both need the
/// same spelling as the Dart VM produces.
extension GameEventName on GameEvent {
  String get name => switch (this) {
    CardPlayedEvent() => 'CardPlayedEvent',
    CardsDrawnEvent() => 'CardsDrawnEvent',
    TurnSkippedEvent() => 'TurnSkippedEvent',
    ChainGrewEvent() => 'ChainGrewEvent',
    ChainResolvedEvent() => 'ChainResolvedEvent',
    ChainBlockedEvent() => 'ChainBlockedEvent',
    SuitChoiceRequestedEvent() => 'SuitChoiceRequestedEvent',
    SuitChosenEvent() => 'SuitChosenEvent',
    DeckRecycledEvent() => 'DeckRecycledEvent',
    TurnChangedEvent() => 'TurnChangedEvent',
    InvalidMoveEvent() => 'InvalidMoveEvent',
    RoundStartedEvent() => 'RoundStartedEvent',
    RoundEndedEvent() => 'RoundEndedEvent',
    Exact101Event() => 'Exact101Event',
    PlayerEliminatedEvent() => 'PlayerEliminatedEvent',
    MatchEndedEvent() => 'MatchEndedEvent',
    PlayerForfeitedEvent() => 'PlayerForfeitedEvent',
  };
}
