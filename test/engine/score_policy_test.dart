import 'package:flutter_test/flutter_test.dart';
import 'package:gioco_del_101/features/game/domain/card_rank.dart';
import 'package:gioco_del_101/features/game/domain/card_suit.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_engine.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_failure.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_event.dart';
import 'package:gioco_del_101/features/game/domain/engine/score_policy.dart';
import 'package:gioco_del_101/features/game/domain/game_action.dart';
import 'package:gioco_del_101/features/game/domain/game_rules.dart';
import 'package:gioco_del_101/features/game/domain/game_state.dart';

import '../support/engine_harness.dart';

const engine = GameEngine();

// §16 — the announcement goes first when a play would take the actor down
// to one card, exactly as the table sends it. These cases are about
// something else; `ultima_carta_test.dart` is about §16 itself.
ActionAccepted ok(GameState s, GameAction a) {
  final r = engine.applyAction(declaredIfNeeded(s, a), a);
  expect(r, isA<ActionAccepted>(), reason: '$r');
  return r as ActionAccepted;
}

void main() {
  final top = c(CardSuit.coppe, CardRank.cinque);
  final win = c(CardSuit.coppe, CardRank.re);

  group('ScorePolicy (§10, §11)', () {
    test('hand penalty follows the confirmed value table', () {
      const p = ScorePolicy(GameRules());
      // §10 — Asso 1 + Re 10 + Fante 8 (the client's 2026-09-01 price:
      // the Fante is back to its printed number, only the Cavallo is 25).
      expect(
        p.handPenalty([
          c(CardSuit.denari, CardRank.asso),
          c(CardSuit.denari, CardRank.re),
          c(CardSuit.spade, CardRank.fante),
        ]),
        19,
      );
      expect(
        p.handPenalty([
          c(CardSuit.denari, CardRank.asso),
          c(CardSuit.denari, CardRank.re),
          c(CardSuit.spade, CardRank.cavallo),
        ]),
        36,
      );
      expect(p.handPenalty(const []), 0);
    });

    test('exact target resets; over target eliminates; otherwise adds', () {
      const p = ScorePolicy(GameRules());
      expect(p.apply(previousScore: 90, penalty: 5).newScore, 95);
      final reset = p.apply(previousScore: 90, penalty: 11);
      expect(reset.newScore, 0);
      expect(reset.hitExact101, isTrue);
      final out = p.apply(previousScore: 90, penalty: 12);
      expect(out.eliminated, isTrue);
      expect(out.newScore, 102);
    });

    test('every threshold is configurable', () {
      const p = ScorePolicy(
        GameRules(targetScore: 50, exact101ResetsToZero: false),
      );
      expect(p.apply(previousScore: 40, penalty: 10).newScore, 50);
      expect(p.apply(previousScore: 40, penalty: 10).hitExact101, isFalse);
      const noElim = ScorePolicy(GameRules(eliminateAbove101: false));
      expect(noElim.apply(previousScore: 100, penalty: 5).eliminated, isFalse);
      const custom = ScorePolicy(GameRules(scoreValues: {CardRank.re: 25}));
      expect(
        custom.handPenalty([
          c(CardSuit.coppe, CardRank.re),
          c(CardSuit.coppe, CardRank.asso),
        ]),
        26,
      );
    });
  });

  group('Round end', () {
    test('the winner scores nothing; others score their hands', () {
      final s = buildState(
        hands: [
          [win],
          [c(CardSuit.denari, CardRank.re), c(CardSuit.denari, CardRank.sette)],
          [c(CardSuit.bastoni, CardRank.asso)],
        ],
        top: top,
        scores: [5, 5, 5],
      );
      final r = ok(s, PlayCardAction(playerId: 'p0', card: win));
      expect(r.state.status, GameStatus.roundOver);
      expect(r.state.roundWinnerId, 'p0');
      expect(r.state.scores, {'p0': 5, 'p1': 22, 'p2': 6});
      final result = r.events.whereType<RoundEndedEvent>().single.result;
      expect(result.winnerId, 'p0');
      expect(result.rows.map((x) => x.penalty), [0, 17, 1]);
      expect(result.matchOver, isFalse);
      expect(r.state.lastRoundResult, isNotNull);
      expect(r.state.stats.roundsWon['p0'], 1);
      expect(r.state.winnerId, isNull);
    });

    test('exactly 101 resets to zero and fires Exact101Event', () {
      final s = buildState(
        hands: [
          [win],
          [c(CardSuit.denari, CardRank.re), c(CardSuit.denari, CardRank.asso)],
        ],
        top: top,
        scores: [0, 90],
      );
      final r = ok(s, PlayCardAction(playerId: 'p0', card: win));
      expect(r.state.players[1].score, 0);
      expect(r.state.players[1].eliminated, isFalse);
      expect(r.events.whereType<Exact101Event>().single.playerId, 'p1');
      expect(r.state.stats.resets101, 1);
      expect(r.state.lastRoundResult!.rows[1].hitExact101, isTrue);
      expect(r.state.status, GameStatus.roundOver, reason: 'the match goes on');
    });

    test('over 101 eliminates; last player standing wins the match', () {
      final s = buildState(
        hands: [
          [win],
          [c(CardSuit.denari, CardRank.re), c(CardSuit.denari, CardRank.due)],
        ],
        top: top,
        scores: [40, 90],
      );
      final r = ok(s, PlayCardAction(playerId: 'p0', card: win));
      expect(r.state.players[1].eliminated, isTrue);
      expect(r.state.players[1].score, 102);
      expect(r.state.status, GameStatus.finished);
      expect(r.state.winnerId, 'p0');
      expect(r.events.whereType<PlayerEliminatedEvent>().single.playerId, 'p1');
      expect(r.events.whereType<MatchEndedEvent>().single.winnerId, 'p0');
      expect(r.state.lastRoundResult!.matchOver, isTrue);
    });

    test('with three players an elimination leaves the match running', () {
      final s = buildState(
        hands: [
          [win],
          [c(CardSuit.denari, CardRank.re), c(CardSuit.denari, CardRank.due)],
          [c(CardSuit.bastoni, CardRank.asso)],
        ],
        top: top,
        scores: [40, 90, 10],
      );
      final r = ok(s, PlayCardAction(playerId: 'p0', card: win));
      expect(r.state.status, GameStatus.roundOver);
      expect(r.state.players[1].eliminated, isTrue);
      expect(r.state.winnerId, isNull);
      // The eliminated seat is not dealt in and never gets a turn.
      final next = ok(
        r.state,
        const StartNextRoundAction(playerId: 'p0'),
      ).state;
      expect(next.players[1].hand, isEmpty);
      expect(next.players[0].hand, hasLength(5));
      expect(next.players[2].hand, hasLength(5));
      expect(next.currentPlayerId, 'p0');
      expect(next.round, 2);
      expect(next.totalCards, 40);
    });

    test(
      'eliminateAbove101=false: the match ends on the first overshoot, lowest wins',
      () {
        final s = buildState(
          hands: [
            [win],
            [c(CardSuit.denari, CardRank.re), c(CardSuit.denari, CardRank.due)],
            [c(CardSuit.bastoni, CardRank.asso)],
          ],
          top: top,
          scores: [40, 90, 10],
          rules: const GameRules(eliminateAbove101: false),
        );
        final r = ok(s, PlayCardAction(playerId: 'p0', card: win));
        expect(r.state.players[1].eliminated, isFalse);
        expect(r.state.status, GameStatus.finished);
        expect(r.state.winnerId, 'p2', reason: '11 is the lowest total');
      },
    );

    test(
      'two players overshooting in the same round: the round winner takes the match',
      () {
        final s = buildState(
          hands: [
            [win],
            [c(CardSuit.denari, CardRank.re), c(CardSuit.denari, CardRank.due)],
            [
              c(CardSuit.bastoni, CardRank.re),
              c(CardSuit.bastoni, CardRank.tre),
            ],
          ],
          top: top,
          scores: [40, 90, 95],
        );
        final r = ok(s, PlayCardAction(playerId: 'p0', card: win));
        expect(r.state.players[1].eliminated, isTrue);
        expect(r.state.players[2].eliminated, isTrue);
        expect(r.state.status, GameStatus.finished);
        expect(r.state.winnerId, 'p0');
        expect(
          r.events.whereType<PlayerEliminatedEvent>().map((e) => e.playerId),
          ['p1', 'p2'],
        );
      },
    );

    test('best comeback tracks the largest deficit among survivors', () {
      final s = buildState(
        hands: [
          [win],
          [c(CardSuit.denari, CardRank.re)],
          [c(CardSuit.bastoni, CardRank.asso)],
        ],
        top: top,
        scores: [0, 50, 20],
      );
      final r = ok(s, PlayCardAction(playerId: 'p0', card: win));
      expect(r.state.stats.bestComeback, 60);
    });
  });

  group('Next round', () {
    test('the previous winner leads and everything is redealt', () {
      final s = buildState(
        hands: [
          [c(CardSuit.denari, CardRank.re)],
          [win],
          [c(CardSuit.bastoni, CardRank.asso)],
        ],
        top: top,
        currentIndex: 1,
        pendingPenalty: 0,
      );
      final over = ok(s, PlayCardAction(playerId: 'p1', card: win)).state;
      final r = ok(over, const StartNextRoundAction(playerId: 'p2'));
      final next = r.state;
      expect(next.round, 2);
      expect(next.currentPlayerId, 'p1');
      expect(next.status, GameStatus.awaitingAction);
      expect(next.roundWinnerId, isNull);
      expect(next.lastRoundResult, isNull);
      expect(next.turnNumber, 0);
      expect(next.playedCards, isEmpty);
      expect(next.drawsByPlayer, isEmpty);
      expect(next.discardPile, hasLength(1));
      expect(next.topCard.isAction, isFalse);
      for (final p in next.players) {
        expect(p.hand, hasLength(5));
      }
      expect(next.totalCards, 40);
      expect(next.scores, over.scores, reason: 'scores carry across rounds');
      expect(r.events.first, isA<RoundStartedEvent>());
    });

    test('RoundStarterPolicy.seatAfterPreviousWinner', () {
      final s = buildState(
        hands: [
          [c(CardSuit.denari, CardRank.re)],
          [win],
          [c(CardSuit.bastoni, CardRank.asso)],
        ],
        top: top,
        currentIndex: 1,
        rules: const GameRules(
          roundStarterPolicy: RoundStarterPolicy.seatAfterPreviousWinner,
        ),
      );
      final over = ok(s, PlayCardAction(playerId: 'p1', card: win)).state;
      expect(
        ok(
          over,
          const StartNextRoundAction(playerId: 'p1'),
        ).state.currentPlayerId,
        'p2',
      );
    });

    test(
      'a full match plays to a winner with 101 resets and eliminations along the way',
      () {
        var s = engine.createGame(
          gameId: 'g',
          players: buildState(hands: const [[], [], []], top: top).players,
          mode: GameMode.vsComputer,
          seed: 8,
        );
        var rounds = 0;
        var steps = 0;
        while (!s.isFinished && steps++ < 50000) {
          if (s.status == GameStatus.roundOver) {
            rounds++;
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
                suit: CardSuit.denari,
              ),
            ).state;
            continue;
          }
          final me = s.currentPlayerId;
          final playable = engine.getPlayableCards(s, me);
          if (playable.isNotEmpty) {
            s = ok(s, PlayCardAction(playerId: me, card: playable.first)).state;
          } else {
            s = ok(s, DrawCardAction(playerId: me)).state;
            if (s.currentPlayerId == me && engine.canPass(s)) {
              s = ok(s, PassAction(playerId: me)).state;
            }
          }
        }
        expect(s.isFinished, isTrue);
        expect(s.winnerId, isNotNull);
        expect(s.players.where((p) => !p.eliminated), hasLength(1));
        expect(
          s.players.where((p) => p.eliminated).every((p) => p.score > 101),
          isTrue,
        );
        expect(rounds, greaterThan(1));
        expect(s.round, rounds + 1);
      },
    );
  });
}
