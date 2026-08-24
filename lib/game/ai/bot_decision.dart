import '../../models/card_suit.dart';
import '../../models/game_card.dart';

enum BotAction { play, draw, endTurn }

/// A bot's move, plus the reaction line it feels like throwing out (§23).
class BotDecision {
  const BotDecision.play(GameCard this.card, {this.suit})
      : action = BotAction.play;
  const BotDecision.draw()
      : action = BotAction.draw,
        card = null,
        suit = null;
  const BotDecision.endTurn()
      : action = BotAction.endTurn,
        card = null,
        suit = null;

  final BotAction action;
  final GameCard? card;

  /// Set when [card] is a Cavallo, so the engine can resolve the suit in the
  /// same step rather than opening the ritual for a bot.
  final CardSuit? suit;
}
