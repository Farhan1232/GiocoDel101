import 'dart:math';

import '../../models/player_type.dart';
import 'bot_strategy.dart';
import 'easy_bot.dart';
import 'hard_bot.dart';
import 'normal_bot.dart';

class BotFactory {
  const BotFactory._();

  static BotStrategy create(
    BotDifficulty difficulty, {
    BotPersonality? personality,
    Random? random,
  }) {
    switch (difficulty) {
      case BotDifficulty.easy:
        return EasyBot(personality: personality, random: random);
      case BotDifficulty.normal:
        return NormalBot(personality: personality, random: random);
      case BotDifficulty.hard:
        return HardBot(personality: personality, random: random);
    }
  }
}
