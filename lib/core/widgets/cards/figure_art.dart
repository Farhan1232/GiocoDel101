import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../features/game/domain/card_suit.dart';
import '../../../app/theme/app_colors.dart';

/// Garment colours for one suit's court.
///
/// A Neapolitan deck dresses each suit's court differently — the King of
/// Swords is blue over red under a green mantle, the King of Clubs is green
/// over a red mantle — so the four courts stay tellable apart by cloth as
/// well as by the sign each figure carries (§48).
class CourtPalette {
  const CourtPalette({
    required this.cape,
    required this.lining,
    required this.robe,
    required this.sleeve,
    required this.skirt,
    required this.hose,
    required this.crown,
    required this.plinth,
  });

  /// The mantle hanging behind the figure.
  final Color cape;

  /// The mantle's turned-back facing, showing on one side only.
  final Color lining;

  final Color robe;
  final Color sleeve;
  final Color skirt;
  final Color hose;
  final Color crown;

  /// The ground bar the figure stands on.
  final Color plinth;

  // The four woodcut inks. Deliberately a touch deeper and warmer than
  // printers' primaries so the figures sit on ivory stock without shouting.
  static const Color red = Color(0xFFBE3A2E);
  static const Color blue = Color(0xFF2C5FA6);
  static const Color green = Color(0xFF3B7A44);
  static const Color gold = Color(0xFFDFAB33);

  static CourtPalette of(CardSuit suit) {
    switch (suit) {
      case CardSuit.denari:
        return const CourtPalette(
          cape: red, lining: blue, robe: blue, sleeve: gold,
          skirt: green, hose: gold, crown: gold, plinth: gold,
        );
      case CardSuit.coppe:
        return const CourtPalette(
          cape: green, lining: gold, robe: red, sleeve: gold,
          skirt: blue, hose: gold, crown: red, plinth: red,
        );
      case CardSuit.spade:
        return const CourtPalette(
          cape: green, lining: blue, robe: blue, sleeve: gold,
          skirt: red, hose: gold, crown: blue, plinth: blue,
        );
      case CardSuit.bastoni:
        return const CourtPalette(
          cape: blue, lining: gold, robe: green, sleeve: red,
          skirt: red, hose: gold, crown: green, plinth: green,
        );
    }
  }
}

/// The three court figures, drawn as full-length Neapolitan woodcuts (§5).
///
/// Every figure is authored in a space one unit wide and [aspect] units tall
/// and scaled *uniformly* into whatever rectangle it is given, so outlines keep
/// an even weight instead of smearing along one axis. Fante is a standing
/// page under a plumed cap, Cavallo is a rider on horseback, Re is a crowned
/// king — each holding the sign of its own suit. All three are original
/// constructions: no commercial deck was traced.
class FigureArt {
  const FigureArt._();

  /// Height of the authoring space, and so the ratio the court rectangle must
  /// have for a figure to fill it under a uniform scale.
  static const double aspect = 1.75;

  // Fixed inks shared by every court.
  static const Color _ink = Color(0xFF241C16);
  static const Color _flesh = Color(0xFFEAC49B);
  static const Color _hair = Color(0xFFCEC6B5);
  static const Color _linen = Color(0xFFF2EDE0);
  static const Color _silver = Color(0xFFDBD9D1);

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

  /// Fill then outline, the way a woodcut is inked.
  static void _plate(Canvas canvas, Path path, Color colour,
      {double weight = 0.016}) {
    canvas.drawPath(path, _fill(colour));
    canvas.drawPath(path, _stroke(_ink, weight));
  }

  /// Engraved shading inside [shape]: parallel strokes, clipped.
  static void _hatch(Canvas canvas, Path shape, double opacity,
      {double spacing = 0.040, double weight = 0.008}) {
    if (opacity <= 0.02) return;
    canvas.save();
    canvas.clipPath(shape);
    final b = shape.getBounds();
    final paint = _stroke(_ink.withValues(alpha: opacity), weight);
    final slant = b.height * 0.42;
    for (var x = b.left - slant; x <= b.right + spacing; x += spacing) {
      canvas.drawLine(
          Offset(x, b.bottom), Offset(x + slant, b.top), paint);
    }
    canvas.restore();
  }

  // ------------------------------------------------------------ entry point

  /// Draws the court figure for [suit] into [rect] under a uniform scale.
  ///
  /// [detail] fades the engraving — faces, hatching, jewels — out of the
  /// small cards in a tight fan, where it would only turn to mud.
  static void standing(Canvas canvas, Rect rect, CardSuit suit,
      {required bool king, double detail = 1.0}) {
    canvas.save();
    canvas.translate(rect.left, rect.top);
    canvas.scale(rect.width);
    _standing(canvas, suit, king: king, detail: detail);
    canvas.restore();
  }

  /// Draws the mounted Cavallo into [rect] under a uniform scale.
  static void rider(Canvas canvas, Rect rect, CardSuit suit,
      {double detail = 1.0}) {
    canvas.save();
    canvas.translate(rect.left, rect.top);
    canvas.scale(rect.width);
    _rider(canvas, suit, detail);
    canvas.restore();
  }

  // ------------------------------------------------------------ the ground

  static void _plinth(Canvas canvas, Color colour, double detail) {
    final bar = Path()
      ..addRect(const Rect.fromLTRB(0.10, 1.654, 0.90, 1.741));
    _plate(canvas, bar, colour, weight: 0.014);
    if (detail > 0.5) {
      final paint = _stroke(_ink.withValues(alpha: 0.35), 0.008);
      for (var x = 0.145; x < 0.90; x += 0.055) {
        canvas.drawLine(Offset(x, 1.664), Offset(x, 1.731), paint);
      }
    }
  }

  // --------------------------------------------------------- standing court

  static void _standing(Canvas canvas, CardSuit suit,
      {required bool king, required double detail}) {
    final c = CourtPalette.of(suit);

    _plinth(canvas, c.plinth, detail);

    // Mantle, hanging behind everything from the shoulders to the ground.
    final cape = Path()
      ..moveTo(0.322, 0.500)
      ..cubicTo(0.238, 0.560, 0.196, 0.860, 0.186, 1.240)
      ..cubicTo(0.180, 1.450, 0.192, 1.580, 0.206, 1.654)
      ..lineTo(0.794, 1.654)
      ..cubicTo(0.808, 1.580, 0.820, 1.450, 0.814, 1.240)
      ..cubicTo(0.804, 0.860, 0.762, 0.560, 0.678, 0.500)
      ..close();
    _plate(canvas, cape, c.cape);
    // The mantle's facing, turned back down its trailing edge.
    final lining = Path()
      ..moveTo(0.678, 0.500)
      ..cubicTo(0.762, 0.560, 0.804, 0.860, 0.814, 1.240)
      ..cubicTo(0.820, 1.450, 0.808, 1.580, 0.794, 1.654)
      ..lineTo(0.712, 1.654)
      ..cubicTo(0.728, 1.560, 0.736, 1.410, 0.728, 1.216)
      ..cubicTo(0.716, 0.888, 0.680, 0.614, 0.624, 0.544)
      ..close();
    _plate(canvas, lining, c.lining, weight: 0.013);
    _hatch(canvas, cape, 0.16 * detail, spacing: 0.075);

    // Hose.
    final legL = Path()
      ..moveTo(0.386, 0.980)
      ..lineTo(0.482, 0.980)
      ..cubicTo(0.480, 1.180, 0.476, 1.400, 0.472, 1.584)
      ..lineTo(0.382, 1.584)
      ..cubicTo(0.378, 1.400, 0.382, 1.180, 0.386, 0.980)
      ..close();
    final legR = Path()
      ..moveTo(0.518, 0.980)
      ..lineTo(0.614, 0.980)
      ..cubicTo(0.618, 1.180, 0.622, 1.400, 0.618, 1.584)
      ..lineTo(0.528, 1.584)
      ..cubicTo(0.524, 1.400, 0.520, 1.180, 0.518, 0.980)
      ..close();
    _plate(canvas, legL, c.hose, weight: 0.015);
    _plate(canvas, legR, c.hose, weight: 0.015);
    _hatch(canvas, legL, 0.30 * detail, spacing: 0.026, weight: 0.007);
    _hatch(canvas, legR, 0.30 * detail, spacing: 0.026, weight: 0.007);

    // Shoes, toes turned out.
    for (final foot in const [(0.408, -1.0), (0.592, 1.0)]) {
      final shoe = Path()
        ..addOval(Rect.fromCenter(
          center: Offset(foot.$1 + 0.020 * foot.$2, 1.622),
          width: 0.170,
          height: 0.062,
        ));
      _plate(canvas, shoe, _silver, weight: 0.014);
    }

    // Skirt over the hose.
    final skirt = Path()
      ..moveTo(0.318, 0.790)
      ..lineTo(0.682, 0.790)
      ..cubicTo(0.702, 0.900, 0.714, 0.995, 0.716, 1.052)
      ..cubicTo(0.610, 1.098, 0.390, 1.098, 0.284, 1.052)
      ..cubicTo(0.286, 0.995, 0.298, 0.900, 0.318, 0.790)
      ..close();
    _plate(canvas, skirt, c.skirt);
    if (detail > 0.45) {
      // Pleats.
      final paint = _stroke(_ink.withValues(alpha: 0.34), 0.009);
      for (var i = 0; i < 5; i++) {
        final x = 0.362 + i * 0.070;
        canvas.drawLine(Offset(x, 0.812), Offset(x - 0.012, 1.070), paint);
      }
    }

    // Doublet.
    final torso = Path()
      ..moveTo(0.354, 0.496)
      ..cubicTo(0.322, 0.600, 0.314, 0.700, 0.320, 0.798)
      ..lineTo(0.680, 0.798)
      ..cubicTo(0.686, 0.700, 0.678, 0.600, 0.646, 0.496)
      ..close();
    _plate(canvas, torso, c.robe);
    _hatch(canvas, torso, 0.20 * detail, spacing: 0.030);

    // Belt.
    final belt = Path()
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTRB(0.306, 0.772, 0.694, 0.844),
        const Radius.circular(0.018),
      ));
    _plate(canvas, belt, CourtPalette.gold, weight: 0.013);
    if (detail > 0.5) {
      canvas.drawCircle(const Offset(0.500, 0.808), 0.024, _fill(_ink));
    }

    _arm(canvas, c, raised: true, detail: detail);
    _heldSign(canvas, suit, _rightFist, 1.0, detail);
    _hand(canvas, _rightFist, detail);

    _arm(canvas, c, raised: false, detail: detail);
    _hand(canvas, _leftPalm, detail);

    // Neck.
    final neck = Path()
      ..addRect(const Rect.fromLTRB(0.454, 0.348, 0.546, 0.492));
    _plate(canvas, neck, _flesh, weight: 0.013);

    // Mantle collar over the shoulders.
    final collar = Path()
      ..moveTo(0.288, 0.616)
      ..cubicTo(0.294, 0.504, 0.380, 0.442, 0.500, 0.442)
      ..cubicTo(0.620, 0.442, 0.706, 0.504, 0.712, 0.616)
      ..cubicTo(0.640, 0.552, 0.578, 0.528, 0.500, 0.528)
      ..cubicTo(0.422, 0.528, 0.360, 0.552, 0.288, 0.616)
      ..close();
    _plate(canvas, collar, king ? CourtPalette.red : _linen);

    if (king) {
      // Medallion of office.
      canvas.drawCircle(const Offset(0.500, 0.652), 0.068,
          _fill(CourtPalette.gold));
      canvas.drawCircle(
          const Offset(0.500, 0.652), 0.068, _stroke(_ink, 0.014));
      if (detail > 0.5) {
        canvas.drawCircle(const Offset(0.500, 0.652), 0.044,
            _stroke(_ink.withValues(alpha: 0.55), 0.010));
        canvas.drawCircle(const Offset(0.500, 0.652), 0.018, _fill(_ink));
      }
    }

    _head(canvas, const Offset(0.500, 0.290), bearded: king, detail: detail);

    if (king) {
      _crown(canvas, c.crown, detail);
    } else {
      _cap(canvas, c, detail);
    }
  }

  /// Where each fist lands, so sleeve, cuff, hand and sign all agree.
  static const Offset _rightFist = Offset(0.180, 0.788);
  static const Offset _leftPalm = Offset(0.820, 0.796);

  /// One arm: a bent sleeve slashed at the shoulder, closed by a linen cuff.
  /// The raised arm carries the suit sign, the other is held open.
  static void _arm(Canvas canvas, CourtPalette c,
      {required bool raised, required double detail}) {
    final sleeve = raised
        ? (Path()
          ..moveTo(0.352, 0.492)
          ..cubicTo(0.264, 0.512, 0.196, 0.596, 0.160, 0.692)
          ..lineTo(0.252, 0.730)
          ..cubicTo(0.284, 0.644, 0.336, 0.586, 0.402, 0.566)
          ..close())
        : (Path()
          ..moveTo(0.648, 0.492)
          ..cubicTo(0.736, 0.512, 0.804, 0.596, 0.840, 0.692)
          ..lineTo(0.748, 0.730)
          ..cubicTo(0.716, 0.644, 0.664, 0.586, 0.598, 0.566)
          ..close());
    _plate(canvas, sleeve, c.sleeve);
    _hatch(canvas, sleeve, 0.28 * detail, spacing: 0.024, weight: 0.007);

    // Linen showing through the slashed upper sleeve.
    if (detail > 0.55) {
      canvas.save();
      canvas.clipPath(sleeve);
      final slash = _stroke(_linen, 0.026);
      for (var i = 0; i < 2; i++) {
        final t = 0.030 * i;
        if (raised) {
          canvas.drawLine(Offset(0.300 - t, 0.512), Offset(0.352 - t, 0.590),
              slash);
        } else {
          canvas.drawLine(Offset(0.700 + t, 0.512), Offset(0.648 + t, 0.590),
              slash);
        }
      }
      canvas.restore();
      canvas.drawPath(sleeve, _stroke(_ink, 0.016));
    }

    // Linen cuff at the wrist.
    final cuff = raised
        ? (Path()
          ..moveTo(0.160, 0.692)
          ..lineTo(0.252, 0.730)
          ..lineTo(0.236, 0.772)
          ..lineTo(0.144, 0.734)
          ..close())
        : (Path()
          ..moveTo(0.840, 0.692)
          ..lineTo(0.748, 0.730)
          ..lineTo(0.764, 0.772)
          ..lineTo(0.856, 0.734)
          ..close());
    _plate(canvas, cuff, _linen, weight: 0.013);
  }

  static void _hand(Canvas canvas, Offset at, double detail) {
    canvas.drawCircle(at, 0.054, _fill(_flesh));
    canvas.drawCircle(at, 0.054, _stroke(_ink, 0.013));
    if (detail > 0.55) {
      final paint = _stroke(_ink.withValues(alpha: 0.45), 0.008);
      for (var i = 0; i < 3; i++) {
        final y = at.dy - 0.022 + i * 0.022;
        canvas.drawLine(
            Offset(at.dx - 0.034, y), Offset(at.dx + 0.034, y), paint);
      }
    }
  }

  /// Head, hair and — on the King — a trimmed beard.
  static void _head(Canvas canvas, Offset c,
      {required bool bearded, required double detail}) {
    final hair = Path()
      ..addOval(Rect.fromCenter(
          center: c.translate(0, 0.008), width: 0.246, height: 0.268));
    _plate(canvas, hair, _hair, weight: 0.014);

    if (bearded) {
      final beard = Path()
        ..moveTo(c.dx - 0.086, c.dy + 0.028)
        ..cubicTo(c.dx - 0.080, c.dy + 0.150, c.dx + 0.080, c.dy + 0.150,
            c.dx + 0.086, c.dy + 0.028)
        ..close();
      _plate(canvas, beard, _hair, weight: 0.013);
    }

    final face = Path()
      ..addOval(Rect.fromCenter(
          center: c.translate(0.006, 0.0), width: 0.172, height: 0.206));
    _plate(canvas, face, _flesh, weight: 0.014);

    if (detail < 0.5) return;

    // Eyes, brow, nose and moustache — the whole read of the face at size.
    final line = _stroke(_ink, 0.011);
    canvas.drawCircle(c.translate(-0.030, -0.016), 0.013, _fill(_ink));
    canvas.drawCircle(c.translate(0.046, -0.016), 0.013, _fill(_ink));
    canvas.drawLine(c.translate(-0.054, -0.052), c.translate(-0.006, -0.056),
        line);
    canvas.drawLine(c.translate(0.022, -0.056), c.translate(0.070, -0.052),
        line);
    canvas.drawLine(c.translate(0.010, -0.006), c.translate(0.004, 0.036),
        line);
    final tache = Path()
      ..moveTo(c.dx - 0.056, c.dy + 0.056)
      ..cubicTo(c.dx - 0.012, c.dy + 0.034, c.dx + 0.034, c.dy + 0.034,
          c.dx + 0.072, c.dy + 0.056);
    canvas.drawPath(tache, _stroke(_ink, 0.016));
  }

  /// Five-point crown with jewelled points.
  static void _crown(Canvas canvas, Color colour, double detail) {
    final crown = Path()
      ..moveTo(0.340, 0.192)
      ..lineTo(0.340, 0.106)
      ..lineTo(0.392, 0.154)
      ..lineTo(0.424, 0.052)
      ..lineTo(0.468, 0.136)
      ..lineTo(0.500, 0.032)
      ..lineTo(0.532, 0.136)
      ..lineTo(0.576, 0.052)
      ..lineTo(0.608, 0.154)
      ..lineTo(0.660, 0.106)
      ..lineTo(0.660, 0.192)
      ..close();
    _plate(canvas, crown, colour, weight: 0.015);

    final band = Path()
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTRB(0.330, 0.184, 0.670, 0.256),
        const Radius.circular(0.016),
      ));
    _plate(canvas, band, CourtPalette.gold, weight: 0.015);

    if (detail < 0.5) return;
    for (final pt in const [
      Offset(0.424, 0.038),
      Offset(0.500, 0.018),
      Offset(0.576, 0.038),
    ]) {
      canvas.drawCircle(pt, 0.028, _fill(CourtPalette.gold));
      canvas.drawCircle(pt, 0.028, _stroke(_ink, 0.011));
    }
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(
          Offset(0.412 + i * 0.088, 0.220), 0.020, _fill(_ink));
    }
  }

  /// The Fante's soft cap, with a feather sweeping back.
  static void _cap(Canvas canvas, CourtPalette c, double detail) {
    canvas.save();
    canvas.translate(0.748, 0.152);
    canvas.rotate(-0.72);
    final feather = Path()
      ..addOval(Rect.fromCenter(
          center: Offset.zero, width: 0.300, height: 0.092));
    _plate(canvas, feather, _linen, weight: 0.013);
    if (detail > 0.5) {
      // Quill and barbs, so the plume never reads as a blade.
      canvas.drawLine(const Offset(-0.136, 0.006), const Offset(0.140, 0.0),
          _stroke(_ink.withValues(alpha: 0.45), 0.009));
      final barb = _stroke(_ink.withValues(alpha: 0.28), 0.007);
      for (var i = 0; i < 5; i++) {
        final x = -0.104 + i * 0.050;
        canvas.drawLine(Offset(x, 0.002), Offset(x + 0.026, -0.034), barb);
        canvas.drawLine(Offset(x, 0.002), Offset(x + 0.026, 0.036), barb);
      }
    }
    canvas.restore();

    final cap = Path()
      ..moveTo(0.330, 0.240)
      ..cubicTo(0.298, 0.124, 0.396, 0.044, 0.516, 0.050)
      ..cubicTo(0.626, 0.056, 0.690, 0.134, 0.668, 0.240)
      ..close();
    _plate(canvas, cap, c.crown, weight: 0.015);
    _hatch(canvas, cap, 0.22 * detail, spacing: 0.032, weight: 0.008);

    final band = Path()
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTRB(0.322, 0.226, 0.682, 0.290),
        const Radius.circular(0.016),
      ));
    _plate(canvas, band, CourtPalette.gold, weight: 0.014);

    if (detail > 0.5) {
      canvas.drawCircle(const Offset(0.622, 0.258), 0.022,
          _fill(CourtPalette.red));
      canvas.drawCircle(
          const Offset(0.622, 0.258), 0.022, _stroke(_ink, 0.010));
    }
  }

  // ------------------------------------------------------------- the rider

  static void _rider(Canvas canvas, CardSuit suit, double detail) {
    final c = CourtPalette.of(suit);
    _plinth(canvas, c.plinth, detail);

    const horse = Color(0xFFB9926A);
    const horseDeep = Color(0xFF8E6B49);

    // Tail, sweeping off the near hindquarter.
    final tail = Path()
      ..moveTo(0.236, 0.968)
      ..cubicTo(0.150, 1.030, 0.086, 1.230, 0.078, 1.470)
      ..cubicTo(0.118, 1.300, 0.176, 1.140, 0.262, 1.062)
      ..close();
    _plate(canvas, tail, horseDeep, weight: 0.014);

    // Far pair of legs, set back and darker.
    for (final x in const [0.300, 0.638]) {
      final leg = Path()
        ..moveTo(x, 1.140)
        ..lineTo(x + 0.062, 1.140)
        ..lineTo(x + 0.052, 1.596)
        ..lineTo(x - 0.002, 1.596)
        ..close();
      _plate(canvas, leg, horseDeep, weight: 0.013);
      final hoof = Path()
        ..addRect(Rect.fromLTRB(x - 0.010, 1.586, x + 0.070, 1.638));
      _plate(canvas, hoof, _ink, weight: 0.010);
    }

    // Barrel.
    final barrel = Path()
      ..addOval(Rect.fromCenter(
          center: const Offset(0.478, 1.116), width: 0.560, height: 0.420));
    _plate(canvas, barrel, horse, weight: 0.016);

    // Near pair of legs.
    for (final x in const [0.362, 0.700]) {
      final leg = Path()
        ..moveTo(x, 1.180)
        ..lineTo(x + 0.068, 1.180)
        ..cubicTo(x + 0.064, 1.360, x + 0.060, 1.480, x + 0.058, 1.596)
        ..lineTo(x + 0.002, 1.596)
        ..cubicTo(x + 0.002, 1.480, x, 1.360, x, 1.180)
        ..close();
      _plate(canvas, leg, horse, weight: 0.015);
      final hoof = Path()
        ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(x - 0.010, 1.586, x + 0.070, 1.642),
          const Radius.circular(0.012),
        ));
      _plate(canvas, hoof, _ink, weight: 0.010);
    }

    // Neck and head, carried high and facing right.
    final neck = Path()
      ..moveTo(0.612, 1.020)
      ..cubicTo(0.660, 0.880, 0.736, 0.760, 0.812, 0.700)
      ..lineTo(0.906, 0.766)
      ..cubicTo(0.836, 0.834, 0.774, 0.950, 0.744, 1.088)
      ..close();
    _plate(canvas, neck, horse, weight: 0.016);

    final head = Path()
      ..moveTo(0.806, 0.686)
      // Ears.
      ..lineTo(0.798, 0.588)
      ..lineTo(0.848, 0.646)
      ..lineTo(0.876, 0.590)
      ..lineTo(0.888, 0.676)
      ..cubicTo(0.938, 0.700, 0.972, 0.744, 0.976, 0.792)
      ..cubicTo(0.978, 0.828, 0.950, 0.848, 0.916, 0.836)
      ..cubicTo(0.878, 0.822, 0.842, 0.800, 0.812, 0.774)
      ..close();
    _plate(canvas, head, horse, weight: 0.015);

    // Mane down the crest.
    final mane = Path()
      ..moveTo(0.802, 0.678)
      ..cubicTo(0.740, 0.760, 0.678, 0.884, 0.640, 1.012);
    canvas.drawPath(mane, _stroke(horseDeep, 0.036));
    canvas.drawPath(mane, _stroke(_ink.withValues(alpha: 0.5), 0.010));

    if (detail > 0.5) {
      canvas.drawCircle(const Offset(0.878, 0.726), 0.017, _fill(_ink));
      canvas.drawCircle(const Offset(0.952, 0.802), 0.013, _fill(_ink));
      // Bridle.
      canvas.drawLine(const Offset(0.836, 0.748), const Offset(0.908, 0.800),
          _stroke(_ink.withValues(alpha: 0.6), 0.011));
    }

    // Caparison over the barrel.
    final cloth = Path()
      ..moveTo(0.352, 0.986)
      ..lineTo(0.640, 0.986)
      ..lineTo(0.616, 1.276)
      ..lineTo(0.496, 1.334)
      ..lineTo(0.376, 1.276)
      ..close();
    _plate(canvas, cloth, c.cape, weight: 0.015);
    _hatch(canvas, cloth, 0.20 * detail, spacing: 0.048);

    // Rider: cape, then leg, torso, arms, head.
    final cloak = Path()
      ..moveTo(0.404, 0.700)
      ..cubicTo(0.318, 0.760, 0.276, 0.940, 0.278, 1.150)
      ..cubicTo(0.330, 1.096, 0.386, 1.040, 0.436, 1.014)
      ..cubicTo(0.430, 0.900, 0.428, 0.790, 0.446, 0.716)
      ..close();
    _plate(canvas, cloak, c.lining, weight: 0.014);

    final thigh = Path()
      ..moveTo(0.446, 0.918)
      ..lineTo(0.560, 0.936)
      ..cubicTo(0.560, 1.030, 0.548, 1.116, 0.536, 1.176)
      ..lineTo(0.454, 1.164)
      ..cubicTo(0.446, 1.080, 0.444, 0.990, 0.446, 0.918)
      ..close();
    _plate(canvas, thigh, c.hose, weight: 0.014);
    final boot = Path()
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTRB(0.442, 1.160, 0.548, 1.268),
        const Radius.circular(0.020),
      ));
    _plate(canvas, boot, _silver, weight: 0.013);

    final torso = Path()
      ..moveTo(0.392, 0.646)
      ..cubicTo(0.372, 0.740, 0.382, 0.856, 0.412, 0.942)
      ..lineTo(0.582, 0.942)
      ..cubicTo(0.588, 0.842, 0.576, 0.726, 0.548, 0.646)
      ..close();
    _plate(canvas, torso, c.robe, weight: 0.016);
    _hatch(canvas, torso, 0.20 * detail, spacing: 0.028);

    final sash = Path()
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTRB(0.386, 0.884, 0.588, 0.944),
        const Radius.circular(0.016),
      ));
    _plate(canvas, sash, CourtPalette.gold, weight: 0.012);

    // Rein arm, reaching forward to the horse's neck.
    final reinArm = Path()
      ..moveTo(0.548, 0.664)
      ..cubicTo(0.618, 0.688, 0.666, 0.756, 0.692, 0.836)
      ..lineTo(0.626, 0.868)
      ..cubicTo(0.600, 0.792, 0.564, 0.744, 0.512, 0.728)
      ..close();
    _plate(canvas, reinArm, c.sleeve, weight: 0.014);
    _hand(canvas, const Offset(0.678, 0.884), detail);

    // Sign arm, raised.
    final signArm = Path()
      ..moveTo(0.398, 0.662)
      ..cubicTo(0.336, 0.674, 0.284, 0.696, 0.244, 0.716)
      ..lineTo(0.268, 0.792)
      ..cubicTo(0.312, 0.766, 0.362, 0.744, 0.418, 0.740)
      ..close();
    _plate(canvas, signArm, c.sleeve, weight: 0.014);
    _heldSign(canvas, suit, const Offset(0.222, 0.756), 0.86, detail);
    _hand(canvas, const Offset(0.222, 0.756), detail);

    // Gorget then head.
    final collar = Path()
      ..moveTo(0.372, 0.678)
      ..cubicTo(0.380, 0.610, 0.436, 0.570, 0.500, 0.572)
      ..cubicTo(0.562, 0.574, 0.600, 0.616, 0.598, 0.678)
      ..cubicTo(0.552, 0.640, 0.500, 0.628, 0.452, 0.634)
      ..close();
    _plate(canvas, collar, c.cape, weight: 0.014);

    _head(canvas, const Offset(0.474, 0.446), bearded: false, detail: detail);

    // The rider's helm: a light casque with a plume.
    final plume = Path()
      ..moveTo(0.556, 0.318)
      ..cubicTo(0.652, 0.268, 0.716, 0.206, 0.740, 0.156)
      ..cubicTo(0.734, 0.242, 0.680, 0.324, 0.588, 0.366)
      ..close();
    _plate(canvas, plume, CourtPalette.red, weight: 0.012);

    final helm = Path()
      ..moveTo(0.336, 0.372)
      ..cubicTo(0.322, 0.286, 0.392, 0.226, 0.482, 0.228)
      ..cubicTo(0.570, 0.230, 0.622, 0.290, 0.608, 0.372)
      ..close();
    _plate(canvas, helm, _silver, weight: 0.014);
    final rim = Path()
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTRB(0.326, 0.362, 0.620, 0.412),
        const Radius.circular(0.014),
      ));
    _plate(canvas, rim, CourtPalette.gold, weight: 0.013);
  }

  // -------------------------------------------------------- the suit signs
  // Each sign is authored with the grip at the origin so it can be dropped
  // into whichever hand carries it, at whichever scale that figure needs.

  static void _heldSign(Canvas canvas, CardSuit suit, Offset hand,
      double scale, double detail) {
    canvas.save();
    canvas.translate(hand.dx, hand.dy);
    canvas.scale(scale);
    final p = SuitPalette.of(suit);
    switch (suit) {
      case CardSuit.spade:
        _sword(canvas, p, detail);
      case CardSuit.bastoni:
        _club(canvas, p, detail);
      case CardSuit.coppe:
        _cup(canvas, p, detail);
      case CardSuit.denari:
        _coin(canvas, p, detail);
    }
    canvas.restore();
  }

  /// A long straight sword, point up, quillons just above the fist.
  static void _sword(Canvas canvas, SuitPalette p, double detail) {
    final blade = Path()
      ..moveTo(0.0, -0.672)
      ..lineTo(0.050, -0.596)
      ..lineTo(0.046, -0.196)
      ..lineTo(-0.046, -0.196)
      ..lineTo(-0.050, -0.596)
      ..close();
    _plate(canvas, blade, p.primary, weight: 0.014);
    if (detail > 0.45) {
      canvas.drawLine(const Offset(0.0, -0.578), const Offset(0.0, -0.220),
          _stroke(_ink.withValues(alpha: 0.42), 0.010));
    }

    final guard = Path()
      ..moveTo(-0.158, -0.132)
      ..cubicTo(-0.104, -0.212, 0.104, -0.212, 0.158, -0.132)
      ..cubicTo(0.104, -0.164, -0.104, -0.164, -0.158, -0.132)
      ..close();
    _plate(canvas, guard, CourtPalette.gold, weight: 0.014);

    final grip = Path()
      ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTRB(-0.032, -0.152, 0.032, 0.070),
        const Radius.circular(0.014),
      ));
    _plate(canvas, grip, CourtPalette.gold, weight: 0.013);

    canvas.drawCircle(const Offset(0.0, 0.098), 0.042,
        _fill(CourtPalette.gold));
    canvas.drawCircle(const Offset(0.0, 0.098), 0.042, _stroke(_ink, 0.013));
  }

  /// A knotted cudgel, head up.
  static void _club(Canvas canvas, SuitPalette p, double detail) {
    final club = Path()
      ..moveTo(0.0, -0.630)
      ..cubicTo(0.070, -0.630, 0.100, -0.566, 0.090, -0.492)
      ..cubicTo(0.084, -0.446, 0.072, -0.416, 0.066, -0.376)
      ..cubicTo(0.058, -0.262, 0.050, -0.146, 0.042, -0.046)
      ..cubicTo(0.038, 0.026, 0.034, 0.076, 0.032, 0.108)
      ..lineTo(-0.032, 0.108)
      ..cubicTo(-0.034, 0.076, -0.038, 0.026, -0.042, -0.046)
      ..cubicTo(-0.050, -0.146, -0.058, -0.262, -0.066, -0.376)
      ..cubicTo(-0.072, -0.416, -0.084, -0.446, -0.090, -0.492)
      ..cubicTo(-0.100, -0.566, -0.070, -0.630, 0.0, -0.630)
      ..close();
    _plate(canvas, club, p.primary, weight: 0.015);

    if (detail < 0.45) return;
    canvas.drawLine(const Offset(-0.068, -0.374), const Offset(0.068, -0.374),
        _stroke(_ink.withValues(alpha: 0.55), 0.012));
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(0.0, -0.522), radius: 0.054),
      math.pi * 0.18,
      math.pi * 0.64,
      false,
      _stroke(_ink.withValues(alpha: 0.4), 0.010),
    );
    canvas.drawCircle(const Offset(0.0, -0.170), 0.020,
        _stroke(_ink.withValues(alpha: 0.45), 0.009));
  }

  /// A lidded chalice, raised on its foot.
  static void _cup(Canvas canvas, SuitPalette p, double detail) {
    final foot = Path()
      ..moveTo(-0.128, 0.062)
      ..cubicTo(-0.092, -0.010, 0.092, -0.010, 0.128, 0.062)
      ..close();
    _plate(canvas, foot, p.primary, weight: 0.014);

    final stem = Path()
      ..moveTo(-0.036, -0.116)
      ..lineTo(0.036, -0.116)
      ..lineTo(0.028, -0.004)
      ..lineTo(-0.028, -0.004)
      ..close();
    _plate(canvas, stem, p.primary, weight: 0.012);

    final bowl = Path()
      ..moveTo(-0.170, -0.318)
      ..cubicTo(-0.170, -0.176, -0.106, -0.116, 0.0, -0.116)
      ..cubicTo(0.106, -0.116, 0.170, -0.176, 0.170, -0.318)
      ..close();
    _plate(canvas, bowl, p.primary, weight: 0.015);
    canvas.drawLine(const Offset(-0.184, -0.318), const Offset(0.184, -0.318),
        _stroke(_ink, 0.018));

    final dome = Path()
      ..moveTo(-0.106, -0.318)
      ..cubicTo(-0.106, -0.438, 0.106, -0.438, 0.106, -0.318)
      ..close();
    _plate(canvas, dome, p.primary, weight: 0.013);
    canvas.drawCircle(const Offset(0.0, -0.470), 0.036, _fill(p.light));
    canvas.drawCircle(const Offset(0.0, -0.470), 0.036, _stroke(_ink, 0.013));

    if (detail < 0.45) return;
    canvas.drawLine(const Offset(-0.140, -0.232), const Offset(0.140, -0.232),
        _stroke(_ink.withValues(alpha: 0.45), 0.010));
  }

  /// A struck coin, held up on the palm.
  static void _coin(Canvas canvas, SuitPalette p, double detail) {
    const c = Offset(0.0, -0.208);
    canvas.drawCircle(c, 0.170, _fill(p.primary));
    canvas.drawCircle(c, 0.170, _stroke(_ink, 0.016));
    canvas.drawCircle(c, 0.132, _stroke(_ink.withValues(alpha: 0.7), 0.011));

    if (detail < 0.45) return;
    // Eight-point rosette struck in the field.
    final star = Path();
    for (var i = 0; i < 16; i++) {
      final a = (i / 16) * math.pi * 2 - math.pi / 2;
      final r = i.isEven ? 0.100 : 0.044;
      final pt = c + Offset(math.cos(a) * r, math.sin(a) * r);
      i == 0 ? star.moveTo(pt.dx, pt.dy) : star.lineTo(pt.dx, pt.dy);
    }
    star.close();
    canvas.drawPath(star, _fill(p.deep));
    canvas.drawCircle(c, 0.030, _fill(p.light));
    canvas.drawCircle(c, 0.030, _stroke(_ink, 0.010));
  }

  // ------------------------------------------------------------- ornament

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
