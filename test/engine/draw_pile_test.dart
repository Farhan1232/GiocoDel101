import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:gioco_del_101/features/game/domain/card_rank.dart';
import 'package:gioco_del_101/features/game/domain/card_suit.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_engine.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_failure.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_event.dart';
import 'package:gioco_del_101/features/game/domain/game_action.dart';
import 'package:gioco_del_101/features/game/domain/game_card.dart';
import 'package:gioco_del_101/features/game/domain/game_state.dart';

import '../support/engine_harness.dart';

const engine = GameEngine();

ActionAccepted ok(GameState s, GameAction a, {GameEngine e = engine}) {
  final r = e.applyAction(s, a);
  expect(r, isA<ActionAccepted>(), reason: '$r');
  return r as ActionAccepted;
}

void expectFortyUnique(GameState s) {
  final all = [
    ...s.drawPile,
    ...s.discardPile,
    for (final p in s.players) ...p.hand,
  ];
  expect(all, hasLength(40));
  expect(all.toSet(), hasLength(40), reason: 'duplicate card');
}

void main() {
  final top = c(CardSuit.coppe, CardRank.cinque);

  group('Draw pile (§8, §9)', () {
    test('a normal draw takes the top of the stock', () {
      final s = buildState(
        hands: [
          [c(CardSuit.bastoni, CardRank.sette)],
          [c(CardSuit.denari, CardRank.tre)],
        ],
        top: top,
        drawPile: [
          c(CardSuit.spade, CardRank.re),
          c(CardSuit.spade, CardRank.sei),
        ],
      );
      final r = ok(s, const DrawCardAction(playerId: 'p0'));
      expect(r.state.players.first.hand.last, c(CardSuit.spade, CardRank.sei));
      expect(r.state.drawPile.length, s.drawPile.length - 1);
      expect(r.state.drawsByPlayer['p0'], 1);
      expect(r.events.whereType<CardsDrawnEvent>().single.cards, [
        c(CardSuit.spade, CardRank.sei),
      ]);
    });

    test(
      'a drawn playable card may be played at once; an unplayable one passes',
      () {
        final s = buildState(
          hands: [
            [c(CardSuit.bastoni, CardRank.sette)],
            [c(CardSuit.denari, CardRank.tre)],
          ],
          top: top,
          drawPile: [c(CardSuit.coppe, CardRank.re)],
        );
        final r = ok(s, const DrawCardAction(playerId: 'p0'));
        expect(r.state.currentPlayerId, 'p0');
        expect(r.state.drawnCard, c(CardSuit.coppe, CardRank.re));
        expect(engine.getPlayableCards(r.state, 'p0'), [
          c(CardSuit.coppe, CardRank.re),
        ]);
        final played = ok(
          r.state,
          PlayCardAction(playerId: 'p0', card: c(CardSuit.coppe, CardRank.re)),
        ).state;
        expect(played.currentPlayerId, 'p1');
        expect(played.drawnCard, isNull);
        // Or the player may simply pass.
        expect(
          ok(r.state, const PassAction(playerId: 'p0')).state.currentPlayerId,
          'p1',
        );
      },
    );

    test(
      'drawing with nothing playable records a void suit; playing it clears it',
      () {
        final s = buildState(
          hands: [
            [c(CardSuit.bastoni, CardRank.sette)],
            [c(CardSuit.denari, CardRank.tre)],
          ],
          top: top,
          drawPile: [c(CardSuit.coppe, CardRank.re)],
        );
        final r = ok(s, const DrawCardAction(playerId: 'p0'));
        expect(r.state.voidSuits['p0'], ['coppe']);
        final played = ok(
          r.state,
          PlayCardAction(playerId: 'p0', card: c(CardSuit.coppe, CardRank.re)),
        ).state;
        expect(played.voidSuits['p0'], isEmpty);
      },
    );

    test('pile exhaustion recycles everything beneath the top card', () {
      final buried = [
        c(CardSuit.bastoni, CardRank.tre),
        c(CardSuit.bastoni, CardRank.quattro),
        c(CardSuit.bastoni, CardRank.sei),
      ];
      final s = buildState(
        hands: [
          [c(CardSuit.spade, CardRank.sette)],
          [c(CardSuit.denari, CardRank.tre)],
        ],
        top: top,
        discardBelowTop: buried,
        fillDeck: false,
      );
      expect(s.drawPile, isEmpty);
      final r = ok(s, const DrawCardAction(playerId: 'p0'));
      expect(r.state.discardPile, [top]);
      expect(r.state.drawPile, hasLength(2));
      expect(r.state.players.first.hand, hasLength(2));
      expect(r.events.first, isA<DeckRecycledEvent>());
      final all = [
        ...r.state.drawPile,
        ...r.state.discardPile,
        for (final p in r.state.players) ...p.hand,
      ];
      expect(all.toSet(), hasLength(s.totalCards));
      expect(
        all.where(buried.contains),
        hasLength(3),
        reason: 'no buried card lost',
      );
      expect(r.state.history.any((h) => h.type.name == 'recycle'), isTrue);
    });

    test(
      'the 40-card invariant holds through a full reshuffle in a real game',
      () {
        var s = engine.createGame(
          gameId: 'g',
          players: [
            for (var i = 0; i < 2; i++)
              buildState(hands: const [[], []], top: top).players[i],
          ],
          mode: GameMode.vsComputer,
          seed: 21,
        );
        var recycles = 0;
        var steps = 0;
        final rng = Random(3);
        while (!s.isFinished && steps++ < 20000) {
          expectFortyUnique(s);
          if (s.status == GameStatus.roundOver) {
            s = ok(
              s,
              const StartNextRoundAction(playerId: GameEngine.systemActorId),
            ).state;
            continue;
          }
          if (s.status == GameStatus.awaitingSuitChoice) {
            s = ok(
              s,
              ChooseSuitAction(
                playerId: s.currentPlayerId,
                suit: CardSuit.values[rng.nextInt(4)],
              ),
            ).state;
            continue;
          }
          final me = s.currentPlayerId;
          final playable = engine.getPlayableCards(s, me);
          // Draw voluntarily now and then to force exhaustion.
          if (playable.isNotEmpty && rng.nextInt(3) != 0) {
            s = ok(
              s,
              PlayCardAction(
                playerId: me,
                card: playable[rng.nextInt(playable.length)],
              ),
            ).state;
          } else if (engine.canDraw(s)) {
            final r = ok(s, DrawCardAction(playerId: me));
            recycles += r.events.whereType<DeckRecycledEvent>().length;
            s = r.state;
            if (s.currentPlayerId == me && engine.canPass(s)) {
              s = ok(s, PassAction(playerId: me)).state;
            }
          } else {
            s = ok(s, PassAction(playerId: me)).state;
          }
        }
        expectFortyUnique(s);
        expect(
          recycles,
          greaterThan(0),
          reason: 'the test must actually exercise a reshuffle',
        );
        expect(s.isFinished, isTrue);
      },
    );

    test(
      'when nothing is left to recycle the draw yields nothing and the turn moves on',
      () {
        final s = buildState(
          hands: [
            [c(CardSuit.spade, CardRank.sette)],
            [c(CardSuit.denari, CardRank.tre)],
          ],
          top: top,
          fillDeck: false,
        );
        final r = ok(s, const DrawCardAction(playerId: 'p0'));
        expect(r.state.players.first.hand, hasLength(1));
        expect(r.state.currentPlayerId, 'p1');
        expect(r.events.whereType<CardsDrawnEvent>().single.cards, isEmpty);
        expect(r.state.discardPile, [top]);
      },
    );

    test('a reshuffle is deterministic for the same state', () {
      final s = buildState(
        hands: [
          [c(CardSuit.spade, CardRank.sette)],
          [c(CardSuit.denari, CardRank.tre)],
        ],
        top: top,
        discardBelowTop: [
          for (final r in CardRank.values) c(CardSuit.bastoni, r),
        ],
        fillDeck: false,
        seed: 77,
        version: 5,
      );
      final a = ok(s, const DrawCardAction(playerId: 'p0')).state;
      final b = ok(s, const DrawCardAction(playerId: 'p0')).state;
      expect(a.drawPile, b.drawPile);
      expect(a.toJson(), b.toJson());
      // A different seed shuffles differently.
      final other = ok(
        s.copyWith(),
        const DrawCardAction(playerId: 'p0'),
        e: GameEngine(random: (_) => Random(1)),
      ).state;
      Set<GameCard> inPlay(GameState x) => {
        ...x.drawPile,
        ...x.players.first.hand,
      };
      expect(inPlay(other), inPlay(a));
      expect(other.drawPile, isNot(equals(a.drawPile)));
    });

    test('the injected random source is what shuffles', () {
      final s = buildState(
        hands: [
          [c(CardSuit.spade, CardRank.sette)],
          [c(CardSuit.denari, CardRank.tre)],
        ],
        top: top,
        discardBelowTop: [
          for (final r in CardRank.values) c(CardSuit.bastoni, r),
        ],
        fillDeck: false,
      );
      var calls = 0;
      final e = GameEngine(
        random: (state) {
          calls++;
          return Random(0);
        },
      );
      ok(s, const DrawCardAction(playerId: 'p0'), e: e);
      expect(calls, 1);
      expect(Deck.standard, hasLength(40));
    });
  });
}
