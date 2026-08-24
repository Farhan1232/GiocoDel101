import 'card_suit.dart';

/// §39 — lifetime counters, all local, all anonymous.
class StatisticsModel {
  const StatisticsModel({
    this.matchesPlayed = 0,
    this.matchesWon = 0,
    this.roundsWon = 0,
    this.roundsPlayed = 0,
    this.cardsPlayed = 0,
    this.acesPlayed = 0,
    this.twosPlayed = 0,
    this.longestChain = 0,
    this.resets101 = 0,
    this.largestComeback = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.suitCounts = const {},
    this.unlockedAchievements = const [],
    this.dailyChallengesCompleted = 0,
    this.lastDailyChallenge = 0,
  });

  final int matchesPlayed;
  final int matchesWon;
  final int roundsWon;
  final int roundsPlayed;
  final int cardsPlayed;
  final int acesPlayed;
  final int twosPlayed;
  final int longestChain;
  final int resets101;
  final int largestComeback;
  final int currentStreak;
  final int bestStreak;

  /// Suit key → times the human played a card of that suit.
  final Map<String, int> suitCounts;

  final List<String> unlockedAchievements;
  final int dailyChallengesCompleted;

  /// §40 — `yyyyMMdd` of the last completed daily challenge, 0 if never.
  final int lastDailyChallenge;

  int get winPercentage =>
      matchesPlayed == 0 ? 0 : ((matchesWon / matchesPlayed) * 100).round();

  /// The suit the player reaches for most often, or null before any data.
  CardSuit? get favouriteSuit {
    String? best;
    var bestCount = 0;
    for (final entry in suitCounts.entries) {
      if (entry.value > bestCount) {
        bestCount = entry.value;
        best = entry.key;
      }
    }
    if (best == null || bestCount == 0) return null;
    try {
      return CardSuit.fromKey(best);
    } on StateError {
      return null;
    }
  }

  StatisticsModel copyWith({
    int? matchesPlayed,
    int? matchesWon,
    int? roundsWon,
    int? roundsPlayed,
    int? cardsPlayed,
    int? acesPlayed,
    int? twosPlayed,
    int? longestChain,
    int? resets101,
    int? largestComeback,
    int? currentStreak,
    int? bestStreak,
    Map<String, int>? suitCounts,
    List<String>? unlockedAchievements,
    int? dailyChallengesCompleted,
    int? lastDailyChallenge,
  }) =>
      StatisticsModel(
        matchesPlayed: matchesPlayed ?? this.matchesPlayed,
        matchesWon: matchesWon ?? this.matchesWon,
        roundsWon: roundsWon ?? this.roundsWon,
        roundsPlayed: roundsPlayed ?? this.roundsPlayed,
        cardsPlayed: cardsPlayed ?? this.cardsPlayed,
        acesPlayed: acesPlayed ?? this.acesPlayed,
        twosPlayed: twosPlayed ?? this.twosPlayed,
        longestChain: longestChain ?? this.longestChain,
        resets101: resets101 ?? this.resets101,
        largestComeback: largestComeback ?? this.largestComeback,
        currentStreak: currentStreak ?? this.currentStreak,
        bestStreak: bestStreak ?? this.bestStreak,
        suitCounts: suitCounts ?? this.suitCounts,
        unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
        dailyChallengesCompleted:
            dailyChallengesCompleted ?? this.dailyChallengesCompleted,
        lastDailyChallenge: lastDailyChallenge ?? this.lastDailyChallenge,
      );

  Map<String, dynamic> toJson() => {
        'matchesPlayed': matchesPlayed,
        'matchesWon': matchesWon,
        'roundsWon': roundsWon,
        'roundsPlayed': roundsPlayed,
        'cardsPlayed': cardsPlayed,
        'acesPlayed': acesPlayed,
        'twosPlayed': twosPlayed,
        'longestChain': longestChain,
        'resets101': resets101,
        'largestComeback': largestComeback,
        'currentStreak': currentStreak,
        'bestStreak': bestStreak,
        'suitCounts': suitCounts,
        'unlockedAchievements': unlockedAchievements,
        'dailyChallengesCompleted': dailyChallengesCompleted,
        'lastDailyChallenge': lastDailyChallenge,
      };

  factory StatisticsModel.fromJson(Map<String, dynamic> json) {
    int i(String key) => (json[key] as num?)?.toInt() ?? 0;
    return StatisticsModel(
      matchesPlayed: i('matchesPlayed'),
      matchesWon: i('matchesWon'),
      roundsWon: i('roundsWon'),
      roundsPlayed: i('roundsPlayed'),
      cardsPlayed: i('cardsPlayed'),
      acesPlayed: i('acesPlayed'),
      twosPlayed: i('twosPlayed'),
      longestChain: i('longestChain'),
      resets101: i('resets101'),
      largestComeback: i('largestComeback'),
      currentStreak: i('currentStreak'),
      bestStreak: i('bestStreak'),
      suitCounts: ((json['suitCounts'] as Map?) ?? const {})
          .map((k, v) => MapEntry(k as String, (v as num).toInt())),
      unlockedAchievements:
          (json['unlockedAchievements'] as List?)?.whereType<String>().toList() ??
              const [],
      dailyChallengesCompleted: i('dailyChallengesCompleted'),
      lastDailyChallenge: i('lastDailyChallenge'),
    );
  }
}
