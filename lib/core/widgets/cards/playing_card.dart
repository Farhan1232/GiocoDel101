import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../constants/app_spacing.dart';
import '../../../features/game/domain/game_card.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/card_backs.dart';
import 'card_back_painter.dart';
import 'card_face_painter.dart';

/// One card, face up or face down, with printed thickness and a soft
/// contact shadow (§34).
class PlayingCard extends StatelessWidget {
  const PlayingCard({
    super.key,
    required this.width,
    this.card,
    this.faceUp = true,
    this.backId = 'oro',
    this.elevation = 1.0,
    this.tilt = 0.0,
    this.dimmed = false,
    this.glow = 0.0,
    this.highContrast = false,
    this.shine = 0.0,
  });

  final double width;

  /// null renders a back regardless of [faceUp].
  final GameCard? card;
  final bool faceUp;
  final String backId;

  /// 0 flat on the felt, 1 lifted, >1 mid-flight.
  final double elevation;

  /// Radians of Y-axis perspective tilt.
  final double tilt;

  final bool dimmed;
  final double glow;
  final bool highContrast;
  final double shine;

  double get height => width * CardMetrics.aspect;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(width * AppRadii.cardCornerRatio);
    final showFace = faceUp && card != null;
    final thickness = math.max(1.0, width * 0.022);

    Widget content = Stack(
      clipBehavior: Clip.none,
      children: [
        // Printed edge peeking out below the face — the card has substance.
        Positioned(
          left: 0,
          right: 0,
          top: thickness * 0.9,
          height: height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              color: showFace
                  ? AppColors.cardEdge
                  : Color.lerp(
                      CardBacks.byId(backId).baseBottom,
                      Colors.black,
                      0.35,
                    )!,
            ),
          ),
        ),
        SizedBox(
          width: width,
          height: height,
          child: CustomPaint(
            painter: showFace
                ? CardFacePainter(
                    card: card!,
                    highContrast: highContrast,
                    dimmed: dimmed,
                    glow: glow,
                  )
                : CardBackPainter(design: CardBacks.byId(backId), shine: shine),
          ),
        ),
      ],
    );

    content = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: AppColors.inkDeep.withValues(alpha: 0.28 + 0.22 * elevation),
            blurRadius: 6 + 16 * elevation,
            offset: Offset(0, 2 + 9 * elevation),
            spreadRadius: -1,
          ),
        ],
      ),
      child: content,
    );

    if (tilt.abs() > 0.001) {
      content = Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0012)
          ..rotateY(tilt),
        child: content,
      );
    }

    return RepaintBoundary(
      child: SizedBox(width: width, height: height + thickness, child: content),
    );
  }
}

/// Flips between back and face around the card's vertical axis (§30).
class FlippingCard extends StatelessWidget {
  const FlippingCard({
    super.key,
    required this.width,
    required this.card,
    required this.progress,
    this.backId = 'oro',
    this.elevation = 1.0,
    this.highContrast = false,
  });

  final double width;
  final GameCard card;

  /// 0 = fully face down, 1 = fully face up.
  final double progress;
  final String backId;
  final double elevation;
  final bool highContrast;

  @override
  Widget build(BuildContext context) {
    final angle = progress * math.pi;
    final showFace = progress > 0.5;
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0014)
        ..rotateY(showFace ? angle - math.pi : angle),
      child: PlayingCard(
        width: width,
        card: card,
        faceUp: showFace,
        backId: backId,
        elevation: elevation,
        highContrast: highContrast,
        // A sheen crosses the back as it turns.
        shine: showFace ? 0 : (1 - (progress * 2 - 0.5).abs()).clamp(0.0, 1.0),
      ),
    );
  }
}
