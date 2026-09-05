import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../constants/app_spacing.dart';
import 'app_icons.dart';
import 'premium_button.dart';

/// The three states every data-backed screen can be in, drawn once (§6).
///
/// They take their copy as arguments so nothing in `core/` reaches for a
/// localization bundle.
class LoadingView extends StatefulWidget {
  const LoadingView({super.key, this.message, this.accent});

  final String? message;
  final Color? accent;

  @override
  State<LoadingView> createState() => _LoadingViewState();
}

class _LoadingViewState extends State<LoadingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tint = widget.accent ?? AppColors.antiqueGold;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _spin,
            builder: (context, _) => Transform.rotate(
              angle: _spin.value * 6.2831853,
              child: CustomPaint(
                size: const Size.square(40),
                painter: _ArcPainter(tint),
              ),
            ),
          ),
          if (widget.message != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              widget.message!,
              style: AppText.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  const _ArcPainter(this.colour);

  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawArc(
      rect.deflate(3),
      0,
      4.2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3
        ..shader = SweepGradient(
          colors: [colour.withValues(alpha: 0.0), colour],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _ArcPainter old) => old.colour != colour;
}

/// A dead end the player can act on.
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.title,
    this.message,
    this.retryLabel,
    this.onRetry,
  });

  final String title;
  final String? message;
  final String? retryLabel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => _Placeholder(
    icon: AppIcon.close,
    tint: AppColors.terracottaCoral,
    title: title,
    message: message,
    actionLabel: retryLabel,
    onAction: onRetry,
  );
}

/// Nothing to show, and that is not an error.
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.title,
    this.message,
    this.icon = AppIcon.cards,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? message;
  final AppIcon icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => _Placeholder(
    icon: icon,
    tint: AppColors.textMuted,
    title: title,
    message: message,
    actionLabel: actionLabel,
    onAction: onAction,
  );
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({
    required this.icon,
    required this.tint,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final AppIcon icon;
  final Color tint;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tint.withValues(alpha: 0.12),
                border: Border.all(color: tint.withValues(alpha: 0.35)),
              ),
              child: Center(child: AppIconView(icon, size: 26, color: tint)),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: AppText.screenTitle.copyWith(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                message!,
                style: AppText.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xl),
              PremiumButton(
                label: actionLabel!,
                variant: ButtonVariant.secondary,
                size: ButtonSize.medium,
                expand: false,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
