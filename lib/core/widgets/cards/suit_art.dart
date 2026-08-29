import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../features/game/domain/card_suit.dart';
import '../../../app/theme/app_colors.dart';

/// Original Neapolitan suit emblems, drawn as vector art.
///
/// Every symbol is authored inside a unit square and scaled into whatever
/// rectangle it is asked for, so a 14 px corner pip and a 90 px centrepiece
/// come from exactly the same geometry (§5). Nothing here traces a
/// commercial deck: the shapes are built from primitives.
class SuitArt {
  const SuitArt._();

  /// Paints [suit] to fill [rect]. [detail] fades out the fine engraving on
  /// small pips, where it would only turn to mud.
  static void draw(
    Canvas canvas,
    Rect rect,
    CardSuit suit,
    SuitPalette palette, {
    double detail = 1.0,
    double opacity = 1.0,
  }) {
    canvas.save();
    canvas.translate(rect.left, rect.top);
    canvas.scale(rect.width, rect.height);
    switch (suit) {
      case CardSuit.denari:
        _denari(canvas, palette, detail, opacity);
      case CardSuit.coppe:
        _coppe(canvas, palette, detail, opacity);
      case CardSuit.spade:
        _spade(canvas, palette, detail, opacity);
      case CardSuit.bastoni:
        _bastoni(canvas, palette, detail, opacity);
    }
    canvas.restore();
  }

  static Paint _fill(Color color, double opacity) => Paint()
    ..style = PaintingStyle.fill
    ..color = color.withValues(alpha: color.a * opacity)
    ..isAntiAlias = true;

  static Paint _stroke(Color color, double width, double opacity) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = color.withValues(alpha: color.a * opacity)
    ..isAntiAlias = true;

  // ------------------------------------------------------------- DENARI
  // A struck coin: milled rim, engraved field, eight-point rosette.

  static void _denari(
      Canvas canvas, SuitPalette p, double detail, double o) {
    const c = Offset(0.5, 0.5);
    final shader = ui.Gradient.linear(
      const Offset(0.15, 0.1),
      const Offset(0.85, 0.92),
      [p.light.withValues(alpha: o), p.primary.withValues(alpha: o),
        p.deep.withValues(alpha: o)],
      const [0.0, 0.55, 1.0],
    );

    canvas.drawCircle(c, 0.47, Paint()..shader = shader..isAntiAlias = true);
    canvas.drawCircle(c, 0.47, _stroke(p.deep, 0.035, o));
    canvas.drawCircle(c, 0.385, _stroke(p.deep, 0.022, o * 0.85));

    if (detail > 0.35) {
      // Milled edge.
      final ticks = 28;
      for (var i = 0; i < ticks; i++) {
        final a = (i / ticks) * math.pi * 2;
        final outer = c + Offset(math.cos(a), math.sin(a)) * 0.465;
        final inner = c + Offset(math.cos(a), math.sin(a)) * 0.415;
        canvas.drawLine(inner, outer, _stroke(p.deep, 0.014, o * 0.55 * detail));
      }
    }

    // Eight-point rosette.
    final star = Path();
    const points = 8;
    for (var i = 0; i < points * 2; i++) {
      final a = (i / (points * 2)) * math.pi * 2 - math.pi / 2;
      final r = i.isEven ? 0.30 : 0.135;
      final pt = c + Offset(math.cos(a) * r, math.sin(a) * r);
      if (i == 0) {
        star.moveTo(pt.dx, pt.dy);
      } else {
        star.lineTo(pt.dx, pt.dy);
      }
    }
    star.close();
    canvas.drawPath(star, _fill(p.deep, o * 0.92));
    canvas.drawCircle(c, 0.085, _fill(p.light, o));
    canvas.drawCircle(c, 0.085, _stroke(p.deep, 0.018, o));

    if (detail > 0.5) {
      canvas.drawCircle(c, 0.325, _stroke(p.deep, 0.012, o * 0.5 * detail));
    }
  }

  // -------------------------------------------------------------- COPPE
  // A footed chalice with a domed lid — the Neapolitan cup silhouette.

  static void _coppe(Canvas canvas, SuitPalette p, double detail, double o) {
    final shader = ui.Gradient.linear(
      const Offset(0.2, 0.05),
      const Offset(0.8, 0.95),
      [p.light.withValues(alpha: o), p.primary.withValues(alpha: o),
        p.deep.withValues(alpha: o)],
      const [0.0, 0.5, 1.0],
    );
    final body = Paint()..shader = shader..isAntiAlias = true;

    // Bowl.
    final bowl = Path()
      ..moveTo(0.20, 0.34)
      ..cubicTo(0.20, 0.62, 0.32, 0.72, 0.50, 0.72)
      ..cubicTo(0.68, 0.72, 0.80, 0.62, 0.80, 0.34)
      ..close();
    canvas.drawPath(bowl, body);
    canvas.drawPath(bowl, _stroke(p.deep, 0.028, o));

    // Lip.
    canvas.drawLine(const Offset(0.185, 0.34), const Offset(0.815, 0.34),
        _stroke(p.deep, 0.034, o));

    // Domed lid and finial.
    final dome = Path()
      ..moveTo(0.30, 0.34)
      ..cubicTo(0.30, 0.16, 0.70, 0.16, 0.70, 0.34)
      ..close();
    canvas.drawPath(dome, body);
    canvas.drawPath(dome, _stroke(p.deep, 0.024, o));
    canvas.drawCircle(const Offset(0.5, 0.135), 0.055, body);
    canvas.drawCircle(const Offset(0.5, 0.135), 0.055, _stroke(p.deep, 0.022, o));

    // Stem, knop and foot.
    final stem = Path()
      ..moveTo(0.44, 0.72)
      ..lineTo(0.56, 0.72)
      ..lineTo(0.545, 0.80)
      ..lineTo(0.455, 0.80)
      ..close();
    canvas.drawPath(stem, body);
    canvas.drawPath(stem, _stroke(p.deep, 0.02, o));
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(0.5, 0.80), width: 0.20, height: 0.075),
        body);
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(0.5, 0.80), width: 0.20, height: 0.075),
        _stroke(p.deep, 0.02, o));

    final foot = Path()
      ..moveTo(0.30, 0.90)
      ..cubicTo(0.36, 0.83, 0.64, 0.83, 0.70, 0.90)
      ..close();
    canvas.drawPath(foot, body);
    canvas.drawPath(foot, _stroke(p.deep, 0.024, o));

    if (detail > 0.45) {
      // Engraved band across the bowl.
      canvas.drawLine(const Offset(0.235, 0.50), const Offset(0.765, 0.50),
          _stroke(p.deep, 0.016, o * 0.6 * detail));
      canvas.drawLine(const Offset(0.255, 0.555), const Offset(0.745, 0.555),
          _stroke(p.deep, 0.012, o * 0.4 * detail));
    }
  }

  // -------------------------------------------------------------- SPADE
  // A straight sword: fullered blade, curved quillons, ringed pommel.

  static void _spade(Canvas canvas, SuitPalette p, double detail, double o) {
    final steel = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0.38, 0.0),
        const Offset(0.62, 1.0),
        [p.light.withValues(alpha: o), p.primary.withValues(alpha: o),
          p.deep.withValues(alpha: o)],
        const [0.0, 0.45, 1.0],
      )
      ..isAntiAlias = true;

    // Blade.
    final blade = Path()
      ..moveTo(0.50, 0.045)
      ..lineTo(0.585, 0.20)
      ..lineTo(0.575, 0.615)
      ..lineTo(0.425, 0.615)
      ..lineTo(0.415, 0.20)
      ..close();
    canvas.drawPath(blade, steel);
    canvas.drawPath(blade, _stroke(p.deep, 0.024, o));

    if (detail > 0.4) {
      canvas.drawLine(const Offset(0.5, 0.11), const Offset(0.5, 0.60),
          _stroke(p.deep, 0.016, o * 0.55 * detail));
    }

    // Quillons.
    final guard = Path()
      ..moveTo(0.095, 0.735)
      ..cubicTo(0.26, 0.575, 0.74, 0.575, 0.905, 0.735)
      ..cubicTo(0.855, 0.700, 0.74, 0.648, 0.575, 0.640)
      ..lineTo(0.425, 0.640)
      ..cubicTo(0.26, 0.648, 0.145, 0.700, 0.095, 0.735)
      ..close();
    canvas.drawPath(guard, steel);
    canvas.drawPath(guard, _stroke(p.deep, 0.026, o));

    // Grip.
    final grip = RRect.fromRectAndRadius(
      Rect.fromLTRB(0.445, 0.695, 0.555, 0.875),
      const Radius.circular(0.03),
    );
    canvas.drawRRect(grip, steel);
    canvas.drawRRect(grip, _stroke(p.deep, 0.022, o));
    if (detail > 0.45) {
      for (var i = 0; i < 3; i++) {
        final y = 0.735 + i * 0.045;
        canvas.drawLine(Offset(0.455, y), Offset(0.545, y),
            _stroke(p.deep, 0.014, o * 0.6 * detail));
      }
    }

    // Pommel.
    canvas.drawCircle(const Offset(0.5, 0.925), 0.065, steel);
    canvas.drawCircle(const Offset(0.5, 0.925), 0.065, _stroke(p.deep, 0.024, o));
  }

  // ------------------------------------------------------------ BASTONI
  // A rough-hewn cudgel, tilted the way it is cut in a Neapolitan deck:
  // heavy knuckled head, tapering shaft, bark rings, trimmed knots. No long
  // side branches — those read as a plant rather than a club.

  static void _bastoni(
      Canvas canvas, SuitPalette p, double detail, double o) {
    canvas.save();
    canvas.translate(0.5, 0.5);
    canvas.rotate(-0.20);
    canvas.translate(-0.5, -0.5);

    final wood = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0.30, 0.05),
        const Offset(0.72, 0.95),
        [p.light.withValues(alpha: o), p.primary.withValues(alpha: o),
          p.deep.withValues(alpha: o)],
        const [0.0, 0.46, 1.0],
      )
      ..isAntiAlias = true;

    // Silhouette: broad domed head, a waist, then a shaft that keeps
    // narrowing to a cut end. The knots are bumps in the outline itself.
    final club = Path()
      ..moveTo(0.50, 0.040)
      ..cubicTo(0.645, 0.040, 0.720, 0.145, 0.700, 0.250)
      ..cubicTo(0.690, 0.315, 0.664, 0.345, 0.658, 0.400)
      ..cubicTo(0.692, 0.432, 0.688, 0.480, 0.652, 0.505)
      ..cubicTo(0.643, 0.590, 0.634, 0.652, 0.626, 0.700)
      ..cubicTo(0.656, 0.726, 0.652, 0.770, 0.618, 0.790)
      ..cubicTo(0.612, 0.862, 0.606, 0.916, 0.602, 0.955)
      ..lineTo(0.398, 0.955)
      ..cubicTo(0.394, 0.916, 0.388, 0.862, 0.382, 0.790)
      ..cubicTo(0.348, 0.770, 0.344, 0.726, 0.374, 0.700)
      ..cubicTo(0.366, 0.652, 0.357, 0.590, 0.348, 0.505)
      ..cubicTo(0.312, 0.480, 0.308, 0.432, 0.342, 0.400)
      ..cubicTo(0.336, 0.345, 0.310, 0.315, 0.300, 0.250)
      ..cubicTo(0.280, 0.145, 0.355, 0.040, 0.50, 0.040)
      ..close();
    canvas.drawPath(club, wood);
    canvas.drawPath(club, _stroke(p.deep, 0.030, o));

    // The waist under the head is the shape's strongest read.
    canvas.drawLine(const Offset(0.340, 0.398), const Offset(0.660, 0.398),
        _stroke(p.deep, 0.028, o * 0.95));

    if (detail > 0.4) {
      // Grain across the head and bark rings down the shaft.
      canvas.drawArc(
        Rect.fromCircle(center: const Offset(0.50, 0.205), radius: 0.125),
        math.pi * 0.18,
        math.pi * 0.64,
        false,
        _stroke(p.deep, 0.020, o * 0.55 * detail),
      );
      canvas.drawLine(const Offset(0.362, 0.592), const Offset(0.638, 0.592),
          _stroke(p.deep, 0.018, o * 0.5 * detail));
      canvas.drawLine(const Offset(0.392, 0.870), const Offset(0.608, 0.870),
          _stroke(p.deep, 0.018, o * 0.5 * detail));
      // A cut knot, flush with the shaft.
      canvas.drawCircle(const Offset(0.500, 0.700), 0.038,
          _stroke(p.deep, 0.018, o * 0.6 * detail));
    }
    canvas.restore();
  }

  /// A compact glyph for badges and buttons, on a transparent ground.
  static void drawBadge(
    Canvas canvas,
    Rect rect,
    CardSuit suit, {
    Color? tint,
    double opacity = 1.0,
  }) {
    final palette = SuitPalette.of(suit);
    final p = tint == null
        ? palette
        : SuitPalette(
            primary: tint,
            deep: Color.lerp(tint, AppColors.inkDeep, 0.45)!,
            light: Color.lerp(tint, Colors.white, 0.5)!,
            ambient: tint,
          );
    draw(canvas, rect, suit, p, detail: 0.5, opacity: opacity);
  }
}
