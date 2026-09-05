import 'package:flutter/material.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/screen_scaffold.dart';
import '../application/auth_controller.dart';
import '../domain/auth_session.dart';
import 'auth_error_copy.dart';

/// Shared chrome for the three credential forms.
///
/// Also owns the one honest message the whole feature depends on: when a form
/// validates and submits, whatever the backend answered is what the player is
/// told — a failure by name, "check your email", or nothing at all when there
/// is no auth service.
class AuthFormScaffold extends StatelessWidget {
  const AuthFormScaffold({
    super.key,
    required this.title,
    required this.intro,
    required this.child,
  });

  final String title;
  final String? intro;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.lg),
          if (intro != null) ...[
            Text(intro!, style: AppText.bodySmall, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xl),
          ],
          child,
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  /// Validates, runs [action], and reports the outcome truthfully.
  ///
  /// [onSuccess] runs for a real session; [onConfirmation] when the backend
  /// accepted the request but needs the player to act on an email first.
  static Future<void> submit({
    required GlobalKey<FormState> formKey,
    required AuthController auth,
    required Future<AuthOutcome> Function() action,
    Future<void> Function(AuthSuccess outcome)? onSuccess,
    Future<void> Function(AuthNeedsConfirmation outcome)? onConfirmation,
  }) async {
    final form = formKey.currentState;
    if (form == null || !form.validate()) return;

    final outcome = await auth.run(action);
    if (outcome == null) return;
    final s = Strings.s;

    switch (outcome) {
      case AuthSuccess():
        await onSuccess?.call(outcome);
      case AuthNeedsConfirmation():
        await onConfirmation?.call(outcome);
      case AuthFailed(code: AuthErrorCode.unavailable):
        await AppDialog.notice(
          title: s.commonErrorTitle,
          body: s.authBackendPending,
          dismissLabel: s.gotIt,
        );
        auth.reset();
      case AuthFailed(:final code):
        await AppDialog.notice(
          title: s.commonErrorTitle,
          body: s.authError(code),
          dismissLabel: s.gotIt,
        );
        auth.reset();
    }
  }
}
