// The three rule changes the client asked for on 2026-08-31, pinned down
// end to end. See docs/CLIENT_CHANGE_2026_08_31.md.
//
//   §12  the seat that CLOSED a round leads the next one
//   §12a the DEAL moves one seat clockwise every round, independently
//   §6b  paying a +2 chain settles the penalty, NOT the turn
//
// Everything here goes through the real engine; nothing re-implements a rule.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gioco_del_101/features/game/domain/ai/bot_factory.dart';
import 'package:gioco_del_101/features/game/domain/ai/bot_view_factory.dart';
import 'package:gioco_del_101/features/game/domain/card_rank.dart';
import 'package:gioco_del_101/features/game/domain/card_suit.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_engine.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_event.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_failure.dart';
import 'package:gioco_del_101/features/game/domain/game_action.dart';
import 'package:gioco_del_101/features/game/domain/game_card.dart';
import 'package:gioco_del_101/features/game/domain/game_player.dart';
import 'package:gioco_del_101/features/game/domain/game_rules.dart';
import 'package:gioco_del_101/features/game/domain/game_state.dart';
import 'package:gioco_del_101/features/game/domain/player_type.dart';

import 'support/engine_harness.dart';

const engine = GameEngine();

ActionAccepted ok(GameState s, GameAction a, {int? now}) {
  final r = engine.applyAction(s, a, now: now);
  expect(r, isA<ActionAccepted>(), reason: '$r');
  return r as ActionAccepted;
}

GameFailure refused(GameState s, GameAction a) {
  final r = engine.applyAction(s, a);
  expect(r, isA<ActionRejected>(), reason: '$r');
  return (r as ActionRejected).failure;
}

/// A finished round in which [closerSeat] emptied its hand, ready for
/// [StartNextRoundAction]. Every other seat still holds one card.
GameState roundOverWith({
  required int seats,
  required int closerSeat,
  required int dealerSeat,
  int seed = 987654,
}) {
  final spare = [
    c(CardSuit.denari, CardRank.re),
    c(CardSuit.bastoni, CardRank.sette),
    c(CardSuit.spade, CardRank.quattro),
    c(CardSuit.denari, CardRank.tre),
  ];
  return buildState(
    hands: [
      for (var i = 0; i < seats; i++)
        if (i == closerSeat) <GameCard>[] else [spare[i]],
    ],
    top: c(CardSuit.coppe, CardRank.cinque),
    status: GameStatus.roundOver,
    currentIndex: closerSeat,
    dealerIndex: dealerSeat,
    seed: seed,
  ).copyWith(roundWinnerId: 'p$closerSeat');
}

void main() {
  // ==================================================================== §12
  group('CHANGE 1 — the previous round closer leads the next round (§12)', () {
    test('the active preset is "previous round winner", not the next seat', () {
      // The client asked for this centrally, not per call site: the default
      // GameRules every mode is built from must already carry it.
      expect(
        const GameRules().roundStarterPolicy,
        RoundStarterPolicy.previousRoundWinner,
      );
    });

    for (final seats in [2, 3, 4]) {
      test('$seats players: the closer leads, whichever seat it was', () {
        for (var closer = 0; closer < seats; closer++) {
          final s = roundOverWith(
            seats: seats,
            closerSeat: closer,
            dealerSeat: 0,
          );
          final r = ok(s, const StartNextRoundAction(playerId: 'system'));
          expect(
            r.state.currentPlayerId,
            'p$closer',
            reason: '$seats players, p$closer closed round 1',
          );
          expect(r.state.round, 2);
          expect(r.state.status, GameStatus.awaitingAction);
          expect(
            r.events.whereType<RoundStartedEvent>().single.firstPlayerId,
            'p$closer',
          );
        }
      });
    }

    for (final seats in [3, 4]) {
      test('$seats players: the leader is NOT the clockwise successor', () {
        // The distinction only bites with three or more seats: with two, the
        // successor of the closer is the other player either way.
        const closer = 2;
        final s = roundOverWith(
          seats: seats,
          closerSeat: closer,
          dealerSeat: 0,
        );
        final r = ok(s, const StartNextRoundAction(playerId: 'system'));
        final successor = 'p${(closer + 1) % seats}';
        expect(r.state.currentPlayerId, 'p$closer');
        expect(r.state.currentPlayerId, isNot(successor));
      });
    }

    test('an eliminated closer hands the lead to the next live seat', () {
      final s = buildState(
        hands: [
          [],
          [c(CardSuit.bastoni, CardRank.sette)],
          [c(CardSuit.spade, CardRank.quattro)],
        ],
        top: c(CardSuit.coppe, CardRank.cinque),
        status: GameStatus.roundOver,
        eliminated: [true, false, false],
        scores: [140, 12, 9],
        currentIndex: 1,
      ).copyWith(roundWinnerId: 'p0');
      final r = ok(s, const StartNextRoundAction(playerId: 'system'));
      expect(r.state.currentPlayerId, 'p1');
    });
  });

  // =================================================================== §12a
  group('CHANGE 5 — the deal rotates clockwise every round (§12a)', () {
    test('a new match seats the dealer at the opening seat', () {
      final state = engine.createGame(
        gameId: 'g',
        players: [
          for (var i = 0; i < 3; i++)
            GamePlayer(
              id: 'p$i',
              name: 'P$i',
              type: PlayerType.bot,
              avatarId: 'marco',
            ),
        ],
        mode: GameMode.vsComputer,
        seed: 11,
      );
      expect(state.dealerSeat, 0);
      expect(state.currentSeat, 0);
    });

    for (final seats in [2, 3, 4]) {
      test('$seats players: the deal steps one seat and wraps', () {
        var dealer = 0;
        // Walk a full lap plus one, so the wrap is covered for every size.
        for (var round = 0; round < seats + 1; round++) {
          final s = roundOverWith(
            seats: seats,
            // Vary the closer so the dealer cannot be tracking the leader.
            closerSeat: (round * 2) % seats,
            dealerSeat: dealer,
          );
          final r = ok(s, const StartNextRoundAction(playerId: 'system'));
          final expected = (dealer + 1) % seats;
          expect(
            r.state.dealerSeat,
            expected,
            reason:
                '$seats players, round ${round + 1}: '
                'dealer $dealer should hand on to $expected',
          );
          dealer = r.state.dealerSeat;
        }
        expect(dealer, (seats + 1) % seats, reason: 'wrapped round the table');
      });
    }

    test('the dealer is independent of who leads', () {
      // p2 closes every round, so the lead never moves; the deal must still
      // travel round the table.
      var dealer = 0;
      final leaders = <String>[];
      final dealers = <int>[];
      for (var round = 0; round < 4; round++) {
        final s = roundOverWith(seats: 4, closerSeat: 2, dealerSeat: dealer);
        final r = ok(s, const StartNextRoundAction(playerId: 'system'));
        leaders.add(r.state.currentPlayerId);
        dealers.add(r.state.dealerSeat);
        dealer = r.state.dealerSeat;
      }
      expect(leaders, ['p2', 'p2', 'p2', 'p2']);
      expect(dealers, [1, 2, 3, 0]);
    });

    test('a knocked-out seat never deals', () {
      final s = buildState(
        hands: [
          [c(CardSuit.denari, CardRank.re)],
          [],
          [],
          [c(CardSuit.bastoni, CardRank.sette)],
        ],
        top: c(CardSuit.coppe, CardRank.cinque),
        status: GameStatus.roundOver,
        eliminated: [false, false, true, false],
        scores: [14, 0, 130, 6],
        currentIndex: 1,
        dealerIndex: 1,
      ).copyWith(roundWinnerId: 'p1');
      final r = ok(s, const StartNextRoundAction(playerId: 'system'));
      expect(r.state.dealerSeat, 3, reason: 'seat 2 is out and is passed over');
      expect(r.state.currentPlayerId, 'p1');
    });

    test('the dealer survives a JSON round trip', () {
      final s = roundOverWith(seats: 4, closerSeat: 3, dealerSeat: 2);
      final dealt = ok(s, const StartNextRoundAction(playerId: 'system')).state;
      expect(dealt.dealerSeat, 3);
      final restored = GameState.fromJson(
        jsonDecode(jsonEncode(dealt.toJson())) as Map<String, dynamic>,
      );
      expect(restored.dealerSeat, 3);
      expect(restored.currentPlayerId, dealt.currentPlayerId);
      // …and keeps rotating from where it was restored.
      final next = ok(
        restored.copyWith(status: GameStatus.roundOver, roundWinnerId: 'p0'),
        const StartNextRoundAction(playerId: 'system'),
      );
      expect(next.state.dealerSeat, 0, reason: 'wraps 3 -> 0');
    });

    test('a save written before dealers existed still loads', () {
      final s = roundOverWith(seats: 3, closerSeat: 1, dealerSeat: 2);
      final json = jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>;
      json.remove('dealerSeat');
      final legacy = GameState.fromJson(json);
      expect(legacy.dealerSeat, 0, reason: 'seat 0 dealt round 1 of any match');
      // A nonsense dealer is treated the same way rather than throwing.
      json['dealerSeat'] = 99;
      expect(GameState.fromJson(json).dealerSeat, 0);
    });
  });

  // ==================================================================== §6b
  group('CHANGE 2 — a paid chain keeps the turn (§6b)', () {
    // p1 owes [owed]; it holds a Tre that cannot answer the chain and a card
    // that becomes legal the moment the chain is gone.
    const bystanders = [
      CardRank.re,
      CardRank.quattro,
      CardRank.cinque,
      CardRank.sette,
    ];
    GameState owing(int owed, int chain, {int seats = 2, int victim = 1}) =>
        buildState(
          hands: [
            for (var i = 0; i < seats; i++)
              if (i == victim)
                [
                  c(CardSuit.spade, CardRank.tre),
                  c(CardSuit.coppe, CardRank.sei),
                ]
              else
                // Distinct cards: the 40-card conservation invariant is real.
                [c(CardSuit.denari, bystanders[i])],
          ],
          top: c(CardSuit.coppe, CardRank.due),
          currentIndex: victim,
          pendingPenalty: owed,
          chainLength: chain,
        );

    for (final (owed, chain) in [(2, 1), (4, 2), (6, 3), (8, 4)]) {
      test('+$owed: the seat draws $owed and is still to act', () {
        final s = owing(owed, chain);
        final before = s.players[1].hand.length;
        final r = ok(s, const DrawCardAction(playerId: 'p1'));

        expect(r.state.players[1].hand, hasLength(before + owed));
        expect(r.state.pendingDrawCount, 0);
        expect(r.state.chainLength, 0);
        expect(r.state.currentPlayerId, 'p1');
        expect(r.state.penaltyResolvedThisTurn, isTrue);
        // The turn did not end, so nothing announced one.
        expect(r.events.whereType<TurnChangedEvent>(), isEmpty);
        expect(r.events.whereType<ChainResolvedEvent>().single.total, owed);
        expect(r.state.totalCards, 40);
      });
    }

    for (final seats in [2, 3, 4]) {
      test('$seats players: draw, then play, then the turn moves on', () {
        final s = owing(2, 1, seats: seats);
        final drawn = ok(s, const DrawCardAction(playerId: 'p1')).state;
        expect(drawn.currentPlayerId, 'p1');

        // The engine — not the widget — says what may be played.
        final playable = engine.getPlayableCards(drawn, 'p1');
        expect(playable, contains(c(CardSuit.coppe, CardRank.sei)));

        final played = ok(
          drawn,
          PlayCardAction(playerId: 'p1', card: c(CardSuit.coppe, CardRank.sei)),
        );
        expect(played.state.topCard, c(CardSuit.coppe, CardRank.sei));
        expect(played.state.currentPlayerId, 'p${(1 + 1) % seats}');
        expect(played.state.penaltyResolvedThisTurn, isFalse);
        expect(played.state.hasDrawnThisTurn, isFalse);
      });
    }

    test(
      'the continuation is an ordinary play: an illegal card is refused',
      () {
        final drawn = ok(
          owing(2, 1),
          const DrawCardAction(playerId: 'p1'),
        ).state;
        expect(
          refused(
            drawn,
            PlayCardAction(
              playerId: 'p1',
              card: c(CardSuit.spade, CardRank.tre),
            ),
          ),
          GameFailure.illegalCard,
        );
        // …and the state is untouched by the refusal.
        expect(drawn.currentPlayerId, 'p1');
      },
    );

    test('the seat cannot draw twice off one chain', () {
      final drawn = ok(owing(2, 1), const DrawCardAction(playerId: 'p1')).state;
      expect(
        refused(drawn, const DrawCardAction(playerId: 'p1')),
        GameFailure.drawNotAllowed,
      );
    });

    test('with nothing legal the seat passes, so the table never stalls', () {
      final s = buildState(
        hands: [
          [c(CardSuit.denari, CardRank.re)],
          [c(CardSuit.spade, CardRank.tre)],
        ],
        // Nothing the stock can supply matches a Bastoni 4 except by luck, so
        // assert on the engine's own answer rather than on a guess.
        top: c(CardSuit.coppe, CardRank.due),
        currentIndex: 1,
        pendingPenalty: 2,
        chainLength: 1,
      );
      final drawn = ok(s, const DrawCardAction(playerId: 'p1')).state;
      expect(drawn.currentPlayerId, 'p1');
      if (engine.getPlayableCards(drawn, 'p1').isEmpty) {
        expect(engine.canPass(drawn), isTrue);
        final passed = ok(drawn, const PassAction(playerId: 'p1'));
        expect(passed.state.currentPlayerId, 'p0');
      } else {
        // Drew something playable — then the continuation is a play, and the
        // point still holds: the seat has a move.
        expect(engine.canPass(drawn), isTrue);
      }
    });

    test(
      'a seat that empties its hand on the continuation closes the round',
      () {
        final s = buildState(
          hands: [
            [c(CardSuit.denari, CardRank.re)],
            [c(CardSuit.coppe, CardRank.sei)],
          ],
          top: c(CardSuit.coppe, CardRank.due),
          drawPile: [c(CardSuit.bastoni, CardRank.quattro)],
          currentIndex: 1,
          pendingPenalty: 2,
          chainLength: 1,
        );
        var st = ok(s, const DrawCardAction(playerId: 'p1')).state;
        expect(st.currentPlayerId, 'p1');
        // Play everything the engine allows until the hand is gone.
        while (st.status == GameStatus.awaitingAction &&
            st.currentPlayerId == 'p1') {
          final playable = engine.getPlayableCards(st, 'p1');
          if (playable.isEmpty) break;
          st = ok(
            st,
            PlayCardAction(playerId: 'p1', card: playable.first),
          ).state;
        }
        if (st.players[1].hand.isEmpty) {
          expect(st.status, GameStatus.roundOver);
          expect(st.roundWinnerId, 'p1');
        }
      },
    );

    test('the Cavallo block is untouched: blocking is not drawing', () {
      final s = buildState(
        hands: [
          [c(CardSuit.denari, CardRank.re)],
          [
            c(CardSuit.spade, CardRank.cavallo),
            c(CardSuit.spade, CardRank.tre),
          ],
        ],
        top: c(CardSuit.coppe, CardRank.due),
        currentIndex: 1,
        pendingPenalty: 2,
        chainLength: 1,
      );
      expect(s.rules.nineBlockMode, NineBlockMode.cancel);
      final r = ok(
        s,
        PlayCardAction(
          playerId: 'p1',
          card: c(CardSuit.spade, CardRank.cavallo),
          chosenSuit: CardSuit.spade,
        ),
      );
      expect(r.state.pendingDrawCount, 0);
      expect(r.events.whereType<ChainBlockedEvent>().single.cancelled, isTrue);
      // Blocking passes the turn on exactly as it always did — the new rule
      // only applies when the chain is actually PAID.
      expect(r.state.currentPlayerId, 'p0');
      expect(r.state.penaltyResolvedThisTurn, isFalse);
    });

    test('§10 — the continuation gets a fresh action deadline', () {
      final s = buildState(
        hands: [
          [c(CardSuit.denari, CardRank.re)],
          [c(CardSuit.spade, CardRank.tre), c(CardSuit.coppe, CardRank.sei)],
        ],
        top: c(CardSuit.coppe, CardRank.due),
        rules: const GameRules(turnTimeLimitSeconds: 30),
        currentIndex: 1,
        pendingPenalty: 2,
        chainLength: 1,
      );
      // The seat has been sitting on this turn for 29 of its 30 seconds.
      final opened = s.copyWith(
        turnStartedAt: 1_000_000,
        turnDeadlineAt: 1_030_000,
      );
      final drawn = ok(
        opened,
        const DrawCardAction(playerId: 'p1'),
        now: 1_029_000,
      );
      expect(drawn.state.currentPlayerId, 'p1');
      expect(drawn.state.turnStartedAt, 1_029_000);
      expect(
        drawn.state.turnDeadlineAt,
        1_059_000,
        reason: 'the player must genuinely have time to make the play',
      );
    });

    test('a paid chain counts one turn, not two', () {
      final s = buildState(
        hands: [
          [c(CardSuit.denari, CardRank.re)],
          [c(CardSuit.spade, CardRank.tre), c(CardSuit.coppe, CardRank.sei)],
        ],
        top: c(CardSuit.coppe, CardRank.due),
        currentIndex: 1,
        pendingPenalty: 2,
        chainLength: 1,
      );
      final drawn = ok(s, const DrawCardAction(playerId: 'p1')).state;
      // Drawing the penalty is not a turn of its own.
      expect(drawn.turnNumber, s.turnNumber);
      expect(drawn.drawsByPlayer['p1'], 2);
      final played = ok(
        drawn,
        PlayCardAction(playerId: 'p1', card: c(CardSuit.coppe, CardRank.sei)),
      ).state;
      expect(played.turnNumber, s.turnNumber + 1, reason: 'exactly one turn');
      // The +2 that opened the chain is still counted once, by whoever played
      // it — the victim's draw must not inflate anything.
      expect(played.stats.twosPlayed, s.stats.twosPlayed);
      expect(played.stats.cardsPlayed, s.stats.cardsPlayed + 1);
      expect(played.drawsByPlayer['p1'], 2);
    });
  });

  // ================================================================== bots
  group('CHANGE 2 — bots use the continuation instead of giving it up', () {
    test('a bot that pays a chain asks the engine again and plays on', () {
      // Hard bots reason the most about chains; run all three.
      for (final difficulty in BotDifficulty.values) {
        final s = buildState(
          hands: [
            [c(CardSuit.denari, CardRank.re)],
            [c(CardSuit.spade, CardRank.tre), c(CardSuit.coppe, CardRank.sei)],
          ],
          top: c(CardSuit.coppe, CardRank.due),
          currentIndex: 1,
          pendingPenalty: 2,
          chainLength: 1,
        );
        final bot = BotFactory.create(difficulty);

        // Forced to take the chain.
        expect(engine.mustTakePenalty(s), isTrue);
        final drawn = ok(s, const DrawCardAction(playerId: 'p1')).state;
        expect(drawn.currentPlayerId, 'p1');

        // Asked again, on the same engine, the bot must have a move — and
        // the move it names must be legal.
        final view = BotViewFactory.forCurrentPlayer(drawn);
        expect(
          view.playable,
          isNotEmpty,
          reason: '${difficulty.name} should be offered a continuation',
        );
        final decision = bot.decide(view);
        if (decision.card != null) {
          expect(
            engine.canPlay(drawn, decision.card!),
            isTrue,
            reason: '${difficulty.name} proposed an illegal continuation',
          );
        }
      }
    });
  });
}
