import 'package:flutter_test/flutter_test.dart';
import 'package:gioco_del_101/features/game/domain/engine/score_calculator.dart';
import 'package:gioco_del_101/features/game/domain/card_rank.dart';
import 'package:gioco_del_101/features/game/domain/card_suit.dart';
import 'package:gioco_del_101/features/game/domain/game_card.dart';
import 'package:gioco_del_101/features/game/domain/game_rules_config.dart';
import 'package:gioco_del_101/features/game/domain/round_state.dart';

import 'support/engine_harness.dart';

void main() {
  const scorer = ScoreCalculator(GameRulesConfig());

  group('Hand penalty values (§14)', () {
    test('sums printed rank values', () {
      expect(
        scorer.handPenalty([
          const GameCard(CardSuit.denari, CardRank.ace),
          const GameCard(CardSuit.coppe, CardRank.re),
          const GameCard(CardSuit.spade, CardRank.cavallo),
          const GameCard(CardSuit.bastoni, CardRank.fante),
        ]),
        1 + 10 + 9 + 8,
      );
    });

    test('an empty hand is worth nothing', () {
      expect(scorer.handPenalty(const []), 0);
    });

    test('honours a client-supplied value table', () {
      // Built at runtime: a const map literal cannot restate a key.
      final table = Map<CardRank, int>.of(GameRulesConfig.defaultScoreValues)
        ..[CardRank.cavallo] = 25;
      final custom = ScoreCalculator(GameRulesConfig(scoreValues: table));
      expect(
        custom.handPenalty([const GameCard(CardSuit.spade, CardRank.cavallo)]),
        25,
      );
    });
  });

  group('The 101 rule (§15, §16)', () {
    test('ordinary accumulation just adds up', () {
      final out = scorer.apply(previousScore: 40, penalty: 12);
      expect(out.newScore, 52);
      expect(out.hitExact101, isFalse);
      expect(out.eliminated, isFalse);
    });

    test('landing on exactly 101 resets to zero', () {
      final out = scorer.apply(previousScore: 94, penalty: 7);
      expect(out.newScore, 0);
      expect(out.hitExact101, isTrue);
      expect(out.eliminated, isFalse);
    });

    test('102 eliminates', () {
      final out = scorer.apply(previousScore: 94, penalty: 8);
      expect(out.newScore, 102);
      expect(out.eliminated, isTrue);
      expect(out.hitExact101, isFalse);
    });

    test('exactly 100 is safe but tense', () {
      final out = scorer.apply(previousScore: 90, penalty: 10);
      expect(out.newScore, 100);
      expect(out.eliminated, isFalse);
    });

    test('the reset can be switched off', () {
      const noReset = ScoreCalculator(
        GameRulesConfig(exact101ResetsToZero: false),
      );
      final out = noReset.apply(previousScore: 94, penalty: 7);
      expect(out.newScore, 101);
      expect(out.hitExact101, isFalse);
      expect(out.eliminated, isFalse);
    });

    test('elimination can be switched off', () {
      const noElim = ScoreCalculator(GameRulesConfig(eliminateAbove101: false));
      final out = noElim.apply(previousScore: 94, penalty: 20);
      expect(out.newScore, 114);
      expect(out.eliminated, isFalse);
    });

    test('the target score is configurable end to end', () {
      const to50 = ScoreCalculator(GameRulesConfig(targetScore: 50));
      expect(to50.apply(previousScore: 45, penalty: 5).newScore, 0);
      expect(to50.apply(previousScore: 45, penalty: 6).eliminated, isTrue);
    });
  });

  group('Round end (§14, §36)', () {
    test('emptying a hand ends the round and scores every opponent', () {
      final e = buildEngine(
        hands: [
          [c(CardSuit.coppe, CardRank.re)],
          [
            c(CardSuit.spade, CardRank.three),
            c(CardSuit.spade, CardRank.fante),
          ],
          [c(CardSuit.denari, CardRank.seven)],
        ],
        top: c(CardSuit.coppe, CardRank.five),
        scores: [10, 20, 30],
      );
      e.playCard(c(CardSuit.coppe, CardRank.re));

      expect(e.round.phase, TurnPhase.roundOver);
      final result = e.lastRoundResult!;
      expect(result.winnerId, 'p0');
      expect(
        e.state.playerById('p0')!.score,
        10,
        reason: 'winner adds nothing',
      );
      expect(e.state.playerById('p1')!.score, 20 + 3 + 8);
      expect(e.state.playerById('p2')!.score, 30 + 7);
      expect(result.rows, hasLength(3));
    });

    test('a round-winning Ace ends the round without skipping anyone', () {
      final e = buildEngine(
        hands: [
          [c(CardSuit.coppe, CardRank.ace)],
          [c(CardSuit.spade, CardRank.three)],
        ],
        top: c(CardSuit.coppe, CardRank.five),
      );
      e.playCard(c(CardSuit.coppe, CardRank.ace));
      expect(e.round.phase, TurnPhase.roundOver);
      expect(e.lastRoundResult!.winnerId, 'p0');
    });

    test('a round-winning 2 ends the round and voids the chain by default', () {
      final e = buildEngine(
        hands: [
          [c(CardSuit.coppe, CardRank.two)],
          [c(CardSuit.spade, CardRank.three)],
        ],
        top: c(CardSuit.coppe, CardRank.five),
        drawPile: [
          c(CardSuit.bastoni, CardRank.re),
          c(CardSuit.bastoni, CardRank.six),
        ],
      );
      e.playCard(c(CardSuit.coppe, CardRank.two));
      expect(e.round.phase, TurnPhase.roundOver);
      expect(e.round.pendingPenalty, 0);
      expect(e.state.playerById('p1')!.hand, hasLength(1));
      expect(e.state.playerById('p1')!.score, 3);
    });

    test('the winning +2 can be made to bite when the client wants it', () {
      final e = buildEngine(
        hands: [
          [c(CardSuit.coppe, CardRank.two)],
          [c(CardSuit.spade, CardRank.three)],
        ],
        top: c(CardSuit.coppe, CardRank.five),
        drawPile: [
          c(CardSuit.bastoni, CardRank.re),
          c(CardSuit.bastoni, CardRank.six),
        ],
        rules: const GameRulesConfig(pendingPenaltyAppliesAfterWin: true),
      );
      e.playCard(c(CardSuit.coppe, CardRank.two));
      expect(e.state.playerById('p1')!.hand, hasLength(3));
      expect(e.state.playerById('p1')!.score, 3 + 6 + 10);
    });

    test('a round-winning Cavallo skips the suit ritual', () {
      final e = buildEngine(
        hands: [
          [c(CardSuit.spade, CardRank.cavallo)],
          [c(CardSuit.denari, CardRank.three)],
        ],
        top: c(CardSuit.coppe, CardRank.five),
      );
      e.playCard(c(CardSuit.spade, CardRank.cavallo));
      expect(e.round.phase, TurnPhase.roundOver);
      expect(e.lastRoundResult!.winnerId, 'p0');
    });

    test('hitting exactly 101 at round end wipes the score', () {
      final e = buildEngine(
        hands: [
          [c(CardSuit.coppe, CardRank.re)],
          [c(CardSuit.spade, CardRank.seven)],
        ],
        top: c(CardSuit.coppe, CardRank.five),
        scores: [0, 94],
      );
      e.playCard(c(CardSuit.coppe, CardRank.re));
      expect(e.state.playerById('p1')!.score, 0);
      expect(e.lastRoundResult!.rows[1].hitExact101, isTrue);
      expect(e.state.stats.resets101, 1);
    });
  });

  group('Match end (§16, §52)', () {
    test('overshooting eliminates and the survivor takes the match', () {
      final e = buildEngine(
        hands: [
          [c(CardSuit.coppe, CardRank.re)],
          [c(CardSuit.spade, CardRank.re), c(CardSuit.spade, CardRank.fante)],
        ],
        top: c(CardSuit.coppe, CardRank.five),
        scores: [20, 95],
      );
      e.playCard(c(CardSuit.coppe, CardRank.re));
      expect(e.state.playerById('p1')!.eliminated, isTrue);
      expect(e.state.matchOver, isTrue);
      expect(e.state.matchWinnerId, 'p0');
      expect(e.round.phase, TurnPhase.matchOver);
    });

    test('two players busting together hands it to the lower score', () {
      final e = buildEngine(
        hands: [
          [c(CardSuit.coppe, CardRank.re), c(CardSuit.coppe, CardRank.four)],
          [c(CardSuit.spade, CardRank.re), c(CardSuit.spade, CardRank.fante)],
          [c(CardSuit.coppe, CardRank.three)],
        ],
        top: c(CardSuit.coppe, CardRank.five),
        currentIndex: 2,
        scores: [99, 95, 0],
      );
      // p2 wins the round; p0 and p1 both bust in the same tally.
      expect(e.playCard(c(CardSuit.coppe, CardRank.three)).accepted, isTrue);
      expect(e.state.playerById('p0')!.eliminated, isTrue);
      expect(e.state.playerById('p1')!.eliminated, isTrue);
      expect(e.state.matchOver, isTrue);
      expect(e.state.matchWinnerId, 'p2');
    });

    test('an eliminated seat is skipped in the next round', () {
      final e = buildEngine(
        hands: [
          [c(CardSuit.coppe, CardRank.re)],
          [c(CardSuit.spade, CardRank.re), c(CardSuit.spade, CardRank.fante)],
          [c(CardSuit.denari, CardRank.three)],
        ],
        top: c(CardSuit.coppe, CardRank.five),
        scores: [0, 95, 0],
      );
      e.playCard(c(CardSuit.coppe, CardRank.re));
      expect(e.state.playerById('p1')!.eliminated, isTrue);
      expect(e.state.matchOver, isFalse);

      e.startNextRound();
      expect(e.state.roundNumber, 2);
      expect(e.state.playerById('p1')!.hand, isEmpty);
      expect(e.state.playerById('p0')!.hand, hasLength(5));
      expect(e.state.playerById('p2')!.hand, hasLength(5));
      expect(e.currentPlayer.id, 'p0', reason: 'the round winner leads');

      // Turn order must hop straight over the eliminated seat.
      final seen = <String>{};
      for (var i = 0; i < 6; i++) {
        seen.add(e.currentPlayer.id);
        e.drawCard();
        if (e.round.drawnCard != null) e.endTurn();
      }
      expect(seen, isNot(contains('p1')));
    });

    test(
      'with elimination disabled the lowest score wins on any overshoot',
      () {
        final e = buildEngine(
          hands: [
            [c(CardSuit.coppe, CardRank.re)],
            [c(CardSuit.spade, CardRank.re), c(CardSuit.spade, CardRank.fante)],
          ],
          top: c(CardSuit.coppe, CardRank.five),
          scores: [20, 95],
          rules: const GameRulesConfig(eliminateAbove101: false),
        );
        e.playCard(c(CardSuit.coppe, CardRank.re));
        expect(e.state.playerById('p1')!.eliminated, isFalse);
        expect(e.state.matchOver, isTrue);
        expect(e.state.matchWinnerId, 'p0');
      },
    );
  });
}
