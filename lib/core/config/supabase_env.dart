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

  /// Where Supabase sends the player back after a password-reset email.
  ///
  /// It has to be three things at once: an entry in the project's redirect
  /// allow-list (`supabase/config.toml`, `auth.additional_redirect_urls`), a
  /// scheme the Android manifest and the iOS URL types claim, and a URL the
  /// phone will hand to this app rather than to a browser. A custom scheme is
  /// all three. Overridable at build time so the owner can point the link at
  /// a web page later without a code change.
  static const String passwordResetRedirect = String.fromEnvironment(
    'SUPABASE_PASSWORD_RESET_REDIRECT',
    defaultValue: 'it.giocodel101://reset-password',
  );

  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;
}
