import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/utils/glow.dart';
import '../../core/utils/motion.dart';
import '../../theme/app_colors.dart';

/// §37/§62 — the match-victory flourish.
///
/// A struck trophy over a slow drift of gold. Deliberately restrained: a
/// hundred confetti pieces would cheapen the moment the whole match builds
/// toward, so this is a small, warm shower with depth instead.
class VictoryFlourish extends StatefulWidget {
  const VictoryFlourish({
    super.key,
    required this.size,
    this.accent = AppColors.antiqueGold,
  });

  final double size;
  final Color accent;

  @override
  State<VictoryFlourish> createState() => _VictoryFlourishState();
}

class _VictoryFlourishState extends State<VictoryFlourish>
    with TickerProviderStateMixin {
  late final AnimationController _enter;
  late final AnimationController _drift;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: Motion.scale(const Duration(milliseconds: 900)),
    )..forward();
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );
    if (Motion.allowAmbient) _drift.repeat();
  }

  @override
  void dispose() {
    _enter.dispose();
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_enter, _drift]),
        builder: (context, _) => CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _TrophyPainter(
            enter: Curves.easeOutBack.transform(_enter.value),
            drift: _drift.value,
            accent: widget.accent,
          ),
        ),
      ),
    );
  }
}

class _TrophyPainter extends CustomPainter {
  const _TrophyPainter({
    required this.enter,
    required this.drift,
    required this.accent,
  });

  final double enter;
  final double drift;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    _particles(canvas, size);

    canvas.save();
    final centre = size.center(Offset.zero);
    canvas.translate(centre.dx, centre.dy);
    canvas.scale(0.7 + enter.clamp(0.0, 1.3) * 0.3);
    canvas.translate(-centre.dx, -centre.dy);
    _trophy(canvas, size);
    canvas.restore();
  }

  void _trophy(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final gold = Paint()
      ..shader = ui.Gradient.linear(
        Offset(w * 0.3, h * 0.2),
        Offset(w * 0.72, h * 0.85),
        const [
          AppColors.goldLight,
          AppColors.goldMid,
          AppColors.goldDeep,
          AppColors.goldMid,
        ],
        const [0.0, 0.35, 0.72, 1.0],
      )
      ..isAntiAlias = true;
    final ink = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.012
      ..strokeJoin = StrokeJoin.round
      ..color = AppColors.goldShadow
      ..isAntiAlias = true;

    // Glow behind the cup.
    Glow.circle(
      canvas,
      Offset(w * 0.5, h * 0.42),
      w * 0.44,
      accent.withValues(alpha: 0.24 * enter.clamp(0.0, 1.0)),
      core: 0.42,
    );

    // Bowl.
    final bowl = Path()
      ..moveTo(w * 0.30, h * 0.24)
      ..lineTo(w * 0.70, h * 0.24)
      ..cubicTo(w * 0.70, h * 0.55, w * 0.60, h * 0.62, w * 0.50, h * 0.62)
      ..cubicTo(w * 0.40, h * 0.62, w * 0.30, h * 0.55, w * 0.30, h * 0.24)
      ..close();
    canvas.drawPath(bowl, gold);
    canvas.drawPath(bowl, ink);

    // Handles.
    for (final dir in const [-1.0, 1.0]) {
      final handle = Path()
        ..moveTo(w * (0.5 + dir * 0.20), h * 0.27)
        ..cubicTo(
          w * (0.5 + dir * 0.36), h * 0.26,
          w * (0.5 + dir * 0.36), h * 0.45,
          w * (0.5 + dir * 0.20), h * 0.46,
        );
      canvas.drawPath(
        handle,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.045
          ..strokeCap = StrokeCap.round
          ..shader = gold.shader,
      );
      canvas.drawPath(
        handle,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.045
          ..strokeCap = StrokeCap.round
          ..color = AppColors.goldShadow.withValues(alpha: 0.25),
      );
    }

    // Rim, stem and plinth.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.275, h * 0.20, w * 0.45, h * 0.055),
        Radius.circular(w * 0.02),
      ),
      gold,
    );
    canvas.drawRect(
        Rect.fromLTWH(w * 0.465, h * 0.62, w * 0.07, h * 0.10), gold);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.35, h * 0.72, w * 0.30, h * 0.055),
        Radius.circular(w * 0.014),
      ),
      gold,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.30, h * 0.775, w * 0.40, h * 0.07),
        Radius.circular(w * 0.018),
      ),
      gold,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.30, h * 0.775, w * 0.40, h * 0.07),
        Radius.circular(w * 0.018),
      ),
      ink,
    );

    // 101 struck into the bowl.
    final label = TextPainter(
      text: TextSpan(
        text: '101',
        style: TextStyle(
          fontFamily: 'Cinzel',
          fontSize: w * 0.15,
          fontWeight: FontWeight.w700,
          color: AppColors.goldShadow.withValues(alpha: 0.65),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(canvas,
        Offset(w * 0.5 - label.width / 2, h * 0.36 - label.height / 2));
  }

  void _particles(Canvas canvas, Size size) {
    if (!Motion.allowAmbient) return;
    final rng = math.Random(11);
    for (var i = 0; i < 26; i++) {
      final seed = rng.nextDouble();
      final speed = 0.4 + seed * 0.8;
      final y = ((drift * speed + seed) % 1.0);
      final x = seed + math.sin((drift * math.pi * 2 * speed) + i) * 0.06;
      final fade = math.sin(y * math.pi);
      final r = (1.2 + rng.nextDouble() * 2.6);
      Glow.circle(
        canvas,
        Offset(x * size.width, y * size.height),
        r * 2.4,
        Color.lerp(AppColors.goldLight, accent, rng.nextDouble())!
            .withValues(alpha: fade * 0.6),
        core: 0.24,
      );
    }
  }

  @override
  bool shouldRepaint(_TrophyPainter old) =>
      old.enter != enter || old.drift != drift;
}
