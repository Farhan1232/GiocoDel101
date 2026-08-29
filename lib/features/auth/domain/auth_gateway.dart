import 'dart:async';

import '../../online/domain/online_status.dart';
import 'auth_session.dart';

/// The authentication seam.
///
/// Controllers and screens only ever see this interface. The real
/// implementation wraps Supabase Auth; [NoBackendAuthGateway] is what the app
/// runs on when no credentials are compiled in (and what the widget tests
/// run on), so nothing ever pretends a sign-in succeeded.
abstract class AuthGateway {
  BackendAvailability get availability;

  /// The restored session at boot, or whatever it is now.
  AuthSession? get current;

  /// Emits every time the session changes (sign-in, sign-out, token refresh
  /// producing a different user).
  Stream<AuthSession?> get changes;

  Future<AuthOutcome> signUp({
    required String email,
    required String password,
    required String nickname,
    required String avatarId,
  });

  Future<AuthOutcome> signIn({required String email, required String password});

  Future<AuthOutcome> signInAsGuest();

  /// Sends the reset email. Deliberately does not reveal whether the address
  /// exists — the screen shows the same copy either way.
  Future<AuthOutcome> sendPasswordReset(String email);

  Future<void> signOut();
}

/// The gateway used when there is nothing to authenticate against.
class NoBackendAuthGateway implements AuthGateway {
  NoBackendAuthGateway();

  final StreamController<AuthSession?> _changes =
      StreamController<AuthSession?>.broadcast();

  @override
  BackendAvailability get availability => BackendAvailability.notConfigured;

  @override
  AuthSession? get current => null;

  @override
  Stream<AuthSession?> get changes => _changes.stream;

  static const AuthOutcome _unavailable = AuthFailed(AuthErrorCode.unavailable);

  @override
  Future<AuthOutcome> signUp({
    required String email,
    required String password,
    required String nickname,
    required String avatarId,
  }) async => _unavailable;

  @override
  Future<AuthOutcome> signIn({
    required String email,
    required String password,
  }) async => _unavailable;

  @override
  Future<AuthOutcome> signInAsGuest() async => _unavailable;

  @override
  Future<AuthOutcome> sendPasswordReset(String email) async => _unavailable;

  @override
  Future<void> signOut() async {}
}
