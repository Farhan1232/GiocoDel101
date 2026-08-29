import 'package:flutter_test/flutter_test.dart';
import 'package:gioco_del_101/features/game/domain/card_rank.dart';
import 'package:gioco_del_101/features/game/domain/card_suit.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_engine.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_event.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_failure.dart';
import 'package:gioco_del_101/features/game/domain/game_action.dart';
import 'package:gioco_del_101/features/game/domain/game_rules.dart';
import 'package:gioco_del_101/features/game/domain/game_state.dart';

import '../support/engine_harness.dart';

const engine = GameEngine();

ActionAccepted ok(GameState s, GameAction a) {
  final r = engine.applyAction(s, a);
  expect(r, isA<ActionAccepted>(), reason: '$r');
  return r as ActionAccepted;
}

void main() {
  final cav = c(CardSuit.spade, CardRank.cavallo);
  final top = c(CardSuit.coppe, CardRank.cinque);

  group('Nove / Cavallo = change suit (§7)', () {
    test('is playable on any suit by default', () {
      final s = buildState(
        hands: [
          [cav],
          [c(CardSuit.denari, CardRank.tre)],
        ],
        top: c(CardSuit.bastoni, CardRank.re),
      );
      expect(engine.canPlay(s, cav), isTrue);
    });

    test(
      'wildNineCanAlwaysPlay=false: must match suit or rank like any card',
      () {
        final s = buildState(
          hands: [
            [cav, c(CardSuit.spade, CardRank.re)],
            [c(CardSuit.denari, CardRank.tre)],
          ],
          top: c(CardSuit.bastoni, CardRank.re),
          rules: const GameRules(wildNineCanAlwaysPlay: false),
        );
        expect(engine.canPlay(s, cav), isFalse);
        final onSpade = s.copyWith(activeSuit: CardSuit.spade);
        expect(engine.canPlay(onSpade, cav), isTrue);
        final onCavallo = buildState(
          hands: [
            [cav, c(CardSuit.spade, CardRank.re)],
            [c(CardSuit.denari, CardRank.tre)],
          ],
          top: c(CardSuit.bastoni, CardRank.cavallo),
          rules: const GameRules(wildNineCanAlwaysPlay: false),
        );
        expect(engine.canPlay(onCavallo, cav), isTrue, reason: 'same rank');
      },
    );

    test(
      'requires a suit selection: nothing else is legal until it is named',
      () {
        final s = buildState(
          hands: [
            [cav, c(CardSuit.spade, CardRank.re)],
            [c(CardSuit.denari, CardRank.tre)],
          ],
          top: top,
        );
        final r = ok(s, PlayCardAction(playerId: 'p0', card: cav));
        expect(r.state.status, GameStatus.awaitingSuitChoice);
        expect(
          r.state.currentPlayerId,
          'p0',
          reason: 'the same player names the suit',
        );
        expect(
          r.state.activeSuit,
          CardSuit.coppe,
          reason: 'unchanged until named',
        );
        expect(r.state.topCard, cav);
        expect(r.events.whereType<SuitChoiceRequestedEvent>().single.card, cav);
        expect(engine.getPlayableCards(r.state, 'p0'), isEmpty);
        expect(
          engine
              .applyAction(
                r.state,
                PlayCardAction(
                  playerId: 'p0',
                  card: c(CardSuit.spade, CardRank.re),
                ),
              )
              .failure,
          GameFailure.suitSelectionRequired,
        );
        expect(
          engine
              .applyAction(r.state, const DrawCardAction(playerId: 'p0'))
              .failure,
          GameFailure.suitSelectionRequired,
        );
        expect(
          engine.applyAction(r.state, const PassAction(playerId: 'p0')).failure,
          GameFailure.suitSelectionRequired,
        );
        expect(
          engine
              .applyAction(
                r.state,
                const ChooseSuitAction(playerId: 'p1', suit: CardSuit.denari),
              )
              .failure,
          GameFailure.notPlayersTurn,
        );
      },
    );

    test('the chosen suit controls the next legal moves', () {
      final s = buildState(
        hands: [
          [cav, c(CardSuit.spade, CardRank.re)],
          [
            c(CardSuit.denari, CardRank.tre),
            c(CardSuit.coppe, CardRank.tre),
            c(CardSuit.bastoni, CardRank.cavallo),
          ],
        ],
        top: top,
      );
      var next = ok(s, PlayCardAction(playerId: 'p0', card: cav)).state;
      final chosen = ok(
        next,
        const ChooseSuitAction(playerId: 'p0', suit: CardSuit.denari),
      );
      next = chosen.state;
      expect(next.activeSuit, CardSuit.denari);
      expect(next.status, GameStatus.awaitingAction);
      expect(next.currentPlayerId, 'p1');
      expect(
        chosen.events.whereType<SuitChosenEvent>().single.suit,
        CardSuit.denari,
      );
      expect(next.stats.cavalloSuits['p0'], ['denari']);
      // denari_tre matches the named suit; coppe_tre matches neither the
      // named suit nor the top rank (cavallo); bastoni_cavallo matches rank.
      expect(engine.getPlayableCards(next, 'p1'), [
        c(CardSuit.denari, CardRank.tre),
        c(CardSuit.bastoni, CardRank.cavallo),
      ]);
      expect(
        engine
            .applyAction(
              next,
              PlayCardAction(
                playerId: 'p1',
                card: c(CardSuit.coppe, CardRank.tre),
              ),
            )
            .failure,
        GameFailure.illegalCard,
      );
    });

    test('all four suits can be named', () {
      for (final suit in CardSuit.values) {
        final s = buildState(
          hands: [
            [cav, c(CardSuit.spade, CardRank.re)],
            [c(CardSuit.denari, CardRank.tre)],
          ],
          top: top,
        );
        final r = ok(
          s,
          PlayCardAction(playerId: 'p0', card: cav, chosenSuit: suit),
        );
        expect(r.state.activeSuit, suit);
        expect(r.state.currentPlayerId, 'p1');
      }
    });

    test('a suit choice with no Cavallo pending is refused', () {
      final s = buildState(
        hands: [
          [c(CardSuit.spade, CardRank.re)],
          [c(CardSuit.denari, CardRank.tre)],
        ],
        top: top,
      );
      expect(
        engine
            .applyAction(
              s,
              const ChooseSuitAction(playerId: 'p0', suit: CardSuit.denari),
            )
            .failure,
        GameFailure.suitSelectionNotPending,
      );
    });

    test('a Cavallo as the last card ends the round without a suit choice', () {
      final s = buildState(
        hands: [
          [cav],
          [c(CardSuit.denari, CardRank.tre)],
        ],
        top: top,
      );
      final r = ok(s, PlayCardAction(playerId: 'p0', card: cav));
      expect(r.state.status, GameStatus.roundOver);
      expect(r.events.whereType<SuitChoiceRequestedEvent>(), isEmpty);
    });

    group('blocking a pending +2 (§6a, provisional)', () {
      GameState chainTable(GameRules rules) => buildState(
        hands: [
          [c(CardSuit.coppe, CardRank.re), c(CardSuit.denari, CardRank.due)],
          [cav, c(CardSuit.spade, CardRank.tre)],
        ],
        top: c(CardSuit.coppe, CardRank.due),
        discardBelowTop: [top],
        currentIndex: 1,
        pendingPenalty: 4,
        chainLength: 2,
        rules: rules,
      );

      test('disabled: the Cavallo is not playable into a chain', () {
        final s = chainTable(
          const GameRules(nineBlockMode: NineBlockMode.disabled),
        );
        expect(engine.getPlayableCards(s, 'p1'), isEmpty);
        expect(
          engine
              .applyAction(s, PlayCardAction(playerId: 'p1', card: cav))
              .failure,
          GameFailure.illegalCard,
        );
        expect(engine.mustTakePenalty(s), isTrue);
      });

      test(
        'cancel (default): the pending total is wiped, suit is named, play continues',
        () {
          final s = chainTable(const GameRules());
          expect(s.rules.nineBlockMode, NineBlockMode.cancel);
          expect(engine.getPlayableCards(s, 'p1'), [cav]);
          final r = ok(s, PlayCardAction(playerId: 'p1', card: cav));
          expect(r.state.pendingDrawCount, 0);
          expect(r.state.chainLength, 0);
          expect(r.state.status, GameStatus.awaitingSuitChoice);
          final blocked = r.events.whereType<ChainBlockedEvent>().single;
          expect(blocked.cancelled, isTrue);
          expect(blocked.total, 4);
          final named = ok(
            r.state,
            const ChooseSuitAction(playerId: 'p1', suit: CardSuit.bastoni),
          ).state;
          expect(named.currentPlayerId, 'p0');
          expect(named.players[0].hand, hasLength(2), reason: 'nobody drew');
          // p0 holds a 2 but there is no chain: normal play applies.
          expect(engine.getPlayableCards(named, 'p0'), isEmpty);
          expect(
            ok(
              named,
              const DrawCardAction(playerId: 'p0'),
            ).state.pendingDrawCount,
            0,
          );
        },
      );

      test(
        'passOn: the pending total is forwarded unchanged and may be stacked or drawn',
        () {
          final s = chainTable(
            const GameRules(nineBlockMode: NineBlockMode.passOn),
          );
          final r = ok(
            s,
            PlayCardAction(
              playerId: 'p1',
              card: cav,
              chosenSuit: CardSuit.bastoni,
            ),
          );
          expect(r.state.pendingDrawCount, 4);
          expect(r.state.chainLength, 2);
          expect(
            r.events.whereType<ChainBlockedEvent>().single.cancelled,
            isFalse,
          );
          expect(r.state.currentPlayerId, 'p0');
          // p0 may stack their 2…
          expect(engine.getPlayableCards(r.state, 'p0'), [
            c(CardSuit.denari, CardRank.due),
          ]);
          final stacked = ok(
            r.state,
            PlayCardAction(
              playerId: 'p0',
              card: c(CardSuit.denari, CardRank.due),
            ),
          ).state;
          expect(stacked.pendingDrawCount, 6);
          expect(stacked.chainLength, 3);
          // …or take the four.
          final drawn = ok(r.state, const DrawCardAction(playerId: 'p0')).state;
          expect(drawn.players[0].hand, hasLength(6));
          expect(drawn.pendingDrawCount, 0);
        },
      );

      test(
        'nineBlockChangesSuit=false: the block does not open the suit ritual',
        () {
          final s = chainTable(const GameRules(nineBlockChangesSuit: false));
          final r = ok(s, PlayCardAction(playerId: 'p1', card: cav));
          expect(r.state.status, GameStatus.awaitingAction);
          expect(r.state.currentPlayerId, 'p0');
          expect(
            r.state.activeSuit,
            CardSuit.coppe,
            reason: 'the previous active suit stands',
          );
          expect(r.state.pendingDrawCount, 0);
        },
      );

      test('a blocking Cavallo that empties the hand ends the round', () {
        final s = buildState(
          hands: [
            [c(CardSuit.coppe, CardRank.re)],
            [cav],
          ],
          top: c(CardSuit.coppe, CardRank.due),
          currentIndex: 1,
          pendingPenalty: 2,
          chainLength: 1,
        );
        final r = ok(s, PlayCardAction(playerId: 'p1', card: cav));
        expect(r.state.status, GameStatus.roundOver);
        expect(r.state.roundWinnerId, 'p1');
        expect(r.state.pendingDrawCount, 0);
      });

      test('history records the block', () {
        final s = chainTable(const GameRules());
        final r = ok(s, PlayCardAction(playerId: 'p1', card: cav));
        expect(
          r.state.history.map((h) => h.type.name),
          contains('chainBlocked'),
        );
      });
    });
  });
}
