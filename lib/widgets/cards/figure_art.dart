import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Heraldic emblems for the three court cards (§5).
///
/// Fante wears a plumed helm, Cavallo is a horse in profile, Re is a crown.
/// All three are original constructions in a unit square — no commercial
/// deck was traced.
class FigureArt {
  const FigureArt._();

  static Paint _fill(Color c) => Paint()
    ..color = c
    ..isAntiAlias = true;

  static Paint _stroke(Color c, double w) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = c
    ..isAntiAlias = true;

  static Shader _metal(SuitPalette p) => ui.Gradient.linear(
        const Offset(0.2, 0.05),
        const Offset(0.8, 0.95),
        [p.light, p.primary, p.deep],
        const [0.0, 0.5, 1.0],
      );

  /// Fante — a knight's helm in profile, facing left, under a crest plume.
  static void helm(Canvas canvas, Rect rect, SuitPalette p) {
    canvas.save();
    canvas.translate(rect.left, rect.top);
    canvas.scale(rect.width, rect.height);
    final body = Paint()..shader = _metal(p)..isAntiAlias = true;

    // Three feathers sweeping back from the crest.
    for (var i = 0; i < 3; i++) {
      final lift = i * 0.055;
      final plume = Path()
        ..moveTo(0.56 + lift * 0.4, 0.22 - lift)
        ..cubicTo(0.74, 0.02 + lift * 0.5, 0.96, 0.16 + lift, 0.90, 0.40 + lift)
        ..cubicTo(0.86, 0.26 + lift, 0.74, 0.20 + lift, 0.62 + lift * 0.4,
            0.30 - lift * 0.5)
        ..close();
      canvas.drawPath(
          plume,
          _fill(Color.lerp(p.light, p.primary, i * 0.35)!
              .withValues(alpha: 0.9)));
      canvas.drawPath(plume, _stroke(p.deep, 0.018));
    }

    // Skull of the helm.
    final dome = Path()
      ..moveTo(0.16, 0.54)
      ..cubicTo(0.14, 0.22, 0.72, 0.18, 0.72, 0.50)
      ..lineTo(0.72, 0.54)
      ..close();
    canvas.drawPath(dome, body);
    canvas.drawPath(dome, _stroke(p.deep, 0.028));

    // Face plate: pushed forward to a point, the silhouette's key read.
    final face = Path()
      ..moveTo(0.16, 0.54)
      ..lineTo(0.72, 0.54)
      ..lineTo(0.70, 0.80)
      ..cubicTo(0.60, 0.90, 0.42, 0.92, 0.30, 0.86)
      ..lineTo(0.055, 0.685)
      ..close();
    canvas.drawPath(face, body);
    canvas.drawPath(face, _stroke(p.deep, 0.028));

    // Sight slit, cut dark and wide so it survives at pip size.
    final slit = Path()
      ..moveTo(0.115, 0.645)
      ..lineTo(0.695, 0.605)
      ..lineTo(0.695, 0.675)
      ..lineTo(0.155, 0.700)
      ..close();
    canvas.drawPath(slit, _fill(p.deep));

    // Breaths.
    for (var i = 0; i < 3; i++) {
      final y = 0.760 + i * 0.048;
      canvas.drawLine(Offset(0.32 + i * 0.045, y), Offset(0.62, y),
          _stroke(p.deep, 0.020));
    }

    // Gorget.
    canvas.drawLine(const Offset(0.30, 0.945), const Offset(0.70, 0.945),
        _stroke(p.deep, 0.034));
    canvas.restore();
  }

  /// Cavallo — a horse's head in profile, facing left.
  static void horse(Canvas canvas, Rect rect, SuitPalette p) {
    canvas.save();
    canvas.translate(rect.left, rect.top);
    canvas.scale(rect.width, rect.height);
    final body = Paint()..shader = _metal(p)..isAntiAlias = true;

    final head = Path()
      // Muzzle, down the nose, round the jaw and up the neck.
      ..moveTo(0.13, 0.46)
      ..cubicTo(0.075, 0.505, 0.085, 0.580, 0.165, 0.595)
      ..cubicTo(0.27, 0.60, 0.34, 0.66, 0.40, 0.74)
      ..cubicTo(0.47, 0.83, 0.58, 0.92, 0.72, 0.945)
      ..lineTo(0.90, 0.945)
      ..cubicTo(0.82, 0.80, 0.80, 0.60, 0.78, 0.44)
      ..cubicTo(0.775, 0.29, 0.70, 0.215, 0.615, 0.195)
      // Ears: two distinct points with a notch between them.
      ..lineTo(0.650, 0.045)
      ..lineTo(0.520, 0.160)
      ..lineTo(0.470, 0.115)
      ..lineTo(0.400, 0.060)
      ..lineTo(0.395, 0.225)
      ..cubicTo(0.295, 0.275, 0.195, 0.355, 0.13, 0.46)
      ..close();
    canvas.drawPath(head, body);
    canvas.drawPath(head, _stroke(p.deep, 0.026));

    // Mane running down the crest of the neck.
    final mane = Path()
      ..moveTo(0.60, 0.21)
      ..cubicTo(0.72, 0.30, 0.80, 0.48, 0.84, 0.70)
      ..cubicTo(0.86, 0.82, 0.88, 0.90, 0.90, 0.945);
    canvas.drawPath(mane, _stroke(p.deep, 0.024));

    // Eye and nostril.
    canvas.drawCircle(const Offset(0.435, 0.375), 0.038, _fill(p.deep));
    canvas.drawCircle(const Offset(0.425, 0.365), 0.014,
        _fill(p.light.withValues(alpha: 0.9)));
    canvas.drawCircle(const Offset(0.175, 0.50), 0.026, _fill(p.deep));
    // Cheek strap.
    canvas.drawLine(const Offset(0.30, 0.36), const Offset(0.365, 0.53),
        _stroke(p.deep, 0.018));
    canvas.restore();
  }

  /// Re — a five-point crown with jewels.
  static void crown(Canvas canvas, Rect rect, SuitPalette p) {
    canvas.save();
    canvas.translate(rect.left, rect.top);
    canvas.scale(rect.width, rect.height);
    final body = Paint()..shader = _metal(p)..isAntiAlias = true;

    final crown = Path()
      ..moveTo(0.10, 0.72)
      ..lineTo(0.10, 0.30)
      ..lineTo(0.26, 0.50)
      ..lineTo(0.38, 0.20)
      ..lineTo(0.50, 0.44)
      ..lineTo(0.62, 0.20)
      ..lineTo(0.74, 0.50)
      ..lineTo(0.90, 0.30)
      ..lineTo(0.90, 0.72)
      ..close();
    canvas.drawPath(crown, body);
    canvas.drawPath(crown, _stroke(p.deep, 0.026));

    // Band.
    final band = Rect.fromLTRB(0.075, 0.72, 0.925, 0.885);
    canvas.drawRRect(
        RRect.fromRectAndRadius(band, const Radius.circular(0.045)), body);
    canvas.drawRRect(
        RRect.fromRectAndRadius(band, const Radius.circular(0.045)),
        _stroke(p.deep, 0.026));

    // Jewels on the points and along the band.
    for (final pt in const [Offset(0.10, 0.265), Offset(0.38, 0.165),
      Offset(0.62, 0.165), Offset(0.90, 0.265)]) {
      canvas.drawCircle(pt, 0.052, _fill(p.light));
      canvas.drawCircle(pt, 0.052, _stroke(p.deep, 0.020));
    }
    for (var i = 0; i < 3; i++) {
      final x = 0.28 + i * 0.22;
      canvas.drawCircle(Offset(x, 0.803), 0.036, _fill(p.deep));
    }
    canvas.restore();
  }

  /// The arched niche the emblems sit in.
  static Path niche(Rect r) {
    final w = r.width;
    final h = r.height;
    final springLine = r.top + h * 0.34;
    return Path()
      ..moveTo(r.left, r.bottom)
      ..lineTo(r.left, springLine)
      ..cubicTo(
        r.left, r.top - h * 0.02,
        r.right, r.top - h * 0.02,
        r.right, springLine,
      )
      ..lineTo(r.right, r.bottom)
      ..close()
      ..addRect(Rect.fromLTWH(r.left, r.bottom - 1, w, 1));
  }

  /// A small four-petal fleuron used in card corners and frames.
  static void fleuron(Canvas canvas, Offset centre, double radius, Color color) {
    final paint = _fill(color);
    canvas.save();
    canvas.translate(centre.dx, centre.dy);
    for (var i = 0; i < 4; i++) {
      canvas.save();
      canvas.rotate(i * math.pi / 2);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(0, -radius * 0.52),
          width: radius * 0.62,
          height: radius * 1.00,
        ),
        paint,
      );
      canvas.restore();
    }
    canvas.drawCircle(Offset.zero, radius * 0.24, paint);
    canvas.restore();
  }
}
