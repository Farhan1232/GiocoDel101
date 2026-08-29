import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../utils/glow.dart';
import '../utils/motion.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/table_themes.dart';

/// §33/§58 — the page backdrop.
///
/// A deep vertical wash, one of three restrained motifs, and a vignette that
/// keeps the eye on the content. The motif drifts very slowly, and stops
/// entirely under Reduce Motion.
class AppBackground extends StatefulWidget {
  const AppBackground({
    super.key,
    required this.child,
    required this.theme,
    this.animate = true,
    this.motifStrength = 1.0,
  });

  final Widget child;
  final TableTheme theme;
  final bool animate;
  final double motifStrength;

  @override
  State<AppBackground> createState() => _AppBackgroundState();
}

class _AppBackgroundState extends State<AppBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 42),
  );
    if (_needsMotionLayer) _drift.repeat();
  }

  @override
  void didUpdateWidget(AppBackground old) {
    super.didUpdateWidget(old);
    if (_needsMotionLayer && !_drift.isAnimating) {
      _drift.repeat();
    } else if (!_needsMotionLayer && _drift.isAnimating) {
      _drift.stop();
    }
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  /// §54 — only the embers genuinely move. Everything else is painted once
  /// into its own layer, so two of the three themes never repaint the
  /// backdrop at all and the third repaints only a handful of small sparks.
  bool get _needsMotionLayer =>
      widget.theme.pattern == TablePattern.embers &&
      widget.animate &&
      Motion.allowAmbient;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: BackdropPainter(
                theme: widget.theme,
                strength: widget.motifStrength,
              ),
            ),
          ),
        ),
        if (_needsMotionLayer)
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _drift,
                  builder: (context, _) => CustomPaint(
                    painter: _EmberPainter(
                      theme: widget.theme,
                      t: _drift.value,
                      strength: widget.motifStrength,
                    ),
                  ),
                ),
              ),
            ),
          ),
        Positioned.fill(child: widget.child),
      ],
    );
  }
}

class BackdropPainter extends CustomPainter {
  const BackdropPainter({required this.theme, this.strength = 1.0});

  final TableTheme theme;
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(size.width * 0.2, 0),
          Offset(size.width * 0.8, size.height),
          [
            theme.backdropTop,
            Color.lerp(theme.backdropTop, theme.backdropBottom, 0.6)!,
            theme.backdropBottom,
          ],
          const [0.0, 0.55, 1.0],
        ),
    );

    switch (theme.pattern) {
      case TablePattern.bokeh:
        _bokeh(canvas, size);
      case TablePattern.maiolica:
        _maiolica(canvas, size);
      case TablePattern.embers:
        _emberGlow(canvas, size);
    }

    // Vignette.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(size.width * 0.5, size.height * 0.42),
          size.height * 0.85,
          [
            Colors.transparent,
            AppColors.inkDeep.withValues(alpha: 0.55),
          ],
          const [0.55, 1.0],
        ),
    );
  }

  /// Distant lights across the bay, low on the frame.
  void _bokeh(Canvas canvas, Size size) {
    final rng = math.Random(7);
    for (var i = 0; i < 26; i++) {
      final bx = rng.nextDouble();
      final by = 0.42 + rng.nextDouble() * 0.62;
      final r = (4 + rng.nextDouble() * 26) * strength;
      final alpha = (0.03 + rng.nextDouble() * 0.07) * strength;
      Glow.circle(
        canvas,
        Offset(bx * size.width, by * size.height),
        r * 1.9,
        theme.particle.withValues(alpha: alpha),
        core: 0.18,
      );
    }
    // A warm horizon glow.
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.62, size.width, size.height * 0.38),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, size.height * 0.62),
          Offset(0, size.height),
          [
            theme.accent.withValues(alpha: 0.0),
            theme.accent.withValues(alpha: 0.055 * strength),
          ],
        ),
    );
  }

  /// An interlocking ceramic tile grid, drawn faintly.
  void _maiolica(Canvas canvas, Size size) {
    final step = size.width / 5.2;
    final ink = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = theme.particle.withValues(alpha: 0.10 * strength);
    final dot = Paint()
      ..color = theme.accent.withValues(alpha: 0.075 * strength);

    for (var y = -step; y < size.height + step; y += step) {
      for (var x = -step; x < size.width + step; x += step) {
        final c = Offset(x + step / 2, y + step / 2);
        final star = Path();
        for (var i = 0; i < 16; i++) {
          final a = (i / 16) * math.pi * 2 - math.pi / 2;
          final r = i.isEven ? step * 0.34 : step * 0.155;
          final p = c + Offset(math.cos(a) * r, math.sin(a) * r);
          if (i == 0) {
            star.moveTo(p.dx, p.dy);
          } else {
            star.lineTo(p.dx, p.dy);
          }
        }
        star.close();
        canvas.drawPath(star, ink);
        canvas.drawCircle(c, step * 0.05, dot);
      }
    }
  }

  /// The volcanic glow along the lower edge — static.
  void _emberGlow(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.55, size.width, size.height * 0.45),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, size.height * 0.55),
          Offset(0, size.height),
          [
            theme.accent.withValues(alpha: 0.0),
            theme.accent.withValues(alpha: 0.11 * strength),
          ],
        ),
    );
  }

  @override
  bool shouldRepaint(BackdropPainter old) =>
      old.theme.id != theme.id || old.strength != strength;
}

/// The only part of the backdrop that moves: sparks drifting up through the
/// Vesuvio table. Kept in its own layer so the gradient and vignette beneath
/// it are rasterised once (§54).
class _EmberPainter extends CustomPainter {
  const _EmberPainter({
    required this.theme,
    required this.t,
    required this.strength,
  });

  final TableTheme theme;
  final double t;
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(19);
    for (var i = 0; i < 26; i++) {
      final seed = rng.nextDouble();
      final speed = 0.35 + seed * 0.9;
      final y = 1.05 - ((t * speed + seed) % 1.0) * 1.15;
      final x = seed + math.sin((t * math.pi * 2 * speed) + i) * 0.035;
      final r = (1.2 + rng.nextDouble() * 2.6) * strength;
      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        r,
        Paint()
          ..color = theme.particle
              .withValues(alpha: (0.10 + rng.nextDouble() * 0.18) * strength),
      );
    }
  }

  @override
  bool shouldRepaint(_EmberPainter old) => old.t != t;
}
