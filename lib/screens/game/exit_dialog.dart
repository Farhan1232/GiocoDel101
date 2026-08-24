import 'package:flutter/material.dart';

import '../../core/constants/app_spacing.dart';
import '../../data/app_strings.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/common/premium_button.dart';

/// §50 — leaving a live match always says what will happen to it.
Future<bool?> showExitDialog(BuildContext context, {Color? accent}) {
  final s = Strings.s;
  return showDialog<bool>(
    context: context,
    barrierColor: AppColors.inkDeep.withValues(alpha: 0.72),
    builder: (context) => Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.xl),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(s.exitTitle, style: AppText.screenTitle.copyWith(fontSize: 20)),
            const SizedBox(height: AppSpacing.md),
            Text(
              s.exitBody,
              textAlign: TextAlign.center,
              style: AppText.bodySmall,
            ),
            const SizedBox(height: AppSpacing.xl),
            PremiumButton(
              label: s.continueGame,
              accent: accent,
              size: ButtonSize.medium,
              onPressed: () => Navigator.of(context).pop(false),
            ),
            const SizedBox(height: AppSpacing.sm),
            PremiumButton(
              label: s.exit,
              variant: ButtonVariant.ghost,
              size: ButtonSize.medium,
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ),
    ),
  );
}
