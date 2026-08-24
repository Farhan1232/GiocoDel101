import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/constants/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../theme/card_backs.dart';

/// §5 — the reverse of the deck: a deep base, a mirrored gold lattice built
/// from Italian tile geometry, and a small 101 medallion at the centre.
class CardBackPainter extends CustomPainter {
  const CardBackPainter({required this.design, this.shine = 0.0});

  final CardBackDesign design;

  /// 0..1 sheen sweep, used while a card is in flight.
  final double shine;

  static final Map<String, TextPainter> _cache = {};

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width * AppRadii.cardCornerRatio;
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    canvas.save();
    canvas.clipRRect(rrect);

    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(size.width * 0.1, 0),
          Offset(size.width * 0.9, size.height),
          [design.baseTop, design.baseBottom],
        ),
    );

    _lattice(canvas, size);
    _border(canvas, size);
    _medallion(canvas, size);

    if (shine > 0.01) {
      final x = (shine * 2 - 0.5) * size.width;
      canvas.drawRect(
        rect,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(x - size.width * 0.35, 0),
            Offset(x + size.width * 0.35, size.height),
            [
              Colors.white.withValues(alpha: 0.0),
              Colors.white.withValues(alpha: 0.16),
              Colors.white.withValues(alpha: 0.0),
            ],
            const [0.0, 0.5, 1.0],
          ),
      );
    }
    canvas.restore();
  }

  /// Interlocking diamonds on a diagonal grid — a tile motif, mirrored about
  /// both axes so the back reads the same whichever way it is dealt.
  void _lattice(Canvas canvas, Size size) {
    final step = size.width * 0.185;
    final thin = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.5, size.width * 0.0075)
      ..color = design.ink.withValues(alpha: 0.34)
      ..isAntiAlias = true;
    final dot = Paint()..color = design.ink.withValues(alpha: 0.22);

    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (var y = -step; y < size.height + step; y += step) {
      for (var x = -step; x < size.width + step; x += step) {
        final centre = Offset(x + step / 2, y + step / 2);
        final d = Path()
          ..moveTo(centre.dx, centre.dy - step * 0.46)
          ..lineTo(centre.dx + step * 0.46, centre.dy)
          ..lineTo(centre.dx, centre.dy + step * 0.46)
          ..lineTo(centre.dx - step * 0.46, centre.dy)
          ..close();
        canvas.drawPath(d, thin);
        canvas.drawCircle(centre, step * 0.075, dot);
      }
    }
    canvas.restore();
  }

  void _border(Canvas canvas, Size size) {
    final m = size.width * 0.062;
    final outer = RRect.fromRectAndRadius(
      Rect.fromLTWH(m, m, size.width - m * 2, size.height - m * 2),
      Radius.circular(size.width * 0.045),
    );
    canvas.drawRRect(
      outer,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, size.width * 0.016)
        ..color = design.ink.withValues(alpha: 0.85),
    );
    canvas.drawRRect(
      outer.deflate(size.width * 0.030),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.5, size.width * 0.006)
        ..color = design.ink.withValues(alpha: 0.45),
    );
  }

  void _medallion(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.245;

    canvas.drawCircle(
      centre,
      r,
      Paint()
        ..shader = ui.Gradient.radial(
          centre.translate(-r * 0.3, -r * 0.35),
          r * 1.5,
          [
            Color.lerp(design.baseTop, Colors.black, 0.25)!,
            Color.lerp(design.baseBottom, Colors.black, 0.45)!,
          ],
        ),
    );
    canvas.drawCircle(
      centre,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, size.width * 0.014)
        ..color = design.medallion.withValues(alpha: 0.9),
    );
    canvas.drawCircle(
      centre,
      r * 0.83,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.5, size.width * 0.005)
        ..color = design.medallion.withValues(alpha: 0.5),
    );

    if (size.width > 44) {
      final label = _label('101', size.width * 0.175, design.medallion);
      label.paint(
        canvas,
        centre - Offset(label.width / 2, label.height / 2),
      );
    } else {
      canvas.drawCircle(
          centre, r * 0.32, Paint()..color = design.medallion.withValues(alpha: 0.85));
    }
  }

  static TextPainter _label(String text, double size, Color color) {
    final key = '$text|${size.toStringAsFixed(1)}|${color.toARGB32()}';
    final cached = _cache[key];
    if (cached != null) return cached;
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: AppText.display,
          fontSize: size,
          fontWeight: FontWeight.w700,
          letterSpacing: size * 0.06,
          color: color,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    if (_cache.length > 40) _cache.clear();
    _cache[key] = painter;
    return painter;
  }

  @override
  bool shouldRepaint(CardBackPainter old) =>
      old.design.id != design.id || old.shine != shine;
}
