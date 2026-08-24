import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:gioco_del_101/game/engine/game_engine.dart';
import 'package:gioco_del_101/models/card_rank.dart';
import 'package:gioco_del_101/models/card_suit.dart';
import 'package:gioco_del_101/models/game_card.dart';
import 'package:gioco_del_101/models/game_player.dart';
import 'package:gioco_del_101/models/match_state.dart';
import 'package:gioco_del_101/models/player_type.dart';
import 'package:gioco_del_101/models/round_state.dart';

import 'support/engine_harness.dart';

void main() {
  group('Deck exhaustion (§18)', () {
    test('recycles the discard pile and keeps the visible top card', () {
      final buried = [
        c(CardSuit.bastoni, CardRank.three),
        c(CardSuit.bastoni, CardRank.four),
        c(CardSuit.bastoni, CardRank.six),
      ];
      final e = buildEngine(
        hands: [
          [c(CardSuit.spade, CardRank.seven)],
          [c(CardSuit.denari, CardRank.three)],
        ],
        top: c(CardSuit.coppe, CardRank.five),
        discardBelowTop: buried,
        drawPile: const [],
      );
      expect(e.round.drawPile, isEmpty);

      e.drawCard();

      expect(e.round.discardPile.last, c(CardSuit.coppe, CardRank.five),
          reason: 'the top card stays on the table');
      expect(e.round.discardPile, hasLength(1));
      // Three buried cards were recycled; one of them was just drawn.
      expect(e.round.drawPile, hasLength(2));
      expect(e.state.playerById('p0')!.hand, hasLength(2));
    });

    test('survives having nothing left to recycle', () {
      final e = buildEngine(
        hands: [
          [c(CardSuit.spade, CardRank.seven)],
          [c(CardSuit.denari, CardRank.three)],
        ],
        top: c(CardSuit.coppe, CardRank.five),
        drawPile: const [],
      );
      expect(e.drawCard().accepted, isTrue);
      expect(e.state.playerById('p0')!.hand, hasLength(1));
      expect(e.currentPlayer.id, 'p1', reason: 'the turn still moves on');
    });

    test('a penalty draw takes what it can when the table runs dry', () {
      final e = buildEngine(
        hands: [
          [c(CardSuit.coppe, CardRank.re)],
          [c(CardSuit.spade, CardRank.seven)],
        ],
        top: c(CardSuit.coppe, CardRank.two),
        discardBelowTop: [c(CardSuit.bastoni, CardRank.three)],
        drawPile: const [],
        currentIndex: 1,
        pendingPenalty: 6,
        chainLength: 3,
      );
      e.drawCard();
      // Only one card was recyclable, so only one could be handed over.
      expect(e.state.playerById('p1')!.hand, hasLength(2));
      expect(e.round.pendingPenalty, 0);
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
        final e = GameEngine.newMatch(
          players: players,
          mode: GameMode.vsComputer,
          random: rng,
        );

        var steps = 0;
        while (!e.state.matchOver && steps++ < 200000) {
          if (e.round.phase == TurnPhase.roundOver) {
            e.startNextRound();
            continue;
          }
          if (e.round.phase == TurnPhase.awaitingSuitChoice) {
            e.chooseSuit(CardSuit.values[rng.nextInt(4)]);
            continue;
          }
          final playable = e.playableCardsFor(e.currentPlayer);
          if (playable.isNotEmpty) {
            e.playCard(playable[rng.nextInt(playable.length)]);
          } else if (e.canDraw) {
            e.drawCard();
            if (e.round.drawnCard == null && e.canEndTurn) e.endTurn();
          } else if (e.canEndTurn) {
            e.endTurn();
          } else {
            fail('Seed $seed deadlocked with no legal action');
          }
        }
        expect(e.state.matchOver, isTrue, reason: 'seed $seed never finished');
        expect(steps, lessThan(200000), reason: 'seed $seed ran away');
      }
    });

    test('card conservation holds across a whole round', () {
      final rng = Random(99);
      final players = [
        for (var i = 0; i < 4; i++)
          GamePlayer(
              id: 'p$i', name: 'P$i', type: PlayerType.bot, avatarId: 'marco'),
      ];
      final e = GameEngine.newMatch(
          players: players, mode: GameMode.vsComputer, random: rng);

      int total() =>
          e.round.drawPile.length +
          e.round.discardPile.length +
          e.state.players.fold<int>(0, (s, p) => s + p.hand.length);

      expect(total(), 40);
      var steps = 0;
      while (e.round.phase != TurnPhase.roundOver && steps++ < 5000) {
        if (e.round.phase == TurnPhase.awaitingSuitChoice) {
          e.chooseSuit(CardSuit.values[rng.nextInt(4)]);
        } else {
          final playable = e.playableCardsFor(e.currentPlayer);
          if (playable.isNotEmpty) {
            e.playCard(playable.first);
          } else {
            e.drawCard();
            if (e.round.drawnCard == null && e.canEndTurn) e.endTurn();
          }
        }
        expect(total(), 40, reason: 'a card went missing after step $steps');
        expect(e.round.discardPile, isNotEmpty);
      }
    });
  });

  group('Corrupt saves (§52)', () {
    test('a match with one seat is rejected', () {
      expect(
        () => MatchState.fromJson({
          'players': [
            {'id': 'p0', 'name': 'Solo', 'type': 'humanLocal', 'hand': []}
          ],
          'round': {'discardPile': ['coppe_five'], 'activeSuit': 'coppe'},
        }),
        throwsFormatException,
      );
    });

    test('an empty discard pile is rejected', () {
      expect(
        () => RoundState.fromJson({'discardPile': [], 'activeSuit': 'coppe'}),
        throwsFormatException,
      );
    });

    test('a turn cursor outside the table is rejected', () {
      expect(
        () => MatchState.fromJson({
          'players': [
            {'id': 'p0', 'name': 'A', 'type': 'humanLocal', 'hand': []},
            {'id': 'p1', 'name': 'B', 'type': 'bot', 'hand': []},
          ],
          'round': {
            'discardPile': ['coppe_five'],
            'activeSuit': 'coppe',
            'currentIndex': 9,
          },
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
      final e = GameEngine.newMatch(
        players: players,
        mode: GameMode.passAndPlay,
        random: rng,
      );
      // Advance a few turns so the state is genuinely mid-game.
      for (var i = 0; i < 12; i++) {
        if (e.round.phase == TurnPhase.awaitingSuitChoice) {
          e.chooseSuit(CardSuit.denari);
          continue;
        }
        if (e.round.phase != TurnPhase.awaitingAction) break;
        final playable = e.playableCardsFor(e.currentPlayer);
        if (playable.isNotEmpty) {
          e.playCard(playable.first);
        } else {
          e.drawCard();
          if (e.round.drawnCard == null && e.canEndTurn) e.endTurn();
        }
      }

      final restored = MatchState.fromJson(e.state.toJson());

      expect(restored.players.map((p) => p.id), e.state.players.map((p) => p.id));
      for (var i = 0; i < restored.players.length; i++) {
        expect(restored.players[i].hand, e.state.players[i].hand);
        expect(restored.players[i].score, e.state.players[i].score);
        expect(restored.players[i].difficulty, BotDifficulty.hard);
      }
      expect(restored.round.drawPile, e.round.drawPile);
      expect(restored.round.discardPile, e.round.discardPile);
      expect(restored.round.activeSuit, e.round.activeSuit);
      expect(restored.round.currentIndex, e.round.currentIndex);
      expect(restored.round.pendingPenalty, e.round.pendingPenalty);
      expect(restored.round.chainLength, e.round.chainLength);
      expect(restored.mode, GameMode.passAndPlay);
      expect(restored.roundNumber, e.state.roundNumber);
      expect(restored.history.length, e.state.history.length);
      expect(restored.rules.toJson(), e.state.rules.toJson());
    });

    test('play continues correctly from a restored state', () {
      final e = buildEngine(
        hands: [
          [c(CardSuit.coppe, CardRank.re), c(CardSuit.spade, CardRank.two)],
          [c(CardSuit.spade, CardRank.three)],
        ],
        top: c(CardSuit.coppe, CardRank.five),
        drawPile: [c(CardSuit.bastoni, CardRank.six)],
      );
      final resumed =
          GameEngine.fromState(MatchState.fromJson(e.state.toJson()));
      expect(resumed.canPlay(c(CardSuit.coppe, CardRank.re)), isTrue);
      resumed.playCard(c(CardSuit.coppe, CardRank.re));
      expect(resumed.currentPlayer.id, 'p1');
      expect(resumed.round.topCard, c(CardSuit.coppe, CardRank.re));
    });

    test('a suit choice interrupted by a lifecycle event survives', () {
      final e = buildEngine(
        hands: [
          [c(CardSuit.spade, CardRank.cavallo), c(CardSuit.spade, CardRank.re)],
          [c(CardSuit.denari, CardRank.three)],
        ],
        top: c(CardSuit.coppe, CardRank.five),
      );
      e.playCard(c(CardSuit.spade, CardRank.cavallo));
      expect(e.round.phase, TurnPhase.awaitingSuitChoice);

      final resumed =
          GameEngine.fromState(MatchState.fromJson(e.state.toJson()));
      expect(resumed.round.phase, TurnPhase.awaitingSuitChoice);
      expect(resumed.currentPlayer.id, 'p0');
      resumed.chooseSuit(CardSuit.coppe);
      expect(resumed.round.activeSuit, CardSuit.coppe);
      expect(resumed.currentPlayer.id, 'p1');
    });

    test('the action history stays bounded', () {
      final rng = Random(11);
      final players = [
        for (var i = 0; i < 2; i++)
          GamePlayer(
              id: 'p$i', name: 'P$i', type: PlayerType.bot, avatarId: 'luca'),
      ];
      final e = GameEngine.newMatch(
          players: players, mode: GameMode.vsComputer, random: rng);
      var steps = 0;
      while (!e.state.matchOver && steps++ < 3000) {
        if (e.round.phase == TurnPhase.roundOver) {
          e.startNextRound();
          continue;
        }
        if (e.round.phase == TurnPhase.awaitingSuitChoice) {
          e.chooseSuit(CardSuit.values[rng.nextInt(4)]);
          continue;
        }
        final playable = e.playableCardsFor(e.currentPlayer);
        if (playable.isNotEmpty) {
          e.playCard(playable.first);
        } else {
          e.drawCard();
          if (e.round.drawnCard == null && e.canEndTurn) e.endTurn();
        }
        expect(e.state.history.length,
            lessThanOrEqualTo(MatchState.historyLimit));
      }
    });
  });
}
