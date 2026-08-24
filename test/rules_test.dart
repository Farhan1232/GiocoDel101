import 'package:flutter_test/flutter_test.dart';
import 'package:gioco_del_101/game/engine/game_engine.dart';
import 'package:gioco_del_101/models/card_rank.dart';
import 'package:gioco_del_101/models/card_suit.dart';
import 'package:gioco_del_101/models/game_rules_config.dart';
import 'package:gioco_del_101/models/round_state.dart';

import 'support/engine_harness.dart';

void main() {
  group('Normal play rule (§7)', () {
    test('accepts a card of the active suit', () {
      final e = buildEngine(
        hands: [
          [c(CardSuit.coppe, CardRank.re)],
          [c(CardSuit.spade, CardRank.three)],
        ],
        top: c(CardSuit.coppe, CardRank.five),
      );
      expect(e.canPlay(c(CardSuit.coppe, CardRank.re)), isTrue);
    });

    test('accepts a card of the same rank in another suit', () {
      final e = buildEngine(
        hands: [
          [c(CardSuit.bastoni, CardRank.five)],
          [c(CardSuit.spade, CardRank.three)],
        ],
        top: c(CardSuit.coppe, CardRank.five),
      );
      expect(e.canPlay(c(CardSuit.bastoni, CardRank.five)), isTrue);
    });

    test('rejects a mismatch in both suit and rank', () {
      final e = buildEngine(
        hands: [
          [c(CardSuit.bastoni, CardRank.seven)],
          [c(CardSuit.spade, CardRank.three)],
        ],
        top: c(CardSuit.coppe, CardRank.five),
      );
      expect(e.canPlay(c(CardSuit.bastoni, CardRank.seven)), isFalse);
      final result = e.playCard(c(CardSuit.bastoni, CardRank.seven));
      expect(result.accepted, isFalse);
      expect(result.rejection, MoveRejection.illegalCard);
    });

    test('matches the suit named by a Cavallo, not the top card suit', () {
      final e = buildEngine(
        hands: [
          [c(CardSuit.spade, CardRank.four), c(CardSuit.coppe, CardRank.four)],
          [c(CardSuit.denari, CardRank.three)],
        ],
        top: c(CardSuit.coppe, CardRank.cavallo),
        activeSuit: CardSuit.spade,
      );
      expect(e.canPlay(c(CardSuit.spade, CardRank.four)), isTrue);
      // Same rank as the top card is still a legal answer.
      expect(e.canPlay(c(CardSuit.coppe, CardRank.four)), isFalse);
    });
  });

  group('Ace = skip (§9)', () {
    test('skips the next player in a three-handed game', () {
      final e = buildEngine(
        hands: [
          [c(CardSuit.coppe, CardRank.ace), c(CardSuit.coppe, CardRank.re)],
          [c(CardSuit.spade, CardRank.three)],
          [c(CardSuit.denari, CardRank.three)],
        ],
        top: c(CardSuit.coppe, CardRank.five),
      );
      expect(e.playCard(c(CardSuit.coppe, CardRank.ace)).accepted, isTrue);
      expect(e.currentPlayer.id, 'p2', reason: 'p1 loses the turn');
    });

    test('returns the turn to the player in a two-handed game', () {
      final e = buildEngine(
        hands: [
          [c(CardSuit.coppe, CardRank.ace), c(CardSuit.coppe, CardRank.re)],
          [c(CardSuit.spade, CardRank.three)],
        ],
        top: c(CardSuit.coppe, CardRank.five),
      );
      e.playCard(c(CardSuit.coppe, CardRank.ace));
      expect(e.currentPlayer.id, 'p0');
    });
  });

  group('Two = draw two, with stacking (§10)', () {
    test('a single 2 leaves the next player owing two cards', () {
      final e = buildEngine(
        hands: [
          [c(CardSuit.coppe, CardRank.two), c(CardSuit.coppe, CardRank.re)],
          [c(CardSuit.spade, CardRank.three)],
        ],
        top: c(CardSuit.coppe, CardRank.five),
        drawPile: List.generate(10, (i) => null)
            .asMap()
            .keys
            .map((i) => c(CardSuit.bastoni, CardRank.values[i]))
            .toList(),
      );
      e.playCard(c(CardSuit.coppe, CardRank.two));
      expect(e.round.pendingPenalty, 2);
      expect(e.round.chainLength, 1);
      expect(e.currentPlayer.id, 'p1');
    });

    test('only another 2 answers a live chain', () {
      final e = buildEngine(
        hands: [
          [c(CardSuit.coppe, CardRank.re)],
          [c(CardSuit.spade, CardRank.two), c(CardSuit.coppe, CardRank.seven)],
        ],
        top: c(CardSuit.coppe, CardRank.two),
        currentIndex: 1,
        pendingPenalty: 2,
        chainLength: 1,
      );
      expect(e.canPlay(c(CardSuit.coppe, CardRank.seven)), isFalse);
      expect(e.canPlay(c(CardSuit.spade, CardRank.two)), isTrue);
    });

    test('stacks to +4 then +6 and hits the player who cannot answer', () {
      final deck = [
        for (final r in CardRank.values) c(CardSuit.bastoni, r),
      ];
      final e = buildEngine(
        hands: [
          [c(CardSuit.coppe, CardRank.two), c(CardSuit.coppe, CardRank.re)],
          [c(CardSuit.spade, CardRank.two), c(CardSuit.spade, CardRank.re)],
          [c(CardSuit.denari, CardRank.two), c(CardSuit.denari, CardRank.re)],
          [c(CardSuit.coppe, CardRank.seven)],
        ],
        top: c(CardSuit.coppe, CardRank.five),
        drawPile: deck,
      );

      e.playCard(c(CardSuit.coppe, CardRank.two));
      expect(e.round.pendingPenalty, 2);
      e.playCard(c(CardSuit.spade, CardRank.two));
      expect(e.round.pendingPenalty, 4);
      e.playCard(c(CardSuit.denari, CardRank.two));
      expect(e.round.pendingPenalty, 6);
      expect(e.round.chainLength, 3);

      expect(e.currentPlayer.id, 'p3');
      expect(e.mustTakePenalty, isTrue);
      e.drawCard();

      expect(e.state.playerById('p3')!.hand, hasLength(1 + 6));
      expect(e.round.pendingPenalty, 0);
      expect(e.round.chainLength, 0);
      expect(e.currentPlayer.id, 'p0', reason: 'p3 also loses the turn');
    });

    test('a player may decline to stack and take the cards instead', () {
      final e = buildEngine(
        hands: [
          [c(CardSuit.coppe, CardRank.re)],
          [c(CardSuit.spade, CardRank.two), c(CardSuit.coppe, CardRank.seven)],
        ],
        top: c(CardSuit.coppe, CardRank.two),
        currentIndex: 1,
        pendingPenalty: 2,
        chainLength: 1,
        drawPile: [
          c(CardSuit.bastoni, CardRank.four),
          c(CardSuit.bastoni, CardRank.six)
        ],
      );
      e.drawCard();
      expect(e.state.playerById('p1')!.hand, hasLength(4));
      expect(e.round.pendingPenalty, 0);
      expect(e.currentPlayer.id, 'p0');
    });

    test('stacking off by config forces the penalty immediately', () {
      final e = buildEngine(
        hands: [
          [c(CardSuit.coppe, CardRank.re)],
          [c(CardSuit.spade, CardRank.two)],
        ],
        top: c(CardSuit.coppe, CardRank.two),
        currentIndex: 1,
        pendingPenalty: 2,
        chainLength: 1,
        rules: const GameRulesConfig(stackDrawTwos: false),
      );
      expect(e.canPlay(c(CardSuit.spade, CardRank.two)), isFalse);
      expect(e.mustTakePenalty, isTrue);
    });
  });

  group('Cavallo = choose suit (§12)', () {
    test('is playable on any suit and asks for a choice', () {
      final e = buildEngine(
        hands: [
          [c(CardSuit.spade, CardRank.cavallo), c(CardSuit.spade, CardRank.re)],
          [c(CardSuit.denari, CardRank.three)],
        ],
        top: c(CardSuit.coppe, CardRank.five),
      );
      expect(e.canPlay(c(CardSuit.spade, CardRank.cavallo)), isTrue);
      e.playCard(c(CardSuit.spade, CardRank.cavallo));
      expect(e.round.phase, TurnPhase.awaitingSuitChoice);
      expect(e.currentPlayer.id, 'p0', reason: 'turn waits for the choice');
    });

    test('changes the active suit and passes the turn on', () {
      final e = buildEngine(
        hands: [
          [c(CardSuit.spade, CardRank.cavallo), c(CardSuit.spade, CardRank.re)],
          [c(CardSuit.denari, CardRank.three)],
        ],
        top: c(CardSuit.coppe, CardRank.five),
      );
      e.playCard(c(CardSuit.spade, CardRank.cavallo));
      e.chooseSuit(CardSuit.bastoni);
      expect(e.round.activeSuit, CardSuit.bastoni);
      expect(e.round.phase, TurnPhase.awaitingAction);
      expect(e.currentPlayer.id, 'p1');
    });

    test('does not answer a live +2 chain', () {
      final e = buildEngine(
        hands: [
          [c(CardSuit.coppe, CardRank.re)],
          [c(CardSuit.spade, CardRank.cavallo)],
        ],
        top: c(CardSuit.coppe, CardRank.two),
        currentIndex: 1,
        pendingPenalty: 2,
        chainLength: 1,
      );
      expect(e.canPlay(c(CardSuit.spade, CardRank.cavallo)), isFalse);
    });

    test('wildNineCanAlwaysPlay=false falls back to normal matching', () {
      final e = buildEngine(
        hands: [
          [c(CardSuit.spade, CardRank.cavallo)],
          [c(CardSuit.denari, CardRank.three)],
        ],
        top: c(CardSuit.coppe, CardRank.five),
        rules: const GameRulesConfig(wildNineCanAlwaysPlay: false),
      );
      expect(e.canPlay(c(CardSuit.spade, CardRank.cavallo)), isFalse);
    });
  });

  group('Turn draw rule (§8)', () {
    test('a drawn playable card may be used at once', () {
      final e = buildEngine(
        hands: [
          [c(CardSuit.spade, CardRank.seven)],
          [c(CardSuit.denari, CardRank.three)],
        ],
        top: c(CardSuit.coppe, CardRank.five),
        drawPile: [c(CardSuit.coppe, CardRank.re)],
      );
      e.drawCard();
      expect(e.round.drawnCard, c(CardSuit.coppe, CardRank.re));
      expect(e.currentPlayer.id, 'p0');
      expect(e.canEndTurn, isTrue);
      e.playCard(c(CardSuit.coppe, CardRank.re));
      expect(e.currentPlayer.id, 'p1');
    });

    test('a drawn unplayable card ends the turn automatically', () {
      final e = buildEngine(
        hands: [
          [c(CardSuit.spade, CardRank.seven)],
          [c(CardSuit.denari, CardRank.three)],
        ],
        top: c(CardSuit.coppe, CardRank.five),
        drawPile: [c(CardSuit.bastoni, CardRank.re)],
      );
      e.drawCard();
      expect(e.currentPlayer.id, 'p1');
    });

    test('a turn cannot be passed before drawing', () {
      final e = buildEngine(
        hands: [
          [c(CardSuit.spade, CardRank.seven)],
          [c(CardSuit.denari, CardRank.three)],
        ],
        top: c(CardSuit.coppe, CardRank.five),
        drawPile: [c(CardSuit.bastoni, CardRank.re)],
      );
      expect(e.canEndTurn, isFalse);
      expect(e.endTurn().rejection, MoveRejection.mustDrawFirst);
    });

    test('voluntary draw can be switched off', () {
      final e = buildEngine(
        hands: [
          [c(CardSuit.coppe, CardRank.re)],
          [c(CardSuit.denari, CardRank.three)],
        ],
        top: c(CardSuit.coppe, CardRank.five),
        drawPile: [c(CardSuit.bastoni, CardRank.re)],
        rules: const GameRulesConfig(allowVoluntaryDraw: false),
      );
      expect(e.canDraw, isFalse);
      expect(e.drawCard().accepted, isFalse);
    });
  });
}
