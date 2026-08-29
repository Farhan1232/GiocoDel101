import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/motion.dart';
import '../../../../app/localization/app_strings.dart';
import '../../domain/card_suit.dart';
import '../../domain/game_card.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/cards/playing_card.dart';
import '../../../../core/widgets/cards/suit_art.dart';

/// The stock. Shows a little depth for the cards left in it and invites a
/// tap when the player is allowed to draw (§27).
class DrawPileView extends StatelessWidget {
  const DrawPileView({
    super.key,
    required this.count,
    required this.cardWidth,
    required this.backId,
    this.onTap,
    this.highlighted = false,
  });

  final int count;
  final double cardWidth;
  final String backId;
  final VoidCallback? onTap;

  /// True when drawing is the player's move.
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final layers = count == 0 ? 0 : math.min(4, (count / 6).ceil() + 1);
    return Semantics(
      button: onTap != null,
      label: '${Strings.s.drawPile}, $count',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: cardWidth + 12,
          height: cardWidth * 1.55 + 26,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (highlighted)
                AnimatedContainer(
                  duration: Motion.scale(AppDurations.quick),
                  width: cardWidth + 16,
                  height: cardWidth * 1.55 + 16,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.goldLight.withValues(alpha: 0.30),
                        blurRadius: 22,
                        spreadRadius: -4,
                      ),
                    ],
                  ),
                ),
              if (count == 0)
                _emptySlot(cardWidth)
              else
                for (var i = layers - 1; i >= 0; i--)
                  Transform.translate(
                    offset: Offset(i * 1.6, -i * 2.0),
                    child: PlayingCard(
                      width: cardWidth,
                      faceUp: false,
                      backId: backId,
                      elevation: i == 0 ? 0.9 : 0.3,
                    ),
                  ),
              Positioned(
                bottom: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: AppColors.inkDeep.withValues(alpha: 0.75),
                    border: Border.all(color: AppColors.hairline),
                  ),
                  child: Text('$count', style: AppText.caption),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptySlot(double cw) => Container(
        width: cw,
        height: cw * 1.55,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(cw * AppRadii.cardCornerRatio),
          border: Border.all(
            color: AppColors.warmIvory.withValues(alpha: 0.16),
            width: 1.2,
          ),
        ),
      );
}

/// The discard pile: the live card, with a couple of earlier cards showing
/// underneath at natural angles (§29).
class DiscardPileView extends StatelessWidget {
  const DiscardPileView({
    super.key,
    required this.top,
    required this.beneath,
    required this.cardWidth,
    this.highContrast = false,
  });

  final GameCard? top;

  /// Up to three cards already played, oldest first.
  final List<GameCard> beneath;
  final double cardWidth;
  final bool highContrast;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: cardWidth + 26,
      height: cardWidth * 1.55 + 26,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (var i = 0; i < beneath.length; i++)
            Transform.rotate(
              // Deterministic per card, so the pile never reshuffles itself
              // when the widget rebuilds.
              angle: _angleFor(beneath[i], i),
              child: PlayingCard(
                width: cardWidth,
                card: beneath[i],
                elevation: 0.25,
                highContrast: highContrast,
              ),
            ),
          if (top != null)
            Transform.rotate(
              angle: _angleFor(top!, beneath.length),
              child: PlayingCard(
                width: cardWidth,
                card: top,
                elevation: 1.0,
                highContrast: highContrast,
              ),
            )
          else
            SizedBox(width: cardWidth, height: cardWidth * 1.55),
        ],
      ),
    );
  }

  static double _angleFor(GameCard card, int depth) {
    final rng = math.Random(card.id.hashCode + depth);
    return (rng.nextDouble() - 0.5) * 0.22;
  }
}

/// §12/§27 — the suit that must currently be matched, locked beside the
/// discard pile.
class ActiveSuitBadge extends StatelessWidget {
  const ActiveSuitBadge({
    super.key,
    required this.suit,
    this.size = 44,
    this.showLabel = true,
  });

  final CardSuit suit;
  final double size;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final p = SuitPalette.of(suit);
    return Semantics(
      label: '${Strings.s.activeSuit}: ${_name(suit)}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            key: ValueKey(suit),
            tween: Tween(begin: 0.75, end: 1.0),
            duration: Motion.scale(AppDurations.ambientShift),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.3, -0.4),
                  colors: [
                    AppColors.surfaceRaised,
                    AppColors.surfaceSunken,
                  ],
                ),
                border: Border.all(color: p.primary.withValues(alpha: 0.75),
                    width: 1.6),
                boxShadow: [
                  BoxShadow(
                    color: p.primary.withValues(alpha: 0.28),
                    blurRadius: 14,
                    spreadRadius: -3,
                  ),
                ],
              ),
              child: CustomPaint(painter: _BadgePainter(suit: suit)),
            ),
          ),
          if (showLabel) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              _name(suit).toUpperCase(),
              style: AppText.caption.copyWith(
                fontSize: 9.5,
                letterSpacing: 1.2,
                color: p.light,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _name(CardSuit suit) => switch (suit) {
        CardSuit.denari => Strings.s.suitDenari,
        CardSuit.coppe => Strings.s.suitCoppe,
        CardSuit.spade => Strings.s.suitSpade,
        CardSuit.bastoni => Strings.s.suitBastoni,
      };
}

class _BadgePainter extends CustomPainter {
  const _BadgePainter({required this.suit});

  final CardSuit suit;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: size.width * 0.58,
      height: size.height * 0.58,
    );
    SuitArt.draw(canvas, rect, suit, SuitPalette.of(suit), detail: 0.6);
  }

  @override
  bool shouldRepaint(_BadgePainter old) => old.suit != suit;
}
