import 'dart:async';

import 'package:get/get.dart';

import '../../../core/utils/log.dart';
import '../domain/auth_gateway.dart';
import '../domain/auth_session.dart';

/// The one owner of "who is signed in".
///
/// Long-lived (registered in `InitialBinding`). Holds the restored session
/// from boot and follows every change the gateway reports. Screens read
/// [session]; the auth forms call the gateway through [AuthController].
class SessionController extends GetxController {
  SessionController(this.gateway);

  final AuthGateway gateway;

  final Rx<AuthSession?> session = Rx<AuthSession?>(null);

  /// Raised once when a session the player did not end goes away — a
  /// refresh token the server refused, an account deleted elsewhere. The
  /// app shell shows "Sessione scaduta" and lowers it again.
  final RxBool expired = false.obs;

  /// Set when the app is opened through a password-reset link — with the
  /// recovery session live, or with the news that the link is spent. The app
  /// shell reads it, acts on it, and lowers it again.
  final Rxn<PasswordRecovery> recovery = Rxn<PasswordRecovery>();

  StreamSubscription<AuthSession?>? _sub;
  StreamSubscription<PasswordRecovery>? _recoverySub;
  bool _signingOut = false;

  AuthSession? get current => session.value;
  bool get isSignedIn => session.value != null;
  bool get isGuest => session.value?.isGuest ?? false;
  bool get isPermanent => session.value?.isPermanent ?? false;

  @override
  void onInit() {
    super.onInit();
    // supabase_flutter restores the persisted session inside `initialize`,
    // so what the gateway reports here is the real restored state — the
    // splash never has to wait on a second round trip.
    session.value = gateway.current;
    _sub = gateway.changes.listen(
      (next) {
        final had = session.value != null;
        session.value = next;
        if (had && next == null && !_signingOut) expired.value = true;
      },
      // Supabase reports some failures — a refresh it could not make, a deep
      // link it could not redeem — as an error on this stream. It is not a
      // session change and must not become an unhandled one: the session
      // stands until the backend actually takes it away.
      onError: (Object error) => Log.d('auth: stream $error'),
    );
    _recoverySub = gateway.passwordRecovery.listen(
      (event) => recovery.value = event,
      onError: (Object error) => Log.d('auth: recovery stream $error'),
    );
  }

  Future<AuthOutcome> signUp({
    required String email,
    required String password,
    required String nickname,
    required String avatarId,
  }) => _adopt(
    gateway.signUp(
      email: email,
      password: password,
      nickname: nickname,
      avatarId: avatarId,
    ),
  );

  Future<AuthOutcome> signIn({
    required String email,
    required String password,
  }) => _adopt(gateway.signIn(email: email, password: password));

  Future<AuthOutcome> signInAsGuest() => _adopt(gateway.signInAsGuest());

  Future<AuthOutcome> sendPasswordReset(String email) =>
      gateway.sendPasswordReset(email);

  Future<AuthOutcome> updatePassword(String password) =>
      _adopt(gateway.updatePassword(password));

  Future<void> signOut() async {
    _signingOut = true;
    try {
      await gateway.signOut();
      session.value = null;
    } finally {
      _signingOut = false;
    }
  }

  /// Erases the account. On success nobody is signed in — and that is a
  /// deliberate sign-out, so the "session expired" notice must not fire.
  Future<AccountDeletion> deleteAccount() async {
    _signingOut = true;
    try {
      final result = await gateway.deleteAccount();
      if (result == AccountDeletion.done) session.value = null;
      return result;
    } finally {
      _signingOut = false;
    }
  }

  Future<AuthOutcome> _adopt(Future<AuthOutcome> call) async {
    final outcome = await call;
    if (outcome is AuthSuccess) session.value = outcome.session;
    return outcome;
  }

  @override
  void onClose() {
    _sub?.cancel();
    _recoverySub?.cancel();
    super.onClose();
  }
}
