import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/router/app_router.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/logo_101.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/screen_scaffold.dart';
import '../../settings/application/settings_controller.dart';

/// §C — the choice between playing now and having an account.
///
/// The social buttons are drawn but explicitly inert: tapping one says so
/// rather than starting a flow that cannot finish.
class AuthLandingScreen extends StatelessWidget {
  const AuthLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = Strings.s;
    final settings = Get.find<SettingsController>();

    return ScreenScaffold(
      showBack: Get.previousRoute.isNotEmpty,
      child: Obx(() {
        final accent = settings.theme.accent;
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: AppSpacing.xl),
            const LogoLockup(size: 84),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              s.authTitle,
              style: AppText.screenTitle.copyWith(fontSize: 21),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              s.authSubtitle,
              textAlign: TextAlign.center,
              style: AppText.bodySmall,
            ),
            const SizedBox(height: AppSpacing.xxl),
            PremiumButton(
              label: s.authPlayAsGuest,
              icon: AppIcon.play,
              accent: accent,
              onPressed: () => Get.offAllNamed<void>(AppRoutes.home),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(s.authGuestHint, style: AppText.caption),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: PremiumButton(
                    label: s.authSignIn,
                    variant: ButtonVariant.secondary,
                    size: ButtonSize.medium,
                    onPressed: () => Get.toNamed<void>(AppRoutes.login),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: PremiumButton(
                    label: s.authRegister,
                    variant: ButtonVariant.secondary,
                    size: ButtonSize.medium,
                    onPressed: () => Get.toNamed<void>(AppRoutes.signup),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            const PanelDivider(),
            const SizedBox(height: AppSpacing.md),
            _social(s.authContinueWithGoogle, s),
            const SizedBox(height: AppSpacing.sm),
            _social(s.authContinueWithApple, s),
            const SizedBox(height: AppSpacing.xl),
          ],
        );
      }),
    );
  }

  Widget _social(String label, AppLocalizations s) => PremiumButton(
    label: label,
    variant: ButtonVariant.ghost,
    size: ButtonSize.medium,
    onPressed: () => AppDialog.notice(
      title: label,
      body: s.authSocialUnavailable,
      dismissLabel: s.gotIt,
    ),
  );
}
