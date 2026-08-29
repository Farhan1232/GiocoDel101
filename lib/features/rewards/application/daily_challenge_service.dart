import 'dart:math';

import '../domain/daily_challenge.dart';
import '../../game/domain/game_rules_config.dart';
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

    return switch (variant) {
      0 => DailyChallenge(
          dateKey: key,
          seed: key,
          title: 'Sull’orlo',
          description:
              'Parti da 80 punti contro un avversario difficile. Un round '
              'sbagliato e sei fuori.',
          playerCount: 2,
          difficulty: BotDifficulty.hard,
          startingScore: 80,
          opponentStartingScore: 0,
          rules: const GameRulesConfig(),
          reward: 'Dorso Notturno',
        ),
      1 => DailyChallenge(
          dateKey: key,
          seed: key,
          title: 'Mano stretta',
          description:
              'Solo 3 carte a testa. Poche scelte, nessun margine di errore.',
          playerCount: players,
          difficulty: difficulty,
          startingScore: 0,
          opponentStartingScore: 0,
          rules: const GameRulesConfig(startingHandSize: 3),
          reward: 'Dorso Notturno',
        ),
      2 => DailyChallenge(
          dateKey: key,
          seed: key,
          title: 'Tempesta di due',
          description:
              'Mano da 8 carte e catene di 2 scatenate. Sopravvivi alla '
              'tempesta.',
          playerCount: players,
          difficulty: difficulty,
          startingScore: 0,
          opponentStartingScore: 0,
          rules: const GameRulesConfig(startingHandSize: 8),
          reward: 'Dorso Notturno',
        ),
      3 => DailyChallenge(
          dateKey: key,
          seed: key,
          title: 'Ritorno a zero',
          description:
              'Parti da 94 punti: trova i 7 punti esatti e torna a zero.',
          playerCount: 2,
          difficulty: BotDifficulty.normal,
          startingScore: 94,
          opponentStartingScore: 20,
          rules: const GameRulesConfig(),
          reward: 'Dorso Notturno',
        ),
      _ => DailyChallenge(
          dateKey: key,
          seed: key,
          title: 'Tavolo pieno',
          description:
              'Quattro giocatori, avversari difficili, nessuna pesca '
              'volontaria.',
          playerCount: 4,
          difficulty: BotDifficulty.hard,
          startingScore: 0,
          opponentStartingScore: 0,
          rules: const GameRulesConfig(allowVoluntaryDraw: false),
          reward: 'Dorso Notturno',
        ),
    };
  }

  DailyChallenge today() => forDate(DateTime.now());

  bool isCompleted(int lastCompletedKey, DateTime date) =>
      lastCompletedKey == dateKeyFor(date);
}
