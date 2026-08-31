import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gioco_del_101/features/game/domain/ai/bot_decision.dart';
import 'package:gioco_del_101/features/game/domain/ai/bot_factory.dart';
import 'package:gioco_del_101/features/game/domain/ai/bot_view_factory.dart';
import 'package:gioco_del_101/features/game/domain/card_rank.dart';
import 'package:gioco_del_101/features/game/domain/card_suit.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_engine.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_event.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_failure.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_session.dart';
import 'package:gioco_del_101/features/game/domain/game_action.dart';
import 'package:gioco_del_101/features/game/domain/game_player.dart';
import 'package:gioco_del_101/features/game/domain/game_rules.dart';
import 'package:gioco_del_101/features/game/domain/history_entry.dart';
import 'package:gioco_del_101/features/game/domain/game_state.dart';
import 'package:gioco_del_101/features/game/domain/player_type.dart';

import 'support/engine_harness.dart';

/// GAME_SPEC §16 — "ULTIMA CARTA".
///
/// The client asked for a button a player must press before the play that
/// leaves them holding a single card. It is a rule, not a decoration: the
/// engine that runs offline and the engine the server runs (the same code
/// compiled to JavaScript) both refuse the play until the announcement has
/// been made, and both forget the announcement the moment it stops being
/// about the hand it was made for.
const engine = GameEngine();

final _top = c(CardSuit.coppe, CardRank.cinque);
final _playable = c(CardSuit.coppe, CardRank.re);
final _spare = c(CardSuit.coppe, CardRank.sette);

/// p0 to act with exactly two cards, both of them legal.
GameState twoInHand({
  int seats = 2,
  GameRules rules = const GameRules(),
  List<int>? scores,
}) => buildState(
  hands: [
    [_playable, _spare],
    [c(CardSuit.denari, CardRank.tre)],
    if (seats > 2) [c(CardSuit.spade, CardRank.tre)],
    if (seats > 3) [c(CardSuit.bastoni, CardRank.tre)],
  ],
  top: _top,
  rules: rules,
  scores: scores,
);

GameFailure? validate(GameState s, GameAction a) => engine.validateAction(s, a);

ActionAccepted accept(GameState s, GameAction a) {
  final r = engine.applyAction(s, a);
  expect(r, isA<ActionAccepted>(), reason: '$a on $s → $r');
  return r as ActionAccepted;
}

void main() {
  group('§16 — the play from two cards to one', () {
    test('is refused when nobody has declared, and changes nothing', () {
      final s = twoInHand();
      final action = PlayCardAction(playerId: 'p0', card: _playable);
      final r = engine.applyAction(s, action);

      expect(r, isA<ActionRejected>());
      expect(r.failure, GameFailure.lastCardDeclarationRequired);
      // Nothing was consumed, nothing moved, nobody's turn ended.
      expect(s.handOf('p0'), [_playable, _spare]);
      expect(s.topCard, _top);
      expect(s.currentPlayerId, 'p0');
      expect(s.version, 0);
    });

    test('goes through once the announcement stands, leaving one card', () {
      var s = twoInHand();
      s = accept(s, const DeclareLastCardAction(playerId: 'p0')).state;
      expect(s.lastCardDeclaredBy, 'p0');

      final r = accept(s, PlayCardAction(playerId: 'p0', card: _playable));
      expect(r.state.handOf('p0'), [_spare]);
      expect(r.state.handOf('p0'), hasLength(1));
      expect(r.state.topCard, _playable);
      expect(r.state.currentPlayerId, 'p1');
    });

    test('an illegal card is still reported as illegal, not as undeclared', () {
      final s = buildState(
        hands: [
          [
            c(CardSuit.bastoni, CardRank.sette),
            c(CardSuit.spade, CardRank.tre),
          ],
          [c(CardSuit.denari, CardRank.tre)],
        ],
        top: _top,
      );
      expect(
        validate(
          s,
          PlayCardAction(
            playerId: 'p0',
            card: c(CardSuit.bastoni, CardRank.sette),
          ),
        ),
        GameFailure.illegalCard,
      );
    });

    test('the final card (1 -> 0) needs no second announcement', () {
      final s = buildState(
        hands: [
          [_playable],
          [c(CardSuit.denari, CardRank.tre)],
        ],
        top: _top,
      );
      final r = accept(s, PlayCardAction(playerId: 'p0', card: _playable));
      expect(r.state.status, GameStatus.roundOver);
      expect(r.state.roundWinnerId, 'p0');
    });

    test('a hand of three is not affected', () {
      final s = buildState(
        hands: [
          [_playable, _spare, c(CardSuit.spade, CardRank.tre)],
          [c(CardSuit.denari, CardRank.tre)],
        ],
        top: _top,
      );
      expect(
        validate(s, PlayCardAction(playerId: 'p0', card: _playable)),
        isNull,
      );
    });

    test('the rule can be switched off centrally, and then never fires', () {
      final s = twoInHand(
        rules: const GameRules(requireLastCardDeclaration: false),
      );
      expect(
        validate(s, PlayCardAction(playerId: 'p0', card: _playable)),
        isNull,
      );
      expect(engine.canDeclareLastCard(s, 'p0'), isFalse);
      expect(
        validate(s, const DeclareLastCardAction(playerId: 'p0')),
        GameFailure.lastCardDeclarationNotAllowed,
      );
    });
  });

  group('§16 — when the announcement means something', () {
    test('exactly two cards, on turn, with a legal play', () {
      expect(engine.canDeclareLastCard(twoInHand(), 'p0'), isTrue);
    });

    test('never with five or ten cards in hand', () {
      for (final size in [1, 3, 5, 10]) {
        final s = buildState(
          hands: [
            [
              _playable,
              for (var i = 1; i < size; i++)
                c(CardSuit.values[i % 4], CardRank.values[i]),
            ],
            [c(CardSuit.denari, CardRank.tre)],
          ],
          top: _top,
          fillDeck: false,
        );
        expect(
          engine.canDeclareLastCard(s, 'p0'),
          isFalse,
          reason: 'a hand of $size is not about to reach one card',
        );
        expect(
          validate(s, const DeclareLastCardAction(playerId: 'p0')),
          GameFailure.lastCardDeclarationNotAllowed,
        );
      }
    });

    test('never out of turn, and never for somebody else', () {
      final s = buildState(
        hands: [
          [_playable, _spare],
          [c(CardSuit.denari, CardRank.tre), c(CardSuit.denari, CardRank.re)],
        ],
        top: _top,
      );
      expect(engine.canDeclareLastCard(s, 'p1'), isFalse);
      expect(
        validate(s, const DeclareLastCardAction(playerId: 'p1')),
        GameFailure.notPlayersTurn,
      );
      expect(
        validate(s, const DeclareLastCardAction(playerId: 'nobody')),
        GameFailure.invalidPlayer,
      );
    });

    test('never with two cards but nothing legal to play', () {
      final s = buildState(
        hands: [
          [
            c(CardSuit.bastoni, CardRank.sette),
            c(CardSuit.spade, CardRank.tre),
          ],
          [c(CardSuit.denari, CardRank.tre)],
        ],
        top: _top,
      );
      expect(engine.canDeclareLastCard(s, 'p0'), isFalse);
    });

    test('never once the round or the match is over', () {
      final over = twoInHand().copyWith(status: GameStatus.roundOver);
      expect(engine.canDeclareLastCard(over, 'p0'), isFalse);
      expect(
        validate(over, const DeclareLastCardAction(playerId: 'p0')),
        GameFailure.roundOver,
      );

      final done = twoInHand().copyWith(
        status: GameStatus.finished,
        winnerId: 'p1',
      );
      expect(engine.canDeclareLastCard(done, 'p0'), isFalse);
      expect(
        validate(done, const DeclareLastCardAction(playerId: 'p0')),
        GameFailure.gameFinished,
      );
    });

    test('never while a Cavallo is waiting for its suit', () {
      final s = twoInHand().copyWith(status: GameStatus.awaitingSuitChoice);
      expect(engine.canDeclareLastCard(s, 'p0'), isFalse);
      expect(
        validate(s, const DeclareLastCardAction(playerId: 'p0')),
        GameFailure.suitSelectionRequired,
      );
    });

    test('not twice for the same turn', () {
      final s = accept(
        twoInHand(),
        const DeclareLastCardAction(playerId: 'p0'),
      ).state;
      expect(engine.canDeclareLastCard(s, 'p0'), isFalse);
      expect(
        validate(s, const DeclareLastCardAction(playerId: 'p0')),
        GameFailure.lastCardDeclarationNotAllowed,
      );
    });
  });

  group('§16 — the announcement itself', () {
    test('plays no card, draws nothing and does not end the turn', () {
      final before = twoInHand();
      final r = accept(before, const DeclareLastCardAction(playerId: 'p0'));
      final after = r.state;

      expect(after.lastCardDeclaredBy, 'p0');
      expect(after.handOf('p0'), before.handOf('p0'));
      expect(after.topCard, before.topCard);
      expect(after.drawPile.length, before.drawPile.length);
      expect(after.currentPlayerId, 'p0');
      expect(after.turnNumber, before.turnNumber);
      expect(after.status, GameStatus.awaitingAction);
      expect(after.version, before.version + 1);
      expect(r.events.single, isA<LastCardDeclaredEvent>());
      expect((r.events.single as LastCardDeclaredEvent).playerId, 'p0');
      expect(after.history.last.type, HistoryEntryType.lastCardDeclared);
    });

    test('belongs to one player only', () {
      final s = accept(
        twoInHand(seats: 3),
        const DeclareLastCardAction(playerId: 'p0'),
      ).state;
      expect(s.hasDeclaredLastCard('p0'), isTrue);
      expect(s.hasDeclaredLastCard('p1'), isFalse);
      expect(s.hasDeclaredLastCard('p2'), isFalse);
    });
  });

  group('§16 — when the announcement is forgotten', () {
    test('the turn moving on clears it', () {
      var s = accept(
        twoInHand(),
        const DeclareLastCardAction(playerId: 'p0'),
      ).state;
      s = accept(s, PlayCardAction(playerId: 'p0', card: _playable)).state;
      expect(s.currentPlayerId, 'p1');
      expect(s.lastCardDeclaredBy, isNull);
    });

    test('drawing instead of playing clears it, and drawing alone never '
        'required it', () {
      final start = twoInHand();
      // Drawing from two cards is legal with no announcement at all.
      expect(validate(start, const DrawCardAction(playerId: 'p0')), isNull);

      var s = accept(start, const DeclareLastCardAction(playerId: 'p0')).state;
      s = accept(s, const DrawCardAction(playerId: 'p0')).state;
      expect(s.handOf('p0'), hasLength(3));
      expect(s.lastCardDeclaredBy, isNull);
    });

    test('a penalty draw clears it: the chain put cards back in the hand', () {
      var s = buildState(
        hands: [
          [c(CardSuit.spade, CardRank.tre), c(CardSuit.spade, CardRank.re)],
          [c(CardSuit.denari, CardRank.due)],
        ],
        top: c(CardSuit.coppe, CardRank.due),
        pendingPenalty: 2,
        chainLength: 1,
      ).copyWith(lastCardDeclaredBy: 'p0');
      s = accept(s, const DrawCardAction(playerId: 'p0')).state;
      expect(s.handOf('p0'), hasLength(4));
      expect(s.penaltyResolvedThisTurn, isTrue);
      expect(s.lastCardDeclaredBy, isNull);
    });

    test('a new deal clears it', () {
      var s = buildState(
        hands: [
          [],
          [c(CardSuit.denari, CardRank.tre)],
        ],
        top: _top,
        status: GameStatus.roundOver,
      ).copyWith(roundWinnerId: 'p0', lastCardDeclaredBy: 'p0');
      s = accept(
        s,
        const StartNextRoundAction(playerId: GameEngine.systemActorId),
      ).state;
      expect(s.lastCardDeclaredBy, isNull);
    });

    test('a seat that forfeits takes its announcement with it', () {
      var s = twoInHand(seats: 3);
      s = accept(s, const DeclareLastCardAction(playerId: 'p0')).state;
      s = accept(s, const ForfeitAction(playerId: 'p0')).state;
      expect(s.lastCardDeclaredBy, isNull);
    });

    test('it never leaks to the next seat', () {
      var s = accept(
        twoInHand(seats: 3),
        const DeclareLastCardAction(playerId: 'p0'),
      ).state;
      s = accept(s, PlayCardAction(playerId: 'p0', card: _playable)).state;
      expect(s.currentPlayerId, 'p1');
      expect(engine.canDeclareLastCard(s, 'p0'), isFalse);
      expect(
        validate(s, PlayCardAction(playerId: 'p1', card: _playable)),
        isNot(GameFailure.lastCardDeclarationRequired),
      );
    });
  });

  group('§16 — save and resume', () {
    test('a pending announcement survives a round trip through JSON', () {
      final s = accept(
        twoInHand(),
        const DeclareLastCardAction(playerId: 'p0'),
      ).state;
      final restored = GameState.fromJson(
        jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>,
      );
      expect(restored.lastCardDeclaredBy, 'p0');
      // And the play it was made for is accepted after the restore.
      expect(
        validate(restored, PlayCardAction(playerId: 'p0', card: _playable)),
        isNull,
      );
    });

    test('a save written before §16 restores with nobody declared, and the '
        'player can still declare', () {
      final json = twoInHand().toJson()..remove('lastCardDeclaredBy');
      final restored = GameState.fromJson(json);
      expect(restored.lastCardDeclaredBy, isNull);
      // Never stuck: the announcement is available, so the turn can proceed.
      expect(engine.canDeclareLastCard(restored, 'p0'), isTrue);
    });

    test('the rule survives a rules round trip and defaults on for old '
        'saves', () {
      const rules = GameRules();
      expect(rules.requireLastCardDeclaration, isTrue);
      expect(
        GameRules.fromJson(rules.toJson()).requireLastCardDeclaration,
        isTrue,
      );
      final legacy = rules.toJson()..remove('requireLastCardDeclaration');
      expect(GameRules.fromJson(legacy).requireLastCardDeclaration, isTrue);
    });
  });

  group('§16 — automated seats go through the same actions', () {
    test('GameSession.autoPlayCard announces first, then plays', () {
      final session = GameSession(twoInHand());
      expect(session.canDeclareLastCard, isTrue);

      final result = session.autoPlayCard(_playable);
      expect(result.accepted, isTrue);
      // Two engine actions, not one shortcut: the announcement is in the log.
      expect(session.state.version, 2);
      expect(session.state.handOf('p0'), [_spare]);
      expect(
        session.state.history.map((h) => h.type),
        containsAllInOrder([
          HistoryEntryType.lastCardDeclared,
          HistoryEntryType.play,
        ]),
      );
    });

    test('a plain playCard from a session is still refused', () {
      final session = GameSession(twoInHand());
      final result = session.playCard(_playable);
      expect(result.failure, GameFailure.lastCardDeclarationRequired);
      expect(session.state.version, 0);
    });

    test(
      'autoPlayCard does not announce when there is nothing to announce',
      () {
        final session = GameSession(
          buildState(
            hands: [
              [_playable, _spare, c(CardSuit.spade, CardRank.tre)],
              [c(CardSuit.denari, CardRank.tre)],
            ],
            top: _top,
          ),
        );
        expect(session.autoPlayCard(_playable).accepted, isTrue);
        expect(session.state.version, 1);
        expect(session.state.lastCardDeclaredBy, isNull);
      },
    );

    test('bots reach one card without ever proposing a refused play', () {
      // A whole bot-vs-bot match; every play goes through autoPlayCard, the
      // one path §16 is implemented on.
      for (final difficulty in BotDifficulty.values) {
        final session = GameSession.newMatch(
          gameId: 'bots-${difficulty.name}',
          players: [
            for (var i = 0; i < 3; i++)
              GamePlayer(
                id: 'p$i',
                name: 'P$i',
                type: PlayerType.bot,
                avatarId: 'marco',
                difficulty: difficulty,
              ),
          ],
          mode: GameMode.vsComputer,
          seed: 4242 + difficulty.index,
        );
        final bots = {
          for (final p in session.state.players)
            p.id: BotFactory.create(difficulty),
        };
        var declarations = 0;
        var steps = 0;
        while (!session.state.isFinished && steps++ < 6000) {
          final s = session.state;
          if (s.status == GameStatus.roundOver) {
            session.startNextRound();
            continue;
          }
          final bot = bots[s.currentPlayerId]!;
          final view = BotViewFactory.forCurrentPlayer(s);
          if (s.status == GameStatus.awaitingSuitChoice) {
            session.chooseSuit(bot.chooseSuit(view));
            continue;
          }
          final decision = bot.decide(view);
          switch (decision.action) {
            case BotAction.play:
              final due = session.canDeclareLastCard;
              final r = session.autoPlayCard(
                decision.card!,
                chosenSuit: decision.suit,
              );
              expect(
                r.accepted,
                isTrue,
                reason: '${difficulty.name} was refused: ${r.failure}',
              );
              if (due) declarations++;
            case BotAction.draw:
              session.drawCard();
              if (session.state.drawnCard == null && session.canEndTurn) {
                session.endTurn();
              }
            case BotAction.endTurn:
              if (session.canEndTurn) {
                session.endTurn();
              } else if (session.canDraw) {
                session.drawCard();
              }
          }
        }
        expect(
          session.state.isFinished,
          isTrue,
          reason: '${difficulty.name} match did not finish',
        );
        expect(
          declarations,
          greaterThan(0),
          reason:
              '${difficulty.name} never reached a last card, so the rule '
              'was never exercised',
        );
      }
    });
  });
}
