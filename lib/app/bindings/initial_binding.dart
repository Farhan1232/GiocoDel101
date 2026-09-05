import 'package:get/get.dart';

import '../../features/auth/application/session_controller.dart';
import '../../features/profile/application/profile_controller.dart';
import '../../features/purchases/application/purchase_controller.dart';
import '../../features/purchases/application/purchase_store.dart';
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
  InitialBinding(this.storage, {BackendServices? backend, PurchaseStore? store})
    : backend = backend ?? BackendServices.none(),
      purchaseStore = store ?? const UnavailablePurchaseStore();

  final LocalStorage storage;
  final BackendServices backend;

  /// The real store on Android/iOS (`main.dart` passes it); the honest
  /// "no store here" everywhere else, tests included.
  final PurchaseStore purchaseStore;

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
    // Permanent so the store's purchase stream has one subscriber for the
    // app's whole life — a pending payment can clear while any screen is up.
    final purchases = Get.put<PurchaseController>(
      PurchaseController(
        store: purchaseStore,
        entitlements: backend.entitlements,
      ),
      permanent: true,
    );
    // Paid cosmetics unlock on the server's word: settings asks the purchase
    // stack, and a change in ownership re-derives what is selectable.
    settings.entitlementCheck = purchases.owns;
    ever(purchases.owned, (_) => settings.refreshCosmetics());
  }
}
