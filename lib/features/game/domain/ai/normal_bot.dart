import 'dart:math';

import '../card_suit.dart';
import '../game_card.dart';
import '../player_type.dart';
import 'bot_decision.dart';
import 'bot_strategy.dart';
import 'bot_view.dart';

/// §21 Normal — understands what the cards actually do. It sheds expensive
/// cards, plays out of its longest suit, keeps the Cavallo in reserve and
/// times its Aces and 2s against the player about to go out.
class NormalBot extends BotStrategy {
  NormalBot({BotPersonality? personality, Random? random, BotWeights? weights})
    : weights = (weights ?? const BotWeights()).scaledBy(
        BotWeights.forPersonality(personality),
      ),
      super(personality, random ?? Random());

  final BotWeights weights;

  @override
  BotDifficulty get difficulty => BotDifficulty.normal;

  @override
  BotDecision decide(BotView view) {
    final forced = fallback(view);
    if (forced != null) return forced;

    GameCard? best;
    var bestScore = double.negativeInfinity;
    for (final card in view.playable) {
      final s = scoreCard(card, view);
      if (s > bestScore) {
        bestScore = s;
        best = card;
      }
    }
    best ??= view.playable.first;
    return BotDecision.play(
      best,
      suit: best.isCavallo ? chooseSuit(view) : null,
    );
  }

  /// Higher is better. Subclasses extend rather than replace this.
  double scoreCard(GameCard card, BotView view) {
    // Going out ends the round with everyone else still holding points.
    if (view.handSize == 1) return 1000;

    var score = 0.0;

    // Expensive cards are liabilities the moment somebody else goes out.
    score += weights.shedHigh * card.value * 1.6;

    // Playing from a long suit keeps the active suit somewhere comfortable.
    score += weights.suitControl * (view.countInHand(card.suit) - 1) * 3.0;

    final next = view.nextOpponent;
    final pressure = next == null
        ? 0.0
        : next.cardCount <= 2
        ? 2.4
        : next.cardCount <= 4
        ? 1.2
        : 0.7;

    if (card.isAce) {
      // With one opponent left, a skip is simply another turn for us.
      final soloBonus = view.opponents.length == 1 ? 10.0 : 0.0;
      score += weights.action * (7.0 * pressure + soloBonus);
    } else if (card.isTwo) {
      score += weights.action * 9.0 * pressure;
      // Answering a live chain is nearly always better than eating it.
      if (view.pendingPenalty > 0) score += 60.0;
    } else if (card.isCavallo) {
      // The wild is worth more later, unless the endgame has arrived.
      score -= weights.holdCavallo * 14.0;
      if (view.handSize <= 3) score += 18.0;
      if (view.countInHand(view.activeSuit) == 0) score += 12.0;
    }

    if (weights.randomness > 0) {
      score += random.nextDouble() * weights.randomness * 30.0;
    }
    return score;
  }

  @override
  CardSuit chooseSuit(BotView view) {
    var best = view.longestSuit;
    var bestScore = double.negativeInfinity;
    for (final suit in CardSuit.values) {
      var s = view.countInHand(suit) * 10.0;
      if (weights.randomness > 0) {
        s += random.nextDouble() * weights.randomness * 8.0;
      }
      if (s > bestScore) {
        bestScore = s;
        best = suit;
      }
    }
    return best;
  }
}
