import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/application/password_reset_link.dart';
import '../config/supabase_env.dart';
import '../utils/log.dart';

/// Initialises the Supabase client once, before the first frame.
///
/// Returns `null` when no credentials are compiled in, or when initialisation
/// fails — in both cases the caller falls back to the no-backend gateway and
/// the app runs offline, honestly. Session restore happens inside
/// [Supabase.initialize] (persisted with the platform's secure/local storage),
/// so `client.auth.currentSession` is already the restored session on return.
class SupabaseBootstrap {
  const SupabaseBootstrap._();

  static Future<SupabaseClient?> initialize() async {
    if (!SupabaseEnv.isConfigured) return null;
    try {
      final supabase = await Supabase.initialize(
        url: SupabaseEnv.url,
        publishableKey: SupabaseEnv.publishableKey,
        authOptions: FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
          // The client still decides which links it acts on — this only lets
          // the app see one go past, so a reset link that fails to exchange
          // can be explained instead of silently doing nothing.
          detectSessionInUriPredicate: (uri) {
            final isCallback = PasswordResetLink.isAuthCallback(uri);
            if (isCallback) PasswordResetLink.observe();
            return isCallback;
          },
        ),
        debug: false,
      );
      return supabase.client;
    } catch (error) {
      Log.d('supabase: initialise failed: $error');
      return null;
    }
  }
}
