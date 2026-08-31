import 'package:flutter_test/flutter_test.dart';
import 'package:gioco_del_101/features/game/domain/engine/score_policy.dart';
import 'package:gioco_del_101/features/game/domain/card_rank.dart';
import 'package:gioco_del_101/features/game/domain/card_suit.dart';
import 'package:gioco_del_101/features/game/domain/game_card.dart';
import 'package:gioco_del_101/features/game/domain/game_rules.dart';

import 'support/engine_harness.dart';
import 'package:gioco_del_101/features/game/domain/game_state.dart';

void main() {
  const scorer = ScorePolicy(GameRules());

  group('Hand penalty values (§14)', () {
    test('sums the confirmed rank values', () {
      expect(
        scorer.handPenalty([
          const GameCard(CardSuit.denari, CardRank.asso),
          const GameCard(CardSuit.coppe, CardRank.re),
          const GameCard(CardSuit.spade, CardRank.cavallo),
          const GameCard(CardSuit.bastoni, CardRank.fante),
        ]),
        // §10 — pip cards by printed rank; Cavallo and Fante 25 each, the
        // client's 2026-08-31 change.
        1 + 10 + 25 + 25,
      );
    });

    test('the Fante and the Cavallo are the two 25-point cards', () {
      expect(
        scorer.handPenalty([const GameCard(CardSuit.spade, CardRank.fante)]),
        25,
      );
      expect(
        scorer.handPenalty([const GameCard(CardSuit.coppe, CardRank.cavallo)]),
        25,
      );
      expect(
        scorer.handPenalty([
          const GameCard(CardSuit.spade, CardRank.fante),
          const GameCard(CardSuit.coppe, CardRank.cavallo),
        ]),
        50,
      );
      // Several of each accumulate; nothing else moved.
      expect(
        scorer.handPenalty([
          const GameCard(CardSuit.spade, CardRank.fante),
          const GameCard(CardSuit.denari, CardRank.fante),
          const GameCard(CardSuit.coppe, CardRank.cavallo),
          const GameCard(CardSuit.bastoni, CardRank.cavallo),
          const GameCard(CardSuit.coppe, CardRank.re),
        ]),
        4 * 25 + 10,
      );
      for (final rank in [
        CardRank.asso,
        CardRank.due,
        CardRank.tre,
        CardRank.quattro,
        CardRank.cinque,
        CardRank.sei,
        CardRank.sette,
        CardRank.re,
      ]) {
        expect(
          scorer.handPenalty([GameCard(CardSuit.denari, rank)]),
          rank.value,
          reason: '${rank.key} keeps its printed value',
        );
      }
    });

    test('an empty hand is worth nothing', () {
      expect(scorer.handPenalty(const []), 0);
    });

    test('honours a client-supplied value table', () {
      // Built at runtime: a const map literal cannot restate a key.
      final table = Map<CardRank, int>.of(GameRules.defaultScoreValues)
        ..[CardRank.cavallo] = 40;
      final custom = ScorePolicy(GameRules(scoreValues: table));
      expect(
        custom.handPenalty([const GameCard(CardSuit.spade, CardRank.cavallo)]),
        40,
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
      const noReset = ScorePolicy(GameRules(exact101ResetsToZero: false));
      final out = noReset.apply(previousScore: 94, penalty: 7);
      expect(out.newScore, 101);
      expect(out.hitExact101, isFalse);
      expect(out.eliminated, isFalse);
    });

    test('elimination can be switched off', () {
      const noElim = ScorePolicy(GameRules(eliminateAbove101: false));
      final out = noElim.apply(previousScore: 94, penalty: 20);
      expect(out.newScore, 114);
      expect(out.eliminated, isFalse);
    });

    test('the target score is configurable end to end', () {
      const to50 = ScorePolicy(GameRules(targetScore: 50));
      expect(to50.apply(previousScore: 45, penalty: 5).newScore, 0);
      expect(to50.apply(previousScore: 45, penalty: 6).eliminated, isTrue);
    });
  });

  group('Round end (§14, §36)', () {
    test('emptying a hand ends the round and scores every opponent', () {
      final e = buildEngine(
        hands: [
          [c(CardSuit.coppe, CardRank.re)],
          [c(CardSuit.spade, CardRank.tre), c(CardSuit.spade, CardRank.fante)],
          [c(CardSuit.denari, CardRank.sette)],
        ],
        top: c(CardSuit.coppe, CardRank.cinque),
        scores: [10, 20, 30],
      );
      e.autoPlayCard(c(CardSuit.coppe, CardRank.re));

      expect(e.state.status, GameStatus.roundOver);
      final result = e.lastRoundResult!;
      expect(result.winnerId, 'p0');
      expect(
        e.state.playerById('p0')!.score,
        10,
        reason: 'winner adds nothing',
      );
      // §10 — the Fante is 25, so p1 pays 3 + 25.
      expect(e.state.playerById('p1')!.score, 20 + 3 + 25);
      expect(e.state.playerById('p2')!.score, 30 + 7);
      expect(result.rows, hasLength(3));
    });

    test('a round-winning Ace ends the round without skipping anyone', () {
      final e = buildEngine(
        hands: [
          [c(CardSuit.coppe, CardRank.asso)],
          [c(CardSuit.spade, CardRank.tre)],
        ],
        top: c(CardSuit.coppe, CardRank.cinque),
      );
      e.autoPlayCard(c(CardSuit.coppe, CardRank.asso));
      expect(e.state.status, GameStatus.roundOver);
      expect(e.lastRoundResult!.winnerId, 'p0');
    });

    test('a round-winning 2 ends the round and voids the chain by default', () {
      final e = buildEngine(
        hands: [
          [c(CardSuit.coppe, CardRank.due)],
          [c(CardSuit.spade, CardRank.tre)],
        ],
        top: c(CardSuit.coppe, CardRank.cinque),
        drawPile: [
          c(CardSuit.bastoni, CardRank.re),
          c(CardSuit.bastoni, CardRank.sei),
        ],
      );
      e.autoPlayCard(c(CardSuit.coppe, CardRank.due));
      expect(e.state.status, GameStatus.roundOver);
      expect(e.state.pendingDrawCount, 0);
      expect(e.state.playerById('p1')!.hand, hasLength(1));
      expect(e.state.playerById('p1')!.score, 3);
    });

    test('the winning +2 can be made to bite when the client wants it', () {
      final e = buildEngine(
        hands: [
          [c(CardSuit.coppe, CardRank.due)],
          [c(CardSuit.spade, CardRank.tre)],
        ],
        top: c(CardSuit.coppe, CardRank.cinque),
        drawPile: [
          c(CardSuit.bastoni, CardRank.re),
          c(CardSuit.bastoni, CardRank.sei),
        ],
        rules: const GameRules(pendingPenaltyAppliesAfterWin: true),
      );
      e.autoPlayCard(c(CardSuit.coppe, CardRank.due));
      expect(e.state.playerById('p1')!.hand, hasLength(3));
      expect(e.state.playerById('p1')!.score, 3 + 6 + 10);
    });

    test('a round-winning Cavallo skips the suit ritual', () {
      final e = buildEngine(
        hands: [
          [c(CardSuit.spade, CardRank.cavallo)],
          [c(CardSuit.denari, CardRank.tre)],
        ],
        top: c(CardSuit.coppe, CardRank.cinque),
      );
      e.autoPlayCard(c(CardSuit.spade, CardRank.cavallo));
      expect(e.state.status, GameStatus.roundOver);
      expect(e.lastRoundResult!.winnerId, 'p0');
    });

    test('hitting exactly 101 at round end wipes the score', () {
      final e = buildEngine(
        hands: [
          [c(CardSuit.coppe, CardRank.re)],
          [c(CardSuit.spade, CardRank.sette)],
        ],
        top: c(CardSuit.coppe, CardRank.cinque),
        scores: [0, 94],
      );
      e.autoPlayCard(c(CardSuit.coppe, CardRank.re));
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
        top: c(CardSuit.coppe, CardRank.cinque),
        scores: [20, 95],
      );
      e.autoPlayCard(c(CardSuit.coppe, CardRank.re));
      expect(e.state.playerById('p1')!.eliminated, isTrue);
      expect(e.state.isFinished, isTrue);
      expect(e.state.winnerId, 'p0');
      expect(e.state.status, GameStatus.finished);
    });

    test('two players busting together hands it to the lower score', () {
      final e = buildEngine(
        hands: [
          [c(CardSuit.coppe, CardRank.re), c(CardSuit.coppe, CardRank.quattro)],
          [c(CardSuit.spade, CardRank.re), c(CardSuit.spade, CardRank.fante)],
          [c(CardSuit.coppe, CardRank.tre)],
        ],
        top: c(CardSuit.coppe, CardRank.cinque),
        currentIndex: 2,
        scores: [99, 95, 0],
      );
      // p2 wins the round; p0 and p1 both bust in the same tally.
      expect(e.autoPlayCard(c(CardSuit.coppe, CardRank.tre)).accepted, isTrue);
      expect(e.state.playerById('p0')!.eliminated, isTrue);
      expect(e.state.playerById('p1')!.eliminated, isTrue);
      expect(e.state.isFinished, isTrue);
      expect(e.state.winnerId, 'p2');
    });

    test('an eliminated seat is skipped in the next round', () {
      final e = buildEngine(
        hands: [
          [c(CardSuit.coppe, CardRank.re)],
          [c(CardSuit.spade, CardRank.re), c(CardSuit.spade, CardRank.fante)],
          [c(CardSuit.denari, CardRank.tre)],
        ],
        top: c(CardSuit.coppe, CardRank.cinque),
        scores: [0, 95, 0],
      );
      e.autoPlayCard(c(CardSuit.coppe, CardRank.re));
      expect(e.state.playerById('p1')!.eliminated, isTrue);
      expect(e.state.isFinished, isFalse);

      e.startNextRound();
      expect(e.state.round, 2);
      expect(e.state.playerById('p1')!.hand, isEmpty);
      expect(e.state.playerById('p0')!.hand, hasLength(5));
      expect(e.state.playerById('p2')!.hand, hasLength(5));
      expect(e.currentPlayer.id, 'p0', reason: 'the round winner leads');

      // Turn order must hop straight over the eliminated seat.
      final seen = <String>{};
      for (var i = 0; i < 6; i++) {
        seen.add(e.currentPlayer.id);
        e.drawCard();
        if (e.state.drawnCard != null) e.endTurn();
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
          top: c(CardSuit.coppe, CardRank.cinque),
          scores: [20, 95],
          rules: const GameRules(eliminateAbove101: false),
        );
        e.autoPlayCard(c(CardSuit.coppe, CardRank.re));
        expect(e.state.playerById('p1')!.eliminated, isFalse);
        expect(e.state.isFinished, isTrue);
        expect(e.state.winnerId, 'p0');
      },
    );
  });
}
