import 'dart:math';

import '../../../app/localization/app_strings.dart';
import '../domain/daily_challenge.dart';
import '../../game/domain/game_rules.dart';
import '../../game/domain/player_type.dart';

/// §68 — builds the day's challenge from the date alone.
///
/// Everything is derived from a `yyyyMMdd` seed through a plain [Random], so
/// the result is stable across devices and needs no network, no account and
/// no stored personal data (§69).
class DailyChallengeService {
  const DailyChallengeService();

  static int dateKeyFor(DateTime date) =>
      date.year * 10000 + date.month * 100 + date.day;

  DailyChallenge forDate(DateTime date) {
    final key = dateKeyFor(date);
    final rng = Random(key);

    // Five recognisable shapes, picked by the date.
    final variant = rng.nextInt(5);
    final players = 2 + rng.nextInt(3);
    final difficulty = switch (rng.nextInt(3)) {
      0 => BotDifficulty.normal,
      1 => BotDifficulty.hard,
      _ => BotDifficulty.hard,
    };

    final s = Strings.s;
    return switch (variant) {
      0 => DailyChallenge(
        dateKey: key,
        seed: key,
        title: s.challengeEdgeTitle,
        description: s.challengeEdgeBody,
        playerCount: 2,
        difficulty: BotDifficulty.hard,
        startingScore: 80,
        opponentStartingScore: 0,
        rules: const GameRules(),
      ),
      1 => DailyChallenge(
        dateKey: key,
        seed: key,
        title: s.challengeTightTitle,
        description: s.challengeTightBody,
        playerCount: players,
        difficulty: difficulty,
        startingScore: 0,
        opponentStartingScore: 0,
        rules: const GameRules(startingHandSize: 3),
      ),
      2 => DailyChallenge(
        dateKey: key,
        seed: key,
        title: s.challengeStormTitle,
        description: s.challengeStormBody,
        playerCount: players,
        difficulty: difficulty,
        startingScore: 0,
        opponentStartingScore: 0,
        rules: const GameRules(startingHandSize: 8),
      ),
      3 => DailyChallenge(
        dateKey: key,
        seed: key,
        title: s.challengeZeroTitle,
        description: s.challengeZeroBody,
        playerCount: 2,
        difficulty: BotDifficulty.normal,
        startingScore: 94,
        opponentStartingScore: 20,
        rules: const GameRules(),
      ),
      _ => DailyChallenge(
        dateKey: key,
        seed: key,
        title: s.challengeFullTitle,
        description: s.challengeFullBody,
        playerCount: 4,
        difficulty: BotDifficulty.hard,
        startingScore: 0,
        opponentStartingScore: 0,
        rules: const GameRules(allowVoluntaryDraw: false),
      ),
    };
  }

  DailyChallenge today() => forDate(DateTime.now());

  bool isCompleted(int lastCompletedKey, DateTime date) =>
      lastCompletedKey == dateKeyFor(date);
}
