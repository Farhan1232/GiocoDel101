import 'package:flutter/material.dart';

import '../../core/constants/app_durations.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/utils/motion.dart';
import '../../services/haptic_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../icons/app_icons.dart';

class SegmentOption<T> {
  const SegmentOption({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final AppIcon? icon;
}

/// A sunken track with a raised gold slider, used wherever the game asks for
/// one of a few choices (§26, §39). Replaces Material's segmented button so
/// the control matches the rest of the interface.
class SegmentedControl<T> extends StatelessWidget {
  const SegmentedControl({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.accent,
    this.height = 46,
    this.compact = false,
  });

  final List<SegmentOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;
  final Color? accent;
  final double height;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final accentColor = accent ?? AppColors.antiqueGold;
    final index = options.indexWhere((o) => o.value == value);
    final count = options.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final slotWidth = constraints.maxWidth / count;
        return Container(
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.md),
            color: AppColors.surfaceSunken,
            border: Border.all(color: AppColors.hairline),
            boxShadow: [
              BoxShadow(
                color: AppColors.inkDeep.withValues(alpha: 0.4),
                blurRadius: 6,
                offset: const Offset(0, 2),
                spreadRadius: -2,
              ),
            ],
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: Motion.scale(AppDurations.quick),
                curve: Curves.easeOutCubic,
                left: slotWidth * (index < 0 ? 0 : index) + 3,
                top: 3,
                bottom: 3,
                width: slotWidth - 6,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color.lerp(accentColor, Colors.white, 0.2)!,
                        accentColor,
                        Color.lerp(accentColor, AppColors.inkDeep, 0.3)!,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.inkDeep.withValues(alpha: 0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < count; i++)
                    Expanded(
                      child: Semantics(
                        selected: i == index,
                        button: true,
                        label: options[i].label,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (options[i].value == value) return;
                            HapticService.instance.light();
                            onChanged(options[i].value);
                          },
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (options[i].icon != null && !compact) ...[
                                  AppIconView(
                                    options[i].icon!,
                                    size: 16,
                                    color: i == index
                                        ? AppColors.inkDeep
                                        : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: AppSpacing.xs + 2),
                                ],
                                Flexible(
                                  child: Text(
                                    options[i].label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppText.label.copyWith(
                                      fontSize: compact ? 12 : 13,
                                      color: i == index
                                          ? AppColors.inkDeep
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
