import 'dart:math';

import 'package:get/get.dart';

import 'game_controller.dart';
import 'table_controller.dart';
import '../../settings/application/settings_controller.dart';
import '../../profile/application/stats_controller.dart';
import '../domain/engine/game_session.dart';
import '../domain/game_state.dart';
import '../domain/match_factory.dart';
import '../../../core/storage/game_storage_service.dart';
import '../../../app/router/app_router.dart';

/// The one place a match is put on screen.
///
/// Registering the controller here (rather than inside a screen) means a
/// resumed match, a new match and a daily challenge all follow exactly the
/// same path.
class MatchLauncher {
  const MatchLauncher._();

  static void launch(MatchSetup setup, {bool replace = false}) {
    if (Get.isRegistered<TableController>()) {
      Get.delete<TableController>(force: true);
    }
    if (Get.isRegistered<GameController>()) {
      Get.delete<GameController>(force: true);
    }
    final controller = Get.put<GameController>(
      GameController(
        session: setup.session,
        storage: Get.find<GameStorageService>(),
        settings: Get.find<SettingsController>(),
        stats: Get.find<StatsController>(),
        humanIds: setup.humanIds,
        random: Random(),
      ),
      // `permanent`: a route-scoped registration is deleted the moment the
      // route it was created under is disposed. With `replace: true` that
      // route is the one being replaced — the launching screen — so the
      // driver would be closed ~300 ms into the match and the bots would
      // stop. The exit paths call [dismiss] instead.
      permanent: true,
    );
    // The screens depend on the contract, not on the local driver.
    Get.put<TableController>(controller, permanent: true);
    if (replace) {
      // Pop back to Home before pushing the new table. A plain `offNamed`
      // replaces only the result screen and leaves the *previous* `/game`
      // route mounted underneath — one whole retained table per "Rivincita",
      // which is exactly the long-session memory growth the client felt.
      Get.offNamedUntil<void>(
        AppRoutes.game,
        (route) => route.settings.name == AppRoutes.home,
      );
    } else {
      Get.toNamed<void>(AppRoutes.game);
    }
  }

  /// Tears the local driver down when the player leaves the table for good
  /// (exit, home from the result screen). A relaunch replaces it anyway.
  static void dismiss() {
    if (Get.isRegistered<TableController>()) {
      Get.delete<TableController>(force: true);
    }
    if (Get.isRegistered<GameController>()) {
      Get.delete<GameController>(force: true);
    }
  }

  /// Rebuilds a match from the saved snapshot. Returns false when the save
  /// is missing or unusable, in which case it has already been cleared.
  static bool resume() {
    final storage = Get.find<GameStorageService>();
    final GameState? saved = storage.load();
    if (saved == null || saved.isFinished) {
      storage.clear();
      return false;
    }
    final session = GameSession(saved);
    // A snapshot taken in the instant between rounds would otherwise restore
    // a table nobody can play. Deal the next round instead.
    if (session.state.status == GameStatus.roundOver) {
      session.startNextRound();
    }
    if (session.state.isFinished) {
      storage.clear();
      return false;
    }
    launch(MatchSetup(session, MatchFactory.humanIdsOf(saved)));
    return true;
  }
}
