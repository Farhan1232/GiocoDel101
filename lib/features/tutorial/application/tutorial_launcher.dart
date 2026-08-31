import 'package:get/get.dart';

import '../../../app/router/app_router.dart';
import '../../game/application/game_controller.dart';
import '../../game/application/table_controller.dart';
import '../../settings/application/settings_controller.dart';
import '../domain/tutorial_lessons.dart';
import 'tutorial_controller.dart';

/// Puts the guided table on screen, the same way [MatchLauncher] seats a
/// match: the driver is registered as the [TableController] the table
/// draws from, then the tutorial route (the table plus its overlay) opens.
class TutorialLauncher {
  const TutorialLauncher._();

  static void launch() {
    if (Get.isRegistered<TableController>()) {
      Get.delete<TableController>(force: true);
    }
    if (Get.isRegistered<GameController>()) {
      Get.delete<GameController>(force: true);
    }
    if (Get.isRegistered<TutorialController>()) {
      Get.delete<TutorialController>(force: true);
    }
    final settings = Get.find<SettingsController>().settings;
    final controller = Get.put<TutorialController>(
      TutorialController(
        seats: TutorialSeats(
          playerName: settings.playerName,
          avatarId: settings.avatarId,
        ),
      ),
      permanent: false,
    );
    Get.put<TableController>(controller, permanent: false);
    Get.toNamed<void>(AppRoutes.tutorial);
  }

  /// Tears the guided table down when the player leaves it for good. The
  /// registration is linked to whichever route was current at [launch] time
  /// (from Home that is the never-disposed home route), so leaving the
  /// tutorial must release it explicitly — otherwise its timers and session
  /// listener survive, and the stale [TableController] key silently blocks
  /// the next launcher's `Get.put`.
  static void dismiss() {
    if (Get.isRegistered<TableController>() &&
        Get.find<TableController>() is TutorialController) {
      Get.delete<TableController>(force: true);
    }
    if (Get.isRegistered<TutorialController>()) {
      Get.delete<TutorialController>(force: true);
    }
  }
}
