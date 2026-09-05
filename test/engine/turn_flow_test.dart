import 'package:flutter_test/flutter_test.dart';
import 'package:gioco_del_101/features/game/domain/card_rank.dart';
import 'package:gioco_del_101/features/game/domain/card_suit.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_engine.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_failure.dart';
import 'package:gioco_del_101/features/game/domain/game_action.dart';
import 'package:gioco_del_101/features/game/domain/game_rules.dart';
import 'package:gioco_del_101/features/game/domain/game_state.dart';

import '../support/engine_harness.dart';

const engine = GameEngine();

// §16 — the announcement goes first when a play would take the actor down
// to one card, exactly as the table sends it. These cases are about
// something else; `ultima_carta_test.dart` is about §16 itself.
GameState apply(GameState s, GameAction a) {
  final r = engine.applyAction(declaredIfNeeded(s, a), a);
  expect(r, isA<ActionAccepted>(), reason: 'expected acceptance, got $r');
  return (r as ActionAccepted).state;
}

GameFailure reject(GameState s, GameAction a) {
  final r = engine.applyAction(s, a);
  expect(r, isA<ActionRejected>(), reason: 'expected rejection');
  return (r as ActionRejected).failure;
}

void main() {
  final co5 = c(CardSuit.coppe, CardRank.cinque);

  group('Turn order', () {
    for (final n in [2, 3, 4]) {
      test('$n players rotate clockwise and wrap', () {
        var s = buildState(
          hands: [
            for (var i = 0; i < n; i++)
              [
                c(
                  CardSuit.coppe,
                  [
                    CardRank.sei,
                    CardRank.sette,
                    CardRank.fante,
                    CardRank.re,
                  ][i],
                ),
                c(CardSuit.bastoni, CardRank.values[i]),
              ],
          ],
          top: co5,
        );
        for (var turn = 0; turn < n * 2; turn++) {
          final expected = 'p${turn % n}';
          expect(s.currentPlayerId, expected);
          final card = s.currentPlayer.hand.firstWhere(
            (x) => x.suit == CardSuit.coppe,
            orElse: () => s.currentPlayer.hand.first,
          );
          if (engine.canPlay(s, card)) {
            s = apply(s, PlayCardAction(playerId: expected, card: card));
          } else {
            s = apply(s, DrawCardAction(playerId: expected));
            if (s.currentPlayerId == expected) {
              s = apply(s, PassAction(playerId: expected));
            }
          }
          if (s.isRoundOver) break;
        }
      });
    }

    test('counter-clockwise direction is honoured', () {
      final s = buildState(
        hands: [
          [c(CardSuit.coppe, CardRank.re)],
          [c(CardSuit.coppe, CardRank.tre)],
          [c(CardSuit.coppe, CardRank.quattro)],
        ],
        top: co5,
      ).copyWith(direction: TurnDirection.counterClockwise);
      final next = apply(
        s,
        PlayCardAction(playerId: 'p0', card: c(CardSuit.coppe, CardRank.re)),
      );
      // p0's hand emptied → round over. Use a two-card hand instead.
      expect(next.isRoundOver, isTrue);
      final s2 = buildState(
        hands: [
          [c(CardSuit.coppe, CardRank.re), c(CardSuit.spade, CardRank.re)],
          [c(CardSuit.coppe, CardRank.tre)],
          [c(CardSuit.coppe, CardRank.quattro)],
        ],
        top: co5,
      ).copyWith(direction: TurnDirection.counterClockwise);
      expect(
        apply(
          s2,
          PlayCardAction(playerId: 'p0', card: c(CardSuit.coppe, CardRank.re)),
        ).currentPlayerId,
        'p2',
      );
    });

    test('eliminated seats are skipped', () {
      final s = buildState(
        hands: [
          [c(CardSuit.coppe, CardRank.re), c(CardSuit.spade, CardRank.re)],
          [c(CardSuit.coppe, CardRank.tre)],
          [c(CardSuit.coppe, CardRank.quattro)],
        ],
        top: co5,
        eliminated: [false, true, false],
      );
      expect(
        apply(
          s,
          PlayCardAction(playerId: 'p0', card: c(CardSuit.coppe, CardRank.re)),
        ).currentPlayerId,
        'p2',
      );
    });

    test('turn number and version advance; lastAction is recorded', () {
      final s = buildState(
        hands: [
          // Three cards, so this stays a test of one action's bookkeeping:
          // from two the play would also need an ULTIMA CARTA (§16) and the
          // version would advance twice.
          [
            c(CardSuit.coppe, CardRank.re),
            c(CardSuit.spade, CardRank.re),
            c(CardSuit.bastoni, CardRank.re),
          ],
          [c(CardSuit.coppe, CardRank.tre)],
        ],
        top: co5,
      );
      final a = PlayCardAction(
        playerId: 'p0',
        card: c(CardSuit.coppe, CardRank.re),
      );
      final next = apply(s, a);
      expect(next.version, s.version + 1);
      expect(next.turnNumber, s.turnNumber + 1);
      expect(next.lastAction, a);
      expect(next.history.last.card, c(CardSuit.coppe, CardRank.re));
    });
  });

  group('Validation', () {
    test('wrong turn', () {
      final s = buildState(
        hands: [
          [c(CardSuit.coppe, CardRank.re)],
          [c(CardSuit.coppe, CardRank.tre)],
        ],
        top: co5,
      );
      expect(
        reject(
          s,
          PlayCardAction(playerId: 'p1', card: c(CardSuit.coppe, CardRank.tre)),
        ),
        GameFailure.notPlayersTurn,
      );
      expect(
        reject(s, const DrawCardAction(playerId: 'p1')),
        GameFailure.notPlayersTurn,
      );
      expect(
        reject(s, const PassAction(playerId: 'p1')),
        GameFailure.notPlayersTurn,
      );
      expect(engine.getPlayableCards(s, 'p1'), isEmpty);
    });

    test('card ownership', () {
      final s = buildState(
        hands: [
          [c(CardSuit.coppe, CardRank.re)],
          [c(CardSuit.coppe, CardRank.tre)],
        ],
        top: co5,
      );
      expect(
        reject(
          s,
          PlayCardAction(playerId: 'p0', card: c(CardSuit.coppe, CardRank.tre)),
        ),
        GameFailure.cardNotOwned,
      );
      expect(
        reject(
          s,
          PlayCardAction(playerId: 'p0', card: c(CardSuit.coppe, CardRank.sei)),
        ),
        GameFailure.cardNotOwned,
      );
    });

    test('same suit, same rank, wild Cavallo are legal; others are not', () {
      final s = buildState(
        hands: [
          [
            c(CardSuit.coppe, CardRank.re),
            c(CardSuit.bastoni, CardRank.cinque),
            c(CardSuit.spade, CardRank.cavallo),
            c(CardSuit.bastoni, CardRank.sette),
          ],
          [c(CardSuit.coppe, CardRank.tre)],
        ],
        top: co5,
      );
      expect(engine.getPlayableCards(s, 'p0'), [
        c(CardSuit.coppe, CardRank.re),
        c(CardSuit.bastoni, CardRank.cinque),
        c(CardSuit.spade, CardRank.cavallo),
      ]);
      expect(
        reject(
          s,
          PlayCardAction(
            playerId: 'p0',
            card: c(CardSuit.bastoni, CardRank.sette),
          ),
        ),
        GameFailure.illegalCard,
      );
    });

    test('unknown and eliminated players', () {
      final s = buildState(
        hands: [
          [c(CardSuit.coppe, CardRank.re)],
          [c(CardSuit.coppe, CardRank.tre)],
          [c(CardSuit.coppe, CardRank.quattro)],
        ],
        top: co5,
        eliminated: [false, false, true],
      );
      expect(
        reject(s, const DrawCardAction(playerId: 'nobody')),
        GameFailure.invalidPlayer,
      );
      expect(
        reject(s, const DrawCardAction(playerId: 'p2')),
        GameFailure.invalidPlayer,
      );
      expect(
        engine.validateAction(
          s,
          const StartNextRoundAction(playerId: 'nobody'),
        ),
        GameFailure.invalidPlayer,
      );
    });

    test('finished and round-over states', () {
      final base = buildState(
        hands: [
          [c(CardSuit.coppe, CardRank.re)],
          [c(CardSuit.coppe, CardRank.tre)],
        ],
        top: co5,
      );
      final finished = base.copyWith(
        status: GameStatus.finished,
        winnerId: 'p0',
      );
      expect(
        reject(finished, const DrawCardAction(playerId: 'p0')),
        GameFailure.gameFinished,
      );
      expect(
        reject(finished, const StartNextRoundAction(playerId: 'p0')),
        GameFailure.gameFinished,
      );
      final over = base.copyWith(
        status: GameStatus.roundOver,
        roundWinnerId: 'p0',
      );
      expect(
        reject(over, const DrawCardAction(playerId: 'p0')),
        GameFailure.roundOver,
      );
      expect(
        reject(base, const StartNextRoundAction(playerId: 'p0')),
        GameFailure.roundNotOver,
      );
      expect(
        engine.validateAction(
          over,
          const StartNextRoundAction(playerId: GameEngine.systemActorId),
        ),
        isNull,
      );
    });

    test('stale version and duplicate submission', () {
      final s = buildState(
        hands: [
          // Three cards: an ULTIMA CARTA (§16) would be a second action and
          // this case is about one action's version bookkeeping.
          [
            c(CardSuit.coppe, CardRank.re),
            c(CardSuit.spade, CardRank.re),
            c(CardSuit.bastoni, CardRank.sette),
          ],
          [c(CardSuit.coppe, CardRank.tre)],
        ],
        top: co5,
        version: 4,
      );
      final a = PlayCardAction(
        playerId: 'p0',
        card: c(CardSuit.coppe, CardRank.re),
        baseVersion: 4,
      );
      final next = apply(s, a);
      // Same action again against the new state: version no longer matches.
      expect(reject(next, a), GameFailure.staleState);
      // Even without a version, the second copy fails: wrong turn, card gone.
      final unversioned = PlayCardAction(
        playerId: 'p0',
        card: c(CardSuit.coppe, CardRank.re),
      );
      expect(reject(next, unversioned), GameFailure.notPlayersTurn);
      expect(
        reject(
          s,
          PlayCardAction(
            playerId: 'p0',
            card: c(CardSuit.coppe, CardRank.re),
            baseVersion: 3,
          ),
        ),
        GameFailure.staleState,
      );
    });

    test('structurally invalid state is refused, not crashed on', () {
      final bad = buildState(
        hands: [
          [c(CardSuit.coppe, CardRank.re)],
          [c(CardSuit.coppe, CardRank.tre)],
        ],
        top: co5,
      ).copyWith(discardPile: const []);
      expect(
        engine.validateAction(bad, const DrawCardAction(playerId: 'p0')),
        GameFailure.invalidState,
      );
    });
  });

  group('Draw / pass discipline', () {
    test('pass requires a draw first; after a draw it is allowed', () {
      final s = buildState(
        hands: [
          [c(CardSuit.bastoni, CardRank.sette)],
          [c(CardSuit.coppe, CardRank.tre)],
        ],
        top: co5,
        drawPile: [c(CardSuit.spade, CardRank.re)],
      );
      expect(
        reject(s, const PassAction(playerId: 'p0')),
        GameFailure.drawRequired,
      );
      expect(engine.canPass(s), isFalse);
      // The drawn spade_re is unplayable, so the turn moves on by itself.
      final drawn = apply(s, const DrawCardAction(playerId: 'p0'));
      expect(drawn.currentPlayerId, 'p1');
      expect(drawn.players.first.hand, hasLength(2));
    });

    test('mustDrawBeforePassing=false allows a bare pass', () {
      final s = buildState(
        hands: [
          [c(CardSuit.bastoni, CardRank.sette)],
          [c(CardSuit.coppe, CardRank.tre)],
        ],
        top: co5,
        rules: const GameRules(mustDrawBeforePassing: false),
      );
      expect(apply(s, const PassAction(playerId: 'p0')).currentPlayerId, 'p1');
    });

    test('a second draw in the same turn is refused', () {
      final s = buildState(
        hands: [
          [c(CardSuit.bastoni, CardRank.sette), c(CardSuit.coppe, CardRank.re)],
          [c(CardSuit.coppe, CardRank.tre)],
        ],
        top: co5,
        hasDrawnThisTurn: true,
        drawnCard: c(CardSuit.coppe, CardRank.re),
      );
      expect(
        reject(s, const DrawCardAction(playerId: 'p0')),
        GameFailure.drawNotAllowed,
      );
      expect(engine.canDraw(s), isFalse);
      expect(engine.canPass(s), isTrue);
    });

    test(
      'allowVoluntaryDraw=false refuses drawing while holding a legal card',
      () {
        final s = buildState(
          hands: [
            [c(CardSuit.coppe, CardRank.re)],
            [c(CardSuit.coppe, CardRank.tre)],
          ],
          top: co5,
          rules: const GameRules(allowVoluntaryDraw: false),
        );
        expect(
          reject(s, const DrawCardAction(playerId: 'p0')),
          GameFailure.drawNotAllowed,
        );
      },
    );

    test('restrictPlayToDrawnCard limits play to the drawn card', () {
      final s = buildState(
        hands: [
          [c(CardSuit.coppe, CardRank.re), c(CardSuit.coppe, CardRank.sei)],
          [c(CardSuit.coppe, CardRank.tre)],
        ],
        top: co5,
        hasDrawnThisTurn: true,
        drawnCard: c(CardSuit.coppe, CardRank.sei),
        rules: const GameRules(restrictPlayToDrawnCard: true),
      );
      expect(engine.getPlayableCards(s, 'p0'), [
        c(CardSuit.coppe, CardRank.sei),
      ]);
      expect(
        reject(
          s,
          PlayCardAction(playerId: 'p0', card: c(CardSuit.coppe, CardRank.re)),
        ),
        GameFailure.illegalCard,
      );
      expect(
        apply(
          s,
          PlayCardAction(playerId: 'p0', card: c(CardSuit.coppe, CardRank.sei)),
        ).currentPlayerId,
        'p1',
      );
    });
  });

  group('Immutability', () {
    test('applying an action never mutates the input state', () {
      final s = buildState(
        hands: [
          [c(CardSuit.coppe, CardRank.re), c(CardSuit.spade, CardRank.re)],
          [c(CardSuit.coppe, CardRank.tre)],
        ],
        top: co5,
      );
      final before = s.toJson();
      apply(
        s,
        PlayCardAction(playerId: 'p0', card: c(CardSuit.coppe, CardRank.re)),
      );
      apply(s, const DrawCardAction(playerId: 'p0'));
      expect(s.toJson(), before);
      expect(() => s.drawPile.add(co5), throwsUnsupportedError);
      expect(() => s.players.first.hand.clear(), throwsUnsupportedError);
    });

    test('the turn clock is stamped only when a caller supplies a time', () {
      final s = buildState(
        hands: [
          // Three cards, so the play is the only action and the clock is
          // stamped by it rather than by a preceding §16 announcement.
          [
            c(CardSuit.coppe, CardRank.re),
            c(CardSuit.spade, CardRank.re),
            c(CardSuit.bastoni, CardRank.sette),
          ],
          [c(CardSuit.coppe, CardRank.tre)],
        ],
        top: co5,
        rules: const GameRules(turnTimeLimitSeconds: 20),
      );
      final a = PlayCardAction(
        playerId: 'p0',
        card: c(CardSuit.coppe, CardRank.re),
      );
      final timed =
          (engine.applyAction(s, a, now: 5000) as ActionAccepted).state;
      expect(timed.turnStartedAt, 5000);
      expect(timed.turnDeadlineAt, 25000);
      final untimed = apply(s, a);
      expect(untimed.turnStartedAt, isNull);
      expect(untimed.turnDeadlineAt, isNull);
    });
  });
}
