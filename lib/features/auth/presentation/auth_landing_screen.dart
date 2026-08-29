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
import '../../online/domain/online_status.dart';
import '../../settings/application/settings_controller.dart';
import '../application/session_controller.dart';
import '../domain/auth_session.dart';
import 'auth_error_copy.dart';

/// §C — the choice between playing now and having an account.
///
/// "Play as guest" creates a real anonymous Supabase user when a backend is
/// configured. If that fails the player is told why and still reaches the
/// offline game — signed out, with every online surface saying so.
///
/// The social buttons are drawn but explicitly inert: tapping one says so
/// rather than starting a flow that cannot finish.
class AuthLandingScreen extends StatefulWidget {
  const AuthLandingScreen({super.key});

  @override
  State<AuthLandingScreen> createState() => _AuthLandingScreenState();
}

class _AuthLandingScreenState extends State<AuthLandingScreen> {
  bool _busy = false;

  Future<void> _playAsGuest() async {
    if (_busy) return;
    if (!OnlineStatus.isConfigured) {
      await Get.offAllNamed<void>(AppRoutes.home);
      return;
    }
    setState(() => _busy = true);
    final session = Get.find<SessionController>();
    final outcome = session.isSignedIn
        ? AuthSuccess(session.current!)
        : await session.signInAsGuest();
    if (!mounted) return;
    setState(() => _busy = false);
    if (outcome is AuthFailed) {
      final s = Strings.s;
      await AppDialog.notice(
        title: s.authGuestFailed,
        body: s.authError(outcome.code),
        dismissLabel: s.gotIt,
      );
    }
    await Get.offAllNamed<void>(AppRoutes.home);
  }

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
              loading: _busy,
              onPressed: _playAsGuest,
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
