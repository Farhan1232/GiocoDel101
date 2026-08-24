import 'package:get/get.dart';

import '../models/daily_challenge.dart';
import '../services/daily_challenge_service.dart';
import '../storage/game_storage_service.dart';

/// Backs the home screen: whether a match is waiting, and what today's
/// challenge is.
class HomeController extends GetxController {
  HomeController(this._storage);

  final GameStorageService _storage;
  final DailyChallengeService _daily = const DailyChallengeService();

  final RxBool hasSavedMatch = false.obs;
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
  }
}
