import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:gioco_del_101/features/game/domain/ai/bot_decision.dart';
import 'package:gioco_del_101/features/game/domain/ai/bot_factory.dart';
import 'package:gioco_del_101/features/game/domain/ai/bot_view_factory.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_session.dart';
import 'package:gioco_del_101/features/game/domain/card_rank.dart';
import 'package:gioco_del_101/features/game/domain/card_suit.dart';
import 'package:gioco_del_101/features/game/domain/game_card.dart';
import 'package:gioco_del_101/features/game/domain/game_player.dart';
import 'package:gioco_del_101/features/game/domain/game_rules.dart';
import 'package:gioco_del_101/features/game/domain/game_state.dart';
import 'package:gioco_del_101/features/game/domain/player_type.dart';

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
          final engine = GameSession.newMatch(
            gameId: 't',
            players: players,
            mode: GameMode.vsComputer,
            seed: rng.nextInt(1 << 30),
          );
          final bots = {
            for (final p in players)
              p.id: BotFactory.create(
                difficulty,
                personality: p.personality,
                random: Random(seed + 100),
              ),
          };

          var steps = 0;
          while (!engine.state.isFinished && steps++ < 40000) {
            if (engine.state.status == GameStatus.roundOver) {
              engine.startNextRound();
              continue;
            }
            final bot = bots[engine.currentPlayer.id]!;
            final view = BotViewFactory.forCurrentPlayer(engine.state);
            if (engine.state.status == GameStatus.awaitingSuitChoice) {
              expect(engine.chooseSuit(bot.chooseSuit(view)).accepted, isTrue);
              continue;
            }
            final decision = bot.decide(view);
            switch (decision.action) {
              case BotAction.play:
                final result = engine.playCard(
                  decision.card!,
                  chosenSuit: decision.suit,
                );
                expect(
                  result.accepted,
                  isTrue,
                  reason:
                      '${difficulty.name} played ${decision.card} illegally '
                      '(seed $seed, step $steps)',
                );
              case BotAction.draw:
                expect(
                  engine.drawCard().accepted,
                  isTrue,
                  reason: '${difficulty.name} drew illegally (seed $seed)',
                );
                if (engine.state.drawnCard == null && engine.canEndTurn) {
                  engine.endTurn();
                }
              case BotAction.endTurn:
                expect(
                  engine.endTurn().accepted,
                  isTrue,
                  reason: '${difficulty.name} passed illegally (seed $seed)',
                );
            }
          }
          expect(
            engine.state.isFinished,
            isTrue,
            reason: '${difficulty.name} stalled on seed $seed',
          );
        }
      });
    }
  });

  group('Bots cannot see hidden information (§21)', () {
    /// Two tables that look identical from the bot's chair must produce the
    /// same move, however different the opponents' actual cards are.
    test('the same public state yields the same decision', () {
      for (final difficulty in BotDifficulty.values) {
        GameSession tableWith(List<GameCard> opponentHand) {
          final players = [
            GamePlayer(
              id: 'p0',
              name: 'Bot',
              type: PlayerType.bot,
              avatarId: 'marco',
              difficulty: difficulty,
              hand: [
                const GameCard(CardSuit.coppe, CardRank.re),
                const GameCard(CardSuit.coppe, CardRank.quattro),
                const GameCard(CardSuit.spade, CardRank.cavallo),
                const GameCard(CardSuit.bastoni, CardRank.due),
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
          return GameSession(
            GameState(
              gameId: 't',
              mode: GameMode.vsComputer,
              rules: const GameRulesProxy().value,
              players: players,
              drawPile: const [],
              discardPile: const [GameCard(CardSuit.coppe, CardRank.cinque)],
              activeSuit: CardSuit.coppe,
              currentSeat: 0,
            ),
          );
        }

        final weakOpponent = [
          const GameCard(CardSuit.denari, CardRank.tre),
          const GameCard(CardSuit.denari, CardRank.sei),
        ];
        final strongOpponent = [
          const GameCard(CardSuit.coppe, CardRank.asso),
          const GameCard(CardSuit.coppe, CardRank.due),
        ];

        final botA = BotFactory.create(difficulty, random: Random(42));
        final botB = BotFactory.create(difficulty, random: Random(42));
        final a = botA.decide(
          BotViewFactory.forCurrentPlayer(tableWith(weakOpponent).state),
        );
        final b = botB.decide(
          BotViewFactory.forCurrentPlayer(tableWith(strongOpponent).state),
        );

        expect(a.action, b.action, reason: '${difficulty.name} changed plan');
        expect(
          a.card,
          b.card,
          reason: '${difficulty.name} reacted to a hidden hand',
        );
      }
    });
  });

  group('Bots make sensible choices', () {
    test('every bot plays its last legal card to win the round', () {
      for (final difficulty in BotDifficulty.values) {
        final e = buildEngine(
          hands: [
            [c(CardSuit.coppe, CardRank.re)],
            [
              c(CardSuit.spade, CardRank.tre),
              c(CardSuit.spade, CardRank.quattro),
            ],
          ],
          top: c(CardSuit.coppe, CardRank.cinque),
        );
        final bot = BotFactory.create(difficulty, random: Random(5));
        final d = bot.decide(BotViewFactory.forCurrentPlayer(e.state));
        expect(d.action, BotAction.play);
        expect(
          d.card,
          c(CardSuit.coppe, CardRank.re),
          reason: '${difficulty.name} missed the winning card',
        );
      }
    });

    test('Normal and Hard answer a +2 chain rather than eat it', () {
      for (final difficulty in [BotDifficulty.normal, BotDifficulty.hard]) {
        final e = buildEngine(
          hands: [
            [c(CardSuit.coppe, CardRank.re)],
            [c(CardSuit.spade, CardRank.due), c(CardSuit.spade, CardRank.re)],
          ],
          top: c(CardSuit.coppe, CardRank.due),
          currentIndex: 1,
          pendingPenalty: 2,
          chainLength: 1,
          drawPile: [c(CardSuit.denari, CardRank.quattro)],
        );
        final bot = BotFactory.create(difficulty, random: Random(5));
        final d = bot.decide(BotViewFactory.forCurrentPlayer(e.state));
        expect(d.action, BotAction.play, reason: '${difficulty.name} folded');
        expect(d.card!.isTwo, isTrue);
      }
    });

    test('Normal keeps the Cavallo back when an ordinary card will do', () {
      final e = buildEngine(
        hands: [
          [
            c(CardSuit.spade, CardRank.cavallo),
            c(CardSuit.coppe, CardRank.sei),
            c(CardSuit.coppe, CardRank.tre),
            c(CardSuit.bastoni, CardRank.sette),
          ],
          [
            c(CardSuit.denari, CardRank.tre),
            c(CardSuit.denari, CardRank.quattro),
          ],
        ],
        top: c(CardSuit.coppe, CardRank.cinque),
      );
      final bot = BotFactory.create(BotDifficulty.normal, random: Random(5));
      final d = bot.decide(BotViewFactory.forCurrentPlayer(e.state));
      expect(d.card!.isCavallo, isFalse);
    });

    test('a Cavallo suit choice always lands on a suit the bot holds', () {
      for (final difficulty in [BotDifficulty.normal, BotDifficulty.hard]) {
        final e = buildEngine(
          hands: [
            [
              c(CardSuit.spade, CardRank.cavallo),
              c(CardSuit.bastoni, CardRank.sei),
              c(CardSuit.bastoni, CardRank.tre),
              c(CardSuit.bastoni, CardRank.sette),
            ],
            [c(CardSuit.denari, CardRank.tre)],
          ],
          top: c(CardSuit.coppe, CardRank.cinque),
        );
        final bot = BotFactory.create(difficulty, random: Random(5));
        expect(
          bot.chooseSuit(BotViewFactory.forCurrentPlayer(e.state)),
          CardSuit.bastoni,
          reason: '${difficulty.name} named a suit it cannot follow',
        );
      }
    });

    test('Hard counts the cards that have already gone by', () {
      final e = buildEngine(
        hands: [
          [c(CardSuit.coppe, CardRank.sei)],
          [c(CardSuit.denari, CardRank.tre)],
        ],
        top: c(CardSuit.coppe, CardRank.cinque),
      );
      e.restore(
        e.state.copyWith(
          playedCards: [
            c(CardSuit.denari, CardRank.asso),
            c(CardSuit.denari, CardRank.due),
            c(CardSuit.denari, CardRank.tre),
          ],
        ),
      );
      final bot = BotFactory.create(BotDifficulty.hard, random: Random(5));
      final view = BotViewFactory.forCurrentPlayer(e.state);
      final hard = bot as dynamic;
      expect(hard.unseenInSuit(CardSuit.denari, view), 7);
      expect(hard.unseenOfRank(CardRank.due, view), 3);
    });

    test('Hard beats Easy over a run of matches', () {
      var hardWins = 0;
      const matches = 100;
      for (var seed = 0; seed < matches; seed++) {
        final rng = Random(seed);
        final players = [
          GamePlayer(
            id: 'hard',
            name: 'Hard',
            type: PlayerType.bot,
            avatarId: 'sofia',
            difficulty: BotDifficulty.hard,
          ),
          GamePlayer(
            id: 'easy',
            name: 'Easy',
            type: PlayerType.bot,
            avatarId: 'luca',
            difficulty: BotDifficulty.easy,
          ),
        ];
        final engine = GameSession.newMatch(
          gameId: 't',
          players: players,
          mode: GameMode.vsComputer,
          seed: rng.nextInt(1 << 30),
        );
        final bots = {
          'hard': BotFactory.create(BotDifficulty.hard, random: Random(seed)),
          'easy': BotFactory.create(BotDifficulty.easy, random: Random(seed)),
        };
        var steps = 0;
        while (!engine.state.isFinished && steps++ < 40000) {
          if (engine.state.status == GameStatus.roundOver) {
            engine.startNextRound();
            continue;
          }
          final bot = bots[engine.currentPlayer.id]!;
          final view = BotViewFactory.forCurrentPlayer(engine.state);
          if (engine.state.status == GameStatus.awaitingSuitChoice) {
            engine.chooseSuit(bot.chooseSuit(view));
            continue;
          }
          final d = bot.decide(view);
          switch (d.action) {
            case BotAction.play:
              engine.playCard(d.card!, chosenSuit: d.suit);
            case BotAction.draw:
              engine.drawCard();
              if (engine.state.drawnCard == null && engine.canEndTurn) {
                engine.endTurn();
              }
            case BotAction.endTurn:
              engine.endTurn();
          }
        }
        if (engine.state.winnerId == 'hard') hardWins++;
      }
      // Not a landslide — the deck decides plenty — but a clear edge.
      expect(
        hardWins,
        greaterThan(matches * 0.55),
        reason: 'Hard won only $hardWins of $matches',
      );
    });
  });
}

/// Small shim so the test can pass a const default config inline.
class GameRulesProxy {
  const GameRulesProxy();
  GameRules get value => const GameRules();
}
