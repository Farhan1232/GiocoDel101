import 'package:flutter_test/flutter_test.dart';
import 'package:gioco_del_101/features/game/domain/card_rank.dart';
import 'package:gioco_del_101/features/game/domain/card_suit.dart';
import 'package:gioco_del_101/features/game/domain/game_rules.dart';

import 'support/engine_harness.dart';
import 'package:gioco_del_101/features/game/domain/game_state.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_failure.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_session.dart';

void main() {
  group('Normal play rule (§7)', () {
    test('accepts a card of the active suit', () {
      final e = buildEngine(
        hands: [
          [c(CardSuit.coppe, CardRank.re)],
          [c(CardSuit.spade, CardRank.tre)],
        ],
        top: c(CardSuit.coppe, CardRank.cinque),
      );
      expect(e.canPlay(c(CardSuit.coppe, CardRank.re)), isTrue);
    });

    test('accepts a card of the same rank in another suit', () {
      final e = buildEngine(
        hands: [
          [c(CardSuit.bastoni, CardRank.cinque)],
          [c(CardSuit.spade, CardRank.tre)],
        ],
        top: c(CardSuit.coppe, CardRank.cinque),
      );
      expect(e.canPlay(c(CardSuit.bastoni, CardRank.cinque)), isTrue);
    });

    test('rejects a mismatch in both suit and rank', () {
      final e = buildEngine(
        hands: [
          [c(CardSuit.bastoni, CardRank.sette)],
          [c(CardSuit.spade, CardRank.tre)],
        ],
        top: c(CardSuit.coppe, CardRank.cinque),
      );
      expect(e.canPlay(c(CardSuit.bastoni, CardRank.sette)), isFalse);
      final result = e.autoPlayCard(c(CardSuit.bastoni, CardRank.sette));
      expect(result.accepted, isFalse);
      expect(result.failure, GameFailure.illegalCard);
    });

    test('matches the suit named by a Cavallo, not the top card suit', () {
      final e = buildEngine(
        hands: [
          [
            c(CardSuit.spade, CardRank.quattro),
            c(CardSuit.coppe, CardRank.quattro),
          ],
          [c(CardSuit.denari, CardRank.tre)],
        ],
        top: c(CardSuit.coppe, CardRank.cavallo),
        activeSuit: CardSuit.spade,
      );
      expect(e.canPlay(c(CardSuit.spade, CardRank.quattro)), isTrue);
      // Same rank as the top card is still a legal answer.
      expect(e.canPlay(c(CardSuit.coppe, CardRank.quattro)), isFalse);
    });
  });

  group('Ace = skip (§9)', () {
    test('skips the next player in a three-handed game', () {
      final e = buildEngine(
        hands: [
          [c(CardSuit.coppe, CardRank.asso), c(CardSuit.coppe, CardRank.re)],
          [c(CardSuit.spade, CardRank.tre)],
          [c(CardSuit.denari, CardRank.tre)],
        ],
        top: c(CardSuit.coppe, CardRank.cinque),
      );
      expect(e.autoPlayCard(c(CardSuit.coppe, CardRank.asso)).accepted, isTrue);
      expect(e.currentPlayer.id, 'p2', reason: 'p1 loses the turn');
    });

    test('returns the turn to the player in a two-handed game', () {
      final e = buildEngine(
        hands: [
          [c(CardSuit.coppe, CardRank.asso), c(CardSuit.coppe, CardRank.re)],
          [c(CardSuit.spade, CardRank.tre)],
        ],
        top: c(CardSuit.coppe, CardRank.cinque),
      );
      e.autoPlayCard(c(CardSuit.coppe, CardRank.asso));
      expect(e.currentPlayer.id, 'p0');
    });
  });

  group('Two = draw two, with stacking (§10)', () {
    test('a single 2 leaves the next player owing two cards', () {
      final e = buildEngine(
        hands: [
          [c(CardSuit.coppe, CardRank.due), c(CardSuit.coppe, CardRank.re)],
          [c(CardSuit.spade, CardRank.tre)],
        ],
        top: c(CardSuit.coppe, CardRank.cinque),
        drawPile: List.generate(10, (i) => null)
            .asMap()
            .keys
            .map((i) => c(CardSuit.bastoni, CardRank.values[i]))
            .toList(),
      );
      e.autoPlayCard(c(CardSuit.coppe, CardRank.due));
      expect(e.state.pendingDrawCount, 2);
      expect(e.state.chainLength, 1);
      expect(e.currentPlayer.id, 'p1');
    });

    test('only another 2 answers a live chain', () {
      final e = buildEngine(
        hands: [
          [c(CardSuit.coppe, CardRank.re)],
          [c(CardSuit.spade, CardRank.due), c(CardSuit.coppe, CardRank.sette)],
        ],
        top: c(CardSuit.coppe, CardRank.due),
        currentIndex: 1,
        pendingPenalty: 2,
        chainLength: 1,
      );
      expect(e.canPlay(c(CardSuit.coppe, CardRank.sette)), isFalse);
      expect(e.canPlay(c(CardSuit.spade, CardRank.due)), isTrue);
    });

    test('stacks to +4 then +6 and hits the player who cannot answer', () {
      final deck = [for (final r in CardRank.values) c(CardSuit.bastoni, r)];
      final e = buildEngine(
        hands: [
          [c(CardSuit.coppe, CardRank.due), c(CardSuit.coppe, CardRank.re)],
          [c(CardSuit.spade, CardRank.due), c(CardSuit.spade, CardRank.re)],
          [c(CardSuit.denari, CardRank.due), c(CardSuit.denari, CardRank.re)],
          [c(CardSuit.coppe, CardRank.sette)],
        ],
        top: c(CardSuit.coppe, CardRank.cinque),
        drawPile: deck,
      );

      e.autoPlayCard(c(CardSuit.coppe, CardRank.due));
      expect(e.state.pendingDrawCount, 2);
      e.autoPlayCard(c(CardSuit.spade, CardRank.due));
      expect(e.state.pendingDrawCount, 4);
      e.autoPlayCard(c(CardSuit.denari, CardRank.due));
      expect(e.state.pendingDrawCount, 6);
      expect(e.state.chainLength, 3);

      expect(e.currentPlayer.id, 'p3');
      expect(e.mustTakePenalty, isTrue);
      e.drawCard();

      expect(e.state.playerById('p3')!.hand, hasLength(1 + 6));
      expect(e.state.pendingDrawCount, 0);
      expect(e.state.chainLength, 0);
      expect(
        e.currentPlayer.id,
        'p3',
        reason: '§6b — p3 pays the +6 but keeps the turn',
      );
      // p3 drew six cards from a Bastoni deck onto a Coppe 5, so it now has
      // a legal continuation and the engine offers it.
      expect(e.playableCardsFor(e.currentPlayer), isNotEmpty);
    });

    test('a player may decline to stack and take the cards instead', () {
      final e = buildEngine(
        hands: [
          [c(CardSuit.coppe, CardRank.re)],
          [c(CardSuit.spade, CardRank.due), c(CardSuit.coppe, CardRank.sette)],
        ],
        top: c(CardSuit.coppe, CardRank.due),
        currentIndex: 1,
        pendingPenalty: 2,
        chainLength: 1,
        drawPile: [
          c(CardSuit.bastoni, CardRank.quattro),
          c(CardSuit.bastoni, CardRank.sei),
        ],
      );
      e.drawCard();
      expect(e.state.playerById('p1')!.hand, hasLength(4));
      expect(e.state.pendingDrawCount, 0);
      // §6b — declining to stack costs the cards, not the turn.
      expect(e.currentPlayer.id, 'p1');
      expect(e.state.penaltyResolvedThisTurn, isTrue);
    });

    test('stacking off by config forces the penalty immediately', () {
      final e = buildEngine(
        hands: [
          [c(CardSuit.coppe, CardRank.re)],
          [c(CardSuit.spade, CardRank.due)],
        ],
        top: c(CardSuit.coppe, CardRank.due),
        currentIndex: 1,
        pendingPenalty: 2,
        chainLength: 1,
        rules: const GameRules(stackDrawTwos: false),
      );
      expect(e.canPlay(c(CardSuit.spade, CardRank.due)), isFalse);
      expect(e.mustTakePenalty, isTrue);
    });
  });

  group('Cavallo = choose suit (§12)', () {
    test('is playable on any suit and asks for a choice', () {
      final e = buildEngine(
        hands: [
          [c(CardSuit.spade, CardRank.cavallo), c(CardSuit.spade, CardRank.re)],
          [c(CardSuit.denari, CardRank.tre)],
        ],
        top: c(CardSuit.coppe, CardRank.cinque),
      );
      expect(e.canPlay(c(CardSuit.spade, CardRank.cavallo)), isTrue);
      e.autoPlayCard(c(CardSuit.spade, CardRank.cavallo));
      expect(e.state.status, GameStatus.awaitingSuitChoice);
      expect(e.currentPlayer.id, 'p0', reason: 'turn waits for the choice');
    });

    test('changes the active suit and passes the turn on', () {
      final e = buildEngine(
        hands: [
          [c(CardSuit.spade, CardRank.cavallo), c(CardSuit.spade, CardRank.re)],
          [c(CardSuit.denari, CardRank.tre)],
        ],
        top: c(CardSuit.coppe, CardRank.cinque),
      );
      e.autoPlayCard(c(CardSuit.spade, CardRank.cavallo));
      e.chooseSuit(CardSuit.bastoni);
      expect(e.state.activeSuit, CardSuit.bastoni);
      expect(e.state.status, GameStatus.awaitingAction);
      expect(e.currentPlayer.id, 'p1');
    });

    test('answers a live +2 chain only when nineBlockMode allows it', () {
      GameSession table(NineBlockMode mode) => buildEngine(
        hands: [
          [c(CardSuit.coppe, CardRank.re)],
          [c(CardSuit.spade, CardRank.cavallo)],
        ],
        top: c(CardSuit.coppe, CardRank.due),
        currentIndex: 1,
        pendingPenalty: 2,
        chainLength: 1,
        rules: GameRules(nineBlockMode: mode),
      );
      final cavallo = c(CardSuit.spade, CardRank.cavallo);
      expect(table(NineBlockMode.disabled).canPlay(cavallo), isFalse);
      expect(table(NineBlockMode.cancel).canPlay(cavallo), isTrue);
      expect(table(NineBlockMode.passOn).canPlay(cavallo), isTrue);
    });

    test('wildNineCanAlwaysPlay=false falls back to normal matching', () {
      final e = buildEngine(
        hands: [
          [c(CardSuit.spade, CardRank.cavallo)],
          [c(CardSuit.denari, CardRank.tre)],
        ],
        top: c(CardSuit.coppe, CardRank.cinque),
        rules: const GameRules(wildNineCanAlwaysPlay: false),
      );
      expect(e.canPlay(c(CardSuit.spade, CardRank.cavallo)), isFalse);
    });
  });

  group('Turn draw rule (§8)', () {
    test('a drawn playable card may be used at once', () {
      final e = buildEngine(
        hands: [
          [c(CardSuit.spade, CardRank.sette)],
          [c(CardSuit.denari, CardRank.tre)],
        ],
        top: c(CardSuit.coppe, CardRank.cinque),
        drawPile: [c(CardSuit.coppe, CardRank.re)],
      );
      e.drawCard();
      expect(e.state.drawnCard, c(CardSuit.coppe, CardRank.re));
      expect(e.currentPlayer.id, 'p0');
      expect(e.canEndTurn, isTrue);
      e.autoPlayCard(c(CardSuit.coppe, CardRank.re));
      expect(e.currentPlayer.id, 'p1');
    });

    test('a drawn unplayable card ends the turn automatically', () {
      final e = buildEngine(
        hands: [
          [c(CardSuit.spade, CardRank.sette)],
          [c(CardSuit.denari, CardRank.tre)],
        ],
        top: c(CardSuit.coppe, CardRank.cinque),
        drawPile: [c(CardSuit.bastoni, CardRank.re)],
      );
      e.drawCard();
      expect(e.currentPlayer.id, 'p1');
    });

    test('a turn cannot be passed before drawing', () {
      final e = buildEngine(
        hands: [
          [c(CardSuit.spade, CardRank.sette)],
          [c(CardSuit.denari, CardRank.tre)],
        ],
        top: c(CardSuit.coppe, CardRank.cinque),
        drawPile: [c(CardSuit.bastoni, CardRank.re)],
      );
      expect(e.canEndTurn, isFalse);
      expect(e.endTurn().failure, GameFailure.drawRequired);
    });

    test('voluntary draw can be switched off', () {
      final e = buildEngine(
        hands: [
          [c(CardSuit.coppe, CardRank.re)],
          [c(CardSuit.denari, CardRank.tre)],
        ],
        top: c(CardSuit.coppe, CardRank.cinque),
        drawPile: [c(CardSuit.bastoni, CardRank.re)],
        rules: const GameRules(allowVoluntaryDraw: false),
      );
      expect(e.canDraw, isFalse);
      expect(e.drawCard().accepted, isFalse);
    });
  });
}
