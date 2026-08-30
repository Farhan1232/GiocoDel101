import 'package:get/get.dart';

import '../../achievements/domain/achievements_catalog.dart';
import '../../game/domain/game_card.dart';
import '../../game/domain/game_state.dart';
import '../../missions/domain/mission.dart';
import '../../game/domain/round_result.dart';
import '../domain/statistics_model.dart';
import '../../rewards/application/daily_challenge_service.dart';
import 'statistics_service.dart';
import '../../../core/storage/statistics_storage.dart';
import '../../settings/application/settings_controller.dart';

/// Lifetime statistics and achievements (§39, §41).
class StatsController extends GetxController {
  StatsController(this._storage, this._settings);

  final StatisticsStorage _storage;
  final SettingsController _settings;
  final StatisticsService _service = const StatisticsService();

  final Rx<StatisticsModel> _stats = const StatisticsModel().obs;

  /// Badges earned since the last time the UI drained this list, so a
  /// results screen can celebrate them.
  final RxList<String> pendingAchievements = <String>[].obs;

  StatisticsModel get stats => _stats.value;

  @override
  void onInit() {
    super.onInit();
    _stats.value = _storage.load();
  }

  Future<void> _commit(StatsUpdate update) async {
    _stats.value = update.stats;
    await _storage.save(update.stats);
    for (final id in update.newAchievements) {
      pendingAchievements.add(id);
      final achievement = AchievementsCatalog.byId(id);
      await _settings.unlock(
        themeId: achievement.unlocksThemeId,
        cardBackId: achievement.unlocksCardBackId,
      );
    }
  }

  Future<void> recordRound({
    required GameState match,
    required RoundResult result,
    required String humanId,
  }) => _commit(
    _service.applyRound(
      stats: stats,
      match: match,
      result: result,
      humanId: humanId,
    ),
  );

  Future<void> recordMatch({
    required GameState match,
    required String humanId,
  }) async {
    await _commit(
      _service.applyMatch(stats: stats, match: match, humanId: humanId),
    );
    await noteMissionEvent(MissionKey.playMatches);
    if (match.winnerId == humanId) {
      await noteMissionEvent(MissionKey.winMatch);
    }
    if (match.isDailyChallenge && match.winnerId == humanId) {
      await markDailyCompleted();
    }
  }

  // ------------------------------------------------------------ missions

  /// §V — the human's own play, as the table sees it happen. Counts only
  /// toward today's OFFLINE missions; online progress is the server's.
  Future<void> noteCardPlayed(GameCard card) async {
    if (card.isAce) await noteMissionEvent(MissionKey.playAces);
    if (card.isTwo) await noteMissionEvent(MissionKey.playTwos);
    if (card.isCavallo) await noteMissionEvent(MissionKey.useNine);
  }

  Future<void> noteChainBlocked() => noteMissionEvent(MissionKey.blockTwo);

  /// Adds [count] to today's offline counter for [key]. Counters from an
  /// earlier day are dropped first, so a mission never carries over.
  Future<void> noteMissionEvent(MissionKey key, {int count = 1}) async {
    if (key.isOnlineOnly) return;
    final today = MissionCatalog.dateKeyFor(_now());
    final fresh = stats.missionDateKey == today;
    final progress = Map<String, int>.of(
      fresh ? stats.missionProgress : const {},
    );
    progress.update(key.key, (v) => v + count, ifAbsent: () => count);
    final next = stats.copyWith(
      missionDateKey: today,
      missionProgress: progress,
      claimedMissions: fresh ? stats.claimedMissions : const [],
    );
    _stats.value = next;
    await _storage.save(next);
  }

  /// Today's offline missions with the local progress on each.
  List<MissionProgress> todayMissions() {
    final now = _now();
    final today = MissionCatalog.dateKeyFor(now);
    final fresh = stats.missionDateKey == today;
    return [
      for (final m in MissionCatalog.forDate(now))
        MissionProgress(
          mission: m,
          progress: fresh ? (stats.missionProgress[m.key.key] ?? 0) : 0,
          claimed: fresh && stats.claimedMissions.contains(m.id),
          isOnline: false,
        ),
    ];
  }

  /// Takes the offline XP for a completed mission. Returns false when the
  /// mission is not complete, already claimed, or not today's.
  Future<bool> claimOfflineMission(MissionKey key) async {
    final row = todayMissions().where((m) => m.mission.key == key);
    if (row.isEmpty || !row.first.claimable) return false;
    final next = stats.copyWith(
      xp: stats.xp + row.first.mission.rewardXp,
      claimedMissions: [...stats.claimedMissions, row.first.mission.id],
    );
    _stats.value = next;
    await _storage.save(next);
    return true;
  }

  /// Test hook: the clock the mission day is derived from.
  DateTime Function() clock = DateTime.now;
  DateTime _now() => clock();

  Future<void> markDailyCompleted() async {
    final key = DailyChallengeService.dateKeyFor(DateTime.now());
    if (stats.lastDailyChallenge == key) return;
    final next = stats.copyWith(
      lastDailyChallenge: key,
      dailyChallengesCompleted: stats.dailyChallengesCompleted + 1,
    );
    _stats.value = next;
    await _storage.save(next);
  }

  bool get dailyCompletedToday =>
      stats.lastDailyChallenge ==
      DailyChallengeService.dateKeyFor(DateTime.now());

  bool hasAchievement(String id) => stats.unlockedAchievements.contains(id);

  List<String> drainPendingAchievements() {
    final list = List<String>.of(pendingAchievements);
    pendingAchievements.clear();
    return list;
  }

  Future<void> resetAll() async {
    await _storage.reset();
    _stats.value = const StatisticsModel();
    pendingAchievements.clear();
  }
}
