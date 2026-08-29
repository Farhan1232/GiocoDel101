import 'package:get/get.dart';

import '../../features/settings/application/settings_controller.dart';
import '../../features/profile/application/stats_controller.dart';
import '../../core/storage/game_storage_service.dart';
import '../../core/storage/local_storage.dart';
import '../../core/storage/settings_storage.dart';
import '../../core/storage/statistics_storage.dart';

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
