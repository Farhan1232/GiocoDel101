import 'dart:math' as math;

import 'package:flutter/material.dart';

/// §45 — the game's own icon set.
///
/// One coherent geometric family drawn on a 24×24 grid with a single stroke
/// weight, so every glyph in the app belongs to the same universe. Material
/// icons are not used anywhere in the interface.
enum AppIcon {
  play,
  resume,
  settings,
  sound,
  soundOff,
  music,
  musicOff,
  haptic,
  stats,
  trophy,
  rules,
  difficulty,
  players,
  reactions,
  back,
  home,
  restart,
  close,
  check,
  chevronDown,
  calendar,
  chain,
  ring,
  hand,
  suits,
  lock,
  edit,
  speed,
  contrast,
  motion,
  cards,
  draw,
  eye,
  eyeOff,
}

class AppIconView extends StatelessWidget {
  const AppIconView(
    this.icon, {
    super.key,
    this.size = 22,
    this.color = Colors.white,
    this.strokeWidth = 1.9,
  });

  final AppIcon icon;
  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      size: Size.square(size),
      painter: AppIconPainter(
        icon: icon,
        color: color,
        strokeWidth: strokeWidth,
      ),
    ),
  );
}

class AppIconPainter extends CustomPainter {
  const AppIconPainter({
    required this.icon,
    required this.color,
    this.strokeWidth = 1.9,
  });

  final AppIcon icon;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24.0;
    canvas.save();
    canvas.scale(s, s);

    // Stroke weight is specified in logical pixels, so undo the grid scale.
    final unit = strokeWidth / s;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = unit
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color
      ..isAntiAlias = true;
    final fill = Paint()
      ..color = color
      ..isAntiAlias = true;

    switch (icon) {
      case AppIcon.play:
        canvas.drawPath(
          Path()
            ..moveTo(7.5, 4.8)
            ..lineTo(19, 12)
            ..lineTo(7.5, 19.2)
            ..close(),
          fill,
        );
      case AppIcon.resume:
        canvas.drawArc(
          const Rect.fromLTWH(4, 4, 16, 16),
          -math.pi * 0.75,
          math.pi * 1.5,
          false,
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(10, 9)
            ..lineTo(16, 12)
            ..lineTo(10, 15)
            ..close(),
          fill,
        );
      case AppIcon.settings:
        canvas.drawCircle(const Offset(12, 12), 3.4, stroke);
        for (var i = 0; i < 8; i++) {
          final a = i * math.pi / 4;
          canvas.drawLine(
            Offset(12 + math.cos(a) * 6.2, 12 + math.sin(a) * 6.2),
            Offset(12 + math.cos(a) * 8.6, 12 + math.sin(a) * 8.6),
            stroke,
          );
        }
        canvas.drawCircle(
          const Offset(12, 12),
          7.0,
          stroke..color = color.withValues(alpha: 0.45),
        );
        stroke.color = color;
      case AppIcon.sound:
      case AppIcon.soundOff:
        canvas.drawPath(
          Path()
            ..moveTo(4.5, 9.5)
            ..lineTo(8, 9.5)
            ..lineTo(12.5, 5.5)
            ..lineTo(12.5, 18.5)
            ..lineTo(8, 14.5)
            ..lineTo(4.5, 14.5)
            ..close(),
          fill,
        );
        if (icon == AppIcon.sound) {
          canvas.drawArc(
            const Rect.fromLTWH(11, 7.5, 8, 9),
            -math.pi / 3,
            math.pi * 2 / 3,
            false,
            stroke,
          );
          canvas.drawArc(
            const Rect.fromLTWH(12.5, 4.5, 11, 15),
            -math.pi / 3,
            math.pi * 2 / 3,
            false,
            stroke,
          );
        } else {
          canvas.drawLine(
            const Offset(16, 9.5),
            const Offset(21, 14.5),
            stroke,
          );
          canvas.drawLine(
            const Offset(21, 9.5),
            const Offset(16, 14.5),
            stroke,
          );
        }
      case AppIcon.music:
      case AppIcon.musicOff:
        canvas.drawLine(const Offset(9.5, 17), const Offset(9.5, 5.5), stroke);
        canvas.drawLine(
          const Offset(9.5, 5.5),
          const Offset(18.5, 3.5),
          stroke,
        );
        canvas.drawLine(
          const Offset(18.5, 3.5),
          const Offset(18.5, 15),
          stroke,
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: const Offset(7.2, 17.4),
            width: 4.8,
            height: 3.9,
          ),
          fill,
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: const Offset(16.2, 15.4),
            width: 4.8,
            height: 3.9,
          ),
          fill,
        );
        if (icon == AppIcon.musicOff) {
          canvas.drawLine(
            const Offset(4.5, 4.5),
            const Offset(19.5, 19.5),
            stroke..strokeWidth = unit * 1.25,
          );
          stroke.strokeWidth = unit;
        }
      case AppIcon.haptic:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(8.5, 4.5, 7, 15),
            const Radius.circular(2),
          ),
          stroke,
        );
        for (final dx in const [-1.0, 1.0]) {
          canvas.drawArc(
            Rect.fromCenter(
              center: Offset(12 + dx * 8.2, 12),
              width: 6,
              height: 12,
            ),
            dx > 0 ? -math.pi / 2.6 : math.pi - math.pi / 2.6,
            dx > 0 ? math.pi / 1.3 : -math.pi / 1.3,
            false,
            stroke,
          );
        }
      case AppIcon.stats:
        for (var i = 0; i < 3; i++) {
          final h = 5.0 + i * 4.5;
          canvas.drawLine(
            Offset(6.5 + i * 5.5, 19),
            Offset(6.5 + i * 5.5, 19 - h),
            stroke..strokeWidth = unit * 1.6,
          );
        }
        stroke.strokeWidth = unit;
      case AppIcon.trophy:
        canvas.drawPath(
          Path()
            ..moveTo(7.5, 3.5)
            ..lineTo(16.5, 3.5)
            ..lineTo(16.5, 9)
            ..cubicTo(16.5, 13, 13.8, 14.5, 12, 14.5)
            ..cubicTo(10.2, 14.5, 7.5, 13, 7.5, 9)
            ..close(),
          stroke,
        );
        canvas.drawArc(
          const Rect.fromLTWH(2.8, 4, 5.5, 6.5),
          math.pi / 2,
          math.pi,
          false,
          stroke,
        );
        canvas.drawArc(
          const Rect.fromLTWH(15.7, 4, 5.5, 6.5),
          -math.pi / 2,
          math.pi,
          false,
          stroke,
        );
        canvas.drawLine(const Offset(12, 14.5), const Offset(12, 17.5), stroke);
        canvas.drawLine(
          const Offset(8, 20.5),
          const Offset(16, 20.5),
          stroke..strokeWidth = unit * 1.5,
        );
        stroke.strokeWidth = unit;
      case AppIcon.rules:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(4.5, 3.5, 15, 17),
            const Radius.circular(2.4),
          ),
          stroke,
        );
        canvas.drawLine(const Offset(8, 8.5), const Offset(16, 8.5), stroke);
        canvas.drawLine(const Offset(8, 12), const Offset(16, 12), stroke);
        canvas.drawLine(const Offset(8, 15.5), const Offset(13, 15.5), stroke);
      case AppIcon.difficulty:
        for (var i = 0; i < 3; i++) {
          final x = 6.0 + i * 6;
          final h = 4.0 + i * 4.0;
          canvas.drawLine(
            Offset(x, 18),
            Offset(x, 18 - h),
            stroke..strokeWidth = unit * 1.7,
          );
        }
        stroke.strokeWidth = unit;
      case AppIcon.players:
        canvas.drawCircle(const Offset(9, 8.5), 3.4, stroke);
        canvas.drawArc(
          const Rect.fromLTWH(3, 13, 12, 11),
          math.pi,
          math.pi,
          false,
          stroke,
        );
        canvas.drawCircle(const Offset(17, 9.5), 2.6, stroke);
        canvas.drawArc(
          const Rect.fromLTWH(13, 13.5, 10, 9),
          math.pi * 1.15,
          math.pi * 0.7,
          false,
          stroke,
        );
      case AppIcon.reactions:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(3.5, 4.5, 17, 12.5),
            const Radius.circular(4),
          ),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(8.5, 17)
            ..lineTo(8.5, 21)
            ..lineTo(12.8, 17)
            ..close(),
          stroke,
        );
        for (var i = 0; i < 3; i++) {
          canvas.drawCircle(Offset(8.0 + i * 4.0, 10.7), 1.15, fill);
        }
      case AppIcon.back:
        canvas.drawPath(
          Path()
            ..moveTo(14.5, 5)
            ..lineTo(8, 12)
            ..lineTo(14.5, 19),
          stroke,
        );
      case AppIcon.home:
        canvas.drawPath(
          Path()
            ..moveTo(3.5, 11.5)
            ..lineTo(12, 4)
            ..lineTo(20.5, 11.5),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(6, 10.5)
            ..lineTo(6, 20)
            ..lineTo(18, 20)
            ..lineTo(18, 10.5),
          stroke,
        );
      case AppIcon.restart:
        canvas.drawArc(
          const Rect.fromLTWH(4, 4, 16, 16),
          -math.pi * 0.35,
          math.pi * 1.6,
          false,
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(18.4, 3.4)
            ..lineTo(19.6, 8.6)
            ..lineTo(14.4, 7.6),
          stroke,
        );
      case AppIcon.close:
        canvas.drawLine(
          const Offset(6.5, 6.5),
          const Offset(17.5, 17.5),
          stroke,
        );
        canvas.drawLine(
          const Offset(17.5, 6.5),
          const Offset(6.5, 17.5),
          stroke,
        );
      case AppIcon.check:
        canvas.drawPath(
          Path()
            ..moveTo(5, 12.6)
            ..lineTo(10, 17.4)
            ..lineTo(19, 6.8),
          stroke..strokeWidth = unit * 1.25,
        );
        stroke.strokeWidth = unit;
      case AppIcon.chevronDown:
        canvas.drawPath(
          Path()
            ..moveTo(5.5, 9)
            ..lineTo(12, 15.5)
            ..lineTo(18.5, 9),
          stroke,
        );
      case AppIcon.calendar:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(3.8, 5.5, 16.4, 14.5),
            const Radius.circular(2.6),
          ),
          stroke,
        );
        canvas.drawLine(const Offset(3.8, 10), const Offset(20.2, 10), stroke);
        canvas.drawLine(const Offset(8, 3.2), const Offset(8, 6.8), stroke);
        canvas.drawLine(const Offset(16, 3.2), const Offset(16, 6.8), stroke);
        canvas.drawCircle(const Offset(12, 15), 1.9, fill);
      case AppIcon.chain:
        for (var i = 0; i < 2; i++) {
          canvas.save();
          canvas.translate(12, 12);
          canvas.rotate(-math.pi / 4);
          canvas.translate(-12, -12);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset(12, 12 + (i == 0 ? -3.6 : 3.6)),
                width: 7.4,
                height: 9.6,
              ),
              const Radius.circular(3.7),
            ),
            stroke,
          );
          canvas.restore();
        }
      case AppIcon.ring:
        canvas.drawCircle(
          const Offset(12, 12),
          8.2,
          stroke..color = color.withValues(alpha: 0.35),
        );
        stroke.color = color;
        canvas.drawArc(
          const Rect.fromLTWH(3.8, 3.8, 16.4, 16.4),
          -math.pi / 2,
          math.pi * 1.45,
          false,
          stroke..strokeWidth = unit * 1.5,
        );
        stroke.strokeWidth = unit;
      case AppIcon.hand:
        for (var i = 0; i < 3; i++) {
          canvas.save();
          canvas.translate(12, 20);
          canvas.rotate((i - 1) * 0.36);
          canvas.translate(-12, -20);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              const Rect.fromLTWH(9, 5.5, 6, 14),
              const Radius.circular(1.5),
            ),
            stroke,
          );
          canvas.restore();
        }
      case AppIcon.suits:
        canvas.drawCircle(const Offset(8, 8), 3.2, stroke);
        canvas.drawRect(const Rect.fromLTWH(13.2, 4.8, 6.4, 6.4), stroke);
        canvas.drawPath(
          Path()
            ..moveTo(8, 13)
            ..lineTo(11.4, 19.6)
            ..lineTo(4.6, 19.6)
            ..close(),
          stroke,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(13.2, 13.2, 6.4, 6.4),
            const Radius.circular(3.2),
          ),
          stroke,
        );
      case AppIcon.lock:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(5, 10.5, 14, 10),
            const Radius.circular(2.6),
          ),
          stroke,
        );
        canvas.drawArc(
          const Rect.fromLTWH(8, 3.5, 8, 10),
          math.pi,
          math.pi,
          false,
          stroke,
        );
        canvas.drawCircle(const Offset(12, 15.5), 1.5, fill);
      case AppIcon.edit:
        canvas.drawPath(
          Path()
            ..moveTo(4.5, 19.5)
            ..lineTo(5.5, 15)
            ..lineTo(16, 4.5)
            ..lineTo(19.5, 8)
            ..lineTo(9, 18.5)
            ..close(),
          stroke,
        );
        canvas.drawLine(const Offset(13.6, 7), const Offset(17, 10.4), stroke);
      case AppIcon.speed:
        canvas.drawArc(
          const Rect.fromLTWH(3.5, 5, 17, 17),
          math.pi,
          math.pi,
          false,
          stroke,
        );
        canvas.drawLine(
          const Offset(12, 13.5),
          const Offset(16.5, 9.2),
          stroke..strokeWidth = unit * 1.3,
        );
        stroke.strokeWidth = unit;
        canvas.drawCircle(const Offset(12, 13.5), 1.5, fill);
      case AppIcon.eye:
        canvas.drawPath(_eyeOutline(), stroke);
        canvas.drawCircle(const Offset(12, 12), 2.6, stroke);
      case AppIcon.eyeOff:
        canvas.drawPath(_eyeOutline(), stroke);
        canvas.drawCircle(const Offset(12, 12), 2.6, stroke);
        // The stroke through it is what says "hidden".
        canvas.drawLine(
          const Offset(4.6, 4.6),
          const Offset(19.4, 19.4),
          stroke,
        );
      case AppIcon.contrast:
        canvas.drawCircle(const Offset(12, 12), 8.2, stroke);
        final half = Path()
          ..addArc(
            const Rect.fromLTWH(3.8, 3.8, 16.4, 16.4),
            -math.pi / 2,
            math.pi,
          )
          ..close();
        canvas.drawPath(half, fill);
      case AppIcon.motion:
        canvas.drawCircle(const Offset(16.5, 12), 4.4, stroke);
        for (var i = 0; i < 3; i++) {
          canvas.drawLine(
            Offset(3.2, 9.2 + i * 2.8),
            Offset(9.4 - i * 1.2, 9.2 + i * 2.8),
            stroke..color = color.withValues(alpha: 1 - i * 0.28),
          );
        }
        stroke.color = color;
      case AppIcon.cards:
        canvas.save();
        canvas.translate(12, 13);
        canvas.rotate(-0.28);
        canvas.translate(-12, -13);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(5.5, 5, 9.5, 14.5),
            const Radius.circular(2),
          ),
          stroke,
        );
        canvas.restore();
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(10.5, 5, 9.5, 14.5),
            const Radius.circular(2),
          ),
          stroke,
        );
      case AppIcon.draw:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(4.5, 7.5, 10.5, 13),
            const Radius.circular(2.2),
          ),
          stroke,
        );
        canvas.drawLine(const Offset(18, 3.5), const Offset(18, 12), stroke);
        canvas.drawPath(
          Path()
            ..moveTo(15, 9)
            ..lineTo(18, 12.4)
            ..lineTo(21, 9),
          stroke,
        );
    }
    canvas.restore();
  }

  /// The almond the eye glyphs are built from, drawn as two mirrored curves.
  static Path _eyeOutline() {
    return Path()
      ..moveTo(2.6, 12)
      ..quadraticBezierTo(7, 5.4, 12, 5.4)
      ..quadraticBezierTo(17, 5.4, 21.4, 12)
      ..quadraticBezierTo(17, 18.6, 12, 18.6)
      ..quadraticBezierTo(7, 18.6, 2.6, 12)
      ..close();
  }

  @override
  bool shouldRepaint(AppIconPainter old) =>
      old.icon != icon || old.color != color || old.strokeWidth != strokeWidth;
}
