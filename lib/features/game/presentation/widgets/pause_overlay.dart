import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/motion.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/app_switch.dart';
import '../../../../core/widgets/premium_button.dart';
import '../../../settings/application/settings_controller.dart';

/// §W — the offline pause menu.
///
/// The table underneath is frozen by the driver ([TableController.pause]):
/// bots wait, cards refuse taps. This sheet only offers the few things a
/// person wants mid-match — carry on, glance at the rules, flip a sound
/// switch, or leave — and nothing that changes the game.
class PauseOverlay extends StatelessWidget {
  const PauseOverlay({
    super.key,
    required this.settings,
    required this.onResume,
    required this.onRules,
    required this.onExit,
    this.accent,
  });

  final SettingsController settings;
  final VoidCallback onResume;
  final VoidCallback onRules;
  final VoidCallback onExit;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final s = Strings.s;
    final colour = accent ?? AppColors.antiqueGold;
    return ColoredBox(
      color: AppColors.inkDeep.withValues(alpha: 0.72),
      child: SafeArea(
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Motion.scale(const Duration(milliseconds: 260)),
            curve: Curves.easeOutCubic,
            builder: (context, t, child) => Opacity(
              opacity: t,
              child: Transform.scale(scale: 0.96 + t * 0.04, child: child),
            ),
            child: Semantics(
              container: true,
              label: s.pauseTitle,
              child: Container(
                width: 320,
                margin: const EdgeInsets.all(AppSpacing.lg),
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  color: AppColors.surfaceRaised,
                  border: Border.all(color: colour.withValues(alpha: 0.4)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.inkDeep.withValues(alpha: 0.6),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      s.pauseTitle.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: AppText.screenTitle.copyWith(
                        fontSize: 22,
                        letterSpacing: 4,
                        color: colour,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      s.pauseHint,
                      textAlign: TextAlign.center,
                      style: AppText.caption,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Obx(() {
                      final v = settings.settings;
                      return Column(
                        children: [
                          _toggle(
                            s.soundEffects,
                            v.soundEnabled ? AppIcon.sound : AppIcon.soundOff,
                            v.soundEnabled,
                            settings.setSound,
                            colour,
                          ),
                          _toggle(
                            s.music,
                            v.musicEnabled ? AppIcon.music : AppIcon.musicOff,
                            v.musicEnabled,
                            settings.setMusic,
                            colour,
                          ),
                          _toggle(
                            s.haptics,
                            AppIcon.haptic,
                            v.hapticsEnabled,
                            settings.setHaptics,
                            colour,
                          ),
                        ],
                      );
                    }),
                    const SizedBox(height: AppSpacing.lg),
                    PremiumButton(
                      label: s.pauseResume,
                      icon: AppIcon.play,
                      accent: colour,
                      size: ButtonSize.medium,
                      onPressed: onResume,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    PremiumButton(
                      label: s.tableRules,
                      icon: AppIcon.rules,
                      variant: ButtonVariant.secondary,
                      size: ButtonSize.small,
                      onPressed: onRules,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    PremiumButton(
                      label: s.exitToMenu,
                      variant: ButtonVariant.ghost,
                      size: ButtonSize.small,
                      onPressed: onExit,
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

  Widget _toggle(
    String title,
    AppIcon icon,
    bool value,
    Future<void> Function(bool) onChanged,
    Color colour,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          AppIconView(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(title, style: AppText.bodySmall)),
          AppSwitch(value: value, accent: colour, onChanged: onChanged),
        ],
      ),
    );
  }
}
