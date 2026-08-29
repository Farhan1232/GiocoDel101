import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../utils/glow.dart';

import '../../features/profile/domain/avatars.dart';
import '../../app/theme/app_colors.dart';

/// §46 — an original struck medallion instead of a stock portrait.
///
/// Each player wears a rimmed disc carrying one heraldic emblem from
/// [MedallionMotif]. The ring around it doubles as the turn indicator (§61)
/// and, on the table, as the 101 Fate Ring's mount.
class AvatarMedallion extends StatelessWidget {
  const AvatarMedallion({
    super.key,
    required this.avatarId,
    this.size = 56,
    this.active = false,
    this.dimmed = false,
    this.glow = 0.0,
  });

  final String avatarId;
  final double size;

  /// Whose turn it is.
  final bool active;

  /// Eliminated players fade back.
  final bool dimmed;

  final double glow;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.square(size),
        painter: _MedallionPainter(
          def: Avatars.byId(avatarId),
          active: active,
          dimmed: dimmed,
          glow: glow,
        ),
      ),
    );
  }
}

class _MedallionPainter extends CustomPainter {
  const _MedallionPainter({
    required this.def,
    required this.active,
    required this.dimmed,
    required this.glow,
  });

  final AvatarDef def;
  final bool active;
  final bool dimmed;
  final double glow;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final alpha = dimmed ? 0.42 : 1.0;

    if (glow > 0.01) {
      Glow.circle(
        canvas,
        c,
        r * (1.22 + 0.16 * glow),
        def.rim.withValues(alpha: 0.34 * glow),
        core: 0.62,
      );
    }

    // Disc.
    canvas.drawCircle(
      c,
      r * 0.9,
      Paint()
        ..shader = ui.Gradient.radial(
          c.translate(-r * 0.3, -r * 0.35),
          r * 1.5,
          [
            Color.lerp(def.base, Colors.white, 0.16)!.withValues(alpha: alpha),
            def.base.withValues(alpha: alpha),
            Color.lerp(def.base, Colors.black, 0.4)!.withValues(alpha: alpha),
          ],
          const [0.0, 0.55, 1.0],
        ),
    );

    _motif(canvas, c, r * 0.56, def.emblem.withValues(alpha: alpha));

    // Rim: a plain bezel, or a lit ring while this seat is to act.
    canvas.drawCircle(
      c,
      r * 0.9,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * (active ? 0.13 : 0.085)
        ..shader = ui.Gradient.sweep(
          c,
          active
              ? [
                  AppColors.goldLight,
                  def.rim,
                  AppColors.goldLight,
                  def.rim,
                  AppColors.goldLight,
                ]
              : [
                  def.rim.withValues(alpha: 0.85 * alpha),
                  Color.lerp(
                    def.rim,
                    Colors.black,
                    0.45,
                  )!.withValues(alpha: 0.85 * alpha),
                  def.rim.withValues(alpha: 0.85 * alpha),
                ],
          active ? const [0.0, 0.25, 0.5, 0.75, 1.0] : const [0.0, 0.5, 1.0],
        ),
    );
  }

  void _motif(Canvas canvas, Offset c, double r, Color color) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.13
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color
      ..isAntiAlias = true;
    final fill = Paint()
      ..color = color
      ..isAntiAlias = true;

    switch (def.motif) {
      case MedallionMotif.sun:
        canvas.drawCircle(c, r * 0.36, fill);
        for (var i = 0; i < 12; i++) {
          final a = i * math.pi / 6;
          canvas.drawLine(
            c + Offset(math.cos(a), math.sin(a)) * r * 0.55,
            c + Offset(math.cos(a), math.sin(a)) * r * (i.isEven ? 0.95 : 0.78),
            stroke,
          );
        }
      case MedallionMotif.wave:
        for (var row = 0; row < 3; row++) {
          final path = Path();
          final y = c.dy + (row - 1) * r * 0.52;
          path.moveTo(c.dx - r * 0.9, y);
          for (var i = 0; i < 2; i++) {
            path.relativeQuadraticBezierTo(r * 0.45, -r * 0.4, r * 0.9, 0);
          }
          canvas.drawPath(path, stroke);
        }
      case MedallionMotif.arch:
        final p = Path()
          ..moveTo(c.dx - r * 0.72, c.dy + r * 0.85)
          ..lineTo(c.dx - r * 0.72, c.dy - r * 0.1)
          ..arcToPoint(
            Offset(c.dx + r * 0.72, c.dy - r * 0.1),
            radius: Radius.circular(r * 0.72),
          )
          ..lineTo(c.dx + r * 0.72, c.dy + r * 0.85);
        canvas.drawPath(p, stroke);
        canvas.drawLine(
          Offset(c.dx - r * 0.95, c.dy + r * 0.85),
          Offset(c.dx + r * 0.95, c.dy + r * 0.85),
          stroke,
        );
      case MedallionMotif.lyre:
        canvas.drawArc(
          Rect.fromCenter(center: c, width: r * 1.7, height: r * 1.8),
          math.pi * 0.15,
          math.pi * 0.7,
          false,
          stroke,
        );
        for (var i = -1; i <= 1; i++) {
          canvas.drawLine(
            Offset(c.dx + i * r * 0.32, c.dy - r * 0.75),
            Offset(c.dx + i * r * 0.32, c.dy + r * 0.55),
            stroke,
          );
        }
        canvas.drawLine(
          Offset(c.dx - r * 0.72, c.dy - r * 0.75),
          Offset(c.dx + r * 0.72, c.dy - r * 0.75),
          stroke,
        );
      case MedallionMotif.olive:
        canvas.drawLine(
          Offset(c.dx - r * 0.1, c.dy + r * 0.9),
          Offset(c.dx + r * 0.15, c.dy - r * 0.85),
          stroke,
        );
        for (var i = 0; i < 4; i++) {
          final t = i / 3.0;
          final base = Offset(
            c.dx - r * 0.1 + r * 0.25 * (1 - t),
            c.dy + r * 0.9 - r * 1.75 * t,
          );
          for (final dir in const [-1.0, 1.0]) {
            canvas.save();
            canvas.translate(base.dx, base.dy);
            canvas.rotate(dir * 0.9);
            canvas.drawOval(
              Rect.fromCenter(
                center: Offset(dir * r * 0.3, 0),
                width: r * 0.55,
                height: r * 0.26,
              ),
              fill,
            );
            canvas.restore();
          }
        }
      case MedallionMotif.mask:
        final p = Path()
          ..moveTo(c.dx - r * 0.85, c.dy - r * 0.6)
          ..cubicTo(
            c.dx - r * 0.95,
            c.dy + r * 0.5,
            c.dx - r * 0.4,
            c.dy + r * 0.95,
            c.dx,
            c.dy + r * 0.95,
          )
          ..cubicTo(
            c.dx + r * 0.4,
            c.dy + r * 0.95,
            c.dx + r * 0.95,
            c.dy + r * 0.5,
            c.dx + r * 0.85,
            c.dy - r * 0.6,
          )
          ..close();
        canvas.drawPath(p, stroke);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(c.dx - r * 0.36, c.dy - r * 0.12),
            width: r * 0.42,
            height: r * 0.30,
          ),
          fill,
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(c.dx + r * 0.36, c.dy - r * 0.12),
            width: r * 0.42,
            height: r * 0.30,
          ),
          fill,
        );
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(c.dx, c.dy + r * 0.3),
            width: r * 0.8,
            height: r * 0.5,
          ),
          0.15,
          math.pi - 0.3,
          false,
          stroke,
        );
      case MedallionMotif.anchor:
        canvas.drawCircle(Offset(c.dx, c.dy - r * 0.7), r * 0.2, stroke);
        canvas.drawLine(
          Offset(c.dx, c.dy - r * 0.5),
          Offset(c.dx, c.dy + r * 0.85),
          stroke,
        );
        canvas.drawLine(
          Offset(c.dx - r * 0.45, c.dy - r * 0.28),
          Offset(c.dx + r * 0.45, c.dy - r * 0.28),
          stroke,
        );
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(c.dx, c.dy + r * 0.28),
            width: r * 1.6,
            height: r * 1.35,
          ),
          0.12,
          math.pi - 0.24,
          false,
          stroke,
        );
      case MedallionMotif.star:
        final path = Path();
        for (var i = 0; i < 12; i++) {
          final a = (i / 12) * math.pi * 2 - math.pi / 2;
          final rr = i.isEven ? r * 0.95 : r * 0.42;
          final pt = c + Offset(math.cos(a) * rr, math.sin(a) * rr);
          if (i == 0) {
            path.moveTo(pt.dx, pt.dy);
          } else {
            path.lineTo(pt.dx, pt.dy);
          }
        }
        path.close();
        canvas.drawPath(path, fill);
    }
  }

  @override
  bool shouldRepaint(_MedallionPainter old) =>
      old.def.id != def.id ||
      old.active != active ||
      old.dimmed != dimmed ||
      old.glow != glow;
}
