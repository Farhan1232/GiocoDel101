import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../constants/app_spacing.dart';
import '../../../features/game/domain/card_rank.dart';
import '../../../features/game/domain/game_card.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import 'figure_art.dart';
import 'suit_art.dart';

/// Draws one of the forty card faces.
///
/// The whole deck is vector art (§5): ivory stock with a paper tooth, a
/// bevelled edge, a double ornamental rule, engraved corner indices, and
/// either a traditional pip layout or a heraldic court emblem. Because it is
/// geometry rather than bitmaps, a card is crisp at any size, weighs nothing
/// in the bundle, and is unambiguously original work.
class CardFacePainter extends CustomPainter {
  const CardFacePainter({
    required this.card,
    this.highContrast = false,
    this.dimmed = false,
    this.glow = 0.0,
  });

  final GameCard card;

  /// §48 — deepens the ink and thickens the rules for readability.
  final bool highContrast;

  /// Unplayable cards sit back very slightly rather than being greyed out.
  final bool dimmed;

  /// §28 — a hairline of warm light along the card's own edge. Deliberately
  /// subtle: no green "playable" outlines anywhere in this game.
  final double glow;

  static final Map<String, TextPainter> _labelCache = {};

  @override
  void paint(Canvas canvas, Size size) {
    final palette = SuitPalette.of(card.suit);
    final radius = size.width * AppRadii.cardCornerRatio;
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    canvas.save();
    canvas.clipRRect(rrect);

    _paintStock(canvas, size, rect);
    _paintGrain(canvas, size);
    _paintBevel(canvas, size, radius);
    _paintFrame(canvas, size, palette);
    _paintIndices(canvas, size, palette);
    _paintCentre(canvas, size, palette);

    if (dimmed) {
      canvas.drawRect(
        rect,
        Paint()..color = AppColors.inkDeep.withValues(alpha: 0.20),
      );
    }
    canvas.restore();

    if (glow > 0.01) {
      canvas.drawRRect(
        rrect.deflate(0.6),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = AppColors.goldLight.withValues(alpha: 0.55 * glow),
      );
    }
  }

  // Ivory stock with a warm gradient, slightly cooler toward the bottom edge.
  void _paintStock(Canvas canvas, Size size, Rect rect) {
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(size.width * 0.15, 0),
          Offset(size.width * 0.85, size.height),
          const [
            Color(0xFFFDF6E9),
            AppColors.cardIvory,
            AppColors.cardIvoryShade,
          ],
          const [0.0, 0.55, 1.0],
        ),
    );
  }

  /// A deterministic tooth, so a given card always has the same fibres.
  void _paintGrain(Canvas canvas, Size size) {
    final rng = math.Random(card.id.hashCode);
    final fibre = Paint()
      ..strokeWidth = 0.7
      ..strokeCap = StrokeCap.round
      ..color = AppColors.goldShadow.withValues(alpha: 0.045);
    for (var i = 0; i < 22; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final len = 2 + rng.nextDouble() * 7;
      final a = rng.nextDouble() * math.pi;
      canvas.drawLine(
        Offset(x, y),
        Offset(x + math.cos(a) * len, y + math.sin(a) * len),
        fibre,
      );
    }
    final speck = Paint()..color = AppColors.goldDeep.withValues(alpha: 0.05);
    for (var i = 0; i < 16; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
        0.5 + rng.nextDouble() * 0.9,
        speck,
      );
    }
  }

  /// Inner highlight top-left, inner shade bottom-right: the card reads as a
  /// physical object with thickness (§34).
  void _paintBevel(Canvas canvas, Size size, double radius) {
    final inset = size.width * 0.014;
    final inner = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        inset,
        inset,
        size.width - inset * 2,
        size.height - inset * 2,
      ),
      Radius.circular(radius * 0.85),
    );
    canvas.drawRRect(
      inner,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.016
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(size.width, size.height),
          [
            Colors.white.withValues(alpha: 0.75),
            Colors.white.withValues(alpha: 0.0),
            AppColors.goldShadow.withValues(alpha: 0.16),
          ],
          const [0.0, 0.45, 1.0],
        ),
    );
  }

  /// Double rule with a fleuron at each corner.
  void _paintFrame(Canvas canvas, Size size, SuitPalette palette) {
    final m = size.width * 0.075;
    final ink = highContrast
        ? Color.lerp(palette.deep, AppColors.inkDeep, 0.35)!
        : palette.deep;

    final outer = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        m * 0.62,
        m * 0.62,
        size.width - m * 1.24,
        size.height - m * 1.24,
      ),
      Radius.circular(size.width * 0.045),
    );
    canvas.drawRRect(
      outer,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(
          1.0,
          size.width * (highContrast ? 0.017 : 0.013),
        )
        ..color = ink.withValues(alpha: 0.75),
    );

    final inner = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        m * 0.95,
        m * 0.95,
        size.width - m * 1.9,
        size.height - m * 1.9,
      ),
      Radius.circular(size.width * 0.035),
    );
    canvas.drawRRect(
      inner,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.6, size.width * 0.006)
        ..color = ink.withValues(alpha: 0.42),
    );

    // Fleurons sit only in the corners the rank indices leave free, so
    // nothing ever stacks on top of anything else.
    if (size.width > 52) {
      final r = size.width * 0.032;
      final dx = m * 0.79;
      for (final corner in [
        Offset(size.width - dx, dx),
        Offset(dx, size.height - dx),
      ]) {
        FigureArt.fleuron(canvas, corner, r, ink.withValues(alpha: 0.55));
      }
    }
  }

  /// Rank in both corners, the second rotated, each over a small suit mark.
  void _paintIndices(Canvas canvas, Size size, SuitPalette palette) {
    final label = _rankLabel(card.rank);
    final ink = highContrast
        ? Color.lerp(palette.deep, AppColors.inkDeep, 0.4)!
        : palette.deep;
    final fontSize = size.width * 0.165;
    final painter = _label(label, fontSize, ink);
    final pipSize = size.width * 0.105;
    // Measured from the inner rule so the index can never touch the frame.
    final padX = size.width * 0.185;
    final padY = size.height * 0.105;

    void drawIndex() {
      painter.paint(canvas, Offset(-painter.width / 2, -painter.height * 0.94));
      SuitArt.draw(
        canvas,
        Rect.fromCenter(
          center: Offset(0, pipSize * 0.60),
          width: pipSize,
          height: pipSize,
        ),
        card.suit,
        palette,
        detail: 0.22,
      );
    }

    canvas.save();
    canvas.translate(padX, padY);
    drawIndex();
    canvas.restore();

    canvas.save();
    canvas.translate(size.width - padX, size.height - padY);
    canvas.rotate(math.pi);
    drawIndex();
    canvas.restore();
  }

  void _paintCentre(Canvas canvas, Size size, SuitPalette palette) {
    if (card.rank.isFigure) {
      _paintCourt(canvas, size);
      return;
    }
    if (card.rank == CardRank.ace) {
      _paintAce(canvas, size, palette);
      return;
    }
    _paintPips(canvas, size, palette);
  }

  /// The Ace: one large emblem inside a laurel ring.
  void _paintAce(Canvas canvas, Size size, SuitPalette palette) {
    final centre = Offset(size.width * 0.5, size.height * 0.5);
    final ring = size.width * 0.335;

    canvas.drawCircle(
      centre,
      ring,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.8, size.width * 0.009)
        ..color = palette.deep.withValues(alpha: 0.30),
    );
    if (size.width > 48) {
      const petals = 12;
      for (var i = 0; i < petals; i++) {
        final a = (i / petals) * math.pi * 2 - math.pi / 2;
        final at = centre + Offset(math.cos(a), math.sin(a)) * ring;
        canvas.save();
        canvas.translate(at.dx, at.dy);
        canvas.rotate(a + math.pi / 2);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset.zero,
            width: size.width * 0.052,
            height: size.width * 0.026,
          ),
          Paint()..color = palette.primary.withValues(alpha: 0.34),
        );
        canvas.restore();
      }
    }

    final art = size.width * 0.46;
    SuitArt.draw(
      canvas,
      Rect.fromCenter(center: centre, width: art, height: art),
      card.suit,
      palette,
      detail: 1.0,
    );
  }

  /// Traditional pip grids for two through seven.
  void _paintPips(Canvas canvas, Size size, SuitPalette palette) {
    final n = card.rank.value;
    final spots = _pipLayout(n);
    final pip = size.width * _pipScale(n);
    final detail = pip > 26 ? 0.8 : 0.35;

    for (final spot in spots) {
      SuitArt.draw(
        canvas,
        Rect.fromCenter(
          center: Offset(size.width * spot.dx, size.height * spot.dy),
          width: pip,
          height: pip,
        ),
        card.suit,
        palette,
        detail: detail,
      );
    }
  }

  /// Court cards: a full-length Neapolitan figure on its ground bar.
  ///
  /// The figure box is cut to [FigureArt.aspect] and centred, so the art is
  /// scaled uniformly — outlines keep one weight — and lands clear of both
  /// corner indices.
  void _paintCourt(Canvas canvas, Size size) {
    final w = size.width * 0.62;
    final h = w * FigureArt.aspect;
    final rect = Rect.fromLTWH(
      (size.width - w) / 2,
      (size.height - h) / 2,
      w,
      h,
    );

    // Fine engraving — faces, hatching, jewels — is dropped on the small
    // cards in a tight fan, where it would only turn to mud.
    final detail = size.width > 96 ? 1.0 : (size.width > 62 ? 0.6 : 0.3);

    switch (card.rank) {
      case CardRank.cavallo:
        FigureArt.rider(canvas, rect, card.suit, detail: detail);
      case CardRank.re:
        FigureArt.standing(canvas, rect, card.suit, king: true, detail: detail);
      default:
        FigureArt.standing(
          canvas,
          rect,
          card.suit,
          king: false,
          detail: detail,
        );
    }
  }

  // --------------------------------------------------------------- helpers

  static String _rankLabel(CardRank rank) {
    switch (rank) {
      case CardRank.ace:
        return 'A';
      case CardRank.fante:
        return 'F';
      case CardRank.cavallo:
        return 'C';
      case CardRank.re:
        return 'R';
      default:
        return '${rank.value}';
    }
  }

  /// Unit-square pip positions, in the traditional arrangement.
  static List<Offset> _pipLayout(int n) {
    switch (n) {
      case 2:
        return const [Offset(0.5, 0.29), Offset(0.5, 0.71)];
      case 3:
        return const [Offset(0.5, 0.255), Offset(0.5, 0.5), Offset(0.5, 0.745)];
      case 4:
        return const [
          Offset(0.325, 0.30),
          Offset(0.675, 0.30),
          Offset(0.325, 0.70),
          Offset(0.675, 0.70),
        ];
      case 5:
        return const [
          Offset(0.315, 0.285),
          Offset(0.685, 0.285),
          Offset(0.5, 0.5),
          Offset(0.315, 0.715),
          Offset(0.685, 0.715),
        ];
      case 6:
        return const [
          Offset(0.315, 0.265),
          Offset(0.685, 0.265),
          Offset(0.315, 0.5),
          Offset(0.685, 0.5),
          Offset(0.315, 0.735),
          Offset(0.685, 0.735),
        ];
      case 7:
        return const [
          Offset(0.315, 0.245),
          Offset(0.685, 0.245),
          Offset(0.5, 0.375),
          Offset(0.315, 0.505),
          Offset(0.685, 0.505),
          Offset(0.315, 0.765),
          Offset(0.685, 0.765),
        ];
      default:
        return const [Offset(0.5, 0.5)];
    }
  }

  static double _pipScale(int n) {
    if (n <= 3) return 0.235;
    if (n <= 5) return 0.205;
    return 0.185;
  }

  static TextPainter _label(String text, double size, Color color) {
    final key = '$text|${size.toStringAsFixed(1)}|${color.toARGB32()}';
    final cached = _labelCache[key];
    if (cached != null) return cached;
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: AppText.display,
          fontSize: size,
          fontWeight: FontWeight.w700,
          color: color,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    if (_labelCache.length > 120) _labelCache.clear();
    _labelCache[key] = painter;
    return painter;
  }

  @override
  bool shouldRepaint(CardFacePainter old) =>
      old.card != card ||
      old.highContrast != highContrast ||
      old.dimmed != dimmed ||
      old.glow != glow;
}
