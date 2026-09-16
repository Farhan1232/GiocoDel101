import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gioco_del_101/features/game/domain/card_rank.dart';
import 'package:gioco_del_101/features/game/domain/card_suit.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_engine.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_failure.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_session.dart';
import 'package:gioco_del_101/features/game/domain/game_action.dart';
import 'package:gioco_del_101/features/game/domain/game_card.dart';
import 'package:gioco_del_101/features/game/domain/game_player.dart';
import 'package:gioco_del_101/features/game/domain/game_rules.dart';
import 'package:gioco_del_101/features/game/domain/game_state.dart';
import 'package:gioco_del_101/features/game/domain/player_type.dart';

import '../support/engine_harness.dart';

/// Encode → decode → encode must be a fixed point.
void expectStableJson(
  Map<String, dynamic> json,
  Map<String, dynamic> Function(Map<String, dynamic>) roundTrip,
) {
  final wire = jsonEncode(json);
  final again = jsonEncode(roundTrip(jsonDecode(wire) as Map<String, dynamic>));
  expect(again, wire);
}

void main() {
  group('Serialization', () {
    test('Card', () {
      for (final card in Deck.standard) {
        expectStableJson(card.toJson(), (j) => GameCard.fromJson(j).toJson());
      }
    });

    test(
      'GameRules — every field survives, including the provisional ones',
      () {
        const rules = GameRules(
          minPlayers: 3,
          maxPlayers: 3,
          startingHandSize: 7,
          allowVoluntaryDraw: false,
          playDrawnCardImmediately: false,
          restrictPlayToDrawnCard: true,
          stackDrawTwos: false,
          wildNineCanAlwaysPlay: false,
          nineBlockMode: NineBlockMode.passOn,
          nineBlockChangesSuit: false,
          exact101ResetsToZero: false,
          eliminateAbove101: false,
          targetScore: 51,
          mustDrawBeforePassing: false,
          drawTwoPenalty: 3,
          pendingPenaltyAppliesAfterWin: true,
          starterCardPolicy: StarterCardPolicy.anyCard,
          roundStarterPolicy: RoundStarterPolicy.seatAfterPreviousWinner,
          initialDirection: TurnDirection.counterClockwise,
          turnTimeLimitSeconds: 45,
          scoreValues: {CardRank.re: 20, CardRank.asso: 11},
        );
        final back = GameRules.fromJson(
          jsonDecode(jsonEncode(rules.toJson())) as Map<String, dynamic>,
        );
        expect(back, rules);
        expect(back.valueOf(CardRank.re), 20);
        expect(
          back.valueOf(CardRank.due),
          2,
          reason: 'unspecified ranks fall back to face value',
        );
        expectStableJson(rules.toJson(), (j) => GameRules.fromJson(j).toJson());
        expect(
          GameRules.fromJson(const {}),
          const GameRules(),
          reason: 'empty json = defaults',
        );
      },
    );

    test('GameRules — legacy English score keys are read', () {
      final r = GameRules.fromJson({
        'scoreValues': {'ace': 5, 'seven': 9},
      });
      expect(r.valueOf(CardRank.asso), 5);
      expect(r.valueOf(CardRank.sette), 9);
    });

    test('GameAction — all five kinds', () {
      final actions = <GameAction>[
        PlayCardAction(
          playerId: 'p0',
          card: c(CardSuit.spade, CardRank.cavallo),
          chosenSuit: CardSuit.denari,
          baseVersion: 3,
        ),
        PlayCardAction(playerId: 'p0', card: c(CardSuit.coppe, CardRank.re)),
        const DrawCardAction(playerId: 'p1', baseVersion: 0),
        const ChooseSuitAction(playerId: 'p2', suit: CardSuit.bastoni),
        const PassAction(playerId: 'p3'),
        const StartNextRoundAction(
          playerId: GameEngine.systemActorId,
          baseVersion: 12,
        ),
      ];
      for (final a in actions) {
        final back = GameAction.fromJson(
          jsonDecode(jsonEncode(a.toJson())) as Map<String, dynamic>,
        );
        expect(back, a);
        expect(back.hashCode, a.hashCode);
        expect(back.runtimeType, a.runtimeType);
        expectStableJson(a.toJson(), (j) => GameAction.fromJson(j).toJson());
      }
      expect(
        () => GameAction.fromJson({'type': 'teleport', 'playerId': 'p0'}),
        throwsFormatException,
      );
      expect(actions[0] == actions[1], isFalse);
      expect(
        const DrawCardAction(playerId: 'a') == const PassAction(playerId: 'a'),
        isFalse,
      );
    });

    test('Player', () {
      final p = GamePlayer(
        id: 'b1',
        name: 'Sofia',
        type: PlayerType.bot,
        avatarId: 'sofia',
        difficulty: BotDifficulty.hard,
        personality: BotPersonality.tactical,
        score: 42,
        eliminated: true,
        hand: [
          c(CardSuit.coppe, CardRank.re),
          c(CardSuit.denari, CardRank.asso),
        ],
      );
      final back = GamePlayer.fromJson(
        jsonDecode(jsonEncode(p.toJson())) as Map<String, dynamic>,
      );
      expect(back, p);
      expectStableJson(p.toJson(), (j) => GamePlayer.fromJson(j).toJson());
    });

    test('GameState — a mid-game state survives encode → decode → resume', () {
      final session = GameSession.newMatch(
        gameId: 'round-trip',
        players: buildState(
          hands: const [[], [], []],
          top: c(CardSuit.coppe, CardRank.cinque),
        ).players,
        mode: GameMode.passAndPlay,
        seed: 31,
        rules: const GameRules(turnTimeLimitSeconds: 30),
      );
      // Play until a Cavallo is waiting for its suit, or 40 moves.
      var moves = 0;
      while (session.state.status != GameStatus.awaitingSuitChoice &&
          moves++ < 40 &&
          !session.state.isRoundOver) {
        final me = session.currentPlayer;
        final playable = session.playableCardsFor(me);
        if (playable.isNotEmpty) {
          session.apply(
            PlayCardAction(playerId: me.id, card: playable.first),
            now: 1000 + moves,
          );
        } else {
          session.apply(DrawCardAction(playerId: me.id), now: 1000 + moves);
          if (session.currentPlayer.id == me.id && session.canEndTurn) {
            session.endTurn();
          }
        }
      }
      final original = session.state;
      final wire = jsonEncode(original.toJson());
      final restored = GameState.fromJson(
        jsonDecode(wire) as Map<String, dynamic>,
      );

      expect(jsonEncode(restored.toJson()), wire, reason: 'fixed point');
      expect(restored.version, original.version);
      expect(restored.lastAction, original.lastAction);
      expect(restored.status, original.status);
      expect(restored.currentPlayerId, original.currentPlayerId);
      expect(restored.players, original.players);
      expect(restored.drawPile, original.drawPile);
      expect(restored.discardPile, original.discardPile);
      expect(restored.history, original.history);
      expect(restored.turnStartedAt, original.turnStartedAt);
      expect(restored.turnDeadlineAt, original.turnDeadlineAt);
      expect(restored.rules, original.rules);
      expect(restored.seed, 31);

      // Resume: the same next action yields the same next state.
      const engine = GameEngine();
      final next = engine.getPlayableCards(original, original.currentPlayerId);
      final action = original.status == GameStatus.awaitingSuitChoice
          ? ChooseSuitAction(
                  playerId: original.currentPlayerId,
                  suit: CardSuit.spade,
                )
                as GameAction
          : (next.isEmpty
                ? DrawCardAction(playerId: original.currentPlayerId)
                : PlayCardAction(
                    playerId: original.currentPlayerId,
                    card: next.first,
                  ));
      final a = engine.applyAction(original, action) as ActionAccepted;
      final b = engine.applyAction(restored, action) as ActionAccepted;
      expect(jsonEncode(b.state.toJson()), jsonEncode(a.state.toJson()));
    });

    test('GameState — a finished state with a round result round-trips', () {
      final s = buildState(
        hands: [
          [c(CardSuit.coppe, CardRank.re)],
          [c(CardSuit.denari, CardRank.re), c(CardSuit.denari, CardRank.due)],
        ],
        top: c(CardSuit.coppe, CardRank.cinque),
        scores: [40, 90],
      );
      final over =
          (const GameEngine().applyAction(
                    s,
                    PlayCardAction(
                      playerId: 'p0',
                      card: c(CardSuit.coppe, CardRank.re),
                    ),
                  )
                  as ActionAccepted)
              .state;
      final back = GameState.fromJson(
        jsonDecode(jsonEncode(over.toJson())) as Map<String, dynamic>,
      );
      expect(back.status, GameStatus.finished);
      expect(back.winnerId, 'p0');
      expect(back.lastRoundResult!.rows[1].eliminated, isTrue);
      expect(jsonEncode(back.toJson()), jsonEncode(over.toJson()));
    });

    test(
      'GameState — a pre-Session-2 save with English keys is still readable',
      () {
        final legacy = {
          'players': [
            {
              'id': 'p0',
              'name': 'A',
              'type': 'humanLocal',
              'hand': ['coppe_ace', 'denari_seven'],
            },
            {
              'id': 'p1',
              'name': 'B',
              'type': 'bot',
              'hand': ['spade_two'],
            },
          ],
          'drawPile': ['bastoni_three'],
          'discardPile': ['coppe_five'],
          'activeSuit': 'coppe',
          'currentSeat': 1,
          'status': 'matchOver',
          'rules': {
            'scoreValues': {'ace': 1},
          },
        };
        final s = GameState.fromJson(legacy);
        expect(s.players.first.hand, [
          c(CardSuit.coppe, CardRank.asso),
          c(CardSuit.denari, CardRank.sette),
        ]);
        expect(s.status, GameStatus.finished);
        expect(s.currentPlayerId, 'p1');
      },
    );

    // §10 — the client re-priced the figures twice. A resumed save must
    // score by the *current* table, never by the one baked into its own
    // rules block, or a match started before the correction would go on
    // charging 25 for a Fante.
    group('legacy score tables are migrated on read', () {
      Map<String, dynamic> save(int schema, Map<String, int>? scoreValues) => {
        'schema': schema,
        'players': [
          {'id': 'p0', 'name': 'A', 'type': 'humanLocal', 'hand': []},
          {'id': 'p1', 'name': 'B', 'type': 'bot', 'hand': []},
        ],
        'discardPile': ['coppe_cinque'],
        'activeSuit': 'coppe',
        if (scoreValues != null) 'rules': {'scoreValues': scoreValues},
      };

      Map<String, int> encode(Map<CardRank, int> t) => {
        for (final e in t.entries) e.key.key: e.value,
      };

      void expectCurrentPrices(GameRules rules, String reason) {
        expect(rules.valueOf(CardRank.fante), 8, reason: 'Fante 8 — $reason');
        expect(
          rules.valueOf(CardRank.cavallo),
          25,
          reason: 'Cavallo 25 — $reason',
        );
        expect(rules.valueOf(CardRank.re), 10, reason: 'Re 10 — $reason');
      }

      test('a schema-3 save stops charging 25 for a Fante', () {
        final s = GameState.fromJson(
          save(3, encode(GameRules.legacyFigureScoreValues)),
        );
        expectCurrentPrices(s.rules, 'schema 3');
      });

      test('a pre-2026-08-31 save is migrated too', () {
        final s = GameState.fromJson(
          save(2, encode(GameRules.legacyPrintedScoreValues)),
        );
        expectCurrentPrices(s.rules, 'schema 2');
      });

      test('a save with no rules block simply takes the defaults', () {
        expectCurrentPrices(
          GameState.fromJson(save(1, null)).rules,
          'schema 1',
        );
      });

      test('a genuinely customised table survives untouched', () {
        final custom = Map<CardRank, int>.of(GameRules.defaultScoreValues)
          ..[CardRank.fante] = 40;
        final s = GameState.fromJson(save(2, encode(custom)));
        expect(
          s.rules.valueOf(CardRank.fante),
          40,
          reason: 'not a superseded default, so not dropped',
        );
      });

      test('a save written by this build is left alone', () {
        final s = GameState.fromJson(
          save(GameState.schemaVersion, encode(GameRules.defaultScoreValues)),
        );
        expectCurrentPrices(s.rules, 'current schema');
      });
    });

    test('GameState — corrupt input is rejected with FormatException', () {
      Map<String, dynamic> base() => {
        'players': [
          {'id': 'p0', 'name': 'A', 'type': 'humanLocal', 'hand': []},
          {'id': 'p1', 'name': 'B', 'type': 'bot', 'hand': []},
        ],
        'discardPile': ['coppe_cinque'],
        'activeSuit': 'coppe',
      };
      expect(
        () => GameState.fromJson(base()..['players'] = [base()['players'][0]]),
        throwsFormatException,
      );
      expect(
        () => GameState.fromJson(base()..['discardPile'] = []),
        throwsFormatException,
      );
      expect(
        () => GameState.fromJson(base()..['currentSeat'] = 5),
        throwsFormatException,
      );
      expect(
        () => GameState.fromJson(base()..remove('activeSuit')),
        throwsFormatException,
      );
      expect(
        () => GameState.fromJson(
          base()..['players'] = [base()['players'][0], base()['players'][0]],
        ),
        throwsFormatException,
      );
      expect(
        () => GameState.fromJson(base()..['drawPile'] = ['garbage']),
        throwsFormatException,
      );
    });
  });
}
