import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/utils/motion.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';

/// §11 "Chain Storm" — the signature +2 mechanic.
///
/// A glowing chain wraps the draw pile and grows with every 2 played: wider
/// links, a stronger pulse, more sparks, and a penalty badge that counts
/// +2 → +4 → +6 → +8. The escalation is deliberately bounded so the table
/// stays readable and the frame budget stays intact (§54).
class ChainStorm extends StatefulWidget {
  const ChainStorm({
    super.key,
    required this.level,
    required this.total,
    required this.size,
  });

  /// Number of 2s stacked, 0 when calm.
  final int level;

  /// Cards currently owed.
  final int total;

  final Size size;

  @override
  State<ChainStorm> createState() => _ChainStormState();
}

class _ChainStormState extends State<ChainStorm>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;

  late final AnimationController _burst;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
    _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );
    if (widget.level > 0) _engage();
  }

  @override
  void didUpdateWidget(ChainStorm old) {
    super.didUpdateWidget(old);
    if (widget.level > old.level) {
      _engage();
      _burst.forward(from: 0);
    } else if (widget.level == 0 && old.level > 0) {
      _pulse.stop();
      _burst.forward(from: 0);
    }
  }

  void _engage() {
    if (!Motion.allowAmbient) return;
    // The chain breathes faster the deeper it gets.
    _pulse.duration = Duration(
        milliseconds: math.max(420, 1100 - widget.level * 180));
    if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    _burst.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.level == 0 && !_burst.isAnimating) {
      return SizedBox.fromSize(size: widget.size);
    }
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: Listenable.merge([_pulse, _burst]),
          builder: (context, _) => CustomPaint(
            size: widget.size,
            painter: _ChainPainter(
              level: widget.level,
              pulse: _pulse.value,
              burst: _burst.isAnimating ? _burst.value : 0,
            ),
            child: widget.total > 0
                ? Center(child: _badge())
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }

  Widget _badge() {
    final kick = _burst.isAnimating
        ? 1 + math.sin(_burst.value * math.pi) * 0.22
        : 1.0;
    return Transform.scale(
      scale: kick,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: LinearGradient(
            colors: [
              AppColors.terracottaCoral,
              Color.lerp(AppColors.terracottaCoral, AppColors.inkDeep, 0.35)!,
            ],
          ),
          border: Border.all(color: AppColors.goldLight.withValues(alpha: 0.7)),
          boxShadow: [
            BoxShadow(
              color: AppColors.terracottaCoral
                  .withValues(alpha: 0.4 + 0.25 * _pulse.value),
              blurRadius: 16,
              spreadRadius: -2,
            ),
          ],
        ),
        child: Text(
          '+${widget.total}',
          style: AppText.scoreSmall.copyWith(
            fontSize: 18,
            color: AppColors.warmIvory,
          ),
        ),
      ),
    );
  }
}

class _ChainPainter extends CustomPainter {
  const _ChainPainter({
    required this.level,
    required this.pulse,
    required this.burst,
  });

  final int level;
  final double pulse;
  final double burst;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final radius = size.shortestSide * 0.44;
    final intensity = (level / 4).clamp(0.0, 1.0);
    final glow = 0.35 + intensity * 0.5 + pulse * 0.18;

    // The chain itself: interlocking links around the pile.
    final links = 10 + level * 2;
    final linkW = size.shortestSide * (0.055 + intensity * 0.022);
    final linkH = linkW * 1.55;
    for (var i = 0; i < links; i++) {
      final a = (i / links) * math.pi * 2 + pulse * 0.12;
      final at = centre +
          Offset(math.cos(a), math.sin(a)) * (radius + pulse * 2.0);
      canvas.save();
      canvas.translate(at.dx, at.dy);
      canvas.rotate(a + math.pi / 2);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.4, linkW * 0.24)
        ..color = Color.lerp(AppColors.goldMid, AppColors.terracottaCoral,
                intensity)!
            .withValues(alpha: 0.55 + 0.4 * intensity);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(0, i.isEven ? -linkH * 0.18 : linkH * 0.18),
              width: linkW,
              height: linkH),
          Radius.circular(linkW * 0.5),
        ),
        paint,
      );
      canvas.restore();
    }

    // Halo.
    canvas.drawCircle(
      centre,
      radius * (1.02 + pulse * 0.05),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.shortestSide * (0.03 + intensity * 0.04)
        ..shader = ui.Gradient.sweep(
          centre,
          [
            AppColors.goldLight.withValues(alpha: 0.0),
            AppColors.terracottaCoral.withValues(alpha: glow * 0.7),
            AppColors.goldLight.withValues(alpha: glow),
            AppColors.terracottaCoral.withValues(alpha: glow * 0.7),
            AppColors.goldLight.withValues(alpha: 0.0),
          ],
          const [0.0, 0.25, 0.5, 0.75, 1.0],
        ),
    );
    // A wider, fainter pass instead of a blur filter (§54).
    canvas.drawCircle(
      centre,
      radius * (1.02 + pulse * 0.05),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.shortestSide * (0.075 + intensity * 0.07)
        ..shader = ui.Gradient.sweep(
          centre,
          [
            AppColors.goldLight.withValues(alpha: 0.0),
            AppColors.terracottaCoral.withValues(alpha: glow * 0.22),
            AppColors.goldLight.withValues(alpha: glow * 0.28),
            AppColors.terracottaCoral.withValues(alpha: glow * 0.22),
            AppColors.goldLight.withValues(alpha: 0.0),
          ],
          const [0.0, 0.25, 0.5, 0.75, 1.0],
        ),
    );

    // Sparks thrown off when the chain grows.
    if (burst > 0 && Motion.allowAmbient) {
      final rng = math.Random(level * 31);
      final count = 8 + level * 4;
      for (var i = 0; i < count; i++) {
        final a = rng.nextDouble() * math.pi * 2;
        final d = radius * (0.9 + burst * (1.1 + rng.nextDouble()));
        final at = centre + Offset(math.cos(a) * d, math.sin(a) * d);
        canvas.drawCircle(
          at,
          (1.4 + rng.nextDouble() * 2.4) * (1 - burst),
          Paint()
            ..color = Color.lerp(AppColors.goldLight,
                    AppColors.terracottaCoral, rng.nextDouble())!
                .withValues(alpha: (1 - burst) * 0.9),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_ChainPainter old) =>
      old.level != level || old.pulse != pulse || old.burst != burst;
}
