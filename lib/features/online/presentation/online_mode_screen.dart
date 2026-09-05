import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/app_panel.dart';
import '../../../core/widgets/network_banner.dart';
import '../../../core/widgets/screen_scaffold.dart';
import '../../../core/widgets/premium_button.dart';
import '../../auth/application/session_controller.dart';
import '../../settings/application/settings_controller.dart';
import '../domain/online_status.dart';

/// §H — the three ways into an online game.
class OnlineModeScreen extends StatelessWidget {
  const OnlineModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = Strings.s;
    final settings = Get.find<SettingsController>();
    final session = Get.find<SessionController>();

    return ScreenScaffold(
      title: s.onlineTitle,
      banner: OnlineStatus.isConfigured
          ? null
          : NetworkStatusBanner(
              status: NetworkStatus.offline,
              connectingLabel: s.networkReconnecting,
              offlineLabel: s.commonComingSoon,
            ),
      child: Obx(() {
        final accent = settings.theme.accent;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.lg),
            _Option(
              icon: AppIcon.play,
              title: s.homeQuickMatch,
              subtitle: s.onlineQuickMatchHint,
              accent: accent,
              onTap: () => Get.toNamed<void>(AppRoutes.matchmaking),
            ),
            const SizedBox(height: AppSpacing.md),
            _Option(
              icon: AppIcon.players,
              title: s.homeCreateRoom,
              subtitle: s.onlineCreateRoomHint,
              accent: AppColors.mediterraneanTeal,
              onTap: () => Get.toNamed<void>(AppRoutes.createRoom),
            ),
            const SizedBox(height: AppSpacing.md),
            _Option(
              icon: AppIcon.cards,
              title: s.homeJoinRoom,
              subtitle: s.onlineJoinRoomHint,
              accent: AppColors.terracottaCoral,
              onTap: () => Get.toNamed<void>(AppRoutes.joinRoom),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (!OnlineStatus.isConfigured)
              Text(
                s.authBackendPending,
                style: AppText.caption,
                textAlign: TextAlign.center,
              )
            else if (!session.isSignedIn) ...[
              Text(
                s.onlineSignInRequired,
                style: AppText.caption,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              PremiumButton(
                label: s.authSignIn,
                variant: ButtonVariant.secondary,
                size: ButtonSize.medium,
                onPressed: () => Get.toNamed<void>(AppRoutes.authLanding),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
          ],
        );
      }),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  final AppIcon icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      excludeSemantics: true,
      child: AppPanel(
        onTap: onTap,
        accent: accent,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.16),
                border: Border.all(color: accent.withValues(alpha: 0.5)),
              ),
              child: Center(child: AppIconView(icon, size: 20, color: accent)),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppText.button.copyWith(
                      fontSize: 15,
                      letterSpacing: 1.6,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(subtitle, style: AppText.caption),
                ],
              ),
            ),
            const AppIconView(
              AppIcon.chevronDown,
              size: 16,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
