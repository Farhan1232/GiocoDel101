import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:gioco_del_101/features/game/domain/ai/bot_decision.dart';
import 'package:gioco_del_101/features/game/domain/ai/bot_factory.dart';
import 'package:gioco_del_101/features/game/domain/ai/bot_view_factory.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_engine.dart';
import 'package:gioco_del_101/features/game/domain/card_rank.dart';
import 'package:gioco_del_101/features/game/domain/card_suit.dart';
import 'package:gioco_del_101/features/game/domain/game_card.dart';
import 'package:gioco_del_101/features/game/domain/game_player.dart';
import 'package:gioco_del_101/features/game/domain/game_rules_config.dart';
import 'package:gioco_del_101/features/game/domain/match_state.dart';
import 'package:gioco_del_101/features/game/domain/player_type.dart';
import 'package:gioco_del_101/features/game/domain/round_state.dart';

import 'support/engine_harness.dart';

void main() {
  group('Every bot obeys the rules (§21)', () {
    for (final difficulty in BotDifficulty.values) {
      test('${difficulty.name} never proposes an illegal move', () {
        for (var seed = 0; seed < 25; seed++) {
          final rng = Random(seed);
          final players = [
            for (var i = 0; i < 2 + (seed % 3); i++)
              GamePlayer(
                id: 'p$i',
                name: 'P$i',
                type: PlayerType.bot,
                avatarId: 'marco',
                difficulty: difficulty,
                personality:
                    BotPersonality.values[i % BotPersonality.values.length],
              ),
          ];
          final engine = GameEngine.newMatch(
              players: players, mode: GameMode.vsComputer, random: rng);
          final bots = {
            for (final p in players)
              p.id: BotFactory.create(difficulty,
                  personality: p.personality, random: Random(seed + 100))
          };

          var steps = 0;
          while (!engine.state.matchOver && steps++ < 40000) {
            if (engine.round.phase == TurnPhase.roundOver) {
              engine.startNextRound();
              continue;
            }
            final bot = bots[engine.currentPlayer.id]!;
            final view = BotViewFactory.forCurrentPlayer(engine);
            if (engine.round.phase == TurnPhase.awaitingSuitChoice) {
              expect(engine.chooseSuit(bot.chooseSuit(view)).accepted, isTrue);
              continue;
            }
            final decision = bot.decide(view);
            switch (decision.action) {
              case BotAction.play:
                final result = engine.playCard(decision.card!,
                    chosenSuit: decision.suit);
                expect(result.accepted, isTrue,
                    reason:
                        '${difficulty.name} played ${decision.card} illegally '
                        '(seed $seed, step $steps)');
              case BotAction.draw:
                expect(engine.drawCard().accepted, isTrue,
                    reason: '${difficulty.name} drew illegally (seed $seed)');
                if (engine.round.drawnCard == null && engine.canEndTurn) {
                  engine.endTurn();
                }
              case BotAction.endTurn:
                expect(engine.endTurn().accepted, isTrue,
                    reason: '${difficulty.name} passed illegally (seed $seed)');
            }
          }
          expect(engine.state.matchOver, isTrue,
              reason: '${difficulty.name} stalled on seed $seed');
        }
      });
    }
  });

  group('Bots cannot see hidden information (§21)', () {
    /// Two tables that look identical from the bot's chair must produce the
    /// same move, however different the opponents' actual cards are.
    test('the same public state yields the same decision', () {
      for (final difficulty in BotDifficulty.values) {
        GameEngine tableWith(List<GameCard> opponentHand) {
          final players = [
            GamePlayer(
              id: 'p0',
              name: 'Bot',
              type: PlayerType.bot,
              avatarId: 'marco',
              difficulty: difficulty,
              hand: [
                const GameCard(CardSuit.coppe, CardRank.re),
                const GameCard(CardSuit.coppe, CardRank.four),
                const GameCard(CardSuit.spade, CardRank.cavallo),
                const GameCard(CardSuit.bastoni, CardRank.two),
              ],
            ),
            GamePlayer(
              id: 'p1',
              name: 'Other',
              type: PlayerType.bot,
              avatarId: 'sofia',
              difficulty: difficulty,
              hand: opponentHand,
            ),
          ];
          return GameEngine.fromState(
            MatchState(
              players: players,
              rules: const GameRulesConfigProxy().value,
              round: RoundState(
                drawPile: const [],
                discardPile: const [GameCard(CardSuit.coppe, CardRank.five)],
                activeSuit: CardSuit.coppe,
                currentIndex: 0,
              ),
              mode: GameMode.vsComputer,
            ),
            random: Random(1),
          );
        }

        final weakOpponent = [
          const GameCard(CardSuit.denari, CardRank.three),
          const GameCard(CardSuit.denari, CardRank.six),
        ];
        final strongOpponent = [
          const GameCard(CardSuit.coppe, CardRank.ace),
          const GameCard(CardSuit.coppe, CardRank.two),
        ];

        final botA = BotFactory.create(difficulty, random: Random(42));
        final botB = BotFactory.create(difficulty, random: Random(42));
        final a = botA.decide(BotViewFactory.forCurrentPlayer(tableWith(weakOpponent)));
        final b = botB.decide(BotViewFactory.forCurrentPlayer(tableWith(strongOpponent)));

        expect(a.action, b.action, reason: '${difficulty.name} changed plan');
        expect(a.card, b.card,
            reason: '${difficulty.name} reacted to a hidden hand');
      }
    });
  });

  group('Bots make sensible choices', () {
    test('every bot plays its last legal card to win the round', () {
      for (final difficulty in BotDifficulty.values) {
        final e = buildEngine(
          hands: [
            [c(CardSuit.coppe, CardRank.re)],
            [c(CardSuit.spade, CardRank.three), c(CardSuit.spade, CardRank.four)],
          ],
          top: c(CardSuit.coppe, CardRank.five),
        );
        final bot = BotFactory.create(difficulty, random: Random(5));
        final d = bot.decide(BotViewFactory.forCurrentPlayer(e));
        expect(d.action, BotAction.play);
        expect(d.card, c(CardSuit.coppe, CardRank.re),
            reason: '${difficulty.name} missed the winning card');
      }
    });

    test('Normal and Hard answer a +2 chain rather than eat it', () {
      for (final difficulty in [BotDifficulty.normal, BotDifficulty.hard]) {
        final e = buildEngine(
          hands: [
            [c(CardSuit.coppe, CardRank.re)],
            [c(CardSuit.spade, CardRank.two), c(CardSuit.spade, CardRank.re)],
          ],
          top: c(CardSuit.coppe, CardRank.two),
          currentIndex: 1,
          pendingPenalty: 2,
          chainLength: 1,
          drawPile: [c(CardSuit.denari, CardRank.four)],
        );
        final bot = BotFactory.create(difficulty, random: Random(5));
        final d = bot.decide(BotViewFactory.forCurrentPlayer(e));
        expect(d.action, BotAction.play, reason: '${difficulty.name} folded');
        expect(d.card!.isTwo, isTrue);
      }
    });

    test('Normal keeps the Cavallo back when an ordinary card will do', () {
      final e = buildEngine(
        hands: [
          [
            c(CardSuit.spade, CardRank.cavallo),
            c(CardSuit.coppe, CardRank.six),
            c(CardSuit.coppe, CardRank.three),
            c(CardSuit.bastoni, CardRank.seven),
          ],
          [c(CardSuit.denari, CardRank.three), c(CardSuit.denari, CardRank.four)],
        ],
        top: c(CardSuit.coppe, CardRank.five),
      );
      final bot = BotFactory.create(BotDifficulty.normal, random: Random(5));
      final d = bot.decide(BotViewFactory.forCurrentPlayer(e));
      expect(d.card!.isCavallo, isFalse);
    });

    test('a Cavallo suit choice always lands on a suit the bot holds', () {
      for (final difficulty in [BotDifficulty.normal, BotDifficulty.hard]) {
        final e = buildEngine(
          hands: [
            [
              c(CardSuit.spade, CardRank.cavallo),
              c(CardSuit.bastoni, CardRank.six),
              c(CardSuit.bastoni, CardRank.three),
              c(CardSuit.bastoni, CardRank.seven),
            ],
            [c(CardSuit.denari, CardRank.three)],
          ],
          top: c(CardSuit.coppe, CardRank.five),
        );
        final bot = BotFactory.create(difficulty, random: Random(5));
        expect(bot.chooseSuit(BotViewFactory.forCurrentPlayer(e)),
            CardSuit.bastoni,
            reason: '${difficulty.name} named a suit it cannot follow');
      }
    });

    test('Hard counts the cards that have already gone by', () {
      final e = buildEngine(
        hands: [
          [c(CardSuit.coppe, CardRank.six)],
          [c(CardSuit.denari, CardRank.three)],
        ],
        top: c(CardSuit.coppe, CardRank.five),
      );
      e.round.playedCards.addAll([
        c(CardSuit.denari, CardRank.ace),
        c(CardSuit.denari, CardRank.two),
        c(CardSuit.denari, CardRank.three),
      ]);
      final bot = BotFactory.create(BotDifficulty.hard, random: Random(5));
      final view = BotViewFactory.forCurrentPlayer(e);
      final hard = bot as dynamic;
      expect(hard.unseenInSuit(CardSuit.denari, view), 7);
      expect(hard.unseenOfRank(CardRank.two, view), 3);
    });

    test('Hard beats Easy over a run of matches', () {
      var hardWins = 0;
      const matches = 40;
      for (var seed = 0; seed < matches; seed++) {
        final rng = Random(seed);
        final players = [
          GamePlayer(
              id: 'hard',
              name: 'Hard',
              type: PlayerType.bot,
              avatarId: 'sofia',
              difficulty: BotDifficulty.hard),
          GamePlayer(
              id: 'easy',
              name: 'Easy',
              type: PlayerType.bot,
              avatarId: 'luca',
              difficulty: BotDifficulty.easy),
        ];
        final engine = GameEngine.newMatch(
            players: players, mode: GameMode.vsComputer, random: rng);
        final bots = {
          'hard': BotFactory.create(BotDifficulty.hard, random: Random(seed)),
          'easy': BotFactory.create(BotDifficulty.easy, random: Random(seed)),
        };
        var steps = 0;
        while (!engine.state.matchOver && steps++ < 40000) {
          if (engine.round.phase == TurnPhase.roundOver) {
            engine.startNextRound();
            continue;
          }
          final bot = bots[engine.currentPlayer.id]!;
          final view = BotViewFactory.forCurrentPlayer(engine);
          if (engine.round.phase == TurnPhase.awaitingSuitChoice) {
            engine.chooseSuit(bot.chooseSuit(view));
            continue;
          }
          final d = bot.decide(view);
          switch (d.action) {
            case BotAction.play:
              engine.playCard(d.card!, chosenSuit: d.suit);
            case BotAction.draw:
              engine.drawCard();
              if (engine.round.drawnCard == null && engine.canEndTurn) {
                engine.endTurn();
              }
            case BotAction.endTurn:
              engine.endTurn();
          }
        }
        if (engine.state.matchWinnerId == 'hard') hardWins++;
      }
      // Not a landslide — the deck decides plenty — but a clear edge.
      expect(hardWins, greaterThan(matches * 0.55),
          reason: 'Hard won only $hardWins of $matches');
    });
  });
}

/// Small shim so the test can pass a const default config inline.
class GameRulesConfigProxy {
  const GameRulesConfigProxy();
  GameRulesConfig get value => const GameRulesConfig();
}
