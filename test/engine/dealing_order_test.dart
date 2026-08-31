import 'package:flutter_test/flutter_test.dart';
import 'package:gioco_del_101/features/game/domain/card_rank.dart';
import 'package:gioco_del_101/features/game/domain/card_suit.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_engine.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_failure.dart';
import 'package:gioco_del_101/features/game/domain/game_action.dart';
import 'package:gioco_del_101/features/game/domain/game_card.dart';
import 'package:gioco_del_101/features/game/domain/game_player.dart';
import 'package:gioco_del_101/features/game/domain/game_rules.dart';
import 'package:gioco_del_101/features/game/domain/game_state.dart';
import 'package:gioco_del_101/features/game/domain/player_type.dart';

import 'package:gioco_del_101/features/game/application/table_cue.dart';

import '../support/engine_harness.dart';

/// GAME_SPEC §3 / §12a — the cards go out **one at a time, clockwise,
/// starting from the seat to the dealer's left**.
///
/// The client reported that "the sequential hand in clockwise order still
/// doesn't work": the dealer badge rotated and the animation travelled round
/// the table, but `GameEngine._deal` handed the cards out in plain seat order
/// (0, 1, 2, 3) whatever the dealer did, so who dealt had no effect on who
/// got which card. These cases pin the **canonical engine order**, not the
/// badge — the card each seat actually receives.
const engine = GameEngine();

List<GamePlayer> _seats(int n, {List<bool>? eliminated}) => [
  for (var i = 0; i < n; i++)
    GamePlayer(
      id: 'p$i',
      name: 'P$i',
      type: i == 0 ? PlayerType.humanLocal : PlayerType.bot,
      avatarId: 'marco',
      difficulty: i == 0 ? null : BotDifficulty.normal,
      eliminated: eliminated == null ? false : eliminated[i],
    ),
];

/// A state with [n] empty-handed seats and a chosen dealer, ready to deal.
GameState _table(
  int n, {
  required int dealerSeat,
  int startingSeat = 0,
  List<bool>? eliminated,
  TurnDirection direction = TurnDirection.clockwise,
  int handSize = 5,
  int seed = 99,
}) => GameState(
  gameId: 'deal',
  mode: GameMode.vsComputer,
  rules: GameRules(startingHandSize: handSize, initialDirection: direction),
  players: _seats(n, eliminated: eliminated),
  drawPile: const [],
  discardPile: const [GameCard(CardSuit.coppe, CardRank.cinque)],
  activeSuit: CardSuit.coppe,
  currentSeat: startingSeat,
  dealerSeat: dealerSeat,
  direction: direction,
  seed: seed,
);

/// Deals [state] through the *public* engine and returns, for every card in
/// the order it left the stock, the seat it went to.
///
/// Reconstructed from the dealt hands rather than from the order list, so it
/// is evidence about the cards themselves: the k-th card off the stock is the
/// k-th element here.
List<int> dealtSeatSequence(GameState state) {
  final dealt = engine.createGame(
    gameId: state.gameId,
    players: state.players,
    mode: state.mode,
    seed: state.seed,
    rules: state.rules,
    startingSeat: state.currentSeat,
  );
  return _sequenceOf(dealt);
}

/// The seat each successive card went to, read back off the finished deal.
///
/// The stock deals from its end, so the full shuffled deck in deal order is
/// the reverse of what a fresh shuffle produces. Rather than reproduce the
/// shuffle, this reads the *positions*: card `i` of a seat's hand was the
/// i-th card that seat received, so interleaving the hands by index in
/// dealing order reconstructs the sequence the engine used.
List<int> _sequenceOf(GameState s) {
  final order = s.dealingSeatOrder;
  final handSize = s.rules.startingHandSize;
  return [
    for (var round = 0; round < handSize; round++)
      for (final seat in order)
        if (round < s.players[seat].hand.length) seat,
  ];
}

/// Every card in the order the engine dealt it, so a test can assert on the
/// cards and not only on the seats.
List<(int, GameCard)> dealtCards(GameState s) {
  final order = s.dealingSeatOrder;
  final out = <(int, GameCard)>[];
  for (var round = 0; round < s.rules.startingHandSize; round++) {
    for (final seat in order) {
      final hand = s.players[seat].hand;
      if (round < hand.length) out.add((seat, hand[round]));
    }
  }
  return out;
}

GameState start(
  int n, {
  required int dealerSeat,
  int startingSeat = 0,
  int handSize = 5,
  int seed = 99,
}) => engine
    .createGame(
      gameId: 'deal',
      players: _seats(n),
      mode: GameMode.vsComputer,
      seed: seed,
      rules: GameRules(startingHandSize: handSize),
      startingSeat: dealerSeat,
    )
    .copyWith(currentSeat: startingSeat);

/// Ends the current round, keeping the 40-card invariant intact.
///
/// The seat to act keeps one card it may legally play and the rest of its
/// hand goes to the bottom of the stock — cards are moved, never invented —
/// and then it plays that card and empties its hand. A seat with nothing
/// legal draws or passes and the next one is tried.
GameState _playRoundOut(GameState s) {
  for (var guard = 0; guard < 200 && !s.isRoundOver; guard++) {
    if (s.status == GameStatus.awaitingSuitChoice) {
      s = _apply(
        s,
        ChooseSuitAction(playerId: s.currentPlayerId, suit: s.activeSuit),
      );
      continue;
    }
    final actor = s.currentPlayer;
    final playable = engine.getPlayableCards(s, actor.id);
    if (playable.isEmpty) {
      if (engine.canDraw(s)) {
        s = _apply(s, DrawCardAction(playerId: actor.id));
      } else if (engine.canPass(s)) {
        s = _apply(s, PassAction(playerId: actor.id));
      } else {
        break;
      }
      continue;
    }
    final keep = playable.firstWhere(
      (c) => !c.isCavallo,
      orElse: () => playable.first,
    );
    final rest = actor.hand.where((c) => c != keep).toList();
    s = s
        .withPlayer(actor.copyWith(hand: [keep]))
        .copyWith(drawPile: [...rest, ...s.drawPile]);
    // §16 — going from one card to none needs no announcement.
    s = _apply(
      s,
      PlayCardAction(
        playerId: actor.id,
        card: keep,
        chosenSuit: keep.isCavallo ? s.activeSuit : null,
      ),
    );
  }
  return s;
}

/// The lap this table's dealer should serve, worked out here rather than
/// asked of the engine: every live seat, clockwise, starting one place after
/// the dealer.
List<int> _expectedLap(GameState s) {
  final n = s.players.length;
  return [
    for (var k = 1; k <= n; k++)
      if (!s.players[(s.dealerSeat + k) % n].eliminated) (s.dealerSeat + k) % n,
  ];
}

GameState _apply(GameState s, GameAction a) {
  final r = engine.applyAction(s, a);
  expect(r, isA<ActionAccepted>(), reason: '$a on $s -> $r');
  return (r as ActionAccepted).state;
}

void main() {
  group('§3/§12a — the deal goes clockwise from the dealer\'s left', () {
    // The exact sequences the client specified.
    final expected = <String, Map<int, List<int>>>{
      '2 players': {
        0: [1, 0],
        1: [0, 1],
      },
      '3 players': {
        0: [1, 2, 0],
        1: [2, 0, 1],
        2: [0, 1, 2],
      },
      '4 players': {
        0: [1, 2, 3, 0],
        1: [2, 3, 0, 1],
        2: [3, 0, 1, 2],
        3: [0, 1, 2, 3],
      },
    };

    for (final entry in expected.entries) {
      final n = int.parse(entry.key.split(' ').first);
      for (final byDealer in entry.value.entries) {
        final dealer = byDealer.key;
        final lap = byDealer.value;

        test('${entry.key}, dealer $dealer: one lap is ${lap.join(",")}', () {
          final s = _table(n, dealerSeat: dealer);
          expect(s.dealingSeatOrder, lap);
          expect(s.dealingOrder, [for (final i in lap) 'p$i']);
        });

        test('${entry.key}, dealer $dealer: the cards themselves go out '
            '${lap.join(",")} lap after lap', () {
          final dealt = engine.createGame(
            gameId: 'deal',
            players: _seats(n),
            mode: GameMode.vsComputer,
            seed: 4242,
            startingSeat: dealer,
          );
          expect(dealt.dealerSeat, dealer);

          // Five laps of the same clockwise sequence, 5 cards each.
          final wanted = [for (var i = 0; i < 5; i++) ...lap];
          expect(_sequenceOf(dealt), wanted);

          // And the cards are consecutive off the top of the stock: rebuild
          // the deal from the hands and check every seat's k-th card is the
          // k-th time that seat came round.
          final sequence = dealtCards(dealt);
          expect(sequence, hasLength(5 * n));
          for (var k = 0; k < sequence.length; k++) {
            expect(
              sequence[k].$1,
              wanted[k],
              reason: 'card ${k + 1} must go to seat ${wanted[k]}',
            );
          }
          // No card was dealt twice and every hand is full.
          expect(sequence.map((e) => e.$2).toSet(), hasLength(5 * n));
          for (final p in dealt.players) {
            expect(p.hand, hasLength(5));
          }
        });
      }
    }

    test('the sequence wraps: the dealer is served last in every lap', () {
      for (final n in [2, 3, 4]) {
        for (var dealer = 0; dealer < n; dealer++) {
          final s = _table(n, dealerSeat: dealer);
          expect(
            s.dealingSeatOrder.last,
            dealer,
            reason: '$n seats, dealer $dealer',
          );
          expect(
            s.dealingSeatOrder.first,
            (dealer + 1) % n,
            reason: 'the dealer serves their left first',
          );
          expect(s.dealingSeatOrder, hasLength(n));
        }
      }
    });

    test('an eliminated seat is skipped, clockwise order preserved', () {
      // 4 seats, seat 2 knocked out, dealer 0 -> 1, 3, 0.
      final s = _table(
        4,
        dealerSeat: 0,
        eliminated: [false, false, true, false],
      );
      expect(s.dealingSeatOrder, [1, 3, 0]);

      // Dealer 1 -> 3, 0, 1.  Dealer 3 -> 0, 1, 3.
      expect(
        _table(
          4,
          dealerSeat: 1,
          eliminated: [false, false, true, false],
        ).dealingSeatOrder,
        [3, 0, 1],
      );
      expect(
        _table(
          4,
          dealerSeat: 3,
          eliminated: [false, false, true, false],
        ).dealingSeatOrder,
        [0, 1, 3],
      );
      // The dealer itself being out does not break the lap.
      expect(
        _table(
          4,
          dealerSeat: 2,
          eliminated: [false, false, true, false],
        ).dealingSeatOrder,
        [3, 0, 1],
      );
    });

    test('counter-clockwise tables deal the other way', () {
      final s = _table(
        4,
        dealerSeat: 0,
        direction: TurnDirection.counterClockwise,
      );
      expect(s.dealingSeatOrder, [3, 2, 1, 0]);
    });

    test('a two-handed table alternates', () {
      expect(_table(2, dealerSeat: 0).dealingSeatOrder, [1, 0]);
      expect(_table(2, dealerSeat: 1).dealingSeatOrder, [0, 1]);
      final dealt = engine.createGame(
        gameId: 'deal',
        players: _seats(2),
        mode: GameMode.vsComputer,
        seed: 7,
        startingSeat: 0,
      );
      expect(_sequenceOf(dealt), [1, 0, 1, 0, 1, 0, 1, 0, 1, 0]);
    });
  });

  group('§12a — the dealer moves every round, and the deal moves with it', () {
    /// Plays [rounds] rounds out by making the leader empty their hand, and
    /// records (dealer, deal order) for each new deal.
    test('four seats: the dealer and the deal order both advance', () {
      var s = engine.createGame(
        gameId: 'rot',
        players: _seats(4),
        mode: GameMode.vsComputer,
        seed: 1234,
        startingSeat: 0,
      );
      final seen = <(int, List<int>)>[(s.dealerSeat, s.dealingSeatOrder)];

      for (var round = 0; round < 4; round++) {
        s = _playRoundOut(s);
        expect(s.isRoundOver, isTrue, reason: 'round $round did not end');
        if (s.isFinished) break;
        final next = engine.applyAction(
          s,
          const StartNextRoundAction(playerId: GameEngine.systemActorId),
        );
        expect(next, isA<ActionAccepted>());
        s = (next as ActionAccepted).state;
        // Worked out independently of the engine: the live seats, clockwise,
        // starting after the dealer. Seats drop out as the scores climb, and
        // the lap must close over whoever is left.
        expect(
          s.dealingSeatOrder,
          _expectedLap(s),
          reason: 'round ${round + 2}: dealer ${s.dealerSeat}',
        );
        seen.add((s.dealerSeat, s.dealingSeatOrder));
      }

      expect(seen.length, greaterThanOrEqualTo(3));
      for (var i = 1; i < seen.length; i++) {
        expect(
          seen[i].$1,
          isNot(seen[i - 1].$1),
          reason: 'the dealer must move every round',
        );
        expect(
          seen[i].$2,
          isNot(seen[i - 1].$2),
          reason: 'the deal order must move with the dealer',
        );
      }
    });

    test('the previous round\'s closer still leads, whoever dealt', () {
      // p2 closes the round; p2 must act first next round, while the deal
      // starts from the seat left of the (rotated) dealer.
      final win = c(CardSuit.coppe, CardRank.re);
      final s = buildState(
        hands: [
          [c(CardSuit.spade, CardRank.tre)],
          [c(CardSuit.denari, CardRank.tre)],
          [win],
        ],
        top: c(CardSuit.coppe, CardRank.cinque),
        currentIndex: 2,
        dealerIndex: 0,
      );
      final closed =
          (engine.applyAction(s, PlayCardAction(playerId: 'p2', card: win))
                  as ActionAccepted)
              .state;
      expect(closed.roundWinnerId, 'p2');

      final next =
          (engine.applyAction(
                    closed,
                    const StartNextRoundAction(
                      playerId: GameEngine.systemActorId,
                    ),
                  )
                  as ActionAccepted)
              .state;

      // §12 — the closer leads.
      expect(next.currentPlayerId, 'p2');
      // §12a — the deal moved on independently: dealer 0 -> 1.
      expect(next.dealerSeat, 1);
      // …and the cards went out from the dealer's left, not from the leader.
      expect(next.dealingSeatOrder, [2, 0, 1]);
      expect(next.dealingSeatOrder.first, isNot(next.currentSeat + 1));
    });

    test('a deal that skips an eliminated seat still serves everyone left', () {
      final s = _table(
        4,
        dealerSeat: 1,
        startingSeat: 0,
        eliminated: [false, true, false, false],
      );
      expect(s.dealingSeatOrder, [2, 3, 0]);
      final dealt = engine.createGame(
        gameId: 'deal',
        players: _seats(4, eliminated: [false, true, false, false]),
        mode: GameMode.vsComputer,
        seed: 5,
        startingSeat: 0,
      );
      // Seat 1 is out and gets nothing; the rest are dealt in full.
      expect(dealt.players[1].hand, isEmpty);
      for (final i in [0, 2, 3]) {
        expect(dealt.players[i].hand, hasLength(5));
      }
    });
  });

  group('§29 — the table animates the sequence the engine dealt', () {
    // `DealCue.seatIds` is what `_animateDeal` walks, one card per seat per
    // lap. It has to be the engine's own order, or the player watches cards
    // arrive somewhere other than where they were dealt — which is the bug
    // the client reported.
    test('the deal cue follows GameState.dealingOrder exactly', () {
      for (final n in [2, 3, 4]) {
        for (var dealer = 0; dealer < n; dealer++) {
          final s = _table(n, dealerSeat: dealer);
          expect(
            dealingOrder(s),
            s.dealingOrder,
            reason: '$n seats, dealer $dealer',
          );
          expect(dealingOrder(s), [
            for (final seat in _expectedLap(s)) 'p$seat',
          ]);
        }
      }
    });

    test('the cue skips an eliminated seat the same way the engine does', () {
      final s = _table(
        4,
        dealerSeat: 0,
        eliminated: [false, false, true, false],
      );
      expect(dealingOrder(s), ['p1', 'p3', 'p0']);
      expect(dealingOrder(s), s.dealingOrder);
    });

    test('the viewer\'s hand is in the order the cards reached them', () {
      // `_animateDeal` flies `own[ownIndex++]` to the viewer on each lap, so
      // hand position k must be the card dealt on lap k. That is only true
      // because the engine appends in dealing order — this pins it.
      final dealt = engine.createGame(
        gameId: 'anim',
        players: _seats(4),
        mode: GameMode.vsComputer,
        seed: 24680,
        startingSeat: 1,
      );
      final order = dealt.dealingSeatOrder;
      expect(order, [2, 3, 0, 1]);

      final sequence = dealtCards(dealt);
      for (var seat = 0; seat < 4; seat++) {
        final mine = [
          for (final e in sequence)
            if (e.$1 == seat) e.$2,
        ];
        expect(
          mine,
          dealt.players[seat].hand,
          reason: 'seat $seat holds its cards in the order it received them',
        );
      }
    });
  });

  group('§3 — the deal survives the round trip and stays deterministic', () {
    test('the same seed and dealer deal the same cards to the same seats', () {
      GameState make() => engine.createGame(
        gameId: 'det',
        players: _seats(4),
        mode: GameMode.vsComputer,
        seed: 31337,
        startingSeat: 2,
      );
      final a = make();
      final b = make();
      for (var i = 0; i < 4; i++) {
        expect(a.players[i].hand, b.players[i].hand);
      }
      expect(a.dealingSeatOrder, [3, 0, 1, 2]);
    });

    test('a different dealer deals the same shuffle to different seats', () {
      List<GameCard> handOf(int dealer, int seat) => engine
          .createGame(
            gameId: 'det',
            players: _seats(4),
            mode: GameMode.vsComputer,
            seed: 31337,
            startingSeat: dealer,
          )
          .players[seat]
          .hand;
      // Seat 1 is served first under dealer 0 and last-but-one under dealer 3,
      // so it cannot hold the same cards.
      expect(handOf(0, 1), isNot(handOf(3, 1)));
    });

    test('a restored save keeps the dealer, so the next deal is unchanged', () {
      final dealt = engine.createGame(
        gameId: 'save',
        players: _seats(4),
        mode: GameMode.vsComputer,
        seed: 808,
        startingSeat: 2,
      );
      final restored = GameState.fromJson(dealt.toJson());
      expect(restored.dealerSeat, dealt.dealerSeat);
      expect(restored.dealingSeatOrder, dealt.dealingSeatOrder);
      expect(restored.dealingOrder, dealt.dealingOrder);
    });

    test('a save written before the dealer existed deals from seat 0', () {
      final dealt = engine.createGame(
        gameId: 'legacy',
        players: _seats(3),
        mode: GameMode.vsComputer,
        seed: 11,
        startingSeat: 0,
      );
      final legacy = dealt.toJson()..remove('dealerSeat');
      final restored = GameState.fromJson(legacy);
      expect(restored.dealerSeat, 0);
      expect(restored.dealingSeatOrder, [1, 2, 0]);
    });
  });
}
