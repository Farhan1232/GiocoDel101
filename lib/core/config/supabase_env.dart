/// Compile-time Supabase configuration.
///
/// Both values are injected with `--dart-define` / `--dart-define-from-file`
/// (see `docs/SUPABASE_SETUP.md`). They are the project URL and the
/// **publishable** key — public by design, safe inside a client. Nothing else
/// (service_role, database password, access tokens) is ever compiled in.
///
/// When either is empty the app runs fully offline and every online surface
/// says so; nothing here can turn a missing backend into a pretend one.
class SupabaseEnv {
  const SupabaseEnv._();

  static const String url = String.fromEnvironment('SUPABASE_URL');
  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;
}
