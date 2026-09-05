import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/app_panel.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/screen_scaffold.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/xp_bar.dart';
import '../../online/domain/online_status.dart';
import '../../settings/application/settings_controller.dart';
import '../application/missions_controller.dart';
import '../application/missions_repository.dart';
import '../domain/mission.dart';

/// §V — today's missions, online and offline, each with its own reward.
class MissionsScreen extends StatelessWidget {
  const MissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = Strings.s;
    final settings = Get.find<SettingsController>();
    final c = MissionsController.ensure();

    return ScreenScaffold(
      title: s.missionsTitle,
      child: Obx(() {
        final accent = settings.theme.accent;
        c.online.length; // subscribe
        final offline = c.offline;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.md),
            Text(
              s.missionsCycleHint,
              style: AppText.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            SectionHeading(s.missionsOnline.toUpperCase()),
            const SizedBox(height: AppSpacing.sm),
            _onlineSection(c, s, accent),
            const SizedBox(height: AppSpacing.lg),
            SectionHeading(s.missionsOffline.toUpperCase()),
            const SizedBox(height: AppSpacing.sm),
            if (offline.isEmpty)
              Text(s.missionsEmpty, style: AppText.caption)
            else
              for (final row in offline) ...[
                _MissionTile(row: row, accent: accent, onClaim: c.claim),
                const SizedBox(height: AppSpacing.sm),
              ],
            const SizedBox(height: AppSpacing.xl),
          ],
        );
      }),
    );
  }

  Widget _onlineSection(
    MissionsController c,
    AppLocalizations s,
    Color accent,
  ) {
    if (!c.canUseOnline) {
      return AppPanel(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              OnlineStatus.isConfigured
                  ? s.missionsSignInHint
                  : s.authBackendPending,
              style: AppText.caption,
              textAlign: TextAlign.center,
            ),
            if (OnlineStatus.isConfigured) ...[
              const SizedBox(height: AppSpacing.sm),
              PremiumButton(
                label: s.authSignIn,
                variant: ButtonVariant.secondary,
                size: ButtonSize.small,
                onPressed: () => Get.toNamed<void>(AppRoutes.authLanding),
              ),
            ],
          ],
        ),
      );
    }
    if (c.loadingOnline.value && c.online.isEmpty) {
      return SizedBox(height: 96, child: LoadingView(accent: accent));
    }
    if (c.onlineFailed.value && c.online.isEmpty) {
      return ErrorView(
        title: s.commonErrorTitle,
        message: s.missionsLoadFailed,
        retryLabel: s.commonRetry,
        onRetry: c.reload,
      );
    }
    if (c.online.isEmpty) {
      return Text(s.missionsEmpty, style: AppText.caption);
    }
    return Column(
      children: [
        for (final row in c.online) ...[
          _MissionTile(
            row: row,
            accent: accent,
            onClaim: (r) async {
              try {
                return await c.claim(r);
              } on MissionsException catch (e) {
                await AppDialog.notice(
                  title: s.commonErrorTitle,
                  body: switch (e.error) {
                    MissionsError.alreadyClaimed => s.missionsClaimed,
                    _ => s.missionsClaimFailed,
                  },
                  dismissLabel: s.gotIt,
                );
                await c.reload();
                return false;
              }
            },
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _MissionTile extends StatelessWidget {
  const _MissionTile({
    required this.row,
    required this.accent,
    required this.onClaim,
  });

  final MissionProgress row;
  final Color accent;
  final Future<bool> Function(MissionProgress) onClaim;

  @override
  Widget build(BuildContext context) {
    final s = Strings.s;
    final m = row.mission;
    final title = s.missionTitle(m);
    final onlineOnlyOffline = !row.isOnline && m.key.isOnlineOnly;
    return AppPanel(
      accent: row.claimable ? AppColors.goldLight : accent,
      tintStrength: row.claimed ? 0.35 : 1,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Semantics(
        label:
            '$title. ${row.clamped}/${m.target}. ${s.missionsReward(m.rewardXp)}',
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppText.body.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  XpBar(
                    progress: row.fraction,
                    accent: row.completed ? AppColors.goldLight : accent,
                    height: 7,
                    caption: onlineOnlyOffline
                        ? s.missionsOnlineOnly
                        : '${row.clamped}/${m.target} · ${s.missionsReward(m.rewardXp)}',
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            if (row.claimed)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppIconView(
                    AppIcon.check,
                    size: 14,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    s.missionsClaimed,
                    style: AppText.caption.copyWith(color: AppColors.success),
                  ),
                ],
              )
            else
              SizedBox(
                width: 112,
                child: PremiumButton(
                  label: s.missionsClaim,
                  size: ButtonSize.small,
                  accent: AppColors.goldLight,
                  onPressed: row.claimable ? () => onClaim(row) : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Mission copy, resolved from the ARB plural forms.
extension MissionCopy on AppLocalizations {
  String missionTitle(Mission m) => switch (m.key) {
    MissionKey.playMatches => missionPlayMatches(m.target),
    MissionKey.winMatch => missionWinMatch(m.target),
    MissionKey.playAces => missionPlayAces(m.target),
    MissionKey.playTwos => missionPlayTwos(m.target),
    MissionKey.useNine => missionUseNine(m.target),
    MissionKey.blockTwo => missionBlockTwo(m.target),
    MissionKey.onlineMatch => missionOnlineMatch(m.target),
  };
}
