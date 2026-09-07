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

  /// What happened when the app was opened through a password-reset link.
  ///
  /// [PasswordRecovery.ready] means the recovery session is live and the
  /// player may choose a new password; [PasswordRecovery.linkInvalid] means
  /// the link could not be redeemed and a fresh one is needed.
  Stream<PasswordRecovery> get passwordRecovery;

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

  /// Sets a new password on the account this device is currently
  /// authenticated as — the recovery session opened by a reset link, or an
  /// ordinary signed-in session. Returns the session that survives the
  /// change, so the player is never left holding a password the app has not
  /// confirmed.
  Future<AuthOutcome> updatePassword(String password);

  Future<void> signOut();

  /// Erases the signed-in account and everything it owns, then leaves the
  /// device signed out. Google Play requires an app that creates accounts to
  /// offer this from inside the app.
  Future<AccountDeletion> deleteAccount();
}

/// The outcome of opening a password-reset link.
enum PasswordRecovery {
  /// The link was redeemed: this device now holds a session that may set a
  /// new password.
  ready,

  /// The link could not be redeemed and never will be.
  linkInvalid,
}

/// The gateway used when there is nothing to authenticate against.
class NoBackendAuthGateway implements AuthGateway {
  NoBackendAuthGateway();

  final StreamController<AuthSession?> _changes =
      StreamController<AuthSession?>.broadcast();

  @override
  BackendAvailability get availability => BackendAvailability.notConfigured;

  @override
  Stream<PasswordRecovery> get passwordRecovery =>
      const Stream<PasswordRecovery>.empty();

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
  Future<AuthOutcome> updatePassword(String password) async => _unavailable;

  @override
  Future<void> signOut() async {}

  @override
  Future<AccountDeletion> deleteAccount() async => AccountDeletion.unavailable;
}
