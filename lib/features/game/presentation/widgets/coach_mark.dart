import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/motion.dart';
import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/premium_button.dart';
import '../../../../core/widgets/app_icons.dart';

/// §65 — a single first-run tip.
///
/// Four of these appear once each during the first match and are then never
/// shown again. They are deliberately small: no forced tutorial, no modal
/// chain, nothing to dismiss twice.
class CoachMark extends StatelessWidget {
  const CoachMark({
    super.key,
    required this.icon,
    required this.message,
    required this.onDismiss,
    this.accent,
  });

  final AppIcon icon;
  final String message;
  final VoidCallback onDismiss;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final colour = accent ?? AppColors.antiqueGold;
    return Align(
      alignment: Alignment.bottomCenter,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Motion.scale(const Duration(milliseconds: 300)),
        curve: Curves.easeOutCubic,
        builder: (context, t, child) => Transform.translate(
          offset: Offset(0, (1 - t) * 24),
          child: Opacity(opacity: t, child: child),
        ),
        child: Container(
          margin: const EdgeInsets.all(AppSpacing.lg),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.md),
            color: AppColors.surfaceRaised,
            border: Border.all(color: colour.withValues(alpha: 0.45)),
            boxShadow: [
              BoxShadow(
                color: AppColors.inkDeep.withValues(alpha: 0.55),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colour.withValues(alpha: 0.14),
                ),
                child: Center(
                  child: AppIconView(icon, size: 18, color: colour),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  message,
                  style: AppText.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              PremiumButton(
                label: Strings.s.gotIt,
                size: ButtonSize.small,
                variant: ButtonVariant.secondary,
                expand: false,
                onPressed: onDismiss,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
