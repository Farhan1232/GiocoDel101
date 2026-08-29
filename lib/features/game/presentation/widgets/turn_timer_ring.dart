import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';

/// The countdown ring shown beside the round number in an online match.
///
/// Draws whatever fraction it is handed; it does not run a clock of its own.
class TurnTimerRing extends StatelessWidget {
  const TurnTimerRing({
    super.key,
    required this.progress,
    required this.secondsRemaining,
    this.size = 34,
    this.accent,
  });

  final double progress;
  final int secondsRemaining;
  final double size;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    // Warm through to alarming as the time runs out.
    final tint = accent ??
        (progress > 0.5
            ? AppColors.mediterraneanTeal
            : progress > 0.25
                ? AppColors.fateWarning
                : AppColors.terracottaCoral);

    return Semantics(
      label: '$secondsRemaining',
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RingPainter(progress: progress, colour: tint),
          child: Center(
            child: Text(
              '$secondsRemaining',
              style: AppText.scoreSmall.copyWith(fontSize: size * 0.36),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress, required this.colour});

  final double progress;
  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(2);
    canvas.drawArc(
      rect,
      0,
      6.2831853,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..color = AppColors.hairline,
    );
    canvas.drawArc(
      rect,
      -1.5707963,
      6.2831853 * progress.clamp(0.0, 1.0),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 2.8
        ..color = colour,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.colour != colour;
}
