import 'package:flutter_test/flutter_test.dart';
import 'package:gioco_del_101/features/game/domain/card_rank.dart';
import 'package:gioco_del_101/features/game/domain/card_suit.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_engine.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_failure.dart';
import 'package:gioco_del_101/features/game/domain/game_action.dart';
import 'package:gioco_del_101/features/game/domain/game_state.dart';

import '../support/engine_harness.dart';

void main() {
  const engine = GameEngine();

  group('ForfeitAction (§15, online abandonment)', () {
    test('keeps the 40-card invariant and eliminates the seat', () {
      final s = buildState(
        hands: [
          [c(CardSuit.coppe, CardRank.re), c(CardSuit.spade, CardRank.tre)],
          [c(CardSuit.denari, CardRank.tre)],
          [c(CardSuit.bastoni, CardRank.sette)],
        ],
        top: c(CardSuit.coppe, CardRank.cinque),
      );
      final r = engine.applyAction(s, const ForfeitAction(playerId: 'p0'));
      final next = (r as ActionAccepted).state;
      expect(next.totalCards, 40);
      expect(next.playerById('p0')!.eliminated, isTrue);
      expect(next.playerById('p0')!.hand, isEmpty);
      expect(next.currentPlayerId, 'p1');
      expect(next.drawPile.first, c(CardSuit.coppe, CardRank.re));
    });

    test(
      'while a suit is pending: the previous suit stands, play moves on',
      () {
        final s = buildState(
          hands: [
            [c(CardSuit.coppe, CardRank.re)],
            [c(CardSuit.denari, CardRank.tre)],
            [c(CardSuit.bastoni, CardRank.sette)],
          ],
          top: c(CardSuit.spade, CardRank.cavallo),
          activeSuit: CardSuit.denari,
          status: GameStatus.awaitingSuitChoice,
        );
        final next =
            (engine.applyAction(s, const ForfeitAction(playerId: 'p0'))
                    as ActionAccepted)
                .state;
        expect(next.status, GameStatus.awaitingAction);
        expect(next.activeSuit, CardSuit.denari);
        expect(next.currentPlayerId, 'p1');
      },
    );

    test('between rounds the seat is simply skipped by the next deal', () {
      final s = buildState(
        hands: [
          [],
          [c(CardSuit.denari, CardRank.tre)],
          [c(CardSuit.bastoni, CardRank.sette)],
        ],
        top: c(CardSuit.coppe, CardRank.cinque),
        status: GameStatus.roundOver,
      ).copyWith(roundWinnerId: 'p0');
      final after =
          (engine.applyAction(s, const ForfeitAction(playerId: 'p1'))
                  as ActionAccepted)
              .state;
      expect(after.status, GameStatus.roundOver);
      final dealt =
          (engine.applyAction(after, const StartNextRoundAction(playerId: 'p0'))
                  as ActionAccepted)
              .state;
      expect(dealt.playerById('p1')!.hand, isEmpty);
      expect(dealt.playerById('p0')!.hand.length, 5);
      expect(dealt.playerById('p2')!.hand.length, 5);
    });

    test('is refused after the match is over and by unknown seats', () {
      final s = buildState(
        hands: [
          [c(CardSuit.coppe, CardRank.re)],
          [c(CardSuit.denari, CardRank.tre)],
        ],
        top: c(CardSuit.coppe, CardRank.cinque),
      );
      expect(
        engine.validateAction(s, const ForfeitAction(playerId: 'ghost')),
        GameFailure.invalidPlayer,
      );
      final finished = s.copyWith(status: GameStatus.finished, winnerId: 'p0');
      expect(
        engine.validateAction(finished, const ForfeitAction(playerId: 'p1')),
        GameFailure.gameFinished,
      );
      expect(
        engine.validateAction(
          s,
          const ForfeitAction(playerId: 'p1', baseVersion: 3),
        ),
        GameFailure.staleState,
      );
    });

    test('round-trips through JSON like every other action', () {
      const a = ForfeitAction(playerId: 'p1', baseVersion: 8);
      expect(GameAction.fromJson(a.toJson()), a);
    });
  });

  group('Redacted state (the online wire format)', () {
    test('parses handCount / drawPileCount and merges the own hand', () {
      final real = buildState(
        hands: [
          [c(CardSuit.coppe, CardRank.re), c(CardSuit.spade, CardRank.tre)],
          [c(CardSuit.denari, CardRank.tre)],
        ],
        top: c(CardSuit.coppe, CardRank.cinque),
      );
      // Mirror app_private.redact_game_state.
      final json = real.toJson();
      json.remove('seed');
      json.remove('drawnCard');
      json.remove('history');
      json['drawPileCount'] = (json.remove('drawPile') as List).length;
      json['players'] = [
        for (final p in json['players'] as List)
          {
            ...p as Map<String, dynamic>,
            'handCount': (p['hand'] as List).length,
          }..remove('hand'),
      ];
      final redacted = GameState.fromJson(json);
      expect(redacted.isRedacted, isTrue);
      expect(redacted.drawPileCount, 36);
      expect(redacted.drawPile, isEmpty);
      expect(redacted.players[0].cardCount, 2);
      expect(redacted.players[0].isConcealed, isTrue);
      expect(redacted.players[1].cardCount, 1);

      final merged = redacted.withPlayer(
        redacted.players[0].copyWith(hand: real.players[0].hand),
      );
      expect(merged.players[0].isConcealed, isFalse);
      expect(merged.players[0].cardCount, 2);
      expect(merged.players[1].cardCount, 1);
      // Legality can be asked on the merged view, exactly as offline.
      expect(engine.getPlayableCards(merged, 'p0'), [
        c(CardSuit.coppe, CardRank.re),
      ]);
      expect(engine.canDraw(merged), isTrue);
    });

    test('a real state never emits the concealed keys', () {
      final real = buildState(
        hands: [
          [c(CardSuit.coppe, CardRank.re)],
          [c(CardSuit.denari, CardRank.tre)],
        ],
        top: c(CardSuit.coppe, CardRank.cinque),
      );
      final json = real.toJson();
      expect(json.containsKey('drawPileCount'), isFalse);
      expect((json['players'] as List).first, isNot(contains('handCount')));
      expect(real.isRedacted, isFalse);
    });
  });
}
