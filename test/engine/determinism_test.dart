import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:gioco_del_101/features/game/domain/card_suit.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_engine.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_failure.dart';
import 'package:gioco_del_101/features/game/domain/game_action.dart';
import 'package:gioco_del_101/features/game/domain/game_state.dart';
import 'package:gioco_del_101/features/game/domain/card_rank.dart';

import '../support/engine_harness.dart';

const engine = GameEngine();

/// Drives a whole match with a scripted policy and returns the action log
/// plus every intermediate state's JSON.
(List<GameAction>, List<String>) playScripted(int seed, {int policySeed = 5}) {
  var s = engine.createGame(
    gameId: 'det-$seed',
    players: buildState(
      hands: const [[], [], []],
      top: c(CardSuit.coppe, CardRank.cinque),
    ).players,
    mode: GameMode.vsComputer,
    seed: seed,
  );
  final rng = Random(policySeed);
  final actions = <GameAction>[];
  final snapshots = <String>[jsonEncode(s.toJson())];
  var steps = 0;
  while (!s.isFinished && steps++ < 20000) {
    GameAction a;
    if (s.status == GameStatus.roundOver) {
      a = const StartNextRoundAction(playerId: GameEngine.systemActorId);
    } else if (s.status == GameStatus.awaitingSuitChoice) {
      a = ChooseSuitAction(
        playerId: s.currentPlayerId,
        suit: CardSuit.values[rng.nextInt(4)],
      );
    } else {
      final me = s.currentPlayerId;
      final playable = engine.getPlayableCards(s, me);
      if (playable.isNotEmpty && rng.nextInt(4) != 0) {
        a = PlayCardAction(
          playerId: me,
          card: playable[rng.nextInt(playable.length)],
          baseVersion: s.version,
        );
      } else if (engine.canDraw(s)) {
        a = DrawCardAction(playerId: me, baseVersion: s.version);
      } else {
        a = PassAction(playerId: me, baseVersion: s.version);
      }
    }
    // §16 — the random driver announces exactly where a table would, so
    // the log it produces is a log a real match could produce.
    if (a is PlayCardAction && engine.canDeclareLastCard(s, a.playerId)) {
      final declare = DeclareLastCardAction(
        playerId: a.playerId,
        baseVersion: s.version,
      );
      s = (engine.applyAction(s, declare) as ActionAccepted).state;
      actions.add(declare);
      snapshots.add(jsonEncode(s.toJson()));
      a = PlayCardAction(
        playerId: a.playerId,
        card: a.card,
        chosenSuit: a.chosenSuit,
        baseVersion: s.version,
      );
    }
    final r = engine.applyAction(s, a);
    expect(r, isA<ActionAccepted>(), reason: '$a on $s → $r');
    s = (r as ActionAccepted).state;
    actions.add(a);
    snapshots.add(jsonEncode(s.toJson()));
  }
  expect(s.isFinished, isTrue);
  return (actions, snapshots);
}

void main() {
  group('Determinism', () {
    test('the same state and action always produce the same state', () {
      final s = buildState(
        hands: [
          // Three cards: purity is the point here, not §16, and a play from
          // two would need the announcement applied first.
          [
            c(CardSuit.coppe, CardRank.re),
            c(CardSuit.spade, CardRank.re),
            c(CardSuit.bastoni, CardRank.sette),
          ],
          [c(CardSuit.denari, CardRank.tre)],
        ],
        top: c(CardSuit.coppe, CardRank.cinque),
      );
      final a = PlayCardAction(
        playerId: 'p0',
        card: c(CardSuit.coppe, CardRank.re),
      );
      final x = engine.applyAction(s, a) as ActionAccepted;
      final y = engine.applyAction(s, a) as ActionAccepted;
      expect(jsonEncode(x.state.toJson()), jsonEncode(y.state.toJson()));
      expect(
        x.events.map((e) => e.runtimeType),
        y.events.map((e) => e.runtimeType),
      );
    });

    test('a whole match replays identically from its seed and action log', () {
      final (actions, snapshots) = playScripted(1234);
      // Replay the recorded actions against a fresh game.
      var s = engine.createGame(
        gameId: 'det-1234',
        players: buildState(
          hands: const [[], [], []],
          top: c(CardSuit.coppe, CardRank.cinque),
        ).players,
        mode: GameMode.vsComputer,
        seed: 1234,
      );
      expect(jsonEncode(s.toJson()), snapshots.first);
      for (var i = 0; i < actions.length; i++) {
        s = (engine.applyAction(s, actions[i]) as ActionAccepted).state;
        expect(
          jsonEncode(s.toJson()),
          snapshots[i + 1],
          reason: 'diverged at action $i: ${actions[i]}',
        );
      }
      expect(actions.length, greaterThan(50));
    });

    test('two independent runs of the same seeds are byte-identical', () {
      final a = playScripted(77);
      final b = playScripted(77);
      expect(a.$2, b.$2);
      final other = playScripted(78);
      expect(other.$2.first, isNot(equals(a.$2.first)));
    });

    test('a replayed action against the wrong version is refused', () {
      final (actions, snapshots) = playScripted(9);
      final mid = GameState.fromJson(
        jsonDecode(snapshots[10]) as Map<String, dynamic>,
      );
      // actions[10] was built against version 10; actions[11] against 11.
      expect(engine.applyAction(mid, actions[10]).accepted, isTrue);
      final r = engine.applyAction(mid, actions[11]);
      expect(r.accepted, isFalse);
      expect(r.failure, GameFailure.staleState);
    });

    test('a state restored from JSON continues exactly like the original', () {
      final (actions, snapshots) = playScripted(42);
      final cut = snapshots.length ~/ 2;
      var restored = GameState.fromJson(
        jsonDecode(snapshots[cut]) as Map<String, dynamic>,
      );
      for (var i = cut; i < actions.length; i++) {
        restored =
            (engine.applyAction(restored, actions[i]) as ActionAccepted).state;
        expect(jsonEncode(restored.toJson()), snapshots[i + 1]);
      }
    });

    test('the engine holds no state of its own', () {
      final s = buildState(
        hands: [
          // Three cards: purity is the point here, not §16, and a play from
          // two would need the announcement applied first.
          [
            c(CardSuit.coppe, CardRank.re),
            c(CardSuit.spade, CardRank.re),
            c(CardSuit.bastoni, CardRank.sette),
          ],
          [c(CardSuit.denari, CardRank.tre)],
        ],
        top: c(CardSuit.coppe, CardRank.cinque),
      );
      final a = PlayCardAction(
        playerId: 'p0',
        card: c(CardSuit.coppe, CardRank.re),
      );
      const e1 = GameEngine();
      const e2 = GameEngine();
      expect(
        jsonEncode((e1.applyAction(s, a) as ActionAccepted).state.toJson()),
        jsonEncode((e2.applyAction(s, a) as ActionAccepted).state.toJson()),
      );
    });
  });
}
