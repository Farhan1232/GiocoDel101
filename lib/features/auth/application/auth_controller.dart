import 'package:get/get.dart';

import '../../online/domain/online_status.dart';
import '../domain/auth_validators.dart';

/// Holds the state of the auth forms.
///
/// It deliberately has **no backend**. [submit] runs the same code path a real
/// sign-in will run — disable the form, await, re-enable — and then reports
/// [AuthFormStatus.unavailable], because no credential store is connected yet.
/// It never returns success, never stores a token and never pretends an
/// account exists. Session 3 replaces the body of [submit] with a Supabase
/// call; the screens do not change.
class AuthController extends GetxController {
  final Rx<AuthFormStatus> status = AuthFormStatus.idle.obs;

  /// True while the app has no auth service at all.
  bool get backendMissing => !OnlineStatus.isConfigured;

  /// Runs the submit cycle and reports what actually happened.
  ///
  /// Returns false in every case for now: there is nothing to authenticate
  /// against. Callers show [AuthController] copy explaining that.
  Future<bool> submit() async {
    if (status.value == AuthFormStatus.submitting) return false;
    status.value = AuthFormStatus.submitting;
    // A single frame of latency so the button's loading state is real rather
    // than theatrical; there is no request to wait on.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    status.value = AuthFormStatus.unavailable;
    return false;
  }

  void reset() => status.value = AuthFormStatus.idle;
}
