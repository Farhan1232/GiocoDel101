import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/motion.dart';
import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';

/// §23 — the eight quick reactions, in a compact overlay.
///
/// No chat screen, no messaging, no network: these are local flourishes the
/// bots occasionally answer in kind.
class ReactionSheet extends StatelessWidget {
  const ReactionSheet({
    super.key,
    required this.onPick,
    required this.onDismiss,
    this.accent,
  });

  final ValueChanged<String> onPick;
  final VoidCallback onDismiss;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final phrases = Strings.s.reactions8;
    final colour = accent ?? AppColors.antiqueGold;

    return GestureDetector(
      onTap: onDismiss,
      behavior: HitTestBehavior.opaque,
      child: ColoredBox(
        color: AppColors.inkDeep.withValues(alpha: 0.55),
        child: SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Motion.scale(const Duration(milliseconds: 240)),
              curve: Curves.easeOutCubic,
              builder: (context, t, child) => Transform.translate(
                offset: Offset(0, (1 - t) * 40),
                child: Opacity(opacity: t, child: child),
              ),
              child: Container(
                margin: const EdgeInsets.all(AppSpacing.lg),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  color: AppColors.surfaceRaised,
                  border: Border.all(color: colour.withValues(alpha: 0.35)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.inkDeep.withValues(alpha: 0.6),
                      blurRadius: 26,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final phrase in phrases)
                      GestureDetector(
                        onTap: () => onPick(phrase),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                            color: AppColors.surfaceSunken,
                            border: Border.all(
                              color: colour.withValues(alpha: 0.28),
                            ),
                          ),
                          child: Text(
                            phrase,
                            style: AppText.body.copyWith(fontSize: 13.5),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
