import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../app/localization/app_strings.dart';
import '../domain/card_rank.dart';
import '../domain/card_suit.dart';
import '../domain/game_card.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/cards/playing_card.dart';
import '../../../core/widgets/app_icons.dart';
import 'widgets/fate_ring.dart';
import 'widgets/table_piles.dart';

/// §38 — the illustrations for the tutorial, built from the real deck.
class TutorialFigures {
  const TutorialFigures._();

  static const GameCard _fiveCoppe = GameCard(CardSuit.coppe, CardRank.five);

  static Widget goal(double cw) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _fan(cw, const [
            GameCard(CardSuit.denari, CardRank.re),
            GameCard(CardSuit.spade, CardRank.seven),
            GameCard(CardSuit.bastoni, CardRank.three),
          ]),
          const SizedBox(width: AppSpacing.lg),
          const AppIconView(AppIcon.play,
              size: 20, color: AppColors.antiqueGold),
          const SizedBox(width: AppSpacing.lg),
          _emptySlot(cw),
        ],
      );

  static Widget matching(double cw) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _caption(Strings.s.discardPile),
          const SizedBox(height: AppSpacing.sm),
          PlayingCard(width: cw, card: _fiveCoppe, elevation: 1.2),
          const SizedBox(height: AppSpacing.lg),
          const AppIconView(AppIcon.chevronDown,
              size: 18, color: AppColors.antiqueGold),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _valid(cw, const GameCard(CardSuit.coppe, CardRank.re),
                  Strings.s.suitCoppe),
              const SizedBox(width: AppSpacing.lg),
              _valid(cw, const GameCard(CardSuit.bastoni, CardRank.five), '5'),
            ],
          ),
        ],
      );

  static Widget drawing(double cw, String backId) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PlayingCard(width: cw, faceUp: false, backId: backId),
              const SizedBox(height: AppSpacing.sm),
              _caption(Strings.s.drawPile),
            ],
          ),
          const SizedBox(width: AppSpacing.lg),
          const AppIconView(AppIcon.draw,
              size: 24, color: AppColors.mediterraneanTeal),
          const SizedBox(width: AppSpacing.lg),
          _fan(cw, const [
            GameCard(CardSuit.spade, CardRank.four),
            GameCard(CardSuit.denari, CardRank.six),
          ]),
        ],
      );

  static Widget ace(double cw) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PlayingCard(
            width: cw * 1.15,
            card: const GameCard(CardSuit.denari, CardRank.ace),
            elevation: 1.8,
            glow: 0.9,
          ),
          const SizedBox(height: AppSpacing.lg),
          _pill(Strings.s.turnSkipped, AppColors.goldLight),
        ],
      );

  static Widget chain(double cw) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final suit in const [
                CardSuit.coppe,
                CardSuit.spade,
                CardSuit.denari
              ])
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Transform.rotate(
                    angle: (suit.index - 1) * 0.10,
                    child: PlayingCard(
                      width: cw * 0.86,
                      card: GameCard(suit, CardRank.two),
                      elevation: 0.9,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _pill('+2', AppColors.antiqueGold),
              const SizedBox(width: AppSpacing.sm),
              _pill('+4', AppColors.fateWarning),
              const SizedBox(width: AppSpacing.sm),
              _pill('+6', AppColors.terracottaCoral),
            ],
          ),
        ],
      );

  static Widget cavallo(double cw) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PlayingCard(
            width: cw * 1.15,
            card: const GameCard(CardSuit.spade, CardRank.cavallo),
            elevation: 1.6,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final suit in CardSuit.values)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  child: ActiveSuitBadge(
                      suit: suit, size: 38, showLabel: false),
                ),
            ],
          ),
        ],
      );

  static Widget scoring(double cw) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final card in const [
                GameCard(CardSuit.denari, CardRank.ace),
                GameCard(CardSuit.coppe, CardRank.fante),
                GameCard(CardSuit.bastoni, CardRank.re),
              ])
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    children: [
                      PlayingCard(width: cw * 0.8, card: card),
                      const SizedBox(height: AppSpacing.sm),
                      _pill('${card.value}', AppColors.antiqueGold),
                    ],
                  ),
                ),
            ],
          ),
        ],
      );

  static Widget reset101() => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const FateRing(score: 101, size: 128, showLabel: false),
          const SizedBox(height: AppSpacing.md),
          _pill(Strings.s.savedFrom101, AppColors.goldLight),
        ],
      );

  static Widget eliminated() => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const FateRing(
              score: 104, size: 128, eliminated: true, showLabel: false),
          const SizedBox(height: AppSpacing.md),
          _pill(Strings.s.eliminated, AppColors.danger),
        ],
      );

  static Widget victory(double cw) => Stack(
        alignment: Alignment.center,
        children: [
          for (var i = -1; i <= 1; i++)
            Transform.translate(
              offset: Offset(i * cw * 0.62, i.abs() * 10),
              child: Transform.rotate(
                angle: i * 0.20,
                child: PlayingCard(
                  width: cw,
                  card: [
                    const GameCard(CardSuit.denari, CardRank.re),
                    const GameCard(CardSuit.coppe, CardRank.re),
                    const GameCard(CardSuit.spade, CardRank.re),
                  ][i + 1],
                  elevation: 1.0,
                ),
              ),
            ),
          Positioned(
            bottom: -6,
            child: _pill('101', AppColors.goldLight),
          ),
        ],
      );

  // ------------------------------------------------------------- fragments

  static Widget _fan(double cw, List<GameCard> cards) => SizedBox(
        width: cw + (cards.length - 1) * cw * 0.42,
        height: cw * 1.55 + 12,
        child: Stack(
          children: [
            for (var i = 0; i < cards.length; i++)
              Positioned(
                left: i * cw * 0.42,
                top: (i - (cards.length - 1) / 2).abs() * 4,
                child: Transform.rotate(
                  angle: (i - (cards.length - 1) / 2) * 0.10,
                  child: PlayingCard(width: cw, card: cards[i], elevation: 0.6),
                ),
              ),
          ],
        ),
      );

  static Widget _emptySlot(double cw) => Container(
        width: cw,
        height: cw * 1.55,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(cw * 0.075),
          border: Border.all(
              color: AppColors.mediterraneanTeal.withValues(alpha: 0.55),
              width: 1.4),
        ),
        alignment: Alignment.center,
        child: const AppIconView(AppIcon.check,
            size: 22, color: AppColors.mediterraneanTeal),
      );

  static Widget _valid(double cw, GameCard card, String label) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PlayingCard(width: cw, card: card, elevation: 0.9, glow: 0.7),
          const SizedBox(height: AppSpacing.sm),
          _pill(label, AppColors.mediterraneanTeal),
        ],
      );

  static Widget _pill(String text, Color colour) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          color: colour.withValues(alpha: 0.14),
          border: Border.all(color: colour.withValues(alpha: 0.55)),
        ),
        child: Text(text,
            style: AppText.label.copyWith(color: colour, fontSize: 11.5)),
      );

  static Widget _caption(String text) =>
      Text(text.toUpperCase(), style: AppText.caption);
}
