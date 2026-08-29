import '../../settings/domain/settings_model.dart';
import 'statistics_model.dart';

/// Everything the Profile screen draws, in one value object.
///
/// The counters are real: they come from the local [StatisticsModel] the
/// offline game already keeps. Level and experience are a **local placeholder**
/// — the app has no progression service yet, so [level] and [xpIntoLevel] are
/// derived from matches played by a formula that lives here and nowhere else.
/// When the backend owns progression, replace [ProfileSummary.fromLocal] and
/// no widget changes.
class ProfileSummary {
  const ProfileSummary({
    required this.nickname,
    required this.avatarId,
    required this.level,
    required this.xpIntoLevel,
    required this.xpForLevel,
    required this.matchesPlayed,
    required this.matchesWon,
    required this.roundsWon,
    required this.currentStreak,
    required this.bestStreak,
    required this.resets101,
    required this.longestChain,
    required this.largestComeback,
    this.isPlaceholderProgression = true,
  });

  final String nickname;
  final String avatarId;

  final int level;

  /// Experience earned inside the current level, and the size of that level.
  final int xpIntoLevel;
  final int xpForLevel;

  final int matchesPlayed;
  final int matchesWon;
  final int roundsWon;
  final int currentStreak;
  final int bestStreak;

  /// The three "101" figures the brief asks the profile to surface.
  final int resets101;
  final int longestChain;
  final int largestComeback;

  /// True while level/XP are the local formula rather than server progression.
  final bool isPlaceholderProgression;

  int get matchesLost => (matchesPlayed - matchesWon).clamp(0, matchesPlayed);

  int get winPercentage =>
      matchesPlayed == 0 ? 0 : ((matchesWon / matchesPlayed) * 100).round();

  double get levelProgress =>
      xpForLevel == 0 ? 0 : (xpIntoLevel / xpForLevel).clamp(0.0, 1.0);

  /// Every match is worth some experience, a win rather more. Levels get
  /// steadily longer so the bar keeps moving early and slows down later.
  static const int _xpPerMatch = 20;
  static const int _xpPerWin = 45;
  static const int _baseLevelCost = 120;
  static const int _levelCostStep = 40;

  factory ProfileSummary.fromLocal(
    SettingsModel settings,
    StatisticsModel stats,
  ) {
    var xp = stats.matchesPlayed * _xpPerMatch + stats.matchesWon * _xpPerWin;
    var level = 1;
    var cost = _baseLevelCost;
    while (xp >= cost) {
      xp -= cost;
      level++;
      cost += _levelCostStep;
    }
    return ProfileSummary(
      nickname: settings.playerName,
      avatarId: settings.avatarId,
      level: level,
      xpIntoLevel: xp,
      xpForLevel: cost,
      matchesPlayed: stats.matchesPlayed,
      matchesWon: stats.matchesWon,
      roundsWon: stats.roundsWon,
      currentStreak: stats.currentStreak,
      bestStreak: stats.bestStreak,
      resets101: stats.resets101,
      longestChain: stats.longestChain,
      largestComeback: stats.largestComeback,
    );
  }
}
