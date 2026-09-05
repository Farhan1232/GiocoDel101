import 'package:get/get.dart';

import '../../online/domain/online_status.dart';
import '../domain/auth_session.dart';
import '../domain/auth_validators.dart';
import 'session_controller.dart';

/// Holds the state of one auth form and runs its submit cycle.
///
/// The form hands in the call it wants made ([run]); this controller only
/// owns the button state and reports the real [AuthOutcome]. Without a
/// backend every call comes back [AuthErrorCode.unavailable] and the screen
/// says so — nothing is ever reported as a success that was not one.
class AuthController extends GetxController {
  AuthController(this.session);

  final SessionController session;

  final Rx<AuthFormStatus> status = AuthFormStatus.idle.obs;

  /// True while the app has no auth service at all.
  bool get backendMissing => !OnlineStatus.isConfigured;

  /// Runs [call] with the form disabled; returns exactly what the backend
  /// said, or `null` if a submit is already in flight.
  Future<AuthOutcome?> run(Future<AuthOutcome> Function() call) async {
    if (status.value == AuthFormStatus.submitting) return null;
    status.value = AuthFormStatus.submitting;
    final outcome = await call();
    status.value = switch (outcome) {
      AuthSuccess() => AuthFormStatus.succeeded,
      AuthNeedsConfirmation() => AuthFormStatus.succeeded,
      AuthFailed(code: AuthErrorCode.unavailable) => AuthFormStatus.unavailable,
      AuthFailed() => AuthFormStatus.failed,
    };
    return outcome;
  }

  void reset() => status.value = AuthFormStatus.idle;
}
