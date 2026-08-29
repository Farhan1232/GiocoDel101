import '../../game/domain/game_rules.dart';
import '../../game/domain/player_type.dart';

/// §40/§68 — a challenge derived purely from the calendar date.
///
/// The same build on the same day produces the same challenge for everybody,
/// with no server involved and nothing transmitted.
class DailyChallenge {
  const DailyChallenge({
    required this.dateKey,
    required this.seed,
    required this.title,
    required this.description,
    required this.playerCount,
    required this.difficulty,
    required this.startingScore,
    required this.opponentStartingScore,
    required this.rules,
    required this.reward,
  });

  /// `yyyyMMdd`.
  final int dateKey;

  /// Seed handed to the deck shuffle so the deal is reproducible.
  final int seed;

  final String title;
  final String description;
  final int playerCount;
  final BotDifficulty difficulty;

  /// Where the human starts on the Fate Ring.
  final int startingScore;
  final int opponentStartingScore;

  final GameRules rules;
  final String reward;
}
