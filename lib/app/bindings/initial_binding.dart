import 'package:get/get.dart';

import '../../controllers/settings_controller.dart';
import '../../controllers/stats_controller.dart';
import '../../storage/game_storage_service.dart';
import '../../storage/local_storage.dart';
import '../../storage/settings_storage.dart';
import '../../storage/statistics_storage.dart';

/// Wires the long-lived singletons. Everything here is local: no clients,
/// no tokens, no network (§69).
class InitialBinding extends Bindings {
  InitialBinding(this.storage);

  final LocalStorage storage;

  @override
  void dependencies() {
    Get.put<LocalStorage>(storage, permanent: true);
    Get.put<GameStorageService>(GameStorageService(storage), permanent: true);

    final settings = Get.put<SettingsController>(
      SettingsController(SettingsStorage(storage)),
      permanent: true,
    );
    Get.put<StatsController>(
      StatsController(StatisticsStorage(storage), settings),
      permanent: true,
    );
  }
}
