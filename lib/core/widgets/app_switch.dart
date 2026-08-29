import 'package:flutter/material.dart';

import '../constants/app_durations.dart';
import '../constants/app_spacing.dart';
import '../utils/motion.dart';
import '../services/haptic_service.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import 'app_icons.dart';

/// A bevelled toggle in the game's own idiom.
class AppSwitch extends StatelessWidget {
  const AppSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.accent,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final on = accent ?? AppColors.mediterraneanTeal;
    return Semantics(
      toggled: value,
      button: true,
      child: GestureDetector(
        onTap: () {
          HapticService.instance.light();
          onChanged(!value);
        },
        child: AnimatedContainer(
          duration: Motion.scale(AppDurations.quick),
          curve: Curves.easeOutCubic,
          width: 52,
          height: 30,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            color: value
                ? on.withValues(alpha: 0.85)
                : AppColors.surfaceSunken,
            border: Border.all(
              color: value
                  ? Color.lerp(on, Colors.white, 0.35)!
                  : AppColors.hairline,
            ),
          ),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.warmIvory, AppColors.cardIvoryShade],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.inkDeep.withValues(alpha: 0.45),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A labelled row with an optional hint and a trailing control.
class SettingRow extends StatelessWidget {
  const SettingRow({
    super.key,
    required this.title,
    required this.trailing,
    this.hint,
    this.icon,
    this.onTap,
  });

  final String title;
  final Widget trailing;
  final String? hint;
  final AppIcon? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
        child: Row(
          children: [
            if (icon != null) ...[
              AppIconView(icon!, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.body.copyWith(fontSize: 14.5)),
                  if (hint != null) ...[
                    const SizedBox(height: 2),
                    Text(hint!, style: AppText.caption),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            trailing,
          ],
        ),
      ),
    );
  }
}
