import 'package:flutter/material.dart';

import '../../constants/app_spacing.dart';
import '../../../features/game/domain/game_card.dart';
import '../../../app/theme/app_colors.dart';
import 'card_face_painter.dart';

/// The printed face of one card: the traditional Carte Napoletane artwork
/// shipped in `assets/cards/` (see `assets/cards/LICENSE.txt`).
///
/// The forty files are authored at exactly [CardMetrics.aspect], so
/// `BoxFit.fill` reproduces the card without stretching it. Decoding is asked
/// for at the size the card is actually drawn — never at the source's own
/// resolution — so a table full of cards costs one small bitmap each however
/// large the file is.
///
/// [CardFacePainter] stays as the fallback and paints if an asset is missing
/// or has not decoded yet, so a card is never a blank rectangle.
class CardFaceImage extends StatelessWidget {
  const CardFaceImage({
    super.key,
    required this.card,
    required this.width,
    this.highContrast = false,
    this.dimmed = false,
  });

  final GameCard card;

  /// Layout width of the card in logical pixels; the decode is sized from it.
  final double width;

  /// §48 — deepens the ink for readability.
  final bool highContrast;

  /// Unplayable cards sit back very slightly rather than being greyed out.
  final bool dimmed;

  /// Pixel width the shipped faces are authored at. A decode may never be
  /// keyed above it: `ResizeImage` clamps the actual decode to the source,
  /// but keeps the *requested* width in the cache key — so keys past 360
  /// would be duplicate full-resolution bitmaps under different names.
  static const int sourceWidth = 360;

  /// Decode width in device pixels, rounded up to a step so that a card which
  /// animates through many intermediate sizes still shares one cache entry
  /// instead of decoding a new bitmap per frame.
  ///
  /// From 256 up the request snaps straight to [sourceWidth]: on a 2.6–4.0
  /// device-pixel-ratio phone every hand and table card lands in that band,
  /// and snapping means the whole deck costs exactly one full-quality entry
  /// per card instead of several near-identical ones.
  static int decodeWidth(double width, double devicePixelRatio) {
    final physical = width * devicePixelRatio;
    const step = 64;
    final stepped = ((physical / step).ceil()) * step;
    if (stepped >= 256) return sourceWidth;
    return stepped.clamp(step, sourceWidth);
  }

  Widget _fallback() => CustomPaint(
    painter: CardFacePainter(
      card: card,
      highContrast: highContrast,
      dimmed: dimmed,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final ratio = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.0;
    final cacheWidth = decodeWidth(width, ratio);

    Widget face = Image.asset(
      card.asset.imagePath,
      fit: BoxFit.fill,
      // `low` is bilinear. `medium` would have Impeller build a mip chain per
      // (card, size) — a raster-thread stall on first draw and ~a third more
      // GPU memory per face — for a downscale that never exceeds ~1.4×,
      // where bilinear is visually identical.
      filterQuality: FilterQuality.low,
      cacheWidth: cacheWidth,
      gaplessPlayback: true,
      excludeFromSemantics: true,
      // Until the first frame is decoded, and forever if the asset is
      // missing, the engraved painter stands in.
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) return child;
        return _fallback();
      },
      errorBuilder: (context, error, stack) => _fallback(),
    );

    if (highContrast) {
      // §48 — the same intent as the painter's high-contrast mode: deepen the
      // ink a little. The artwork is already strongly coloured, so this is a
      // gentle contrast lift, not a recolour.
      face = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          1.16, 0, 0, 0, -20, //
          0, 1.16, 0, 0, -20, //
          0, 0, 1.16, 0, -20, //
          0, 0, 0, 1, 0,
        ]),
        child: face,
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        face,
        if (dimmed)
          ColoredBox(color: AppColors.inkDeep.withValues(alpha: 0.20)),
      ],
    );
  }
}
