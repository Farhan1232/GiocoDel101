import 'package:get/get.dart';

import '../../../app/bindings/backend_services.dart';
import '../../../app/router/app_router.dart';
import '../../auth/application/session_controller.dart';
import '../../game/application/game_controller.dart';
import '../../game/application/table_controller.dart';
import '../domain/online_match_models.dart';
import 'online_match_controller.dart';
import '../../../core/utils/log.dart';

/// Puts an online match on screen — from a lobby start, a quick match, a
/// rematch, or "Rientra nella partita" after a restart. Always the same
/// path: read the authoritative snapshot first, then build the driver.
class OnlineMatchLauncher {
  const OnlineMatchLauncher._();

  /// Tears down the online driver (timers, heartbeat, channels). Called when
  /// the player leaves the table and before a new match is launched.
  static void dismiss() {
    if (Get.isRegistered<TableController>() &&
        Get.find<TableController>() is OnlineMatchController) {
      Get.delete<TableController>(force: true);
    }
    if (Get.isRegistered<OnlineMatchController>()) {
      Get.delete<OnlineMatchController>(force: true);
    }
  }

  static Future<void> launch(String matchId, {bool replace = false}) async {
    final backend = Get.find<BackendServices>();
    final userId = Get.find<SessionController>().current?.userId;
    if (userId == null) throw const OnlineException(OnlineError.notSignedIn);
    final snapshot = await backend.matches.snapshot(matchId);
    Log.d('online-match: launch $matchId snapshot v${snapshot.version}');

    dismiss();
    if (Get.isRegistered<GameController>()) {
      Get.delete<GameController>(force: true);
    }
    if (Get.isRegistered<TableController>()) {
      // A stale local or tutorial registration left behind by another exit
      // path. It must go now: `Get.put` keeps the existing instance when the
      // key is occupied, so the online driver below would run with sockets
      // and timers live but never reach the screen — and never be dismissed.
      Get.delete<TableController>(force: true);
    }
    // `permanent`: the launch replaces the lobby route, and GetX would
    // otherwise delete a route-scoped controller the moment that route is
    // popped — with the table still on screen. [dismiss] is the explicit
    // end of life instead.
    final controller = Get.put<OnlineMatchController>(
      OnlineMatchController(
        repository: backend.matches,
        matchId: matchId,
        initial: snapshot,
        userId: userId,
      ),
      permanent: true,
    );
    Get.put<TableController>(controller, permanent: true);
    if (replace) {
      Get.offNamedUntil<void>(
        AppRoutes.game,
        (route) => route.settings.name == AppRoutes.home,
      );
    } else {
      await Get.toNamed<void>(AppRoutes.game);
    }
  }
}
