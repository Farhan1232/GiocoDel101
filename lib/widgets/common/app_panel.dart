import 'package:flutter/material.dart';

import '../../core/constants/app_spacing.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// §58 — the standard raised surface: a soft vertical gradient, a gold
/// hairline and a single grounded shadow. Used instead of Material `Card`
/// so every panel in the game matches.
class AppPanel extends StatelessWidget {
  const AppPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.radius = AppRadii.lg,
    this.accent,
    this.onTap,
    this.elevated = true,
    this.tintStrength = 1.0,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color? accent;
  final VoidCallback? onTap;
  final bool elevated;
  final double tintStrength;

  @override
  Widget build(BuildContext context) {
    final line = (accent ?? AppColors.antiqueGold).withValues(alpha: 0.24);
    final panel = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(AppColors.surfaceRaised, accent ?? AppColors.surfaceRaised,
                0.06 * tintStrength)!,
            AppColors.surface,
            AppColors.surfaceSunken,
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
        border: Border.all(color: line),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: AppColors.inkDeep.withValues(alpha: 0.45),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                  spreadRadius: -6,
                ),
              ]
            : null,
      ),
      child: Stack(
        children: [
          // A lit top edge sells the raised surface.
          Positioned(
            left: radius,
            right: radius,
            top: 0,
            height: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.transparent,
                  Colors.white.withValues(alpha: 0.16),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Padding(padding: padding, child: child),
        ],
      ),
    );

    if (onTap == null) return panel;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        splashColor: (accent ?? AppColors.antiqueGold).withValues(alpha: 0.08),
        highlightColor: Colors.transparent,
        child: panel,
      ),
    );
  }
}

/// A small gold-ruled heading used above grouped content.
class SectionHeading extends StatelessWidget {
  const SectionHeading(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Text(title, style: AppText.sectionTitle),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  AppColors.antiqueGold.withValues(alpha: 0.45),
                  AppColors.antiqueGold.withValues(alpha: 0.0),
                ]),
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.md),
            trailing!,
          ],
        ],
      ),
    );
  }
}
