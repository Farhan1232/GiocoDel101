/// Whether the app has an online backend at all.
///
/// Session 1 ships no networking, so this is deliberately a hard-coded
/// [BackendAvailability.notConfigured]. Every online screen reads it and says
/// plainly that the service is not connected yet, rather than showing invented
/// rooms, opponents or scores. Session 3 replaces the constant with a real
/// Supabase-backed check; nothing in the presentation layer has to change.
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

  /// The single place the app decides whether online play exists.
  ///
  /// Hard-coded until Session 3 wires Supabase. Keep it a constant: an
  /// optimistic default here is what turns a shell into a lie.
  static const BackendAvailability availability =
      BackendAvailability.notConfigured;

  static bool get isConfigured =>
      availability != BackendAvailability.notConfigured;
}
