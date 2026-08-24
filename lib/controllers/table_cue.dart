import '../models/card_suit.dart';
import '../models/game_card.dart';

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
