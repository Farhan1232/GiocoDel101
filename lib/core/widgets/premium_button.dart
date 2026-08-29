import 'package:flutter/material.dart';

import '../constants/app_durations.dart';
import '../constants/app_spacing.dart';
import '../utils/motion.dart';
import '../services/haptic_service.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import 'app_icons.dart';

enum ButtonVariant { primary, secondary, ghost, danger }

enum ButtonSize { large, medium, small }

/// §25/§58 — the game's tactile button.
///
/// Layered by hand: cast shadow, bevelled body, inner top highlight, inner
/// bottom shade. Pressing sinks it a couple of pixels and takes the shadow
/// with it, so the control feels like a physical key rather than a rectangle
/// with a ripple.
class PremiumButton extends StatefulWidget {
  const PremiumButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.large,
    this.icon,
    this.accent,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final AppIcon? icon;

  /// Overrides the variant colour, used to tint buttons per table theme.
  final Color? accent;

  final bool expand;

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton> {
  bool _down = false;

  bool get _enabled => widget.onPressed != null;

  double get _height => switch (widget.size) {
        ButtonSize.large => 60,
        ButtonSize.medium => 50,
        ButtonSize.small => 40,
      };

  double get _fontSize => switch (widget.size) {
        ButtonSize.large => 17,
        ButtonSize.medium => 15,
        ButtonSize.small => 13,
      };

  @override
  Widget build(BuildContext context) {
    final base = widget.accent ?? _baseColour(widget.variant);
    final depth = _down ? 2.0 : 5.0;
    final radius = BorderRadius.circular(
        widget.size == ButtonSize.small ? AppRadii.sm : AppRadii.md);

    final content = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          AppIconView(
            widget.icon!,
            size: _fontSize * 1.35,
            color: _labelColour(widget.variant, base),
          ),
          const SizedBox(width: AppSpacing.sm + 2),
        ],
        Flexible(
          child: Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppText.button.copyWith(
              fontSize: _fontSize,
              color: _labelColour(widget.variant, base),
              letterSpacing: widget.size == ButtonSize.small ? 1.4 : 2.4,
            ),
          ),
        ),
      ],
    );

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      child: GestureDetector(
        onTapDown: _enabled ? (_) => setState(() => _down = true) : null,
        onTapUp: _enabled ? (_) => setState(() => _down = false) : null,
        onTapCancel: _enabled ? () => setState(() => _down = false) : null,
        onTap: _enabled
            ? () {
                HapticService.instance.light();
                widget.onPressed!();
              }
            : null,
        child: AnimatedOpacity(
          duration: AppDurations.micro,
          opacity: _enabled ? 1 : 0.42,
          child: AnimatedScale(
            duration: Motion.scale(AppDurations.micro),
            scale: _down ? 0.982 : 1.0,
            child: AnimatedContainer(
              duration: Motion.scale(AppDurations.micro),
              height: _height,
              width: widget.expand ? double.infinity : null,
              padding: EdgeInsets.symmetric(
                horizontal: widget.size == ButtonSize.small
                    ? AppSpacing.md
                    : AppSpacing.xl,
              ),
              transform: Matrix4.translationValues(0, _down ? 2 : 0, 0),
              decoration: BoxDecoration(
                borderRadius: radius,
                gradient: _bodyGradient(widget.variant, base),
                border: Border.all(
                  color: widget.variant == ButtonVariant.ghost
                      ? base.withValues(alpha: 0.42)
                      : Color.lerp(base, Colors.white, 0.35)!
                          .withValues(alpha: 0.5),
                  width: 1,
                ),
                boxShadow: widget.variant == ButtonVariant.ghost
                    ? null
                    : [
                        BoxShadow(
                          color: AppColors.inkDeep.withValues(alpha: 0.55),
                          blurRadius: depth * 2.6,
                          offset: Offset(0, depth),
                        ),
                        BoxShadow(
                          color: base.withValues(alpha: _down ? 0.10 : 0.22),
                          blurRadius: 18,
                          offset: const Offset(0, 4),
                          spreadRadius: -6,
                        ),
                      ],
              ),
              child: Stack(
                children: [
                  // Inner bevel: lit along the top, shaded along the bottom.
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: radius,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(alpha: 0.16),
                              Colors.white.withValues(alpha: 0.0),
                              AppColors.inkDeep.withValues(alpha: 0.18),
                            ],
                            stops: const [0.0, 0.42, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Center(child: content),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Color _baseColour(ButtonVariant v) => switch (v) {
        ButtonVariant.primary => AppColors.antiqueGold,
        ButtonVariant.secondary => AppColors.surfaceRaised,
        ButtonVariant.ghost => AppColors.warmIvory,
        ButtonVariant.danger => AppColors.danger,
      };

  static Color _labelColour(ButtonVariant v, Color base) => switch (v) {
        ButtonVariant.primary => AppColors.inkDeep,
        ButtonVariant.secondary => AppColors.textPrimary,
        ButtonVariant.ghost => base,
        ButtonVariant.danger => AppColors.warmIvory,
      };

  static Gradient? _bodyGradient(ButtonVariant v, Color base) {
    if (v == ButtonVariant.ghost) return null;
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color.lerp(base, Colors.white, 0.22)!,
        base,
        Color.lerp(base, AppColors.inkDeep, 0.30)!,
      ],
      stops: const [0.0, 0.5, 1.0],
    );
  }
}
