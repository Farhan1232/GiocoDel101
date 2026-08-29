import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../constants/app_spacing.dart';

/// The level progress bar.
///
/// Purely presentational: it is handed a fraction and a caption and knows
/// nothing about how experience is earned.
class XpBar extends StatelessWidget {
  const XpBar({
    super.key,
    required this.progress,
    this.label,
    this.caption,
    this.accent,
    this.height = 10,
  });

  /// 0..1. Clamped, so an out-of-range model cannot break the layout.
  final double progress;

  final String? label;
  final String? caption;
  final Color? accent;
  final double height;

  @override
  Widget build(BuildContext context) {
    final tint = accent ?? AppColors.antiqueGold;
    final value = progress.isNaN ? 0.0 : progress.clamp(0.0, 1.0);
    return Semantics(
      label: label,
      value: '${(value * 100).round()}%',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null || caption != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: [
                  if (label != null)
                    Expanded(child: Text(label!, style: AppText.label)),
                  if (caption != null)
                    Text(caption!, style: AppText.caption),
                ],
              ),
            ),
          ClipRRect(
            borderRadius: BorderRadius.circular(height),
            child: Stack(
              children: [
                Container(
                  height: height,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSunken,
                    border: Border.all(color: AppColors.hairline),
                    borderRadius: BorderRadius.circular(height),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: value,
                  child: Container(
                    height: height,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(height),
                      gradient: LinearGradient(
                        colors: [tint.withValues(alpha: 0.75), AppColors.goldLight],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
