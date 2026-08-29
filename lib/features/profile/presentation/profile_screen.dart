import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/app_panel.dart';
import '../../../core/widgets/avatar_medallion.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/screen_scaffold.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/xp_bar.dart';
import '../../settings/application/settings_controller.dart';
import '../application/stats_controller.dart';
import '../domain/profile_summary.dart';

/// §P — who the player is, drawn entirely from a [ProfileSummary].
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = Strings.s;
    final settings = Get.find<SettingsController>();
    final stats = Get.find<StatsController>();

    return ScreenScaffold(
      title: s.profile,
      child: Obx(() {
        final accent = settings.theme.accent;
        final profile =
            ProfileSummary.fromLocal(settings.settings, stats.stats);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.lg),
            AppPanel(
              accent: accent,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  AvatarMedallion(
                    avatarId: profile.avatarId,
                    size: 88,
                    active: true,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    profile.nickname,
                    style: AppText.screenTitle.copyWith(fontSize: 20),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  XpBar(
                    progress: profile.levelProgress,
                    accent: accent,
                    label: s.profileLevelValue(profile.level),
                    caption: s.profileXpProgress(
                      profile.xpIntoLevel,
                      profile.xpForLevel,
                    ),
                  ),
                  if (profile.isPlaceholderProgression) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      s.commonComingSoon,
                      style: AppText.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SectionHeading(s.sectionStatistics),
            const SizedBox(height: AppSpacing.md),
            StatCardGrid(
              children: [
                StatCard(
                  label: s.profileWinRate,
                  value: '${profile.winPercentage}%',
                  icon: AppIcon.stats,
                  accent: accent,
                  emphasis: true,
                ),
                StatCard(
                  label: s.profileMatches,
                  value: '${profile.matchesPlayed}',
                  icon: AppIcon.cards,
                ),
                StatCard(
                  label: s.profileWins,
                  value: '${profile.matchesWon}',
                  icon: AppIcon.trophy,
                ),
                StatCard(
                  label: s.profileLosses,
                  value: '${profile.matchesLost}',
                  icon: AppIcon.close,
                ),
                StatCard(
                  label: s.profileBestStreak,
                  value: '${profile.bestStreak}',
                  icon: AppIcon.ring,
                ),
                StatCard(
                  label: s.statStreak,
                  value: '${profile.currentStreak}',
                  icon: AppIcon.restart,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            SectionHeading('101'),
            const SizedBox(height: AppSpacing.md),
            StatCardGrid(
              children: [
                StatCard(
                  label: s.statResets,
                  value: '${profile.resets101}',
                  icon: AppIcon.ring,
                ),
                StatCard(
                  label: s.statChain,
                  value: '${profile.longestChain}',
                  icon: AppIcon.chain,
                ),
                StatCard(
                  label: s.statComeback,
                  value: '${profile.largestComeback}',
                  icon: AppIcon.stats,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            PremiumButton(
              label: s.profileEdit,
              icon: AppIcon.edit,
              variant: ButtonVariant.secondary,
              onPressed: () => Get.toNamed<void>(AppRoutes.editProfile),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        );
      }),
    );
  }
}
