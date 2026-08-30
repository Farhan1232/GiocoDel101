import 'dart:async';

import 'package:get/get.dart';

import '../../../app/bindings/backend_services.dart';
import '../../auth/application/session_controller.dart';
import '../../online/domain/online_status.dart';
import '../../profile/application/profile_controller.dart';
import '../../profile/application/stats_controller.dart';
import '../domain/mission.dart';
import 'missions_repository.dart';

/// Today's missions, both halves.
///
/// * **Offline** rows come from [StatsController]: counted on this device
///   from the person's own plays at the local table, rewarded with local XP.
/// * **Online** rows come from the server: progress the server observed in
///   online matches, claimable for profile XP under the server's clock.
///
/// The two are shown side by side and never mixed: an offline win cannot
/// complete an online mission, and vice versa.
class MissionsController extends GetxController {
  MissionsController(
    this._stats,
    this._repository,
    this._session, [
    this._profile,
  ]);

  final StatsController _stats;
  final MissionsRepository _repository;
  final SessionController _session;
  final ProfileController? _profile;

  final RxList<MissionProgress> online = <MissionProgress>[].obs;
  final RxBool loadingOnline = false.obs;
  final RxBool onlineFailed = false.obs;
  Worker? _sessionWorker;

  static MissionsController ensure() {
    if (Get.isRegistered<MissionsController>()) {
      return Get.find<MissionsController>();
    }
    return Get.put(
      MissionsController(
        Get.find<StatsController>(),
        Get.find<BackendServices>().missions,
        Get.find<SessionController>(),
        Get.isRegistered<ProfileController>()
            ? Get.find<ProfileController>()
            : null,
      ),
      permanent: true,
    );
  }

  bool get canUseOnline => OnlineStatus.isConfigured && _session.isSignedIn;

  /// Today's offline missions, live from the local record.
  List<MissionProgress> get offline => _stats.todayMissions();

  /// What the home card counts: online rows when signed in, plus offline.
  List<MissionProgress> get visible => [
    if (canUseOnline) ...online,
    ...offline.where((m) => !m.mission.key.isOnlineOnly),
  ];

  int get claimableCount => visible.where((m) => m.claimable).length;

  @override
  void onInit() {
    super.onInit();
    _sessionWorker = ever(_session.session, (_) => unawaited(reload()));
    unawaited(reload());
  }

  @override
  void onClose() {
    _sessionWorker?.dispose();
    super.onClose();
  }

  /// Re-reads both halves. (`refresh` is taken by GetxController.)
  Future<void> reload() async {
    // Touching the stats Rx re-reads the offline rows for any Obx.
    _stats.stats;
    if (!canUseOnline) {
      online.clear();
      onlineFailed.value = false;
      return;
    }
    loadingOnline.value = true;
    try {
      online.assignAll(await _repository.today());
      onlineFailed.value = false;
    } catch (_) {
      // Keep what we had; the screen offers a retry.
      onlineFailed.value = true;
    } finally {
      loadingOnline.value = false;
    }
  }

  /// Claims a mission. Offline rows are settled locally; online rows are
  /// settled by the server, which re-checks completion and the date.
  Future<bool> claim(MissionProgress row) async {
    if (!row.isOnline) {
      final ok = await _stats.claimOfflineMission(row.mission.key);
      update();
      return ok;
    }
    final id = row.remoteId;
    if (id == null) return false;
    final next = await _repository.claim(id);
    final i = online.indexWhere((m) => m.remoteId == id);
    if (i >= 0) online[i] = next;
    // The profile's XP moved on the server: show it.
    unawaited(_profile?.reload());
    return true;
  }
}
