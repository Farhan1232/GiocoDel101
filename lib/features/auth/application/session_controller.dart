import 'dart:async';

import 'package:get/get.dart';

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

  StreamSubscription<AuthSession?>? _sub;
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
    _sub = gateway.changes.listen((next) {
      final had = session.value != null;
      session.value = next;
      if (had && next == null && !_signingOut) expired.value = true;
    });
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

  Future<void> signOut() async {
    _signingOut = true;
    try {
      await gateway.signOut();
      session.value = null;
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
    super.onClose();
  }
}
