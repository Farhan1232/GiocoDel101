import 'package:flutter_test/flutter_test.dart';
import 'package:gioco_del_101/features/game/domain/card_rank.dart';
import 'package:gioco_del_101/features/game/domain/card_suit.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_engine.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_event.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_failure.dart';
import 'package:gioco_del_101/features/game/domain/game_action.dart';
import 'package:gioco_del_101/features/game/domain/game_rules.dart';
import 'package:gioco_del_101/features/game/domain/game_state.dart';

import '../support/engine_harness.dart';

const engine = GameEngine();

void main() {
  final asso = c(CardSuit.coppe, CardRank.asso);
  final top = c(CardSuit.coppe, CardRank.cinque);

  ActionAccepted playAsso(GameState s, String actor) {
    final r = engine.applyAction(
      s,
      PlayCardAction(playerId: actor, card: asso),
    );
    expect(r, isA<ActionAccepted>());
    return r as ActionAccepted;
  }

  group('Asso = skip (§5)', () {
    test('2 players: the turn comes straight back', () {
      final s = buildState(
        hands: [
          [asso, c(CardSuit.coppe, CardRank.re)],
          [c(CardSuit.spade, CardRank.tre)],
        ],
        top: top,
      );
      final r = playAsso(s, 'p0');
      expect(r.state.currentPlayerId, 'p0');
      expect(r.state.turnNumber, 1);
      expect(r.events.whereType<TurnSkippedEvent>().single.playerId, 'p1');
      // And p0 can act again immediately.
      expect(engine.getPlayableCards(r.state, 'p0'), [
        c(CardSuit.coppe, CardRank.re),
      ]);
    });

    test('3 players: the next seat is skipped', () {
      final s = buildState(
        hands: [
          [asso, c(CardSuit.coppe, CardRank.re)],
          [c(CardSuit.spade, CardRank.tre)],
          [c(CardSuit.denari, CardRank.tre)],
        ],
        top: top,
      );
      final r = playAsso(s, 'p0');
      expect(r.state.currentPlayerId, 'p2');
      expect(r.events.whereType<TurnSkippedEvent>().single.playerId, 'p1');
    });

    test('3 players: from the last seat it wraps around and skips seat 0', () {
      final s = buildState(
        hands: [
          [c(CardSuit.spade, CardRank.tre)],
          [c(CardSuit.denari, CardRank.tre)],
          [asso, c(CardSuit.coppe, CardRank.re)],
        ],
        top: top,
        currentIndex: 2,
      );
      expect(playAsso(s, 'p2').state.currentPlayerId, 'p1');
    });

    test('4 players: skips one, lands on the seat after', () {
      final s = buildState(
        hands: [
          [asso, c(CardSuit.coppe, CardRank.re)],
          [c(CardSuit.spade, CardRank.tre)],
          [c(CardSuit.denari, CardRank.tre)],
          [c(CardSuit.bastoni, CardRank.tre)],
        ],
        top: top,
      );
      expect(playAsso(s, 'p0').state.currentPlayerId, 'p2');
      final fromLast = buildState(
        hands: [
          [c(CardSuit.spade, CardRank.tre)],
          [c(CardSuit.denari, CardRank.tre)],
          [c(CardSuit.bastoni, CardRank.tre)],
          [asso, c(CardSuit.coppe, CardRank.re)],
        ],
        top: top,
        currentIndex: 3,
      );
      expect(playAsso(fromLast, 'p3').state.currentPlayerId, 'p1');
    });

    test('4 players with one eliminated: the skip counts only live seats', () {
      final s = buildState(
        hands: [
          [asso, c(CardSuit.coppe, CardRank.re)],
          [c(CardSuit.spade, CardRank.tre)],
          [c(CardSuit.denari, CardRank.tre)],
          [c(CardSuit.bastoni, CardRank.tre)],
        ],
        top: top,
        eliminated: [false, true, false, false],
      );
      final r = playAsso(s, 'p0');
      expect(r.events.whereType<TurnSkippedEvent>().single.playerId, 'p2');
      expect(r.state.currentPlayerId, 'p3');
    });

    test('counter-clockwise: skips the seat before', () {
      final s = buildState(
        hands: [
          [asso, c(CardSuit.coppe, CardRank.re)],
          [c(CardSuit.spade, CardRank.tre)],
          [c(CardSuit.denari, CardRank.tre)],
          [c(CardSuit.bastoni, CardRank.tre)],
        ],
        top: top,
      ).copyWith(direction: TurnDirection.counterClockwise);
      final r = playAsso(s, 'p0');
      expect(r.events.whereType<TurnSkippedEvent>().single.playerId, 'p3');
      expect(r.state.currentPlayerId, 'p2');
    });

    test('an Asso is only legal on its suit or on another Asso', () {
      final s = buildState(
        hands: [
          [c(CardSuit.spade, CardRank.asso)],
          [c(CardSuit.denari, CardRank.tre)],
        ],
        top: top,
      );
      expect(
        engine
            .applyAction(
              s,
              PlayCardAction(
                playerId: 'p0',
                card: c(CardSuit.spade, CardRank.asso),
              ),
            )
            .failure,
        GameFailure.illegalCard,
      );
      final onAsso = buildState(
        hands: [
          [c(CardSuit.spade, CardRank.asso), c(CardSuit.spade, CardRank.re)],
          [c(CardSuit.denari, CardRank.tre)],
        ],
        top: c(CardSuit.coppe, CardRank.asso),
      );
      expect(
        engine
            .applyAction(
              onAsso,
              PlayCardAction(
                playerId: 'p0',
                card: c(CardSuit.spade, CardRank.asso),
              ),
            )
            .accepted,
        isTrue,
      );
    });

    test('an Asso as the last card ends the round; nobody is skipped', () {
      final s = buildState(
        hands: [
          [asso],
          [c(CardSuit.spade, CardRank.tre)],
        ],
        top: top,
      );
      final r = playAsso(s, 'p0');
      expect(r.state.status, GameStatus.roundOver);
      expect(r.events.whereType<TurnSkippedEvent>(), isEmpty);
    });

    test('acesPlayed statistic increments', () {
      final s = buildState(
        hands: [
          [asso, c(CardSuit.coppe, CardRank.re)],
          [c(CardSuit.spade, CardRank.tre)],
        ],
        top: top,
      );
      expect(playAsso(s, 'p0').state.stats.acesPlayed, 1);
    });
  });
}
