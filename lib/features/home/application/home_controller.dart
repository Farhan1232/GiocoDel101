import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../online/application/online_match_repository.dart';
import '../../rewards/domain/daily_challenge.dart';
import '../../rewards/application/daily_challenge_service.dart';
import '../../../core/storage/game_storage_service.dart';

/// Backs the home screen: whether a match is waiting, and what today's
/// challenge is.
class HomeController extends GetxController {
  HomeController(this._storage, {OnlineMatchRepository? matches})
    : _matches = matches ?? const NoBackendOnlineMatchRepository();

  final GameStorageService _storage;
  final OnlineMatchRepository _matches;
  final DailyChallengeService _daily = const DailyChallengeService();

  final RxBool hasSavedMatch = false.obs;

  /// An in-progress ONLINE match this account is seated at (server-side
  /// truth, refreshed with the home screen). Null when there is none.
  final Rx<String?> activeOnlineMatchId = Rx<String?>(null);
  late final DailyChallenge challenge = _daily.today();

  @override
  void onInit() {
    super.onInit();
    refreshSavedMatch();
  }

  /// Re-checked every time the home screen comes back into view, so the
  /// "Riprendi Partita" card never lies (§25).
  void refreshSavedMatch() {
    hasSavedMatch.value = _storage.hasSavedMatch && _storage.load() != null;
    refreshOnlineMatch();
  }

  /// Asks the server whether this account is seated at a live match, so
  /// "Rientra nella partita" appears after a restart or a crash.
  Future<void> refreshOnlineMatch() async {
    if (_matches.currentUserId == null) {
      activeOnlineMatchId.value = null;
      return;
    }
    final id = await _matches.activeMatchId();
    debugPrint('home: active online match = $id');
    activeOnlineMatchId.value = id;
  }
}
