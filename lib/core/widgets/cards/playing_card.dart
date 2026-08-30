import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../constants/app_spacing.dart';
import '../../../features/game/domain/game_card.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/card_backs.dart';
import 'card_back_painter.dart';
import 'card_face_painter.dart';
import 'card_names.dart';
import '../../../app/localization/app_strings.dart';

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

    return Semantics(
      image: true,
      label: showFace ? cardDisplayName(card!) : Strings.s.cardBack,
      child: RepaintBoundary(
        child: SizedBox(
          width: width,
          height: height + thickness,
          child: content,
        ),
      ),
    );
  }
}
