import '../domain/card_suit.dart';
import '../domain/engine/game_event.dart';
import '../domain/game_state.dart';
import '../domain/game_card.dart';

/// Something the table has to show before play may continue.
///
/// The engine produces facts; [GameController] turns them into an ordered
/// queue of cues; the gameplay view animates them and reports back. Keeping
/// the queue explicit is what stops effects from overlapping and what keeps
/// the engine free of any notion of time (§20).
sealed class TableCue {
  const TableCue();
}

class PlayCardCue extends TableCue {
  const PlayCardCue(this.playerId, this.card);
  final String playerId;
  final GameCard card;
}

class DrawCue extends TableCue {
  const DrawCue(this.playerId, this.cards, {required this.isPenalty});
  final String playerId;
  final List<GameCard> cards;
  final bool isPenalty;
}

class SkipCue extends TableCue {
  const SkipCue(this.playerId);
  final String playerId;
}

class ChainGrowCue extends TableCue {
  const ChainGrowCue(this.total, this.level);
  final int total;
  final int level;
}

class ChainBreakCue extends TableCue {
  const ChainBreakCue(this.playerId, this.total, this.level);
  final String playerId;
  final int total;
  final int level;
}

class SuitChosenCue extends TableCue {
  const SuitChosenCue(this.playerId, this.suit);
  final String playerId;
  final CardSuit suit;
}

class RecycleCue extends TableCue {
  const RecycleCue(this.count);
  final int count;
}

class InvalidCue extends TableCue {
  const InvalidCue(this.card);
  final GameCard card;
}

class TurnCue extends TableCue {
  const TurnCue(this.playerId, {required this.isHuman});
  final String playerId;
  final bool isHuman;
}

class ReactionCue extends TableCue {
  const ReactionCue(this.playerId, this.phrase);
  final String playerId;
  final String phrase;
}

/// A fresh hand being dealt: [seatIds] in deal order, [handSize] cards each.
///
/// The engine deals in one step; the table shows the cards leaving the
/// stock one by one so a new round reads as a new round (§29).
///
/// §12a — [seatIds] starts one seat clockwise of the dealer and wraps, the
/// order a dealer actually deals in, so the deal visibly travels round the
/// table as [dealerId] moves. This is presentation only: which cards a seat
/// receives is fixed by the engine and does not depend on this order.
class DealCue extends TableCue {
  const DealCue(this.seatIds, this.handSize, {this.dealerId});
  final List<String> seatIds;
  final int handSize;

  /// The seat that dealt this round, when the driver knows it.
  final String? dealerId;
}

/// The live seats in dealing order for [state]: first the seat clockwise of
/// the dealer, then on round the table, wrapping back to the dealer last.
List<String> dealingOrder(GameState state) {
  final live = <int>[
    for (var i = 0; i < state.players.length; i++)
      if (!state.players[i].eliminated) i,
  ];
  if (live.isEmpty) return const [];
  final step = state.direction.step;
  final n = state.players.length;
  final order = <String>[];
  var seat = state.dealerSeat;
  for (var moved = 0; moved < live.length;) {
    seat = (seat + step + n) % n;
    if (state.players[seat].eliminated) continue;
    order.add(state.players[seat].id);
    moved++;
  }
  return order;
}

/// The one mapping from engine facts to table cues, shared by every local
/// driver (the bot table and the tutorial) so they cannot drift apart.
class TableCues {
  const TableCues._();

  /// Returns the cue [event] should be shown as, or null when it is a pure
  /// state fact the table reads directly (round ended, match ended, …).
  static TableCue? fromEvent(
    GameEvent event, {
    required bool Function(String playerId) isHumanSeat,
  }) {
    switch (event) {
      case CardPlayedEvent():
        return PlayCardCue(event.playerId, event.card);
      case CardsDrawnEvent():
        return DrawCue(event.playerId, event.cards, isPenalty: event.isPenalty);
      case TurnSkippedEvent():
        return SkipCue(event.playerId);
      case ChainGrewEvent():
        return ChainGrowCue(event.total, event.chainLength);
      case ChainResolvedEvent():
        return ChainBreakCue(event.playerId, event.total, event.chainLength);
      case ChainBlockedEvent():
        // §6a — a Cavallo stopped the chain. The table shows the chain
        // collapsing; a passed-on chain keeps its level through ChainGrew.
        return event.cancelled
            ? ChainBreakCue(event.playerId, event.total, event.chainLength)
            : null;
      case SuitChosenEvent():
        return SuitChosenCue(event.playerId, event.suit);
      case DeckRecycledEvent():
        return RecycleCue(event.count);
      case InvalidMoveEvent():
        return InvalidCue(event.card);
      case TurnChangedEvent():
        return TurnCue(event.playerId, isHuman: isHumanSeat(event.playerId));
      case SuitChoiceRequestedEvent():
      case RoundStartedEvent():
      case RoundEndedEvent():
      case Exact101Event():
      case PlayerEliminatedEvent():
      case PlayerForfeitedEvent():
      case MatchEndedEvent():
        return null;
    }
  }
}
