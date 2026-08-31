import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gioco_del_101/app/theme/app_theme.dart';
import 'package:gioco_del_101/core/utils/motion.dart';
import 'package:gioco_del_101/core/widgets/cards/playing_card.dart';
import 'package:gioco_del_101/features/game/domain/game_card.dart';
import 'package:gioco_del_101/features/game/presentation/widgets/hand_fan.dart';

/// §18–§24 — the client reported that a hand of about ten cards stopped
/// being fully usable. These cases hold the fan to the standard the client
/// asked for at 5, 10, 15, 20 and 25 cards, on a small phone and on a
/// tablet: nothing overflows, every card can be reached, the first and the
/// last are both usable, and a selected card is readable and on top.

/// A hand of [n] distinct cards taken from the real 40-card deck.
List<GameCard> _hand(int n) => Deck.standard.take(n).toList();

/// Phone sizes the client's players actually hold.
const _smallPhone = Size(320, 568);
const _phone = Size(390, 844);
const _largePhone = Size(430, 932);
const _tablet = Size(834, 1112);

class _Harness extends StatefulWidget {
  const _Harness({
    required this.cards,
    required this.cardWidth,
    this.startSelected,
  });

  final List<GameCard> cards;
  final double cardWidth;
  final GameCard? startSelected;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  GameCard? selected;
  final taps = <GameCard>[];
  final played = <GameCard>[];
  final rejected = <GameCard>[];

  @override
  void initState() {
    super.initState();
    selected = widget.startSelected;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF10202A),
      body: Column(
        children: [
          const Expanded(child: SizedBox.expand()),
          HandFan(
            cards: widget.cards,
            cardWidth: widget.cardWidth,
            playable: widget.cards.toSet(),
            selected: selected,
            enabled: true,
            onSelect: (card) => setState(() {
              taps.add(card);
              selected = card;
            }),
            onPlay: played.add,
            onReject: rejected.add,
          ),
        ],
      ),
    );
  }
}

Future<_HarnessState> _pump(
  WidgetTester tester,
  int count, {
  Size size = _phone,
  GameCard? selected,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final cards = _hand(count);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.build(),
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: _Harness(
          cards: cards,
          // What GameScreen hands the fan on a device this wide.
          cardWidth: (size.width * 0.20).clamp(52.0, 104.0),
          startSelected: selected,
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 400));
  return tester.state<_HarnessState>(find.byType(_Harness));
}

Finder _cardAt(GameCard card) => find.byKey(ValueKey('hand_${card.id}'));

/// A point on the part of [card] no other card covers — where a player
/// aiming at that card would actually put their thumb.
Offset _exposedPoint(WidgetTester tester, GameCard card) {
  final r = tester.getRect(_cardAt(card));
  return Offset(r.left + HandFan.minStepPixels / 2, r.center.dy);
}

void main() {
  setUp(() => Motion.reduceMotion = true);
  tearDown(() => Motion.reduceMotion = false);

  group('Large hands stay usable (§18–§24)', () {
    for (final n in [5, 10, 15, 20, 25]) {
      testWidgets('$n cards: no overflow and every card is laid out', (
        tester,
      ) async {
        await _pump(tester, n);
        expect(tester.takeException(), isNull);
        // Every card is in the tree, whether or not it is on screen now.
        for (final card in _hand(n)) {
          expect(
            _cardAt(card),
            findsOneWidget,
            reason: '$card must exist in a $n-card hand',
          );
        }
      });

      testWidgets('$n cards: the first and last can both be brought into '
          'view and selected', (tester) async {
        final state = await _pump(tester, n);
        final cards = _hand(n);

        final scrollable = find.byType(Scrollable);
        for (final card in [cards.first, cards.last, cards[n ~/ 2]]) {
          if (scrollable.evaluate().isNotEmpty) {
            await tester.scrollUntilVisible(
              _cardAt(card),
              120,
              scrollable: scrollable.first,
            );
            await tester.pump(const Duration(milliseconds: 200));
          }
          // Tap the part of the card the player can actually see: the strip
          // its right-hand neighbour does not cover.
          await tester.tapAt(_exposedPoint(tester, card));
          await tester.pump(const Duration(milliseconds: 200));
          expect(
            state.selected,
            card,
            reason: 'card $card must be tappable in a $n-card hand',
          );
        }
      });

      testWidgets('$n cards: no card is drawn narrower than a readable '
          'minimum', (tester) async {
        await _pump(tester, n);
        for (final card in _hand(n)) {
          final box = tester.getSize(_cardAt(card));
          expect(
            box.width,
            greaterThanOrEqualTo(HandFan.minReadableCardWidth),
            reason: 'cards must stay readable in a $n-card hand',
          );
        }
      });

      testWidgets('$n cards: every card keeps a strip wide enough to tap', (
        tester,
      ) async {
        await _pump(tester, n);
        final cards = _hand(n);
        for (var i = 0; i < n - 1; i++) {
          final here = tester.getRect(_cardAt(cards[i]));
          final next = tester.getRect(_cardAt(cards[i + 1]));
          expect(
            next.left - here.left,
            greaterThanOrEqualTo(HandFan.minStepPixels - 0.5),
            reason: 'card $i is covered too far in a $n-card hand',
          );
        }
      });
    }

    testWidgets('a selected card is raised clear of its neighbours and '
        'painted on top', (tester) async {
      final cards = _hand(15);
      final middle = cards[7];
      await _pump(tester, 15, selected: middle);

      final selectedRect = tester.getRect(_cardAt(middle));
      final neighbour = tester.getRect(_cardAt(cards[8]));
      // Raised: its top edge is above the neighbour that overlaps it.
      expect(selectedRect.top, lessThan(neighbour.top));

      // On top: while it is raised, a tap on its own strip still reaches it
      // rather than the neighbour painted over it before — which is what
      // makes "tap again to play" work in the middle of a long fan.
      final state = tester.state<_HarnessState>(find.byType(_Harness));
      await tester.tapAt(_exposedPoint(tester, middle));
      await tester.pump(const Duration(milliseconds: 200));
      expect(state.taps, [middle]);
    });

    testWidgets('the fan fits without scrolling until it honestly cannot', (
      tester,
    ) async {
      // Five cards on a normal phone must not need a scroll view.
      await _pump(tester, 5);
      expect(find.byType(Scrollable), findsNothing);
    });

    for (final entry in {
      'small phone': _smallPhone,
      'phone': _phone,
      'large phone': _largePhone,
      'tablet': _tablet,
    }.entries) {
      testWidgets('20 cards lay out without overflow on a ${entry.key}', (
        tester,
      ) async {
        await _pump(tester, 20, size: entry.value);
        expect(tester.takeException(), isNull);
        // The strip never forces the page itself sideways.
        final fan = tester.getRect(find.byType(HandFan));
        expect(fan.width, lessThanOrEqualTo(entry.value.width));
      });
    }

    testWidgets('drawing many cards keeps the hand consistent', (tester) async {
      final state = await _pump(tester, 5);
      // 5 -> 25 in one rebuild, the "drew a whole chain" case the client hit.
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.build(),
          home: MediaQuery(
            data: const MediaQueryData(size: _phone),
            child: _Harness(cards: _hand(25), cardWidth: 78),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
      expect(find.byType(PlayingCard), findsNWidgets(25));
      expect(state.mounted, isTrue);
    });
  });
}
