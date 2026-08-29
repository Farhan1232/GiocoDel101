import '../card_suit.dart';
import '../game_card.dart';
import '../game_rules_config.dart';

/// What a bot is allowed to know about another seat.
///
/// There is deliberately no `hand` here: §21 forbids bots from reading hidden
/// information, and the cheapest way to guarantee that is to make it
/// impossible to express.
class OpponentInfo {
  const OpponentInfo({
    required this.id,
    required this.name,
    required this.cardCount,
    required this.score,
    required this.eliminated,
    required this.voidSuits,
    required this.seatsAway,
  });

  final String id;
  final String name;
  final int cardCount;
  final int score;
  final bool eliminated;

  /// Suits this seat looked short of the last time they had to draw.
  final List<CardSuit> voidSuits;

  /// 1 means "plays immediately after me".
  final int seatsAway;
}

/// The public state of the table, from one bot's chair.
class BotView {
  const BotView({
    required this.hand,
    required this.playable,
    required this.topCard,
    required this.activeSuit,
    required this.pendingPenalty,
    required this.chainLength,
    required this.playedCards,
    required this.opponents,
    required this.drawPileCount,
    required this.myScore,
    required this.rules,
    required this.hasDrawnThisTurn,
    required this.drawnCard,
    required this.canDraw,
    required this.canEndTurn,
  });

  final List<GameCard> hand;
  final List<GameCard> playable;
  final GameCard topCard;
  final CardSuit activeSuit;
  final int pendingPenalty;
  final int chainLength;

  /// Every card played this round — the same list a human can see go by.
  final List<GameCard> playedCards;

  /// Ordered by turn order, starting with the seat that plays next.
  final List<OpponentInfo> opponents;

  final int drawPileCount;
  final int myScore;
  final GameRulesConfig rules;
  final bool hasDrawnThisTurn;
  final GameCard? drawnCard;
  final bool canDraw;
  final bool canEndTurn;

  OpponentInfo? get nextOpponent => opponents.isEmpty ? null : opponents.first;

  int get handSize => hand.length;

  /// How many of [suit] the bot is holding.
  int countInHand(CardSuit suit) => hand.where((c) => c.suit == suit).length;

  /// The bot's longest suit — its best guess at future flexibility.
  CardSuit get longestSuit {
    var best = hand.isEmpty ? activeSuit : hand.first.suit;
    var bestCount = -1;
    for (final suit in CardSuit.values) {
      final n = countInHand(suit);
      if (n > bestCount) {
        bestCount = n;
        best = suit;
      }
    }
    return best;
  }
}
