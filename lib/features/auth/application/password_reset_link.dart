/// Remembers that the OS just handed the app a Supabase auth deep link.
///
/// `supabase_flutter` owns the incoming link: it consumes the URI, exchanges
/// the PKCE code and only then tells the app what happened. When the exchange
/// *fails* — an expired link, one already used, one opened on a phone that
/// never asked for the reset — all the app sees is a bare error on the auth
/// stream, which looks exactly like a token refresh that lost the network.
///
/// So the link is noted here as it arrives (from the detection predicate the
/// client is built with) and the note is spent by whoever explains the
/// outcome. Without it the player taps the link, the app opens, and nothing
/// at all is said.
class PasswordResetLink {
  const PasswordResetLink._();

  /// How long after a link arrives an auth error may still be blamed on it.
  /// The exchange is one HTTPS round trip; twenty seconds is generous.
  static const Duration window = Duration(seconds: 20);

  /// Injectable so tests need not wait, or sleep, for the window to pass.
  static DateTime Function() clock = DateTime.now;

  static DateTime? _arrivedAt;

  /// Called for every deep link the auth client is offered.
  static void observe() => _arrivedAt = clock();

  /// Whether a link arrived recently enough to explain an auth failure.
  static bool get isPending {
    final at = _arrivedAt;
    return at != null && clock().difference(at) < window;
  }

  /// Spends the note: the outcome has been reported, one way or the other.
  static void consume() => _arrivedAt = null;

  /// Test seam.
  static void reset() {
    _arrivedAt = null;
    clock = DateTime.now;
  }

  /// The default `supabase_flutter` heuristic, restated so the app can watch
  /// links pass without changing which ones the client acts on.
  ///
  /// Keep in step with `SupabaseAuth._defaultIsAuthCallbackDeeplink`; the
  /// package keeps it private, and `supabase_deep_link_test.dart` pins the
  /// behaviour either way.
  static bool isAuthCallback(Uri uri) {
    final fragment = Uri.splitQueryString(uri.fragment);
    bool has(String key) =>
        uri.queryParameters.containsKey(key) || fragment.containsKey(key);

    return has('access_token') ||
        has('code') ||
        has('error') ||
        has('error_code') ||
        has('error_description');
  }
}
