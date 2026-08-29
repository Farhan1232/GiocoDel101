import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/achievement_tile.dart';
import '../../../core/widgets/app_panel.dart';
import '../../../core/widgets/screen_scaffold.dart';
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

    return ScreenScaffold(
      title: s.achievements,
      child: Obx(() {
        final accent = settings.theme.accent;
        final earned = AchievementsCatalog.all
            .where((a) => stats.hasAchievement(a.id))
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
                unlocked: stats.hasAchievement(achievement.id),
                statusLabel: stats.hasAchievement(achievement.id)
                    ? s.achUnlocked
                    : s.achLocked,
                accent: accent,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            const SizedBox(height: AppSpacing.xl),
          ],
        );
      }),
    );
  }
}
