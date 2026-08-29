import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/game_card.dart';
import '../../../../core/widgets/cards/playing_card.dart';

/// One card travelling between two places on the table.
class CardFlight {
  CardFlight({
    required this.id,
    required this.card,
    required this.from,
    required this.to,
    required this.controller,
    required this.width,
    required this.startFaceUp,
    required this.endFaceUp,
    required this.backId,
    required this.startAngle,
    required this.endAngle,
    required this.highContrast,
  });

  final int id;
  final GameCard card;
  final Offset from;
  final Offset to;
  final AnimationController controller;
  final double width;
  final bool startFaceUp;
  final bool endFaceUp;
  final String backId;
  final double startAngle;
  final double endAngle;
  final bool highContrast;

  bool get flips => startFaceUp != endFaceUp;
}

/// §29/§30 — draws the cards currently in motion.
///
/// Every flight follows a curved path with a small overshoot at the end, so
/// nothing ever teleports and nothing arrives with a dead stop.
class CardFlightLayer extends StatelessWidget {
  const CardFlightLayer({super.key, required this.flights});

  final List<CardFlight> flights;

  @override
  Widget build(BuildContext context) {
    if (flights.isEmpty) return const SizedBox.shrink();
    return IgnorePointer(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final flight in flights)
            AnimatedBuilder(
              key: ValueKey(flight.id),
              animation: flight.controller,
              builder: (context, _) => _build(flight),
            ),
        ],
      ),
    );
  }

  Widget _build(CardFlight flight) {
    final raw = flight.controller.value;
    final t = Curves.easeInOutCubic.transform(raw);

    // Quadratic bezier, bowed perpendicular to the direction of travel, so
    // cards arc across the felt instead of sliding in a straight line.
    final delta = flight.to - flight.from;
    final distance = delta.distance;
    final normal = distance == 0
        ? Offset.zero
        : Offset(-delta.dy, delta.dx) / distance;
    final control = flight.from +
        delta * 0.5 +
        normal * math.min(distance * 0.22, 70.0);

    final inv = 1 - t;
    final position = flight.from * (inv * inv) +
        control * (2 * inv * t) +
        flight.to * (t * t);

    // A little overshoot in scale as the card settles.
    final settle = raw < 0.82
        ? 1.0
        : 1.0 + math.sin((raw - 0.82) / 0.18 * math.pi) * 0.055;
    final scale = (0.94 + t * 0.10) * settle;
    final angle = flight.startAngle +
        (flight.endAngle - flight.startAngle) * Curves.easeOutCubic.transform(t);

    final faceUp = flight.flips
        ? (t > 0.5 ? flight.endFaceUp : flight.startFaceUp)
        : flight.endFaceUp;
    // Past the halfway point the card is turned the rest of the way round,
    // so the revealed side is never seen mirrored.
    final flipAngle = !flight.flips
        ? 0.0
        : (t > 0.5 ? t * math.pi - math.pi : t * math.pi);

    final height = flight.width * 1.55;

    return Positioned(
      left: position.dx - flight.width / 2,
      top: position.dy - height / 2,
      child: Transform.rotate(
        angle: angle,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateY(flipAngle)
            ..scaleByDouble(scale, scale, 1.0, 1.0),
          child: PlayingCard(
            width: flight.width,
            card: flight.card,
            faceUp: faceUp,
            backId: flight.backId,
            elevation: 1.6 + math.sin(t * math.pi) * 0.9,
            highContrast: flight.highContrast,
          ),
        ),
      ),
    );
  }
}
