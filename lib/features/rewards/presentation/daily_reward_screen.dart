import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/localization/app_strings.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_icons.dart';
import '../../../core/widgets/app_panel.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/screen_scaffold.dart';
import '../../settings/application/settings_controller.dart';
import '../domain/daily_reward.dart';

/// §T — the seven-day ladder.
///
/// Presentation only. Claiming needs an account service to hold the balance,
/// so the button explains that rather than crediting coins that go nowhere.
class DailyRewardScreen extends StatelessWidget {
  const DailyRewardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = Strings.s;
    final settings = Get.find<SettingsController>();
    final calendar = DailyRewardCalendar.forStreak(0);

    return ScreenScaffold(
      title: s.dailyRewardTitle,
      child: Obx(() {
        final accent = settings.theme.accent;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.lg),
            Text(
              s.dailyRewardBody,
              style: AppText.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            LayoutBuilder(
              builder: (context, box) {
                // Four across on a phone, seven on anything wide enough.
                final columns = box.maxWidth > 460 ? 7 : 4;
                final width =
                    (box.maxWidth - AppSpacing.sm * (columns - 1)) / columns;
                return Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final day in calendar.days)
                      SizedBox(
                        width: width,
                        child: _DayTile(day: day, accent: accent),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.xxl),
            PremiumButton(
              label: s.dailyRewardClaim,
              accent: accent,
              // No balance exists to credit yet.
              onPressed: null,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              s.authBackendPending,
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

class _DayTile extends StatelessWidget {
  const _DayTile({required this.day, required this.accent});

  final DailyRewardDay day;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final s = Strings.s;
    final active = day.isToday;
    final colour = day.isClaimed
        ? AppColors.mediterraneanTeal
        : (active ? accent : AppColors.textMuted);

    return Semantics(
      label:
          '${s.dailyRewardDay(day.day)}. ${day.amount}. '
          '${day.isClaimed ? s.dailyRewardClaimed : ''}',
      excludeSemantics: true,
      child: AppPanel(
        accent: active ? accent : null,
        tintStrength: active ? 1.0 : 0.3,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              s.dailyRewardDay(day.day),
              style: AppText.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppIconView(
              day.isClaimed ? AppIcon.check : AppIcon.trophy,
              size: 20,
              color: colour,
            ),
            const SizedBox(height: AppSpacing.sm),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${day.amount}',
                style: AppText.scoreSmall.copyWith(color: colour),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
