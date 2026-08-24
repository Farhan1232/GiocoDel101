import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/utils/motion.dart';
import '../../data/app_strings.dart';
import '../../models/card_suit.dart';
import '../../models/game_card.dart';
import '../../services/haptic_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../cards/playing_card.dart';
import '../cards/suit_art.dart';

/// §13 "Rituale dei Semi" — the Cavallo's suit selector.
///
/// Four sculpted tokens bloom out of the card just played. Choosing one
/// enlarges it, sends the others backward, turns the ring once, and locks
/// the new suit in. Entry and resolution together sit inside the 400–650ms
/// the brief asks for, so it reads as a flourish rather than a wait.
class SuitRitual extends StatefulWidget {
  const SuitRitual({
    super.key,
    required this.card,
    required this.onChosen,
    this.cardWidth = 92,
  });

  final GameCard card;
  final ValueChanged<CardSuit> onChosen;
  final double cardWidth;

  @override
  State<SuitRitual> createState() => _SuitRitualState();
}

class _SuitRitualState extends State<SuitRitual>
    with TickerProviderStateMixin {
  late final AnimationController _open;
  late final AnimationController _close;

  CardSuit? _picked;

  @override
  void initState() {
    super.initState();
    _open = AnimationController(
      vsync: this,
      duration: Motion.scale(const Duration(milliseconds: 420)),
    )..forward();
    _close = AnimationController(
      vsync: this,
      duration: Motion.scale(const Duration(milliseconds: 460)),
    );
  }

  @override
  void dispose() {
    _open.dispose();
    _close.dispose();
    super.dispose();
  }

  Future<void> _choose(CardSuit suit) async {
    if (_picked != null) return;
    setState(() => _picked = suit);
    HapticService.instance.medium();
    await _close.forward();
    if (mounted) widget.onChosen(suit);
  }

  @override
  Widget build(BuildContext context) {
    final radius = math.min(
      MediaQuery.sizeOf(context).width * 0.26,
      116.0,
    );
    // The tokens sit a full radius out and carry a label beneath them; the
    // Stack has to contain all of that or the outer ones stop taking taps.
    final extent = radius * 3.2;

    return AnimatedBuilder(
      animation: Listenable.merge([_open, _close]),
      builder: (context, _) {
        final open = Curves.easeOutBack.transform(_open.value);
        final close = _close.value;

        return Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        AppColors.inkDeep
                            .withValues(alpha: 0.62 * _open.value),
                        AppColors.inkDeep
                            .withValues(alpha: 0.86 * _open.value),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: extent,
              height: extent,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // The ring the tokens sit on, which turns once on choosing.
                  Transform.rotate(
                    angle: Curves.easeInOutCubic.transform(close) * math.pi * 2,
                    child: CustomPaint(
                      size: Size.square(radius * 2.2),
                      painter: _RitualRingPainter(
                        progress: _open.value,
                        highlight: _picked,
                        close: close,
                      ),
                    ),
                  ),
                  // The Cavallo that started it all.
                  Transform.scale(
                    scale: 0.9 + open * 0.1 - close * 0.12,
                    child: Opacity(
                      opacity: (1 - close * 0.55).clamp(0.0, 1.0),
                      child: PlayingCard(
                        width: widget.cardWidth,
                        card: widget.card,
                        elevation: 1.8,
                      ),
                    ),
                  ),
                  for (var i = 0; i < CardSuit.values.length; i++)
                    _token(CardSuit.values[i], i, radius, open, close),
                  Positioned(
                    bottom: 0,
                    child: Opacity(
                      opacity: (_open.value * (1 - close * 2)).clamp(0.0, 1.0),
                      child: Text(
                        Strings.s.chooseSuit.toUpperCase(),
                        style: AppText.label.copyWith(
                          color: AppColors.warmIvory.withValues(alpha: 0.8),
                          letterSpacing: 2.6,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _token(
      CardSuit suit, int index, double radius, double open, double close) {
    final chosen = _picked == suit;
    final angle = -math.pi / 2 + (index / CardSuit.values.length) * math.pi * 2;
    final distance = radius * open * (chosen ? 1 - close * 0.72 : 1.0);
    final offset = Offset(math.cos(angle), math.sin(angle)) * distance;

    // Losers fade backward; the winner comes forward.
    final scale = chosen
        ? 1.0 + Curves.easeOutBack.transform(close) * 0.42
        : 1.0 - close * 0.35;
    final opacity = _picked == null
        ? open.clamp(0.0, 1.0)
        : chosen
            ? 1.0
            : (1 - close * 1.4).clamp(0.0, 1.0);

    final size = radius * 0.62;

    return Transform.translate(
      offset: offset,
      child: Transform.scale(
        scale: scale * (0.6 + open * 0.4),
        child: Opacity(
          opacity: opacity,
          child: Semantics(
            button: true,
            label: _label(suit),
            child: GestureDetector(
              onTap: () => _choose(suit),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SuitToken(suit: suit, size: size, lit: chosen),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _label(suit),
                    style: AppText.caption.copyWith(
                      fontSize: 10.5,
                      color: chosen
                          ? SuitPalette.of(suit).light
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _label(CardSuit suit) => switch (suit) {
        CardSuit.denari => Strings.s.suitDenari,
        CardSuit.coppe => Strings.s.suitCoppe,
        CardSuit.spade => Strings.s.suitSpade,
        CardSuit.bastoni => Strings.s.suitBastoni,
      };
}

/// A struck token: a bevelled disc carrying one suit emblem.
class _SuitToken extends StatelessWidget {
  const _SuitToken({required this.suit, required this.size, this.lit = false});

  final CardSuit suit;
  final double size;
  final bool lit;

  @override
  Widget build(BuildContext context) {
    final p = SuitPalette.of(suit);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.4),
          colors: [
            Color.lerp(p.light, Colors.white, 0.25)!,
            p.primary,
            p.deep,
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
        border: Border.all(
          color: lit ? AppColors.goldLight : p.light.withValues(alpha: 0.55),
          width: lit ? 2.4 : 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.inkDeep.withValues(alpha: 0.6),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
          if (lit)
            BoxShadow(
              color: p.light.withValues(alpha: 0.5),
              blurRadius: 26,
              spreadRadius: -2,
            ),
        ],
      ),
      child: CustomPaint(
        painter: _TokenEmblemPainter(suit: suit),
      ),
    );
  }
}

class _TokenEmblemPainter extends CustomPainter {
  const _TokenEmblemPainter({required this.suit});

  final CardSuit suit;

  @override
  void paint(Canvas canvas, Size size) {
    // The emblem is struck into the token: dark, with a lit top edge.
    final rect = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: size.width * 0.58,
      height: size.height * 0.58,
    );
    final ink = SuitPalette(
      primary: AppColors.inkDeep.withValues(alpha: 0.72),
      deep: AppColors.inkDeep.withValues(alpha: 0.9),
      light: Colors.white.withValues(alpha: 0.55),
      ambient: AppColors.inkDeep,
    );
    canvas.save();
    canvas.translate(0, size.height * 0.012);
    SuitArt.draw(canvas, rect, suit, ink, detail: 0.55, opacity: 0.9);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_TokenEmblemPainter old) => old.suit != suit;
}

class _RitualRingPainter extends CustomPainter {
  const _RitualRingPainter({
    required this.progress,
    required this.highlight,
    required this.close,
  });

  final double progress;
  final CardSuit? highlight;
  final double close;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final r = size.width * 0.5;
    final accent = highlight == null
        ? AppColors.antiqueGold
        : SuitPalette.of(highlight!).light;

    canvas.drawCircle(
      centre,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = accent.withValues(alpha: 0.30 * progress),
    );
    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: r),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 2.6
        ..shader = ui.Gradient.sweep(
          centre,
          [
            accent.withValues(alpha: 0.0),
            accent.withValues(alpha: 0.65 + close * 0.35),
            accent.withValues(alpha: 0.0),
          ],
          const [0.0, 0.5, 1.0],
        ),
    );

    // Four notches marking the token positions.
    for (var i = 0; i < 4; i++) {
      final a = -math.pi / 2 + (i / 4) * math.pi * 2;
      canvas.drawCircle(
        centre + Offset(math.cos(a), math.sin(a)) * r,
        2.2,
        Paint()..color = accent.withValues(alpha: 0.5 * progress),
      );
    }
  }

  @override
  bool shouldRepaint(_RitualRingPainter old) =>
      old.progress != progress ||
      old.highlight != highlight ||
      old.close != close;
}
