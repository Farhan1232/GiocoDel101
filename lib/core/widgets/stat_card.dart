import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../constants/app_spacing.dart';
import 'app_icons.dart';
import 'app_panel.dart';

/// A single figure with its caption. Used by Profile and Statistics.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.accent,
    this.emphasis = false,
  });

  final String label;
  final String value;
  final AppIcon? icon;
  final Color? accent;

  /// Draws the tile in the accent colour — used for the headline figure.
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final tint = accent ?? AppColors.antiqueGold;
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: AppPanel(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        accent: emphasis ? tint : null,
        tintStrength: emphasis ? 1.0 : 0.4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              AppIconView(icon!, size: 18, color: tint),
              const SizedBox(height: AppSpacing.sm),
            ],
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: AppText.scoreLarge.copyWith(
                  fontSize: emphasis ? 30 : 24,
                  color: emphasis ? tint : AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              label,
              style: AppText.caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Lays stat cards out in a grid that reflows rather than overflowing (§7).
class StatCardGrid extends StatelessWidget {
  const StatCardGrid({super.key, required this.children, this.minTileWidth = 150});

  final List<Widget> children;
  final double minTileWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final columns = (box.maxWidth / minTileWidth).floor().clamp(2, 4);
        final width =
            (box.maxWidth - AppSpacing.md * (columns - 1)) / columns;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}
