import 'package:flutter_test/flutter_test.dart';
import 'package:gioco_del_101/features/game/domain/card_rank.dart';
import 'package:gioco_del_101/features/game/domain/card_suit.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_engine.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_event.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_failure.dart';
import 'package:gioco_del_101/features/game/domain/game_action.dart';
import 'package:gioco_del_101/features/game/domain/game_card.dart';
import 'package:gioco_del_101/features/game/domain/game_rules.dart';
import 'package:gioco_del_101/features/game/domain/game_state.dart';

import '../support/engine_harness.dart';

const engine = GameEngine();

ActionAccepted ok(GameState s, GameAction a) {
  final r = engine.applyAction(s, a);
  expect(r, isA<ActionAccepted>(), reason: '$r');
  return r as ActionAccepted;
}

void main() {
  final co2 = c(CardSuit.coppe, CardRank.due);
  final sp2 = c(CardSuit.spade, CardRank.due);
  final de2 = c(CardSuit.denari, CardRank.due);
  final ba2 = c(CardSuit.bastoni, CardRank.due);

  group('Due = +2 chain (§6)', () {
    test('+2: a 2 starts the chain and passes the turn', () {
      final s = buildState(
        hands: [
          [co2, c(CardSuit.coppe, CardRank.re)],
          [c(CardSuit.spade, CardRank.tre)],
        ],
        top: c(CardSuit.coppe, CardRank.cinque),
      );
      final r = ok(s, PlayCardAction(playerId: 'p0', card: co2));
      expect(r.state.pendingDrawCount, 2);
      expect(r.state.chainLength, 1);
      expect(r.state.currentPlayerId, 'p1');
      expect(r.events.whereType<ChainGrewEvent>().single.total, 2);
      expect(r.state.stats.twosPlayed, 1);
      expect(r.state.stats.longestChain, 1);
    });

    test('+4, +6, +8: every 2 in the deck stacks', () {
      var s = buildState(
        hands: [
          [co2, c(CardSuit.coppe, CardRank.re)],
          [sp2, c(CardSuit.spade, CardRank.tre)],
          [de2, c(CardSuit.denari, CardRank.tre)],
          [ba2, c(CardSuit.bastoni, CardRank.tre)],
        ],
        top: c(CardSuit.coppe, CardRank.cinque),
      );
      final twos = [co2, sp2, de2, ba2];
      for (var i = 0; i < 4; i++) {
        final actor = 'p$i';
        expect(s.currentPlayerId, actor);
        // Under a chain the only legal card is the 2.
        if (i > 0) {
          expect(engine.getPlayableCards(s, actor), [twos[i]]);
        }
        s = ok(s, PlayCardAction(playerId: actor, card: twos[i])).state;
        expect(s.pendingDrawCount, 2 * (i + 1));
        expect(s.chainLength, i + 1);
      }
      expect(s.pendingDrawCount, 8);
      expect(s.stats.longestChain, 4);
      // Back to p0 with nothing to answer: must draw all eight.
      expect(s.currentPlayerId, 'p0');
      expect(engine.mustTakePenalty(s), isTrue);
      expect(engine.canPass(s), isFalse);
      final drawn = ok(s, const DrawCardAction(playerId: 'p0'));
      expect(drawn.state.players.first.hand, hasLength(1 + 8));
      expect(drawn.state.pendingDrawCount, 0);
      expect(drawn.state.chainLength, 0);
      // §6b — +8 is paid and p0 keeps the turn, exactly as it would for +2.
      expect(drawn.state.currentPlayerId, 'p0');
      expect(drawn.state.penaltyResolvedThisTurn, isTrue);
      final resolved = drawn.events.whereType<ChainResolvedEvent>().single;
      expect(resolved.total, 8);
      expect(resolved.chainLength, 4);
      expect(drawn.state.totalCards, 40);
      // …and only after p0's continuation does the turn move on.
      final after = ok(drawn.state, const PassAction(playerId: 'p0'));
      expect(after.state.currentPlayerId, 'p1');
      expect(after.state.penaltyResolvedThisTurn, isFalse);
    });

    test('drawing resolves +2 and +6 exactly', () {
      for (final (pending, chain) in [(2, 1), (6, 3)]) {
        final s = buildState(
          hands: [
            [c(CardSuit.coppe, CardRank.re)],
            [c(CardSuit.spade, CardRank.tre)],
          ],
          top: co2,
          currentIndex: 1,
          pendingPenalty: pending,
          chainLength: chain,
        );
        final r = ok(s, const DrawCardAction(playerId: 'p1'));
        expect(r.state.players[1].hand, hasLength(1 + pending));
        expect(r.state.pendingDrawCount, 0);
        // §6b — paying the chain settles the penalty, not the turn: p1 is
        // still to act and may make one ordinary legal play.
        expect(r.state.currentPlayerId, 'p1');
        expect(r.state.penaltyResolvedThisTurn, isTrue);
        expect(r.state.hasDrawnThisTurn, isTrue);
        expect(r.events.whereType<TurnChangedEvent>(), isEmpty);
        expect(r.state.drawsByPlayer['p1'], pending);
        final e = r.events.whereType<CardsDrawnEvent>().single;
        expect(e.isPenalty, isTrue);
        expect(e.cards, hasLength(pending));
      }
    });

    test('under a chain nothing but a 2 (or a blocking 9) is legal', () {
      final s = buildState(
        hands: [
          [c(CardSuit.coppe, CardRank.re)],
          [
            c(CardSuit.coppe, CardRank.sette),
            c(CardSuit.spade, CardRank.due),
            c(CardSuit.bastoni, CardRank.asso),
          ],
        ],
        top: co2,
        currentIndex: 1,
        pendingPenalty: 2,
        chainLength: 1,
      );
      expect(engine.getPlayableCards(s, 'p1'), [sp2]);
      expect(
        engine
            .applyAction(
              s,
              PlayCardAction(
                playerId: 'p1',
                card: c(CardSuit.coppe, CardRank.sette),
              ),
            )
            .failure,
        GameFailure.illegalCard,
      );
      expect(
        engine.applyAction(s, const PassAction(playerId: 'p1')).failure,
        GameFailure.drawRequired,
      );
    });

    test('stackDrawTwos=false: a 2 cannot answer a 2', () {
      final s = buildState(
        hands: [
          [c(CardSuit.coppe, CardRank.re)],
          [sp2],
        ],
        top: co2,
        currentIndex: 1,
        pendingPenalty: 2,
        chainLength: 1,
        rules: const GameRules(
          stackDrawTwos: true,
        ).copyWith(stackDrawTwos: false),
      );
      expect(engine.getPlayableCards(s, 'p1'), isEmpty);
      expect(
        engine
            .applyAction(s, PlayCardAction(playerId: 'p1', card: sp2))
            .failure,
        GameFailure.illegalCard,
      );
      expect(
        ok(s, const DrawCardAction(playerId: 'p1')).state.players[1].hand,
        hasLength(3),
      );
    });

    test('drawTwoPenalty is configurable', () {
      final s = buildState(
        hands: [
          [co2, c(CardSuit.coppe, CardRank.re)],
          [c(CardSuit.spade, CardRank.tre)],
        ],
        top: c(CardSuit.coppe, CardRank.cinque),
        rules: const GameRules(drawTwoPenalty: 3),
      );
      expect(
        ok(s, PlayCardAction(playerId: 'p0', card: co2)).state.pendingDrawCount,
        3,
      );
    });

    test(
      'a penalty draw recycles the discard pile when the stock runs out',
      () {
        final s = buildState(
          hands: [
            [c(CardSuit.coppe, CardRank.re)],
            [c(CardSuit.spade, CardRank.tre)],
          ],
          top: sp2,
          discardBelowTop: [
            co2,
            c(CardSuit.bastoni, CardRank.tre),
            c(CardSuit.bastoni, CardRank.quattro),
            c(CardSuit.bastoni, CardRank.sei),
          ],
          drawPile: [c(CardSuit.denari, CardRank.sette)],
          currentIndex: 1,
          pendingPenalty: 4,
          chainLength: 2,
          fillDeck: false,
        );
        final r = ok(s, const DrawCardAction(playerId: 'p1'));
        expect(r.state.players[1].hand, hasLength(5));
        expect(r.state.discardPile, [sp2], reason: 'top stays');
        expect(r.state.drawPile, hasLength(1));
        expect(r.events.whereType<DeckRecycledEvent>().single.count, 4);
        final all = [
          ...r.state.drawPile,
          ...r.state.discardPile,
          for (final p in r.state.players) ...p.hand,
        ];
        expect(all, hasLength(s.totalCards));
        expect(all.toSet(), hasLength(s.totalCards));
      },
    );

    test(
      'a 2 as the winning card: the chain dies with the round by default',
      () {
        final s = buildState(
          hands: [
            [co2],
            [c(CardSuit.spade, CardRank.tre)],
          ],
          top: c(CardSuit.coppe, CardRank.cinque),
        );
        final r = ok(s, PlayCardAction(playerId: 'p0', card: co2));
        expect(r.state.status, GameStatus.roundOver);
        expect(r.state.pendingDrawCount, 0);
        expect(r.state.players[1].hand, hasLength(1));
        expect(r.state.lastRoundResult!.rows[1].penalty, 3);
      },
    );

    test('pendingPenaltyAppliesAfterWin=true: the next player draws first', () {
      final s = buildState(
        hands: [
          [co2],
          [c(CardSuit.spade, CardRank.tre)],
        ],
        top: c(CardSuit.coppe, CardRank.cinque),
        rules: const GameRules(pendingPenaltyAppliesAfterWin: true),
      );
      final r = ok(s, PlayCardAction(playerId: 'p0', card: co2));
      expect(r.state.status, GameStatus.roundOver);
      expect(r.state.players[1].hand, hasLength(3));
      expect(r.state.lastRoundResult!.rows[1].cardsLeft, 3);
      expect(r.state.totalCards, 40);
    });

    test('a 2 played onto another 2 (same rank) also stacks', () {
      // Cross-suit 2 on a 2 is legal by rank even with no chain pending —
      // e.g. after a recycle left a 2 on top.
      final s = buildState(
        hands: [
          [sp2, c(CardSuit.spade, CardRank.re)],
          [c(CardSuit.denari, CardRank.tre)],
        ],
        top: co2,
      );
      final r = ok(s, PlayCardAction(playerId: 'p0', card: sp2));
      expect(r.state.pendingDrawCount, 2);
      expect(r.state.activeSuit, CardSuit.spade);
    });

    test('list of cards drawn matches what left the stock, in order', () {
      final stock = [
        c(CardSuit.bastoni, CardRank.quattro),
        c(CardSuit.bastoni, CardRank.sei),
        c(CardSuit.denari, CardRank.quattro),
        c(CardSuit.denari, CardRank.sei),
      ];
      final s = buildState(
        hands: [
          [c(CardSuit.coppe, CardRank.re)],
          [c(CardSuit.spade, CardRank.tre)],
        ],
        top: co2,
        drawPile: stock,
        currentIndex: 1,
        pendingPenalty: 4,
        chainLength: 2,
      );
      final r = ok(s, const DrawCardAction(playerId: 'p1'));
      final drawn = r.events.whereType<CardsDrawnEvent>().single.cards;
      expect(
        drawn,
        stock.reversed.toList(),
        reason: 'the stock deals from its end',
      );
      expect(r.state.players[1].hand.sublist(1), drawn);
      expect(r.state.drawPile.length, s.drawPile.length - 4);
      expect(r.state.drawPile.any((GameCard x) => stock.contains(x)), isFalse);
    });
  });
}
