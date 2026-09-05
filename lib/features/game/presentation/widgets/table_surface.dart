import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_durations.dart';
import '../../../../core/utils/glow.dart';
import '../../../../core/utils/motion.dart';
import '../../domain/card_suit.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/table_themes.dart';

/// §35 "Tavolo Vivo" — the felt, and the light it throws.
///
/// The table carries a wash tinted by the active suit: a golden glimmer for
/// Denari, a wine vignette for Coppe, a steel sweep for Spade, an olive edge
/// for Bastoni. The transition takes about half a second, so a Cavallo
/// visibly changes the mood of the table without ever obscuring a card.
class TableSurface extends StatefulWidget {
  const TableSurface({
    super.key,
    required this.theme,
    required this.activeSuit,
    this.intensity = 1.0,
    this.showSigil = false,
  });

  final TableTheme theme;
  final CardSuit activeSuit;

  /// §shop — "Sigillo del 101" (`gadget.01`): a gold laurel seal struck into
  /// the felt. Pure ornament in the static felt layer — it costs nothing per
  /// frame and touches no rule, score or card.
  final bool showSigil;

  /// Scaled down while overlays are open so effects never fight the UI.
  final double intensity;

  @override
  State<TableSurface> createState() => _TableSurfaceState();
}

class _TableSurfaceState extends State<TableSurface>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ambient;

  @override
  void initState() {
    super.initState();
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
    if (Motion.allowAmbient) _ambient.repeat();
  }

  @override
  void didUpdateWidget(TableSurface old) {
    super.didUpdateWidget(old);
    if (Motion.allowAmbient && !_ambient.isAnimating) {
      _ambient.repeat();
    } else if (!Motion.allowAmbient && _ambient.isAnimating) {
      _ambient.stop();
    }
  }

  @override
  void dispose() {
    _ambient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = SuitPalette.of(widget.activeSuit);
    // §54 — the felt's drop shadow is a large blur. It is painted into its own
    // layer that only changes with the table theme, so the per-frame cost is
    // just the suit wash on top of it.
    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _FeltBasePainter(
                theme: widget.theme,
                sigil: widget.showSigil,
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: RepaintBoundary(
            child: TweenAnimationBuilder<Color?>(
              tween: ColorTween(end: palette.ambient),
              duration: Motion.scale(AppDurations.ambientShift),
              curve: Curves.easeInOut,
              builder: (context, ambient, _) {
                return AnimatedBuilder(
                  animation: _ambient,
                  builder: (context, child) => CustomPaint(
                    painter: _AmbientPainter(
                      ambient: ambient ?? palette.ambient,
                      suit: widget.activeSuit,
                      // 24 steps per cycle: the drift is imperceptible at
                      // that rate and 23 of every 24 frames skip the paint.
                      t: (_ambient.value * 24).floor() / 24,
                      intensity: widget.intensity,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Geometry shared by both felt layers so the wash lines up exactly with the
/// surface it is lighting.
Rect _feltRect(Size size) {
  final centre = Offset(size.width / 2, size.height * 0.48);
  return Rect.fromCenter(
    center: centre,
    width: size.width * 1.24,
    height: size.height * 0.92,
  );
}

class _FeltBasePainter extends CustomPainter {
  const _FeltBasePainter({required this.theme, this.sigil = false});

  final TableTheme theme;
  final bool sigil;

  @override
  void paint(Canvas canvas, Size size) {
    final felt = _feltRect(size);
    final centre = felt.center;
    final rx = felt.width / 2;
    final ry = felt.height / 2;

    // Ground shadow under the felt.
    Glow.oval(
      canvas,
      felt.inflate(size.width * 0.06).shift(Offset(0, size.height * 0.025)),
      AppColors.inkDeep.withValues(alpha: 0.55),
      core: 0.72,
    );

    // The felt itself.
    canvas.drawOval(
      felt,
      Paint()
        ..shader = ui.Gradient.radial(
          centre.translate(0, -ry * 0.22),
          rx * 1.15,
          [
            Color.lerp(theme.feltInner, Colors.white, 0.05)!,
            theme.feltInner,
            theme.feltOuter,
          ],
          const [0.0, 0.45, 1.0],
        ),
    );

    // Gold rim, doubled.
    canvas.drawOval(
      felt,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.5, size.width * 0.006)
        ..color = theme.feltRim.withValues(alpha: 0.55),
    );
    canvas.drawOval(
      felt.deflate(size.width * 0.016),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.8, size.width * 0.002)
        ..color = theme.feltRim.withValues(alpha: 0.24),
    );

    // Inner shade so the cards sit in a well rather than on a flat disc.
    canvas.drawOval(
      felt,
      Paint()
        ..shader = ui.Gradient.radial(
          centre,
          rx,
          [Colors.transparent, AppColors.inkDeep.withValues(alpha: 0.28)],
          const [0.72, 1.0],
        ),
    );

    if (sigil) _paintSigil(canvas, size, felt);
  }

  /// The Sigillo del 101: a double gold ring, two laurel sprigs and the 101
  /// numeral — the same medallion motif the card backs carry, embossed low
  /// on the felt where no card ever lands.
  void _paintSigil(Canvas canvas, Size size, Rect felt) {
    final r = size.width * 0.052;
    final at = Offset(felt.center.dx, felt.center.dy + felt.height * 0.355);
    final gold = Color.lerp(theme.feltRim, const Color(0xFFF2CF7A), 0.5)!;

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, r * 0.07)
      ..color = gold.withValues(alpha: 0.34);
    canvas.drawCircle(at, r, ring);
    canvas.drawCircle(
      at,
      r * 0.82,
      ring
        ..strokeWidth = math.max(0.7, r * 0.04)
        ..color = gold.withValues(alpha: 0.22),
    );

    // Laurel sprigs: leaves along the lower arc, mirrored.
    final leaf = Paint()..color = gold.withValues(alpha: 0.26);
    for (var side = -1; side <= 1; side += 2) {
      for (var i = 0; i < 5; i++) {
        final a = math.pi / 2 + side * (0.28 + i * 0.30);
        final tip = at + Offset(math.cos(a), math.sin(a)) * (r * 1.06);
        canvas.save();
        canvas.translate(tip.dx, tip.dy);
        canvas.rotate(a + side * 0.9);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset.zero,
            width: r * 0.34,
            height: r * 0.14,
          ),
          leaf,
        );
        canvas.restore();
      }
    }

    final label = TextPainter(
      text: TextSpan(
        text: '101',
        style: TextStyle(
          fontSize: r * 0.72,
          fontWeight: FontWeight.w700,
          letterSpacing: r * 0.06,
          color: gold.withValues(alpha: 0.42),
          fontFamily: 'Cinzel',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(canvas, at - Offset(label.width / 2, label.height / 2));
  }

  @override
  bool shouldRepaint(_FeltBasePainter old) =>
      old.theme.id != theme.id || old.sigil != sigil;
}

/// §35 — the living light. One wash per suit, each with its own character.
class _AmbientPainter extends CustomPainter {
  const _AmbientPainter({
    required this.ambient,
    required this.suit,
    required this.t,
    required this.intensity,
  });

  final Color ambient;
  final CardSuit suit;
  final double t;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final felt = _feltRect(size);
    final centre = felt.center;
    final rx = felt.width / 2;
    final ry = felt.height / 2;
    final pulse = 0.5 + 0.5 * math.sin(t * math.pi * 2);
    final strength = intensity * (Motion.allowAmbient ? 1.0 : 0.6);
    canvas.save();
    canvas.clipPath(Path()..addOval(felt));

    switch (suit) {
      case CardSuit.denari:
        // A slow glimmer of struck gold.
        final rng = math.Random(3);
        for (var i = 0; i < 16; i++) {
          final a = rng.nextDouble() * math.pi * 2;
          final d = 0.25 + rng.nextDouble() * 0.72;
          final phase = (t + rng.nextDouble()) % 1.0;
          final at =
              centre + Offset(math.cos(a) * rx * d, math.sin(a) * ry * d);
          final r = (2.0 + rng.nextDouble() * 4.0);
          Glow.circle(
            canvas,
            at,
            r * 3.0,
            ambient.withValues(
              alpha: math.sin(phase * math.pi) * 0.34 * strength,
            ),
            core: 0.16,
          );
        }
      case CardSuit.coppe:
        // A warm vignette closing in from the rim.
        canvas.drawOval(
          felt,
          Paint()
            ..shader = ui.Gradient.radial(
              centre,
              rx,
              [
                Colors.transparent,
                ambient.withValues(alpha: (0.10 + pulse * 0.05) * strength),
              ],
              const [0.45, 1.0],
            ),
        );
      case CardSuit.spade:
        // A cool sweep of light crossing the felt.
        final x = (t * 1.6 - 0.3) % 1.6 - 0.3;
        canvas.drawRect(
          felt,
          Paint()
            ..shader = ui.Gradient.linear(
              Offset(felt.left + felt.width * (x - 0.22), felt.top),
              Offset(felt.left + felt.width * (x + 0.22), felt.bottom),
              [
                Colors.transparent,
                ambient.withValues(alpha: 0.13 * strength),
                Colors.transparent,
              ],
              const [0.0, 0.5, 1.0],
            ),
        );
      case CardSuit.bastoni:
        // Soft olive light along the lower edge.
        canvas.drawRect(
          felt,
          Paint()
            ..shader = ui.Gradient.linear(
              Offset(centre.dx, felt.top + felt.height * 0.45),
              Offset(centre.dx, felt.bottom),
              [
                Colors.transparent,
                ambient.withValues(alpha: (0.11 + pulse * 0.04) * strength),
              ],
            ),
        );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_AmbientPainter old) =>
      old.ambient != ambient ||
      old.suit != suit ||
      old.t != t ||
      old.intensity != intensity;
}

/// §31 — the ring of turn flow.
///
/// Instead of announcing whose turn it is in words, a light runs around the
/// table toward the seat about to play.
class DirectionRing extends StatelessWidget {
  const DirectionRing({
    super.key,
    required this.seatAngles,
    required this.activeIndex,
    required this.accent,
  });

  /// Angle of every seat around the table, in radians (0 = right, clockwise).
  final List<double> seatAngles;
  final int activeIndex;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final target = activeIndex.clamp(0, math.max(0, seatAngles.length - 1));
    return RepaintBoundary(
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: target.toDouble()),
        duration: Motion.scale(const Duration(milliseconds: 420)),
        curve: Curves.easeInOutCubic,
        builder: (context, value, _) => CustomPaint(
          painter: _DirectionRingPainter(
            seatAngles: seatAngles,
            position: value,
            accent: accent,
          ),
        ),
      ),
    );
  }
}

class _DirectionRingPainter extends CustomPainter {
  const _DirectionRingPainter({
    required this.seatAngles,
    required this.position,
    required this.accent,
  });

  final List<double> seatAngles;
  final double position;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    if (seatAngles.isEmpty) return;
    final centre = Offset(size.width / 2, size.height * 0.48);
    final rx = size.width * 0.665;
    final ry = size.height * 0.505;
    final rect = Rect.fromCenter(center: centre, width: rx * 2, height: ry * 2);

    canvas.drawOval(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = accent.withValues(alpha: 0.14),
    );

    // Interpolate the head of the light between the two nearest seats.
    final n = seatAngles.length;
    final lower = position.floor() % n;
    final upper = (lower + 1) % n;
    final frac = position - position.floor();
    var a0 = seatAngles[lower];
    var a1 = seatAngles[upper];
    while (a1 < a0) {
      a1 += math.pi * 2;
    }
    final head = a0 + (a1 - a0) * frac;
    const span = 0.9;

    canvas.drawArc(
      rect,
      head - span,
      span,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3.0
        ..shader = ui.Gradient.sweep(
          centre,
          [accent.withValues(alpha: 0.0), accent.withValues(alpha: 0.75)],
          const [0.0, 1.0],
          TileMode.clamp,
          head - span,
          head,
        ),
    );

    // A bead of light at the leading edge.
    final at = Offset(
      centre.dx + math.cos(head) * rx,
      centre.dy + math.sin(head) * ry,
    );
    canvas.drawCircle(at, 3.6, Paint()..color = accent);
    Glow.circle(canvas, at, 13.0, accent.withValues(alpha: 0.40), core: 0.22);
  }

  @override
  bool shouldRepaint(_DirectionRingPainter old) =>
      old.position != position || old.accent != accent;
}
