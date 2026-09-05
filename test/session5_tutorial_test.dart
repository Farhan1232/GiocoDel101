import 'package:flutter_test/flutter_test.dart';
import 'package:gioco_del_101/features/game/domain/card_rank.dart';
import 'package:gioco_del_101/features/game/domain/card_suit.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_engine.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_event.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_session.dart';
import 'package:gioco_del_101/features/game/domain/game_card.dart';
import 'package:gioco_del_101/features/game/domain/game_state.dart';
import 'package:gioco_del_101/features/tutorial/application/tutorial_controller.dart';
import 'package:gioco_del_101/features/tutorial/domain/tutorial_lessons.dart';

const _seats = TutorialSeats(playerName: 'Tu', avatarId: 'lucia');

/// Applies one expectation to a session the way the controller would,
/// returning the events the engine produced.
List<GameEvent> _apply(GameSession s, TutorialExpectation e) {
  final events = <GameEvent>[];
  final off = s.listen(events.add);
  switch (e) {
    case ExpectAnyLegalCard():
      final legal = s.playableCardsFor(s.currentPlayer);
      expect(legal, isNotEmpty);
      expect(s.playCard(legal.first).accepted, isTrue);
    case ExpectCard(:final card):
      expect(
        s.playableCardsFor(s.currentPlayer),
        contains(card),
        reason: 'the lesson asks for a card the engine refuses',
      );
      expect(s.playCard(card).accepted, isTrue);
    case ExpectDraw():
      expect(s.canDraw, isTrue);
      expect(s.drawCard().accepted, isTrue);
    case ExpectSuit():
      expect(s.state.status, GameStatus.awaitingSuitChoice);
      expect(s.chooseSuit(CardSuit.bastoni).accepted, isTrue);
  }
  off();
  return events;
}

void main() {
  group('Tutorial lessons are real engine states (§X)', () {
    for (final lesson in TutorialLessons.all) {
      test('${lesson.id.name}: 40 cards, no duplicates, legal steps', () {
        final state = lesson.build(_seats);
        final all = [
          ...state.drawPile,
          ...state.discardPile,
          for (final p in state.players) ...p.hand,
        ];
        expect(all, hasLength(Deck.size));
        expect(all.map((c) => c.id).toSet(), hasLength(Deck.size));
        expect(state.currentPlayerId, TutorialSeats.humanId);
        expect(state.status, GameStatus.awaitingAction);
        // The engine itself accepts the state: an action validates.
        expect(
          const GameEngine().getPlayableCards(state, state.currentPlayerId),
          isNotNull,
        );

        final session = GameSession(state);
        for (final step in lesson.steps) {
          _apply(session, step);
        }
      });
    }

    test('firstCard offers a suit match and a rank match', () {
      final s = GameSession(
        TutorialLessons.byId(TutorialLessonId.firstCard).build(_seats),
      );
      final legal = s.playableCardsFor(s.currentPlayer).toSet();
      expect(legal, {
        const GameCard(CardSuit.coppe, CardRank.sette),
        const GameCard(CardSuit.spade, CardRank.cinque),
      });
    });

    test('drawing: nothing playable, the drawn card is', () {
      final s = GameSession(
        TutorialLessons.byId(TutorialLessonId.drawing).build(_seats),
      );
      expect(s.playableCardsFor(s.currentPlayer), isEmpty);
      _apply(s, const ExpectDraw());
      expect(s.state.drawnCard, const GameCard(CardSuit.coppe, CardRank.sei));
      expect(s.currentPlayer.id, TutorialSeats.humanId);
    });

    test('ace: the opponent is skipped and the turn comes back', () {
      final lesson = TutorialLessons.byId(TutorialLessonId.ace);
      final s = GameSession(lesson.build(_seats));
      final events = _apply(s, lesson.steps.single);
      expect(events.whereType<TurnSkippedEvent>(), hasLength(1));
      expect(s.currentPlayer.id, TutorialSeats.humanId);
    });

    test('two: a +2 is pending for the opponent', () {
      final lesson = TutorialLessons.byId(TutorialLessonId.two);
      final s = GameSession(lesson.build(_seats));
      final events = _apply(s, lesson.steps.single);
      expect(events.whereType<ChainGrewEvent>().single.total, 2);
      expect(s.currentPlayer.id, TutorialSeats.opponentId);
      // The scripted opponent holds no 2 and no Cavallo: it must draw.
      expect(s.playableCardsFor(s.currentPlayer), isEmpty);
      expect(s.drawCard().accepted, isTrue);
      expect(s.state.playerById(TutorialSeats.opponentId)!.hand, hasLength(7));
    });

    test('chain: answering a 2 stacks to +4', () {
      final lesson = TutorialLessons.byId(TutorialLessonId.chain);
      final s = GameSession(lesson.build(_seats));
      // Inside the chain only the 2 is legal, not the Coppe 7.
      expect(s.playableCardsFor(s.currentPlayer), [
        const GameCard(CardSuit.spade, CardRank.due),
      ]);
      final events = _apply(s, lesson.steps.single);
      expect(events.whereType<ChainGrewEvent>().single.total, 4);
    });

    test('cavallo: opens the suit choice, then the chosen suit is active', () {
      final lesson = TutorialLessons.byId(TutorialLessonId.cavallo);
      final s = GameSession(lesson.build(_seats));
      _apply(s, lesson.steps[0]);
      expect(s.state.status, GameStatus.awaitingSuitChoice);
      _apply(s, lesson.steps[1]);
      expect(s.state.activeSuit, CardSuit.bastoni);
    });

    test('block: the Cavallo cancels the pending +2', () {
      final lesson = TutorialLessons.byId(TutorialLessonId.block);
      final s = GameSession(lesson.build(_seats));
      final events = _apply(s, lesson.steps[0]);
      final blocked = events.whereType<ChainBlockedEvent>().single;
      expect(blocked.cancelled, isTrue);
      expect(s.state.pendingDrawCount, 0);
      _apply(s, lesson.steps[1]);
      expect(s.state.status, GameStatus.awaitingAction);
    });

    test('centouno: the last card lands the opponent on exactly 101', () {
      final lesson = TutorialLessons.byId(TutorialLessonId.centouno);
      final s = GameSession(lesson.build(_seats));
      final events = _apply(s, lesson.steps.single);
      final ended = events.whereType<RoundEndedEvent>().single;
      final marco = ended.result.rows.firstWhere(
        (r) => r.playerId == TutorialSeats.opponentId,
      );
      expect(marco.previousScore + marco.penalty, 101);
      expect(marco.hitExact101, isTrue);
      expect(marco.newScore, 0);
      expect(events.whereType<Exact101Event>(), hasLength(1));
      expect(s.state.isRoundOver, isTrue);
    });
  });

  group('TutorialController walks every lesson (§X)', () {
    TutorialController make() {
      final c = TutorialController(seats: _seats, withDelays: () => false);
      c.onInit();
      return c;
    }

    test(
      'only the asked-for card lights up and a wrong card is refused',
      () async {
        final c = make();
        c.start();
        await Future<void>.delayed(Duration.zero);
        expect(c.phase.value, TutorialPhase.waiting);
        // Lesson 1 is free: both legal cards light up.
        expect(c.playableForViewer, hasLength(2));
        // A card that is not legal is refused with a hint, not applied.
        final before = c.state.version;
        await c.playCard(const GameCard(CardSuit.denari, CardRank.tre));
        expect(c.state.version, before);
        expect(c.hint.value, isNotNull);
        expect(c.phase.value, TutorialPhase.waiting);
        c.onClose();
      },
    );

    test(
      'the whole course, start to finish, with the scripted opponent',
      () async {
        final c = make();
        c.start();
        await Future<void>.delayed(Duration.zero);

        for (var i = 0; i < c.lessons.length; i++) {
          expect(c.lessonIndex.value, i);
          expect(c.phase.value, TutorialPhase.waiting, reason: 'lesson $i');
          expect(
            c.isHumanTurn,
            isTrue,
            reason: 'lesson $i starts on the player',
          );
          for (final step in c.lesson.steps) {
            expect(c.canInteract || step is ExpectSuit, isTrue);
            switch (step) {
              case ExpectAnyLegalCard():
                await c.playCard(c.playableForViewer.first);
              case ExpectCard(:final card):
                expect(c.playableForViewer, [card]);
                await c.playCard(card);
              case ExpectDraw():
                expect(c.canDraw, isTrue);
                await c.drawCard();
              case ExpectSuit():
                expect(c.pendingSuitChoice.value, isNotNull);
                await c.chooseSuit(CardSuit.bastoni);
            }
          }
          expect(c.phase.value, TutorialPhase.lessonDone, reason: 'lesson $i');
          // The opponent's reply (where scripted) has already played and the
          // turn is back with the player, or the round ended.
          if (c.lesson.opponentReplies) {
            expect(c.isHumanTurn || c.state.isRoundOver, isTrue);
          }
          // The results screen must never be triggered by the tutorial.
          expect(c.lastRoundResult.value, isNull);
          await c.next();
        }
        expect(c.phase.value, TutorialPhase.finished);

        await c.restart();
        expect(c.lessonIndex.value, 0);
        expect(c.phase.value, TutorialPhase.waiting);
        c.onClose();
      },
    );

    test(
      'the Centouno lesson ends the round without a results screen',
      () async {
        final c = TutorialController(
          seats: _seats,
          withDelays: () => false,
          lessons: [TutorialLessons.byId(TutorialLessonId.centouno)],
        )..onInit();
        c.start();
        await Future<void>.delayed(Duration.zero);
        await c.playCard(const GameCard(CardSuit.coppe, CardRank.sette));
        expect(c.state.isRoundOver, isTrue);
        expect(c.phase.value, TutorialPhase.lessonDone);
        expect(c.lastRoundResult.value, isNull);
        expect(c.state.playerById(TutorialSeats.opponentId)!.score, 0);
        c.onClose();
      },
    );
  });
}
