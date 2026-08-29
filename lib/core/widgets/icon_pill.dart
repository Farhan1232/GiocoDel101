import 'package:flutter/material.dart';

import '../constants/app_spacing.dart';
import '../services/haptic_service.dart';
import '../../app/theme/app_colors.dart';
import 'app_icons.dart';

/// A round, bevelled icon button. Used for every chrome control in the game
/// so nothing falls back to a Material `IconButton` (§45).
class IconPill extends StatefulWidget {
  const IconPill({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 44,
    this.accent,
    this.tooltip,
    this.badge,
  });

  final AppIcon icon;
  final VoidCallback? onTap;
  final double size;
  final Color? accent;
  final String? tooltip;
  final Widget? badge;

  @override
  State<IconPill> createState() => _IconPillState();
}

class _IconPillState extends State<IconPill> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent ?? AppColors.antiqueGold;
    final button = GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap == null
          ? null
          : () {
              HapticService.instance.light();
              widget.onTap!();
            },
      child: AnimatedScale(
        duration: const Duration(milliseconds: 110),
        scale: _down ? 0.93 : 1.0,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.surfaceRaised,
                AppColors.surfaceSunken,
              ],
            ),
            border: Border.all(color: accent.withValues(alpha: 0.30)),
            boxShadow: [
              BoxShadow(
                color: AppColors.inkDeep.withValues(alpha: 0.5),
                blurRadius: _down ? 4 : 10,
                offset: Offset(0, _down ? 1 : 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              AppIconView(
                widget.icon,
                size: widget.size * 0.48,
                color: accent,
              ),
              if (widget.badge != null)
                Positioned(right: 2, top: 2, child: widget.badge!),
            ],
          ),
        ),
      ),
    );

    if (widget.tooltip == null) {
      return Semantics(button: true, child: button);
    }
    return Semantics(
      button: true,
      label: widget.tooltip,
      child: Tooltip(message: widget.tooltip!, child: button),
    );
  }
}

/// A small gold dot used to mark something new or available.
class NotificationDot extends StatelessWidget {
  const NotificationDot({super.key, this.color = AppColors.terracottaCoral});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: AppSpacing.sm,
        height: AppSpacing.sm,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 6),
          ],
        ),
      );
}
