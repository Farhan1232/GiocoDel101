import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_session.dart';
import 'package:gioco_del_101/features/game/domain/card_rank.dart';
import 'package:gioco_del_101/features/game/domain/card_suit.dart';
import 'package:gioco_del_101/features/game/domain/game_card.dart';
import 'package:gioco_del_101/features/game/domain/game_player.dart';
import 'package:gioco_del_101/features/game/domain/game_state.dart';
import 'package:gioco_del_101/features/game/domain/player_type.dart';

import 'support/engine_harness.dart';

void main() {
  group('Deck exhaustion (§18)', () {
    test('recycles the discard pile and keeps the visible top card', () {
      final buried = [
        c(CardSuit.bastoni, CardRank.tre),
        c(CardSuit.bastoni, CardRank.quattro),
        c(CardSuit.bastoni, CardRank.sei),
      ];
      final e = buildEngine(
        hands: [
          [c(CardSuit.spade, CardRank.sette)],
          [c(CardSuit.denari, CardRank.tre)],
        ],
        top: c(CardSuit.coppe, CardRank.cinque),
        discardBelowTop: buried,
        drawPile: const [],
        fillDeck: false,
      );
      expect(e.state.drawPile, isEmpty);

      e.drawCard();

      expect(
        e.state.discardPile.last,
        c(CardSuit.coppe, CardRank.cinque),
        reason: 'the top card stays on the table',
      );
      expect(e.state.discardPile, hasLength(1));
      // Three buried cards were recycled; one of them was just drawn.
      expect(e.state.drawPile, hasLength(2));
      expect(e.state.playerById('p0')!.hand, hasLength(2));
    });

    test('survives having nothing left to recycle', () {
      final e = buildEngine(
        hands: [
          [c(CardSuit.spade, CardRank.sette)],
          [c(CardSuit.denari, CardRank.tre)],
        ],
        top: c(CardSuit.coppe, CardRank.cinque),
        drawPile: const [],
        fillDeck: false,
      );
      expect(e.drawCard().accepted, isTrue);
      expect(e.state.playerById('p0')!.hand, hasLength(1));
      expect(e.currentPlayer.id, 'p1', reason: 'the turn still moves on');
    });

    test('a penalty draw takes what it can when the table runs dry', () {
      final e = buildEngine(
        hands: [
          [c(CardSuit.coppe, CardRank.re)],
          [c(CardSuit.spade, CardRank.sette)],
        ],
        top: c(CardSuit.coppe, CardRank.due),
        discardBelowTop: [c(CardSuit.bastoni, CardRank.tre)],
        drawPile: const [],
        currentIndex: 1,
        pendingPenalty: 6,
        chainLength: 3,
        fillDeck: false,
      );
      e.drawCard();
      // Only one card was recyclable, so only one could be handed over.
      expect(e.state.playerById('p1')!.hand, hasLength(2));
      expect(e.state.pendingDrawCount, 0);
      // §6b — even a chain the table could not fully pay keeps the turn with
      // p1. What matters is that the table never stalls: with nothing legal
      // to continue with, p1 can still pass out of the turn.
      expect(e.currentPlayer.id, 'p1');
      expect(e.playableCardsFor(e.currentPlayer), isEmpty);
      expect(e.canDraw, isFalse);
      expect(e.canEndTurn, isTrue);
      e.endTurn();
      expect(e.currentPlayer.id, 'p0');
    });
  });

  group('No infinite loops (§52)', () {
    test('a full random match always terminates', () {
      for (var seed = 0; seed < 40; seed++) {
        final rng = Random(seed);
        final players = [
          for (var i = 0; i < 2 + (seed % 3); i++)
            GamePlayer(
              id: 'p$i',
              name: 'P$i',
              type: i == 0 ? PlayerType.humanLocal : PlayerType.bot,
              avatarId: 'marco',
              difficulty: BotDifficulty.easy,
            ),
        ];
        final e = GameSession.newMatch(
          gameId: 't',
          players: players,
          mode: GameMode.vsComputer,
          seed: rng.nextInt(1 << 30),
        );

        var steps = 0;
        while (!e.state.isFinished && steps++ < 200000) {
          if (e.state.status == GameStatus.roundOver) {
            e.startNextRound();
            continue;
          }
          if (e.state.status == GameStatus.awaitingSuitChoice) {
            e.chooseSuit(CardSuit.values[rng.nextInt(4)]);
            continue;
          }
          final playable = e.playableCardsFor(e.currentPlayer);
          if (playable.isNotEmpty) {
            e.autoPlayCard(playable[rng.nextInt(playable.length)]);
          } else if (e.canDraw) {
            e.drawCard();
            if (e.state.drawnCard == null && e.canEndTurn) e.endTurn();
          } else if (e.canEndTurn) {
            e.endTurn();
          } else {
            fail('Seed $seed deadlocked with no legal action');
          }
        }
        expect(e.state.isFinished, isTrue, reason: 'seed $seed never finished');
        expect(steps, lessThan(200000), reason: 'seed $seed ran away');
      }
    });

    test('card conservation holds across a whole round', () {
      final rng = Random(99);
      final players = [
        for (var i = 0; i < 4; i++)
          GamePlayer(
            id: 'p$i',
            name: 'P$i',
            type: PlayerType.bot,
            avatarId: 'marco',
          ),
      ];
      final e = GameSession.newMatch(
        gameId: 't',
        players: players,
        mode: GameMode.vsComputer,
        seed: rng.nextInt(1 << 30),
      );

      int total() =>
          e.state.drawPile.length +
          e.state.discardPile.length +
          e.state.players.fold<int>(0, (s, p) => s + p.hand.length);

      expect(total(), 40);
      var steps = 0;
      while (e.state.status != GameStatus.roundOver && steps++ < 5000) {
        if (e.state.status == GameStatus.awaitingSuitChoice) {
          e.chooseSuit(CardSuit.values[rng.nextInt(4)]);
        } else {
          final playable = e.playableCardsFor(e.currentPlayer);
          if (playable.isNotEmpty) {
            e.autoPlayCard(playable.first);
          } else {
            e.drawCard();
            if (e.state.drawnCard == null && e.canEndTurn) e.endTurn();
          }
        }
        expect(total(), 40, reason: 'a card went missing after step $steps');
        expect(e.state.discardPile, isNotEmpty);
      }
    });
  });

  group('Corrupt saves (§52)', () {
    test('a match with one seat is rejected', () {
      expect(
        () => GameState.fromJson({
          'players': [
            {'id': 'p0', 'name': 'Solo', 'type': 'humanLocal', 'hand': []},
          ],
          'discardPile': ['coppe_cinque'],
          'activeSuit': 'coppe',
        }),
        throwsFormatException,
      );
    });

    test('an empty discard pile is rejected', () {
      expect(
        () => GameState.fromJson({
          'players': [
            {'id': 'p0', 'name': 'A', 'type': 'humanLocal', 'hand': []},
            {'id': 'p1', 'name': 'B', 'type': 'bot', 'hand': []},
          ],
          'discardPile': [],
          'activeSuit': 'coppe',
        }),
        throwsFormatException,
      );
    });

    test('a turn cursor outside the table is rejected', () {
      expect(
        () => GameState.fromJson({
          'players': [
            {'id': 'p0', 'name': 'A', 'type': 'humanLocal', 'hand': []},
            {'id': 'p1', 'name': 'B', 'type': 'bot', 'hand': []},
          ],
          'discardPile': ['coppe_cinque'],
          'activeSuit': 'coppe',
          'currentSeat': 9,
        }),
        throwsFormatException,
      );
    });

    test('a malformed card token is rejected', () {
      expect(() => GameCard.fromStorage('nonsense'), throwsFormatException);
    });
  });

  group('Save and restore (§49)', () {
    test('an in-flight match round-trips exactly', () {
      final rng = Random(5);
      final players = [
        for (var i = 0; i < 3; i++)
          GamePlayer(
            id: 'p$i',
            name: 'P$i',
            type: i == 0 ? PlayerType.humanLocal : PlayerType.bot,
            avatarId: 'sofia',
            difficulty: BotDifficulty.hard,
            personality: BotPersonality.tactical,
          ),
      ];
      final e = GameSession.newMatch(
        gameId: 't',
        players: players,
        mode: GameMode.passAndPlay,
        seed: rng.nextInt(1 << 30),
      );
      // Advance a few turns so the state is genuinely mid-game.
      for (var i = 0; i < 12; i++) {
        if (e.state.status == GameStatus.awaitingSuitChoice) {
          e.chooseSuit(CardSuit.denari);
          continue;
        }
        if (e.state.status != GameStatus.awaitingAction) break;
        final playable = e.playableCardsFor(e.currentPlayer);
        if (playable.isNotEmpty) {
          e.autoPlayCard(playable.first);
        } else {
          e.drawCard();
          if (e.state.drawnCard == null && e.canEndTurn) e.endTurn();
        }
      }

      final restored = GameState.fromJson(e.state.toJson());

      expect(
        restored.players.map((p) => p.id),
        e.state.players.map((p) => p.id),
      );
      for (var i = 0; i < restored.players.length; i++) {
        expect(restored.players[i].hand, e.state.players[i].hand);
        expect(restored.players[i].score, e.state.players[i].score);
        expect(restored.players[i].difficulty, BotDifficulty.hard);
      }
      expect(restored.drawPile, e.state.drawPile);
      expect(restored.discardPile, e.state.discardPile);
      expect(restored.activeSuit, e.state.activeSuit);
      expect(restored.currentSeat, e.state.currentSeat);
      expect(restored.pendingDrawCount, e.state.pendingDrawCount);
      expect(restored.chainLength, e.state.chainLength);
      expect(restored.mode, GameMode.passAndPlay);
      expect(restored.round, e.state.round);
      expect(restored.history.length, e.state.history.length);
      expect(restored.rules.toJson(), e.state.rules.toJson());
    });

    test('play continues correctly from a restored state', () {
      final e = buildEngine(
        hands: [
          [c(CardSuit.coppe, CardRank.re), c(CardSuit.spade, CardRank.due)],
          [c(CardSuit.spade, CardRank.tre)],
        ],
        top: c(CardSuit.coppe, CardRank.cinque),
        drawPile: [c(CardSuit.bastoni, CardRank.sei)],
      );
      final resumed = GameSession(GameState.fromJson(e.state.toJson()));
      expect(resumed.canPlay(c(CardSuit.coppe, CardRank.re)), isTrue);
      resumed.autoPlayCard(c(CardSuit.coppe, CardRank.re));
      expect(resumed.currentPlayer.id, 'p1');
      expect(resumed.state.topCard, c(CardSuit.coppe, CardRank.re));
    });

    test('a suit choice interrupted by a lifecycle event survives', () {
      final e = buildEngine(
        hands: [
          [c(CardSuit.spade, CardRank.cavallo), c(CardSuit.spade, CardRank.re)],
          [c(CardSuit.denari, CardRank.tre)],
        ],
        top: c(CardSuit.coppe, CardRank.cinque),
      );
      e.autoPlayCard(c(CardSuit.spade, CardRank.cavallo));
      expect(e.state.status, GameStatus.awaitingSuitChoice);

      final resumed = GameSession(GameState.fromJson(e.state.toJson()));
      expect(resumed.state.status, GameStatus.awaitingSuitChoice);
      expect(resumed.currentPlayer.id, 'p0');
      resumed.chooseSuit(CardSuit.coppe);
      expect(resumed.state.activeSuit, CardSuit.coppe);
      expect(resumed.currentPlayer.id, 'p1');
    });

    test('the action history stays bounded', () {
      final rng = Random(11);
      final players = [
        for (var i = 0; i < 2; i++)
          GamePlayer(
            id: 'p$i',
            name: 'P$i',
            type: PlayerType.bot,
            avatarId: 'luca',
          ),
      ];
      final e = GameSession.newMatch(
        gameId: 't',
        players: players,
        mode: GameMode.vsComputer,
        seed: rng.nextInt(1 << 30),
      );
      var steps = 0;
      while (!e.state.isFinished && steps++ < 3000) {
        if (e.state.status == GameStatus.roundOver) {
          e.startNextRound();
          continue;
        }
        if (e.state.status == GameStatus.awaitingSuitChoice) {
          e.chooseSuit(CardSuit.values[rng.nextInt(4)]);
          continue;
        }
        final playable = e.playableCardsFor(e.currentPlayer);
        if (playable.isNotEmpty) {
          e.autoPlayCard(playable.first);
        } else {
          e.drawCard();
          if (e.state.drawnCard == null && e.canEndTurn) e.endTurn();
        }
        expect(
          e.state.history.length,
          lessThanOrEqualTo(GameState.historyLimit),
        );
      }
    });
  });
}
