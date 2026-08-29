import '../card_suit.dart';
import '../game_card.dart';
import '../round_result.dart';

/// Something the table should react to.
///
/// The engine never touches Flutter; it emits these instead, and the
/// controller turns them into animations, sound and haptics. This is what
/// keeps the engine unit-testable (§20) and networking-ready (§64).
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

/// §11 — a 2 was played and the Chain Storm grew.
class ChainGrewEvent extends GameEvent {
  const ChainGrewEvent(this.total, this.chainLength);
  final int total;
  final int chainLength;
}

/// §11 — somebody took the whole chain on the chin.
class ChainResolvedEvent extends GameEvent {
  const ChainResolvedEvent(this.playerId, this.total, this.chainLength);
  final String playerId;
  final int total;
  final int chainLength;
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

class InvalidMoveEvent extends GameEvent {
  const InvalidMoveEvent(this.card);
  final GameCard card;
}

class RoundEndedEvent extends GameEvent {
  const RoundEndedEvent(this.result);
  final RoundResult result;
}

/// §15 — the signature moment.
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
