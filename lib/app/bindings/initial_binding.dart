import 'package:get/get.dart';

import '../../features/auth/application/session_controller.dart';
import '../../features/profile/application/profile_controller.dart';
import '../../features/settings/application/settings_controller.dart';
import '../../features/profile/application/stats_controller.dart';
import '../../core/storage/game_storage_service.dart';
import '../../core/storage/local_storage.dart';
import '../../core/storage/settings_storage.dart';
import '../../core/storage/statistics_storage.dart';
import 'backend_services.dart';

/// Wires the long-lived singletons.
///
/// [backend] defaults to [BackendServices.none] — no client, no tokens, no
/// network — which is exactly what the tests run on. `main.dart` passes the
/// Supabase-backed set once the client has initialised.
class InitialBinding extends Bindings {
  InitialBinding(this.storage, {BackendServices? backend})
    : backend = backend ?? BackendServices.none();

  final LocalStorage storage;
  final BackendServices backend;

  @override
  void dependencies() {
    Get.put<LocalStorage>(storage, permanent: true);
    Get.put<GameStorageService>(GameStorageService(storage), permanent: true);
    Get.put<BackendServices>(backend, permanent: true);

    final settings = Get.put<SettingsController>(
      SettingsController(SettingsStorage(storage)),
      permanent: true,
    );
    Get.put<StatsController>(
      StatsController(StatisticsStorage(storage), settings),
      permanent: true,
    );

    final session = Get.put<SessionController>(
      SessionController(backend.auth),
      permanent: true,
    );
    Get.put<ProfileController>(
      ProfileController(backend.profiles, session),
      permanent: true,
    );
  }
}
