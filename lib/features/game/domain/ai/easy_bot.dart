import 'dart:math';

import '../card_suit.dart';
import '../player_type.dart';
import 'bot_decision.dart';
import 'bot_strategy.dart';
import 'bot_view.dart';

/// §21 Easy — plays a legal card almost at random. It notices when it is
/// about to win and little else.
class EasyBot extends BotStrategy {
  EasyBot({BotPersonality? personality, Random? random})
      : super(personality, random ?? Random());

  @override
  BotDifficulty get difficulty => BotDifficulty.easy;

  @override
  BotDecision decide(BotView view) {
    final forced = fallback(view);
    if (forced != null) return forced;

    // Even a beginner spots the winning card.
    for (final card in view.playable) {
      if (view.handSize == 1) {
        return BotDecision.play(card,
            suit: card.isCavallo ? chooseSuit(view) : null);
      }
    }
    final card = view.playable[random.nextInt(view.playable.length)];
    return BotDecision.play(card,
        suit: card.isCavallo ? chooseSuit(view) : null);
  }

  @override
  CardSuit chooseSuit(BotView view) {
    if (random.nextDouble() < 0.4) {
      return CardSuit.values[random.nextInt(CardSuit.values.length)];
    }
    return view.longestSuit;
  }
}
