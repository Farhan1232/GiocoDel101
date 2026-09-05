import 'package:get/get.dart';

/// Whether the app has an online backend at all.
///
/// Session 1 hard-coded [BackendAvailability.notConfigured]. Session 3 keeps
/// the same single seam but makes it *observable*: [OnlineStatus.availability]
/// is set once at boot by the Supabase bootstrap, from a real
/// initialisation, and never guessed. Without compile-time credentials it stays
/// [BackendAvailability.notConfigured] and every online screen says so.
enum BackendAvailability {
  /// No backend credentials are compiled in. The UI is fully navigable and
  /// every action that would need the network explains why it cannot run.
  notConfigured,

  /// Configured and reachable.
  ready,

  /// Configured but currently unreachable.
  unreachable,
}

class OnlineStatus {
  const OnlineStatus._();

  static final Rx<BackendAvailability> _availability =
      BackendAvailability.notConfigured.obs;

  /// The single place the app decides whether online play exists.
  static BackendAvailability get availability => _availability.value;

  /// Reactive form, for `Obx` builders.
  static Rx<BackendAvailability> get rx => _availability;

  static bool get isConfigured =>
      availability != BackendAvailability.notConfigured;

  static bool get isReady => availability == BackendAvailability.ready;

  /// Called by the backend bootstrap with what it actually observed.
  static void report(BackendAvailability value) => _availability.value = value;

  /// Test hook: back to the no-backend state.
  static void reset() =>
      _availability.value = BackendAvailability.notConfigured;
}
