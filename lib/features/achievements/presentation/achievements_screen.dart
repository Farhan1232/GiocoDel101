import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/achievement_tile.dart';
import '../../../core/widgets/app_panel.dart';
import '../../../core/widgets/screen_scaffold.dart';
import '../../../app/theme/app_colors.dart';
import '../../profile/application/profile_controller.dart';
import '../../profile/application/stats_controller.dart';
import '../../settings/application/settings_controller.dart';
import '../domain/achievements_catalog.dart';

/// §S — every badge, earned or not.
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = Strings.s;
    final settings = Get.find<SettingsController>();
    final stats = Get.find<StatsController>();
    final remote = Get.isRegistered<ProfileController>()
        ? Get.find<ProfileController>()
        : null;

    return ScreenScaffold(
      title: s.achievements,
      child: Obx(() {
        final accent = settings.theme.accent;
        // Offline badges live on this device; online ones are the server's
        // verdict. Either counts as earned; the label says which.
        bool online(String id) => remote?.hasAchievement(id) ?? false;
        bool earnedAny(String id) => stats.hasAchievement(id) || online(id);
        String status(String id) => !earnedAny(id)
            ? s.achLocked
            : online(id)
            ? s.achOnline
            : s.achOffline;
        final earned = AchievementsCatalog.all
            .where((a) => earnedAny(a.id))
            .length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.md),
            SectionHeading(
              s.achievements.toUpperCase(),
              trailing: Text(
                '$earned/${AchievementsCatalog.all.length}',
                style: AppText.label,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final achievement in AchievementsCatalog.all) ...[
              AchievementTile(
                title: s.achievementTitle(achievement.id),
                description: s.achievementDescription(achievement.id),
                icon: achievement.icon,
                unlocked: earnedAny(achievement.id),
                statusLabel: status(achievement.id),
                accent: accent,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            const SizedBox(height: AppSpacing.md),
            Text(
              s.achServerHint,
              style: AppText.caption.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        );
      }),
    );
  }
}
