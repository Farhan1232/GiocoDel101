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
}
