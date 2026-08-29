import 'package:get/get.dart';

import '../../achievements/domain/achievements_catalog.dart';
import '../../game/domain/match_state.dart';
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
    required MatchState match,
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
    required MatchState match,
    required String humanId,
  }) async {
    await _commit(
      _service.applyMatch(stats: stats, match: match, humanId: humanId),
    );
    if (match.isDailyChallenge && match.matchWinnerId == humanId) {
      await markDailyCompleted();
    }
  }

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
