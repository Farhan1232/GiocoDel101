import '../../models/card_rank.dart';
import '../../models/card_suit.dart';
import '../../models/game_card.dart';
import '../../models/player_type.dart';
import 'bot_view.dart';
import 'normal_bot.dart';

/// §21 Hard — counts the cards that have gone by, keeps track of who looked
/// short of which suit, and weighs the score table before committing.
///
/// Everything it reasons from is on the table: the discard history, hand
/// sizes, scores and the suits opponents failed to follow. It never sees a
/// card it should not see — [BotView] cannot express one.
class HardBot extends NormalBot {
  HardBot({super.personality, super.random, super.weights});

  @override
  BotDifficulty get difficulty => BotDifficulty.hard;

  /// How many cards of [suit] are still unaccounted for, from this bot's
  /// point of view: ten per suit, minus what it has seen played and what it
  /// is holding itself.
  int unseenInSuit(CardSuit suit, BotView view) {
    var seen = 0;
    for (final card in view.playedCards) {
      if (card.suit == suit) seen++;
    }
    if (!view.playedCards.contains(view.topCard) &&
        view.topCard.suit == suit) {
      seen++;
    }
    for (final card in view.hand) {
      if (card.suit == suit) seen++;
    }
    final remaining = 10 - seen;
    return remaining < 0 ? 0 : remaining;
  }

  /// How many of [rank] are still out there.
  int unseenOfRank(CardRank rank, BotView view) {
    var seen = view.playedCards.where((c) => c.rank == rank).length;
    seen += view.hand.where((c) => c.rank == rank).length;
    final remaining = 4 - seen;
    return remaining < 0 ? 0 : remaining;
  }

  /// True when this bot is one bad round away from being knocked out (§16).
  bool inDanger(BotView view) {
    final headroom = view.rules.targetScore - view.myScore;
    return headroom <= 20;
  }

  double _handValue(BotView view) =>
      view.hand.fold(0.0, (s, c) => s + view.rules.valueOf(c.rank));

  @override
  double scoreCard(GameCard card, BotView view) {
    var score = super.scoreCard(card, view);
    if (score >= 1000) return score; // the winning card needs no analysis

    final next = view.nextOpponent;

    // Forcing a suit the next seat could not follow last time usually costs
    // them a draw.
    if (next != null && next.voidSuits.contains(card.suit)) {
      final theyCanStillMatchRank = unseenOfRank(card.rank, view) > 0;
      score += weights.voidExploit * (theyCanStillMatchRank ? 9.0 : 16.0);
    }

    // Playing into a suit that is nearly exhausted leaves opponents stuck.
    final scarcity = 10 - unseenInSuit(card.suit, view);
    score += scarcity * 1.1;

    // Sitting on a big hand while close to the line is how matches are lost.
    if (inDanger(view)) {
      score += card.value * 2.2;
      if (_handValue(view) > 25) score += card.value * 1.4;
    }

    // Somebody within one round of elimination? End the round on them.
    final doomed = view.opponents.any((o) =>
        !o.eliminated &&
        o.cardCount >= 3 &&
        view.rules.targetScore - o.score <= 18);
    if (doomed) score += card.value * 1.1;

    if (card.isCavallo) {
      // Hold the wild longer than Normal does, unless it is the only bridge
      // out of a suit this bot cannot follow.
      final stuck = view.playable.length <= 1;
      score -= stuck ? 0.0 : weights.holdCavallo * 8.0;
      if (view.handSize <= 2) score += 25.0;
    }

    if (card.isTwo && next != null) {
      // A 2 aimed at somebody holding one card is worth far more than a 2
      // spent on a full hand.
      if (next.cardCount == 1) score += weights.action * 22.0;
      // Keep one 2 back as an answer while chains are still likely.
      final twosLeft = unseenOfRank(CardRank.two, view);
      final myTwos = view.hand.where((c) => c.isTwo).length;
      if (myTwos == 1 && twosLeft > 0 && view.pendingPenalty == 0) {
        score -= weights.action * 6.0;
      }
    }

    if (card.isAce && next != null && next.cardCount == 1) {
      score += weights.action * 20.0;
    }

    return score;
  }

  @override
  CardSuit chooseSuit(BotView view) {
    final next = view.nextOpponent;
    var best = view.longestSuit;
    var bestScore = double.negativeInfinity;

    for (final suit in CardSuit.values) {
      // Start from what this bot can actually follow up with.
      var s = view.countInHand(suit) * 12.0;

      // Naming a suit the next seat looked short of buys a free draw.
      if (next != null && next.voidSuits.contains(suit)) s += 18.0;

      // A suit that is mostly spent is a suit opponents probably lack.
      s += (10 - unseenInSuit(suit, view)) * 1.6;

      // Never strand yourself: a suit you hold nothing in is a last resort.
      if (view.countInHand(suit) == 0) s -= 14.0;

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
