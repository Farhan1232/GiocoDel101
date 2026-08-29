import 'package:flutter/material.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/screen_scaffold.dart';
import '../application/auth_controller.dart';
import '../domain/auth_validators.dart';

/// Shared chrome for the three credential forms.
///
/// Also owns the one honest message the whole feature depends on: when a form
/// validates and submits, and there is no auth service, the player is told
/// exactly that.
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

  /// Validates, submits, and reports the outcome truthfully.
  static Future<void> submit({
    required GlobalKey<FormState> formKey,
    required AuthController auth,
  }) async {
    final form = formKey.currentState;
    if (form == null || !form.validate()) return;

    await auth.submit();
    if (auth.status.value == AuthFormStatus.unavailable) {
      final s = Strings.s;
      await AppDialog.notice(
        title: s.commonComingSoon,
        body: s.authBackendPending,
        dismissLabel: s.gotIt,
      );
      auth.reset();
    }
  }
}
