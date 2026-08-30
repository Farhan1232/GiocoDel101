import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/motion.dart';
import '../../domain/game_card.dart';
import '../../../../app/localization/app_strings.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/cards/card_names.dart';
import '../../../../core/widgets/cards/playing_card.dart';

/// §27/§28 — the player's hand.
///
/// Cards sit on a shallow arc. Overlap tightens as the hand grows and, once
/// the fan can no longer fit without hiding the rank indices, the strip
/// becomes horizontally scrollable rather than illegible. Selection lifts a
/// card, straightens it and deepens its shadow; an illegal card shakes and
/// drops back.
class HandFan extends StatefulWidget {
  const HandFan({
    super.key,
    required this.cards,
    required this.cardWidth,
    required this.playable,
    required this.selected,
    required this.enabled,
    required this.onSelect,
    required this.onPlay,
    required this.onReject,
    this.faceUp = true,
    this.backId = 'oro',
    this.highContrast = false,
    this.dropTarget,
  });

  final List<GameCard> cards;
  final double cardWidth;
  final Set<GameCard> playable;
  final GameCard? selected;
  final bool enabled;
  final ValueChanged<GameCard> onSelect;
  final ValueChanged<GameCard> onPlay;
  final ValueChanged<GameCard> onReject;
  final bool faceUp;
  final String backId;
  final bool highContrast;

  /// Where the discard pile is, in this widget's coordinate space. Dragging a
  /// card near it plays the card.
  final Offset? dropTarget;

  @override
  State<HandFan> createState() => _HandFanState();
}

class _HandFanState extends State<HandFan> with TickerProviderStateMixin {
  GameCard? _dragging;
  Offset _dragOffset = Offset.zero;

  late final AnimationController _shake;
  GameCard? _shakingCard;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  void _reject(GameCard card) {
    setState(() => _shakingCard = card);
    _shake.forward(from: 0).whenComplete(() {
      if (mounted) setState(() => _shakingCard = null);
    });
    widget.onReject(card);
  }

  @override
  Widget build(BuildContext context) {
    final cw = widget.cardWidth;
    final ch = cw * CardMetrics.aspect;
    final n = widget.cards.length;
    if (n == 0) {
      return SizedBox(height: ch + 26);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth - AppSpacing.lg * 2;
        // Comfortable overlap first; tighten only as far as the indices allow.
        var step = cw * 0.66;
        if (n > 1) {
          final fit = (available - cw) / (n - 1);
          step = math.min(step, fit);
        }
        // Never let neighbouring cards share less than a thumb's width.
        final minStep = math.max(cw * 0.30, 48.0);
        final scrolls = step < minStep;
        if (scrolls) step = minStep;

        final fanWidth = cw + step * (n - 1);
        final content = SizedBox(
          width: math.max(fanWidth + AppSpacing.lg * 2, available),
          height: ch + 30,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              for (var i = 0; i < n; i++) _card(i, n, cw, ch, step, fanWidth),
            ],
          ),
        );

        if (!scrolls) return content;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: content,
        );
      },
    );
  }

  Widget _card(
    int i,
    int n,
    double cw,
    double ch,
    double step,
    double fanWidth,
  ) {
    final card = widget.cards[i];
    final centre = (n - 1) / 2;
    final rel = i - centre;

    // Gentle arc: the further from the middle, the lower and more turned.
    final spread = math.min(0.075, 0.55 / math.max(1, n));
    final angle = rel * spread;
    final lift =
        -math.pow(rel / math.max(1, centre == 0 ? 1 : centre), 2).toDouble() *
        (n > 2 ? 10.0 : 0.0);

    final isSelected = widget.selected == card;
    final isPlayable = widget.playable.contains(card);
    final isDragging = _dragging == card;

    var dx = (i * step) + AppSpacing.lg;
    var dy = 22.0 + lift;

    if (isSelected && !isDragging) {
      dy -= 26;
    } else if (isPlayable && widget.enabled) {
      // §28 — a micro-lift only. No coloured outlines anywhere.
      dy -= 5;
    }

    Widget child = PlayingCard(
      width: cw,
      card: card,
      faceUp: widget.faceUp,
      backId: widget.backId,
      highContrast: widget.highContrast,
      elevation: isDragging ? 2.2 : (isSelected ? 1.6 : 0.55),
      dimmed: widget.enabled && widget.faceUp && !isPlayable,
      glow: widget.enabled && isPlayable && widget.faceUp
          ? (isSelected ? 0.9 : 0.34)
          : 0.0,
    );

    if (_shakingCard == card) {
      child = AnimatedBuilder(
        animation: _shake,
        builder: (context, inner) {
          final t = _shake.value;
          final dx =
              math.sin(t * math.pi * 6) * 9 * (1 - t) * Motion.shakeScale;
          return Transform.translate(offset: Offset(dx, 0), child: inner);
        },
        child: child,
      );
    }

    final tilted = AnimatedScale(
      duration: Motion.scale(AppDurations.micro),
      scale: isSelected || isDragging ? 1.05 : 1.0,
      child: Transform.rotate(
        angle: isSelected || isDragging ? angle * 0.25 : angle,
        alignment: Alignment.bottomCenter,
        child: child,
      ),
    );

    return Positioned(
      // A stable key per card: it keeps the element attached to the same card
      // as the fan re-sorts, and gives tests something to aim at.
      key: ValueKey('hand_${card.id}'),
      left: dx + (isDragging ? _dragOffset.dx : 0),
      bottom: dy - (isDragging ? _dragOffset.dy : 0),
      width: cw,
      height: ch,
      child: widget.enabled
          ? Semantics(
              button: true,
              enabled: isPlayable,
              selected: isSelected,
              label: isPlayable
                  ? Strings.s.cardSemanticsPlayable(cardDisplayName(card))
                  : Strings.s.cardSemanticsNotPlayable(cardDisplayName(card)),
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (!isPlayable) {
                    _reject(card);
                    return;
                  }
                  widget.onSelect(card);
                },
                onPanStart: (_) {
                  if (!isPlayable) return;
                  setState(() {
                    _dragging = card;
                    _dragOffset = Offset.zero;
                  });
                  widget.onSelect(card);
                },
                onPanUpdate: (details) {
                  if (_dragging != card) return;
                  setState(() => _dragOffset += details.delta);
                },
                onPanEnd: (_) {
                  if (_dragging != card) return;
                  final travelled = -_dragOffset.dy;
                  setState(() {
                    _dragging = null;
                    _dragOffset = Offset.zero;
                  });
                  // A decisive push toward the table plays the card.
                  if (travelled > ch * 0.42) widget.onPlay(card);
                },
                child: tilted,
              ),
            )
          : IgnorePointer(child: tilted),
    );
  }
}

/// A face-down fan used for opponents' hands.
class OpponentHand extends StatelessWidget {
  const OpponentHand({
    super.key,
    required this.count,
    required this.cardWidth,
    required this.backId,
    this.maxShown = 7,
    this.horizontal = true,
  });

  final int count;
  final double cardWidth;
  final String backId;
  final int maxShown;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final shown = math.min(count, maxShown);
    if (shown == 0) return SizedBox(width: cardWidth, height: cardWidth * 0.7);
    final step = cardWidth * 0.30;
    final centre = (shown - 1) / 2;

    return SizedBox(
      width: cardWidth + step * (shown - 1),
      // Tall enough to contain the fan's own arc, so the cards below it are
      // never overlapped.
      height: cardWidth * CardMetrics.aspect * 0.74,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < shown; i++)
            Positioned(
              left: i * step,
              top: math.pow((i - centre).abs(), 1.4).toDouble() * 1.1,
              child: Transform.rotate(
                angle: (i - centre) * 0.10,
                alignment: Alignment.bottomCenter,
                child: PlayingCard(
                  width: cardWidth,
                  faceUp: false,
                  backId: backId,
                  elevation: 0.35,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The small badge showing how many cards a seat is holding.
class CardCountChip extends StatelessWidget {
  const CardCountChip({
    super.key,
    required this.count,
    this.accent = AppColors.antiqueGold,
    this.warn = false,
  });

  final int count;
  final Color accent;

  /// §27 — a seat down to its last card is called out.
  final bool warn;

  @override
  Widget build(BuildContext context) {
    final colour = warn ? AppColors.terracottaCoral : accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: AppColors.surfaceSunken.withValues(alpha: 0.9),
        border: Border.all(color: colour.withValues(alpha: 0.6)),
        boxShadow: warn
            ? [BoxShadow(color: colour.withValues(alpha: 0.35), blurRadius: 10)]
            : null,
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontFamily: AppText.ui,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: colour,
        ),
      ),
    );
  }
}
