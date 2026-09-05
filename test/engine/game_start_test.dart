import 'package:flutter_test/flutter_test.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_engine.dart';
import 'package:gioco_del_101/features/game/domain/card_rank.dart';
import 'package:gioco_del_101/features/game/domain/card_suit.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_failure.dart';
import 'package:gioco_del_101/features/game/domain/game_card.dart';
import 'package:gioco_del_101/features/game/domain/game_player.dart';
import 'package:gioco_del_101/features/game/domain/game_rules.dart';
import 'package:gioco_del_101/features/game/domain/game_state.dart';
import 'package:gioco_del_101/features/game/domain/player_type.dart';

List<GamePlayer> seats(int n, {List<String>? ids}) => [
  for (var i = 0; i < n; i++)
    GamePlayer(
      id: ids == null ? 'p$i' : ids[i],
      name: 'P$i',
      type: i == 0 ? PlayerType.humanLocal : PlayerType.bot,
      avatarId: 'marco',
    ),
];

GameState start(
  int n, {
  GameRules rules = const GameRules(),
  int seed = 1,
  int startingSeat = 0,
}) => const GameEngine().createGame(
  gameId: 'g',
  players: seats(n),
  mode: GameMode.vsComputer,
  rules: rules,
  seed: seed,
  startingSeat: startingSeat,
);

void main() {
  group('Match creation', () {
    for (final n in [2, 3, 4]) {
      test('$n players: 5 cards each, one discard, rest in the stock', () {
        final s = start(n);
        expect(s.players, hasLength(n));
        for (final p in s.players) {
          expect(p.hand, hasLength(5));
        }
        expect(s.discardPile, hasLength(1));
        expect(s.drawPile, hasLength(40 - n * 5 - 1));
        expect(s.totalCards, 40);
        expect(s.status, GameStatus.awaitingAction);
        expect(s.round, 1);
        expect(s.version, 0);
        expect(s.pendingDrawCount, 0);
        expect(s.activeSuit, s.topCard.suit);
        expect(s.direction, TurnDirection.clockwise);
      });
    }

    test('every card is dealt exactly once', () {
      for (var seed = 0; seed < 25; seed++) {
        final s = start(4, seed: seed);
        final all = [
          ...s.drawPile,
          ...s.discardPile,
          for (final p in s.players) ...p.hand,
        ];
        expect(all, hasLength(40));
        expect(all.toSet(), hasLength(40));
      }
    });

    test('rejects one player and five players', () {
      expect(
        () => start(1),
        throwsA(
          isA<GameSetupException>().having(
            (e) => e.failure,
            'failure',
            GameFailure.invalidPlayerCount,
          ),
        ),
      );
      expect(
        () => start(5),
        throwsA(
          isA<GameSetupException>().having(
            (e) => e.failure,
            'failure',
            GameFailure.invalidPlayerCount,
          ),
        ),
      );
      expect(() => start(0), throwsA(isA<GameSetupException>()));
    });

    test('rules may narrow but never widen the 2–4 range', () {
      expect(
        () => start(2, rules: const GameRules(minPlayers: 3)),
        throwsA(isA<GameSetupException>()),
      );
      expect(
        () => start(4, rules: const GameRules(maxPlayers: 3)),
        throwsA(isA<GameSetupException>()),
      );
      expect(
        () => start(5, rules: const GameRules(maxPlayers: 9)),
        throwsA(isA<GameSetupException>()),
      );
    });

    test('rejects duplicate or empty player ids', () {
      expect(
        () => const GameEngine().createGame(
          gameId: 'g',
          players: seats(3, ids: ['a', 'b', 'a']),
          mode: GameMode.vsComputer,
          seed: 1,
        ),
        throwsA(
          isA<GameSetupException>().having(
            (e) => e.failure,
            'failure',
            GameFailure.duplicatePlayer,
          ),
        ),
      );
      expect(
        () => const GameEngine().createGame(
          gameId: 'g',
          players: seats(2, ids: ['', 'b']),
          mode: GameMode.vsComputer,
          seed: 1,
        ),
        throwsA(isA<GameSetupException>()),
      );
    });

    test('rejects a hand size the deck cannot cover', () {
      expect(
        () => start(4, rules: const GameRules(startingHandSize: 10)),
        throwsA(
          isA<GameSetupException>().having(
            (e) => e.failure,
            'failure',
            GameFailure.invalidRules,
          ),
        ),
      );
      expect(
        start(4, rules: const GameRules(startingHandSize: 9)).drawPile,
        hasLength(3),
      );
    });

    test('the first player is the requested seat', () {
      expect(start(3).currentPlayerId, 'p0');
      expect(start(3, startingSeat: 2).currentPlayerId, 'p2');
      expect(
        () => start(3, startingSeat: 3),
        throwsA(isA<GameSetupException>()),
      );
    });

    test('the opening discard is never an action card by default', () {
      for (var seed = 0; seed < 200; seed++) {
        expect(
          start(4, seed: seed).topCard.isAction,
          isFalse,
          reason: 'seed $seed',
        );
      }
    });

    test('StarterCardPolicy.anyCard turns up whatever comes', () {
      var sawAction = false;
      for (var seed = 0; seed < 200 && !sawAction; seed++) {
        final s = start(
          4,
          seed: seed,
          rules: const GameRules(starterCardPolicy: StarterCardPolicy.anyCard),
        );
        sawAction = s.topCard.isAction;
        // Whatever it is, its effect is not applied.
        expect(s.pendingDrawCount, 0);
        expect(s.status, GameStatus.awaitingAction);
      }
      expect(sawAction, isTrue);
    });

    test('the deal is a pure function of the seed', () {
      final a = start(3, seed: 99);
      final b = start(3, seed: 99);
      final c = start(3, seed: 100);
      expect(a.toJson(), b.toJson());
      expect(a.drawPile, isNot(equals(c.drawPile)));
    });

    test('hands are cleared from the supplied players', () {
      final dirty = [
        GamePlayer(
          id: 'p0',
          name: 'A',
          type: PlayerType.humanLocal,
          avatarId: 'marco',
          hand: const [GameCard(CardSuit.coppe, CardRank.re)],
        ),
        GamePlayer(
          id: 'p1',
          name: 'B',
          type: PlayerType.bot,
          avatarId: 'marco',
        ),
      ];
      final s = const GameEngine().createGame(
        gameId: 'g',
        players: dirty,
        mode: GameMode.vsComputer,
        seed: 3,
      );
      expect(s.totalCards, 40);
      expect(s.players.first.hand, hasLength(5));
    });

    test('scores carry over into a new match (daily challenge handicap)', () {
      final players = [
        GamePlayer(
          id: 'p0',
          name: 'A',
          type: PlayerType.humanLocal,
          avatarId: 'marco',
          score: 30,
        ),
        GamePlayer(
          id: 'p1',
          name: 'B',
          type: PlayerType.bot,
          avatarId: 'marco',
        ),
      ];
      final s = const GameEngine().createGame(
        gameId: 'daily',
        players: players,
        mode: GameMode.vsComputer,
        seed: 3,
        isDailyChallenge: true,
      );
      expect(s.players.first.score, 30);
      expect(s.isDailyChallenge, isTrue);
      expect(s.gameId, 'daily');
    });

    test('a supplied clock stamps the first turn', () {
      final s = const GameEngine().createGame(
        gameId: 'g',
        players: seats(2),
        mode: GameMode.vsComputer,
        seed: 3,
        rules: const GameRules(turnTimeLimitSeconds: 30),
        now: 1000,
      );
      expect(s.turnStartedAt, 1000);
      expect(s.turnDeadlineAt, 31000);
      expect(start(2).turnDeadlineAt, isNull);
    });
  });
}
