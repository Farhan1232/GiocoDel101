import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../constants/app_spacing.dart';
import 'app_icons.dart';
import 'app_panel.dart';

/// One badge, earned or not.
class AchievementTile extends StatelessWidget {
  const AchievementTile({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.unlocked,
    required this.statusLabel,
    this.progress,
    this.accent,
    this.onTap,
  });

  final String title;
  final String description;
  final AppIcon icon;
  final bool unlocked;

  /// "Sbloccato" / "Da sbloccare" — already localized by the caller.
  final String statusLabel;

  /// 0..1 when the badge has measurable progress; null hides the bar.
  final double? progress;

  final Color? accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tint = accent ?? AppColors.antiqueGold;
    final colour = unlocked ? tint : AppColors.textMuted;

    return Semantics(
      button: onTap != null,
      label: '$title. $description. $statusLabel',
      excludeSemantics: true,
      child: AppPanel(
        onTap: onTap,
        accent: unlocked ? tint : null,
        tintStrength: unlocked ? 0.9 : 0.3,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colour.withValues(alpha: unlocked ? 0.18 : 0.08),
                border: Border.all(
                  color: colour.withValues(alpha: unlocked ? 0.6 : 0.3),
                ),
              ),
              child: Center(
                child: AppIconView(
                  unlocked ? icon : AppIcon.lock,
                  size: 20,
                  color: colour,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppText.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: unlocked
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(description, style: AppText.bodySmall),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Text(
                        statusLabel,
                        style: AppText.caption.copyWith(color: colour),
                      ),
                      if (progress != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: progress!.clamp(0.0, 1.0),
                              minHeight: 4,
                              backgroundColor: AppColors.surfaceSunken,
                              valueColor: AlwaysStoppedAnimation(colour),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
