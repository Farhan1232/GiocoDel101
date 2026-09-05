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
/// Cards sit on a shallow arc. The layout is computed from three numbers —
/// the width actually available, the card width and how many cards there
/// are — and it degrades in a fixed order as the hand grows, which is what
/// the client asked for after reporting that a hand of about ten cards
/// stopped being fully usable:
///
///  1. **Comfortable spacing** while the fan fits. Cards keep their full
///     width and a generous gap.
///  2. **Tightening overlap.** The gap closes gradually, never below
///     [minStepRatio] of the card width, so a rank index is always showing
///     and every card keeps a tappable strip.
///  3. **Narrower cards**, down to [minReadableCardWidth] and no further.
///     Past that a card stops being readable, which the client ruled out.
///  4. **Horizontal scrolling**, with the selected card kept in view. A hand
///     of any size stays reachable; nothing is ever laid out off-screen with
///     no way back to it.
///
/// Selection raises a card clear of its neighbours, straightens it, deepens
/// its shadow *and moves it to the front of the paint order*, so an
/// overlapped card in the middle of a long fan is both readable and the
/// thing a tap actually lands on. An illegal card shakes and drops back.
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

  /// The narrowest a card may be drawn. Below this the rank index and the
  /// suit stop being legible, and the client ruled that out explicitly: a
  /// long hand scrolls instead of shrinking further.
  static const double minReadableCardWidth = 46;

  /// The least of a card's width that must stay uncovered by its neighbour.
  /// Enough for the index in the corner and for a thumb to land on.
  static const double minStepRatio = 0.42;

  /// …and the absolute floor for that, in logical pixels. This is also the
  /// width of the strip that belongs to an overlapped card for the purpose
  /// of hit testing, so it is a tap target, not just a sliver of paint.
  static const double minStepPixels = 34;

  /// Headroom above the fan for the selected card to rise into, expressed
  /// as a fraction of the card height.
  static const double selectionLiftRatio = 0.16;

  @override
  State<HandFan> createState() => _HandFanState();
}

class _HandFanState extends State<HandFan> with TickerProviderStateMixin {
  GameCard? _dragging;
  Offset _dragOffset = Offset.zero;

  late final AnimationController _shake;
  GameCard? _shakingCard;

  /// Owned here so a selected card can be scrolled back into view; only
  /// attached when the fan actually scrolls.
  final ScrollController _scroll = ScrollController();

  /// The geometry the last build settled on, so `didUpdateWidget` can put a
  /// newly selected card on screen without recomputing the layout.
  _FanGeometry? _geometry;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );
  }

  @override
  void didUpdateWidget(covariant HandFan old) {
    super.didUpdateWidget(old);
    if (widget.selected != null && widget.selected != old.selected) {
      _revealSelected();
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// §21 — a card the player just picked must be somewhere they can see it,
  /// even if it was off the end of a long fan.
  void _revealSelected() {
    final geometry = _geometry;
    final card = widget.selected;
    if (geometry == null || card == null || !geometry.scrolls) return;
    final index = widget.cards.indexOf(card);
    if (index < 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final left = geometry.leftOf(index);
      final viewport = _scroll.position.viewportDimension;
      final target = (left + geometry.cardWidth / 2 - viewport / 2).clamp(
        _scroll.position.minScrollExtent,
        _scroll.position.maxScrollExtent,
      );
      _scroll.animateTo(
        target,
        duration: Motion.scale(AppDurations.quick),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _reject(GameCard card) {
    setState(() => _shakingCard = card);
    // `whenCompleteOrCancel`: a second rapid tap restarts the controller,
    // which *cancels* the previous TickerFuture — a plain `whenComplete`
    // never fires on that path and left `_shakingCard` pinned.
    _shake.forward(from: 0).whenCompleteOrCancel(() {
      if (mounted && _shakingCard == card) {
        setState(() => _shakingCard = null);
      }
    });
    widget.onReject(card);
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.cards.length;
    if (n == 0) {
      return SizedBox(height: widget.cardWidth * CardMetrics.aspect + 26);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final geometry = _FanGeometry.solve(
          count: n,
          preferredCardWidth: widget.cardWidth,
          // An unbounded width (a Row without Expanded, a test harness) has
          // no "available": fall back to what one screen can show, so the
          // fan is never laid out infinitely wide.
          maxWidth: constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.sizeOf(context).width,
        );
        _geometry = geometry;

        final content = SizedBox(
          width: geometry.contentWidth,
          height: geometry.contentHeight,
          child: Stack(
            // The box already reserves room for the arc and the selection
            // lift; `Clip.none` is for the 1.05 scale and the shadow a
            // selected card grows, which are decoration, not layout.
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              // §21 — paint order is hit-test order in reverse: the selected
              // card goes last so nothing overlaps the card the player is
              // about to play.
              for (final i in _paintOrder(n)) _card(i, n, geometry),
            ],
          ),
        );

        if (!geometry.scrolls) {
          // Centred rather than left-aligned: a short hand should sit under
          // the player's thumb, not against the edge.
          return SizedBox(
            height: geometry.contentHeight,
            child: Center(child: content),
          );
        }
        return SizedBox(
          height: geometry.contentHeight,
          child: Stack(
            children: [
              SingleChildScrollView(
                controller: _scroll,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                // Clip.none so a raised card is not sliced off at the top;
                // the strip is the full height of the row anyway.
                clipBehavior: Clip.none,
                child: content,
              ),
              // §20 — the one hint that there is more hand off the edge.
              const Positioned.fill(child: IgnorePointer(child: _EdgeFade())),
            ],
          ),
        );
      },
    );
  }

  /// Indices in paint order: everything in dealing order, then the card the
  /// player is holding or has selected, on top.
  Iterable<int> _paintOrder(int n) sync* {
    final front = _dragging ?? widget.selected;
    final frontIndex = front == null ? -1 : widget.cards.indexOf(front);
    for (var i = 0; i < n; i++) {
      if (i != frontIndex) yield i;
    }
    if (frontIndex >= 0) yield frontIndex;
  }

  Widget _card(int i, int n, _FanGeometry g) {
    final card = widget.cards[i];
    final cw = g.cardWidth;
    final ch = g.cardHeight;
    final centre = (n - 1) / 2;
    final rel = i - centre;

    // Gentle arc: the further from the middle, the lower and more turned.
    // Both the turn and the drop shrink as the hand grows, so a long fan
    // reads as a straight strip rather than a wheel that hides its ends.
    final spread = math.min(0.075, 0.55 / math.max(1, n));
    final angle = rel * spread;
    final arcDrop =
        -math.pow(rel / math.max(1, centre == 0 ? 1 : centre), 2).toDouble() *
        (n > 2 ? g.arcDepth : 0.0);

    final isSelected = widget.selected == card;
    final isPlayable = widget.playable.contains(card);
    final isDragging = _dragging == card;

    final dx = g.leftOf(i);
    // Measured up from the bottom of the strip: the baseline sits above the
    // arc's deepest point so the outermost cards stay inside the box.
    var dy = g.baseline + arcDrop;

    if (isSelected && !isDragging) {
      // §21 — a real lift, into the headroom the geometry reserved, so an
      // overlapped card becomes readable rather than merely highlighted.
      dy += g.selectionLift;
    } else if (isPlayable && widget.enabled) {
      // §28 — a micro-lift only. No coloured outlines anywhere.
      dy += 5;
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

    // §21 — a card in the middle of a fan is only *visible* along the strip
    // its right-hand neighbour does not cover, so that strip is what a tap
    // must land on. Without this, tapping what looks like the third card
    // selects the fourth, which is the shape of the bug the client hit once
    // hands grew past a handful. The card at the front of the paint order —
    // the last one, the selected one, the one being dragged — is covered by
    // nothing and owns its whole face.
    //
    // A *selected* card deliberately keeps its strip rather than claiming
    // its whole face: it is painted last, so its strip is on top of
    // everything and nothing can block the second tap that plays it, while
    // the card next to it stays reachable. Only a card being dragged, or the
    // last card in the fan, is covered by nothing at all.
    final ownsWholeFace = isDragging || i == n - 1 || g.step >= cw;
    final hitWidth = ownsWholeFace ? cw : g.step;

    final visual = IgnorePointer(child: tilted);

    return Positioned(
      // A stable key per card: it keeps the element attached to the same card
      // as the fan re-sorts, and gives tests something to aim at.
      key: ValueKey('hand_${card.id}'),
      left: dx + (isDragging ? _dragOffset.dx : 0),
      bottom: dy - (isDragging ? _dragOffset.dy : 0),
      width: cw,
      height: ch,
      child: widget.enabled
          ? Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(child: visual),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: hitWidth,
                  child: Semantics(
                    button: true,
                    enabled: isPlayable,
                    selected: isSelected,
                    label: isPlayable
                        ? Strings.s.cardSemanticsPlayable(cardDisplayName(card))
                        : Strings.s.cardSemanticsNotPlayable(
                            cardDisplayName(card),
                          ),
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
                    ),
                  ),
                ),
              ],
            )
          : visual,
    );
  }
}

/// The whole hand layout, solved once per build from the three numbers that
/// determine it, and then read by every card.
///
/// Keeping it in one immutable object is what makes the fan predictable: the
/// spacing, the card width, whether the strip scrolls, how tall the box has
/// to be and where a given card sits are all answers to the same
/// calculation, not decisions taken separately in a dozen places.
class _FanGeometry {
  const _FanGeometry({
    required this.count,
    required this.cardWidth,
    required this.step,
    required this.scrolls,
    required this.leadingPad,
    required this.contentWidth,
  });

  final int count;
  final double cardWidth;

  /// Distance between the left edges of neighbouring cards. Always at least
  /// [HandFan.minStepPixels] and [HandFan.minStepRatio] of [cardWidth].
  final double step;

  /// True when the fan is wider than the space it was given and the strip
  /// has to scroll.
  final bool scrolls;

  /// Padding before the first card, so a card at either end still has a
  /// margin to be grabbed by.
  final double leadingPad;

  final double contentWidth;

  double get cardHeight => cardWidth * CardMetrics.aspect;

  /// How far the outermost cards drop below the middle of the arc. Shallow
  /// by design, and shallower still for a long hand.
  double get arcDepth => math.min(10.0, 120.0 / math.max(1, count));

  /// §21 — how far a selected card rises. Scaled to the card so it is the
  /// same gesture on a phone and on a tablet.
  double get selectionLift => cardHeight * HandFan.selectionLiftRatio;

  /// The bottom offset an un-lifted middle card sits at. High enough that
  /// the arc never pushes a card out of the bottom of the box.
  double get baseline => arcDepth + 6;

  /// Room for the card, the arc, the baseline and the selection lift, so
  /// nothing a card can do takes it outside the strip.
  double get contentHeight => cardHeight + baseline + selectionLift + 8;

  /// Left edge of card [i] inside the content box.
  double leftOf(int i) => leadingPad + step * i;

  /// Works out the widest comfortable layout that fits [maxWidth],
  /// degrading in the order documented on [HandFan]: spacing, then overlap,
  /// then card width, and only then scrolling.
  static _FanGeometry solve({
    required int count,
    required double preferredCardWidth,
    required double maxWidth,
  }) {
    // A margin at each end so the outermost cards are never flush against
    // the screen edge, where a swipe-back gesture would fight the tap.
    const pad = AppSpacing.md;
    final available = math.max(0.0, maxWidth - pad * 2);

    double minStepFor(double cw) =>
        math.max(cw * HandFan.minStepRatio, HandFan.minStepPixels);
    // The room a hand of [count] cards needs at width [cw], packed as
    // tightly as the minimum overlap allows.
    double tightestWidth(double cw) => cw + (count - 1) * minStepFor(cw);

    var cw = preferredCardWidth;
    if (count > 1 && tightestWidth(cw) > available) {
      // Narrow the cards — but only as far as it *earns* something. The two
      // candidates below solve `cw + (n-1)·max(cw·r, p) = available` on
      // either side of the point where the ratio floor overtakes the pixel
      // floor; the larger one that genuinely fits is the answer.
      final byRatio = available / (1 + (count - 1) * HandFan.minStepRatio);
      final byPixels = available - (count - 1) * HandFan.minStepPixels;
      final best = [byRatio, byPixels]
          .where((w) => w >= HandFan.minReadableCardWidth)
          .where((w) => tightestWidth(w) <= available + 0.5)
          .fold<double>(0, math.max);
      // Nothing readable fits: keep the cards readable and scroll instead.
      // Shrinking past this point is the one thing the client ruled out.
      if (best > 0) cw = math.min(best, preferredCardWidth);
    }

    final minStep = minStepFor(cw);
    // Comfortable spacing while there is room for it, tightening towards the
    // floor as the hand grows, and never below it: the floor is what keeps a
    // card both readable and tappable.
    final fit = count > 1 ? (available - cw) / (count - 1) : cw;
    final scrolls = count > 1 && fit < minStep;
    final step = scrolls
        ? minStep
        : math.max(minStep, math.min(cw * 0.66, fit));

    // Exactly the fan plus its margins, so a hand narrower than the screen is
    // centred under the player's thumb instead of hugging the left edge.
    // When the fan does not fit this is the scrollable extent instead.
    final fanWidth = cw + step * (count - 1);
    return _FanGeometry(
      count: count,
      cardWidth: cw,
      step: step,
      scrolls: scrolls,
      leadingPad: pad,
      contentWidth: fanWidth + pad * 2,
    );
  }
}

/// §20 — a soft gradient at each end of a scrolling hand: the only cue the
/// player needs that the fan continues past the edge of the screen.
class _EdgeFade extends StatelessWidget {
  const _EdgeFade();

  @override
  Widget build(BuildContext context) {
    final shade = AppColors.inkDeep.withValues(alpha: 0.55);
    return Row(
      children: [
        _Fade(colors: [shade, shade.withValues(alpha: 0)]),
        const Spacer(),
        _Fade(colors: [shade.withValues(alpha: 0), shade]),
      ],
    );
  }
}

class _Fade extends StatelessWidget {
  const _Fade({required this.colors});

  final List<Color> colors;

  @override
  Widget build(BuildContext context) => Container(
    width: AppSpacing.lg,
    decoration: BoxDecoration(gradient: LinearGradient(colors: colors)),
  );
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

/// §12a — the badge marking the seat that dealt the current round.
///
/// Deliberately quieter than [CardCountChip]: the dealer is a fact about the
/// round, not something the player has to act on. It travels one seat
/// clockwise at every new deal.
class DealerChip extends StatelessWidget {
  const DealerChip({super.key, this.accent = AppColors.antiqueGold});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: Strings.s.dealerBadge,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: AppColors.surfaceSunken.withValues(alpha: 0.9),
          border: Border.all(color: accent.withValues(alpha: 0.45)),
        ),
        child: Text(
          // The initial alone: a seat medallion has no room for "MAZZIERE",
          // and the full word is on the badge's semantics label.
          Strings.s.dealerBadge.characters.first,
          style: TextStyle(
            fontFamily: AppText.ui,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
            color: accent.withValues(alpha: 0.95),
          ),
        ),
      ),
    );
  }
}
