import 'dart:math';

import 'package:get/get.dart';

import 'game_controller.dart';
import '../../settings/application/settings_controller.dart';
import '../../profile/application/stats_controller.dart';
import '../domain/engine/game_engine.dart';
import '../domain/match_factory.dart';
import '../domain/match_state.dart';
import '../domain/round_state.dart';
import '../../../core/storage/game_storage_service.dart';
import '../../../app/router/app_router.dart';

/// The one place a match is put on screen.
///
/// Registering the controller here (rather than inside a screen) means a
/// resumed match, a new match and a daily challenge all follow exactly the
/// same path (§49, §64).
class MatchLauncher {
  const MatchLauncher._();

  static void launch(MatchSetup setup, {bool replace = false}) {
    if (Get.isRegistered<GameController>()) {
      Get.delete<GameController>(force: true);
    }
    Get.put<GameController>(
      GameController(
        engine: setup.engine,
        storage: Get.find<GameStorageService>(),
        settings: Get.find<SettingsController>(),
        stats: Get.find<StatsController>(),
        humanIds: setup.humanIds,
        random: Random(),
      ),
      permanent: false,
    );
    if (replace) {
      Get.offNamed<void>(AppRoutes.game);
    } else {
      Get.toNamed<void>(AppRoutes.game);
    }
  }

  /// §49 — rebuilds a match from the saved snapshot. Returns false when the
  /// save is missing or unusable, in which case it has already been cleared.
  static bool resume() {
    final storage = Get.find<GameStorageService>();
    final MatchState? saved = storage.load();
    if (saved == null || saved.matchOver) {
      storage.clear();
      return false;
    }
    final engine = GameEngine.fromState(saved);
    // §52 — a snapshot taken in the instant between rounds would otherwise
    // restore a table nobody can play. Deal the next round instead.
    if (engine.round.phase == TurnPhase.roundOver) {
      engine.startNextRound();
    }
    if (engine.state.matchOver) {
      storage.clear();
      return false;
    }
    launch(MatchSetup(engine, MatchFactory.humanIdsOf(saved)));
    return true;
  }
}
