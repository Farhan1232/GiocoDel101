import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../app/localization/app_strings.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

/// §3 — the identity mark.
///
/// Three embossed gold numerals where the central zero is struck like a
/// denari coin: an Italian medal rather than a cartoon logo. Depth comes
/// from stacked offset passes (drop shadow, body, inner highlight) instead
/// of a bitmap, so it stays crisp at any size.
class Logo101 extends StatelessWidget {
  const Logo101({
    super.key,
    this.size = 96,
    this.showWordmark = true,
    this.shimmer = 0.0,
  });

  final double size;
  final bool showWordmark;

  /// 0..1 sweep of highlight across the numerals.
  final double shimmer;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showWordmark) ...[
            Text(
              'GIOCO DEL',
              style: AppText.sectionTitle.copyWith(
                fontSize: size * 0.135,
                letterSpacing: size * 0.085,
                color: AppColors.warmIvory.withValues(alpha: 0.72),
              ),
            ),
            SizedBox(height: size * 0.08),
          ],
          CustomPaint(
            size: Size(size * 2.0, size),
            painter: _Logo101Painter(shimmer: shimmer),
          ),
        ],
      ),
    );
  }
}

class _Logo101Painter extends CustomPainter {
  _Logo101Painter({required this.shimmer});

  final double shimmer;

  @override
  void paint(Canvas canvas, Size size) {
    final glyphSize = size.height * 0.95;
    final one = _glyph('1', glyphSize);
    final zero = _glyph('0', glyphSize);

    final gap = glyphSize * 0.055;
    final total = one.width * 2 + zero.width + gap * 2;
    var x = (size.width - total) / 2;
    final y = (size.height - one.height) / 2;

    final positions = <(TextPainter, double)>[
      (one, x),
      (zero, x + one.width + gap),
      (one, x + one.width + zero.width + gap * 2),
    ];
    x = 0;

    final bodyShader = ui.Gradient.linear(
      Offset(0, y),
      Offset(0, y + one.height),
      const [
        AppColors.goldLight,
        AppColors.goldMid,
        AppColors.goldDeep,
        AppColors.goldMid,
      ],
      const [0.0, 0.36, 0.72, 1.0],
    );

    // Cast shadow, then the struck body, then a lit top edge.
    for (final (painter, px) in positions) {
      _paintTinted(
        canvas,
        painter,
        Offset(px + glyphSize * 0.035, y + glyphSize * 0.05),
        AppColors.inkDeep.withValues(alpha: 0.55),
      );
    }
    for (final (painter, px) in positions) {
      _paintTinted(
        canvas,
        painter,
        Offset(px, y + glyphSize * 0.018),
        AppColors.goldShadow.withValues(alpha: 0.9),
      );
    }
    for (final (painter, px) in positions) {
      _paintShaded(canvas, painter, Offset(px, y), bodyShader);
    }
    for (final (painter, px) in positions) {
      _paintTinted(
        canvas,
        painter,
        Offset(px, y - glyphSize * 0.012),
        AppColors.goldLight.withValues(alpha: 0.34),
      );
    }

    // Strike the central zero into a coin. The medallion is centred on the
    // glyph's ink, not on its layout box: a text box carries descender space
    // that a digit never uses, which would drop the coin low in the counter.
    final baseline = zero.computeDistanceToActualBaseline(
      TextBaseline.alphabetic,
    );
    final zeroRect = Rect.fromCenter(
      center: Offset(
        positions[1].$2 + zero.width / 2,
        y + baseline - glyphSize * 0.355,
      ),
      width: zero.width,
      height: zero.height,
    );
    _coinFace(canvas, zeroRect);

    if (shimmer > 0.001) {
      final sweep = (shimmer * 1.6 - 0.3) * size.width;
      canvas.saveLayer(Offset.zero & size, Paint());
      for (final (painter, px) in positions) {
        _paintTinted(canvas, painter, Offset(px, y), Colors.white);
      }
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..blendMode = BlendMode.srcIn
          ..shader = ui.Gradient.linear(
            Offset(sweep - size.width * 0.18, 0),
            Offset(sweep + size.width * 0.18, size.height),
            [
              Colors.white.withValues(alpha: 0.0),
              Colors.white.withValues(alpha: 0.55),
              Colors.white.withValues(alpha: 0.0),
            ],
            const [0.0, 0.5, 1.0],
          ),
      );
      canvas.restore();
    }
  }

  /// Engraved rosette and milled rim inside the zero's counter.
  void _coinFace(Canvas canvas, Rect r) {
    final centre = r.center;
    final radius = r.width * 0.215;

    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..shader = ui.Gradient.radial(
          centre.translate(-radius * 0.3, -radius * 0.35),
          radius * 1.7,
          const [AppColors.goldLight, AppColors.goldDeep],
        ),
    );
    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.13
        ..color = AppColors.goldShadow.withValues(alpha: 0.85),
    );

    final star = Path();
    const points = 8;
    for (var i = 0; i < points * 2; i++) {
      final a = (i / (points * 2)) * math.pi * 2 - math.pi / 2;
      final rr = i.isEven ? radius * 0.66 : radius * 0.28;
      final pt = centre + Offset(math.cos(a) * rr, math.sin(a) * rr);
      if (i == 0) {
        star.moveTo(pt.dx, pt.dy);
      } else {
        star.lineTo(pt.dx, pt.dy);
      }
    }
    star.close();
    canvas.drawPath(
      star,
      Paint()..color = AppColors.goldShadow.withValues(alpha: 0.75),
    );
    canvas.drawCircle(
      centre,
      radius * 0.17,
      Paint()..color = AppColors.goldLight,
    );
  }

  void _paintTinted(
    Canvas canvas,
    TextPainter painter,
    Offset at,
    Color color,
  ) {
    canvas.saveLayer(at & Size(painter.width, painter.height), Paint());
    painter.paint(canvas, at);
    canvas.drawRect(
      at & Size(painter.width, painter.height),
      Paint()
        ..blendMode = BlendMode.srcIn
        ..color = color,
    );
    canvas.restore();
  }

  void _paintShaded(
    Canvas canvas,
    TextPainter painter,
    Offset at,
    Shader shader,
  ) {
    canvas.saveLayer(at & Size(painter.width, painter.height), Paint());
    painter.paint(canvas, at);
    canvas.drawRect(
      at & Size(painter.width, painter.height),
      Paint()
        ..blendMode = BlendMode.srcIn
        ..shader = shader,
    );
    canvas.restore();
  }

  static final Map<String, TextPainter> _cache = {};

  static TextPainter _glyph(String text, double size) {
    final key = '$text|${size.toStringAsFixed(1)}';
    final cached = _cache[key];
    if (cached != null) return cached;
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: AppText.display,
          fontSize: size,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    if (_cache.length > 20) _cache.clear();
    _cache[key] = painter;
    return painter;
  }

  @override
  bool shouldRepaint(_Logo101Painter old) => old.shimmer != shimmer;
}

/// Full lockup: wordmark, numerals and tagline.
class LogoLockup extends StatelessWidget {
  const LogoLockup({super.key, this.size = 96, this.shimmer = 0.0});

  final double size;
  final double shimmer;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Logo101(size: size, shimmer: shimmer),
        SizedBox(height: size * 0.14),
        Container(
          width: size * 1.25,
          height: 1,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0x00D9A441),
                AppColors.antiqueGold,
                Color(0x00D9A441),
              ],
            ),
          ),
        ),
        SizedBox(height: size * 0.12),
        Text(
          Strings.s.appTagline,
          style: AppText.caption.copyWith(
            fontSize: size * 0.11,
            letterSpacing: size * 0.022,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
