import '../../achievements/domain/achievements_catalog.dart';
import '../../game/domain/game_state.dart';
import '../../game/domain/round_result.dart';
import '../domain/statistics_model.dart';

/// The result of folding one finished match into the lifetime record.
class StatsUpdate {
  const StatsUpdate(this.stats, this.newAchievements);

  final StatisticsModel stats;
  final List<String> newAchievements;
}

/// §39/§41 — turns match outcomes into lifetime counters and badges.
///
/// Kept free of Flutter and of storage so the rules for "what counts" can be
/// unit-tested on their own.
class StatisticsService {
  const StatisticsService();

  /// Applies a completed round. [perfectHand] means the round winner never
  /// drew a card ("Mano Perfetta").
  StatsUpdate applyRound({
    required StatisticsModel stats,
    required GameState match,
    required RoundResult result,
    required String humanId,
  }) {
    final unlocked = List<String>.of(stats.unlockedAchievements);
    void grant(String id) {
      if (!unlocked.contains(id)) unlocked.add(id);
    }

    final humanWonRound = result.winnerId == humanId;
    final humanRow = result.rows.where((r) => r.playerId == humanId);
    final human101 = humanRow.isNotEmpty && humanRow.first.hitExact101;

    if (human101) grant(AchievementsCatalog.rinascita);
    if (humanWonRound && (match.drawsByPlayer[humanId] ?? 0) == 0) {
      grant(AchievementsCatalog.manoPerfetta);
    }
    if (match.stats.longestChain >= 3) grant(AchievementsCatalog.catena);

    return StatsUpdate(
      stats.copyWith(
        roundsPlayed: stats.roundsPlayed + 1,
        roundsWon: stats.roundsWon + (humanWonRound ? 1 : 0),
        resets101: stats.resets101 + (human101 ? 1 : 0),
        unlockedAchievements: unlocked,
      ),
      unlocked.where((id) => !stats.unlockedAchievements.contains(id)).toList(),
    );
  }

  /// Applies a completed match.
  StatsUpdate applyMatch({
    required StatisticsModel stats,
    required GameState match,
    required String humanId,
  }) {
    final unlocked = List<String>.of(stats.unlockedAchievements);
    void grant(String id) {
      if (!unlocked.contains(id)) unlocked.add(id);
    }

    final won = match.winnerId == humanId;
    final matches = stats.matchesPlayed + 1;
    final streak = won ? stats.currentStreak + 1 : 0;

    // §41 "Maestro dei Semi" — win having named all four suits with a Cavallo.
    final named = match.stats.cavalloSuits[humanId] ?? const [];
    if (won && named.length >= 4) grant(AchievementsCatalog.maestroNove);
    if (matches >= 25) grant(AchievementsCatalog.veterano);
    // §41 — the first win ever.
    if (won && stats.matchesWon == 0) grant(AchievementsCatalog.primaVittoria);
    // "Vendetta": this win came straight after a defeat, which is exactly
    // what a zeroed streak on a player who has already played means.
    if (won && stats.currentStreak == 0 && stats.matchesPlayed > 0) {
      grant(AchievementsCatalog.vendetta);
    }
    if (streak >= 5) grant(AchievementsCatalog.imbattibile);
    if (match.stats.longestChain >= 3) grant(AchievementsCatalog.catena);
    if (match.isDailyChallenge && won) grant(AchievementsCatalog.sfidaGiorno);

    final suits = Map<String, int>.of(stats.suitCounts);
    match.stats.suitsPlayed.forEach((key, value) {
      suits.update(key, (v) => v + value, ifAbsent: () => value);
    });

    return StatsUpdate(
      stats.copyWith(
        matchesPlayed: matches,
        matchesWon: stats.matchesWon + (won ? 1 : 0),
        cardsPlayed: stats.cardsPlayed + match.stats.cardsPlayed,
        acesPlayed: stats.acesPlayed + match.stats.acesPlayed,
        twosPlayed: stats.twosPlayed + match.stats.twosPlayed,
        longestChain: match.stats.longestChain > stats.longestChain
            ? match.stats.longestChain
            : stats.longestChain,
        largestComeback: won && match.stats.bestComeback > stats.largestComeback
            ? match.stats.bestComeback
            : stats.largestComeback,
        currentStreak: streak,
        bestStreak: streak > stats.bestStreak ? streak : stats.bestStreak,
        suitCounts: suits,
        unlockedAchievements: unlocked,
      ),
      unlocked.where((id) => !stats.unlockedAchievements.contains(id)).toList(),
    );
  }
}
