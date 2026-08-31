// §L — the long-session guard.
//
// The client reported that "after playing for a while the game starts to slow
// down". A slowdown that grows with the number of turns played is almost
// always something accumulating: tickers that are never disposed, listeners
// added per round, timers re-armed on top of live ones, a collection that
// only ever grows, or a widget tree that never sheds what it built.
//
// This drives the REAL table through many consecutive rounds and asserts that
// none of those grow with the number of rounds. It is a regression guard, not
// a benchmark: it measures counts, which are stable and meaningful under the
// software renderer `flutter test` uses, rather than frame times, which are
// not. Wall-clock per round is recorded and compared as a coarse ratio, wide
// enough not to flake on a loaded CI box but tight enough to catch an O(n²).
//
// Limitations, stated plainly: this cannot see native heap growth, GPU memory
// or platform-channel objects (audio players, real Realtime sockets). Those
// are covered by review notes in docs/CLIENT_CHANGE_2026_08_31.md rather than
// by this file.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gioco_del_101/app/bindings/initial_binding.dart';
import 'package:gioco_del_101/app/localization/app_strings.dart';
import 'package:gioco_del_101/app/theme/app_theme.dart';
import 'package:gioco_del_101/core/storage/game_storage_service.dart';
import 'package:gioco_del_101/core/storage/local_storage.dart';
import 'package:gioco_del_101/core/utils/motion.dart';
import 'package:gioco_del_101/features/game/application/game_controller.dart';
import 'package:gioco_del_101/features/game/application/table_controller.dart';
import 'package:gioco_del_101/features/game/domain/ai/bot_decision.dart';
import 'package:gioco_del_101/features/game/domain/ai/bot_factory.dart';
import 'package:gioco_del_101/features/game/domain/ai/bot_view_factory.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_engine.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_session.dart';
import 'package:gioco_del_101/features/game/domain/game_action.dart';
import 'package:gioco_del_101/features/game/domain/game_player.dart';
import 'package:gioco_del_101/features/game/domain/game_state.dart';
import 'package:gioco_del_101/features/game/domain/match_factory.dart';
import 'package:gioco_del_101/features/game/domain/player_type.dart';
import 'package:gioco_del_101/features/game/presentation/game_screen.dart';
import 'package:gioco_del_101/features/profile/application/stats_controller.dart';
import 'package:gioco_del_101/features/settings/application/settings_controller.dart';

/// One reading of everything that could grow without bound.
class Sample {
  Sample({
    required this.round,
    required this.transientCallbacks,
    required this.elements,
    required this.liveImages,
    required this.imageCacheBytes,
    required this.historyLength,
    required this.playedCards,
    required this.micros,
  });

  final int round;

  /// Animation frame callbacks still registered — one per running Ticker.
  /// The signature of a leaked AnimationController.
  final int transientCallbacks;

  /// Elements mounted in the tree.
  final int elements;

  final int liveImages;
  final int imageCacheBytes;

  /// Engine-side collections that reset or stay bounded per round.
  final int historyLength;
  final int playedCards;

  final int micros;

  @override
  String toString() =>
      'r$round ticks=$transientCallbacks els=$elements imgs=$liveImages '
      'cache=${(imageCacheBytes / 1024).round()}KB hist=$historyLength '
      'played=$playedCards ${micros ~/ 1000}ms';
}

GameController _seatBotTable({required int seats, required int seed}) {
  final setup = MatchFactory.vsComputer(
    playerName: 'Tu',
    avatarId: 'lucia',
    playerCount: seats,
    difficulty: BotDifficulty.normal,
    seed: seed,
    random: Random(seed),
  );
  final c = Get.put(
    GameController(
      session: setup.session,
      storage: Get.find<GameStorageService>(),
      settings: Get.find<SettingsController>(),
      stats: Get.find<StatsController>(),
      // No seat is a person, so the table plays itself: a long session
      // needs no synthetic taps and still exercises the whole cue,
      // animation and persistence path a human would drive. `viewingPlayer`
      // falls back to seat 0, so the hand fan renders exactly as usual.
      humanIds: const ['spectator'],
      random: Random(seed),
    ),
  );
  Get.put<TableController>(c);
  return c;
}

Future<void> _slice(WidgetTester tester, {int slices = 12}) async {
  for (var i = 0; i < slices; i++) {
    await tester.pump(const Duration(milliseconds: 40));
  }
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Get.reset();
    InitialBinding(await LocalStorage.open()).dependencies();
    // Reduce Motion keeps the run quick and, more usefully, makes ticker
    // leaks LOUDER: with animations collapsed, anything still ticking after a
    // round is something that should have been disposed.
    Motion.reduceMotion = true;
    Strings.use(const Locale('it'));
    final settings = Get.find<SettingsController>();
    for (final id in const [
      'coach_match',
      'coach_draw',
      'coach_specials',
      'coach_ring',
    ]) {
      await settings.markCoachMarkSeen(id);
    }
  });

  tearDown(() {
    Motion.reduceMotion = false;
    Get.reset();
  });

  group('Long session (§L)', () {
    testWidgets(
      'nothing accumulates over many consecutive rounds',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final c = _seatBotTable(seats: 4, seed: 20260831);
        await tester.pumpWidget(
          GetMaterialApp(
            theme: AppTheme.build(),
            home: const MediaQuery(
              data: MediaQueryData(size: Size(390, 844)),
              child: GameScreen(),
            ),
          ),
        );
        await _slice(tester, slices: 20);

        // A fixed pump budget rather than "play N rounds to completion": the
        // table drives itself off real delays, so a wall-clock budget is both
        // reproducible and exactly the shape of the client's report — "after
        // playing for a while". Each window is one sample.
        const windows = 12;
        const slicesPerWindow = 25;
        final samples = <Sample>[];
        final watch = Stopwatch();

        for (var window = 1; window <= windows; window++) {
          watch
            ..reset()
            ..start();
          await _slice(tester, slices: slicesPerWindow);
          // Deal the next round the moment one ends, so a long session really
          // is a long session and not one round held open.
          if (c.round.status == GameStatus.roundOver && !c.state.isFinished) {
            await c.beginNextRound();
            await _slice(tester, slices: 5);
          }
          watch.stop();

          samples.add(
            Sample(
              round: window,
              transientCallbacks: tester.binding.transientCallbackCount,
              elements: tester.allElements.length,
              liveImages: PaintingBinding.instance.imageCache.liveImageCount,
              imageCacheBytes:
                  PaintingBinding.instance.imageCache.currentSizeBytes,
              historyLength: c.round.history.length,
              playedCards: c.round.playedCards.length,
              micros: watch.elapsedMicroseconds,
            ),
          );
          if (c.state.isFinished) break;
        }

        for (final s in samples) {
          // ignore: avoid_print
          print(s);
        }

        expect(
          c.round.version,
          greaterThan(0),
          reason: 'the table never played anything, so nothing was measured',
        );
        expect(samples.length, greaterThanOrEqualTo(6));

        final first = samples.first;
        final last = samples.last;

        // 1. Tickers. The clearest leak signal: an AnimationController that was
        //    never disposed keeps a frame callback registered forever, so the
        //    count would climb window after window.
        expect(
          last.transientCallbacks,
          lessThanOrEqualTo(first.transientCallbacks + 4),
          reason:
              'animation tickers accumulated: '
              '${first.transientCallbacks} -> ${last.transientCallbacks}',
        );
        for (final s in samples) {
          expect(
            s.transientCallbacks,
            lessThan(40),
            reason: 'too many live tickers at window ${s.round}: $s',
          );
        }

        // 2. The widget tree. A table that never sheds what it builds grows
        //    with every round; a healthy one oscillates around a fixed size.
        final maxElements = samples.map((s) => s.elements).reduce(max);
        expect(
          maxElements,
          lessThan(first.elements * 2),
          reason:
              'the tree grew as play went on: '
              '${first.elements} -> $maxElements',
        );

        // 3. Engine collections. `history` is explicitly bounded and
        //    `playedCards` resets on every deal — read straight off the
        //    authoritative state, so this guards the save file too.
        for (final s in samples) {
          expect(
            s.historyLength,
            lessThanOrEqualTo(GameState.historyLimit),
            reason: 'history is unbounded at window ${s.round}',
          );
          expect(
            s.playedCards,
            lessThanOrEqualTo(40),
            reason: 'playedCards outgrew the deck at window ${s.round}',
          );
        }

        // 4. The image cache. The forty printed faces are decoded at the size
        //    they are drawn, and CardFaceImage rounds that request to a step so
        //    a card animating through many widths still shares one entry. The
        //    cache therefore settles at deck scale instead of climbing.
        for (final s in samples) {
          expect(
            s.liveImages,
            lessThanOrEqualTo(60),
            reason: 'more live images than the deck can explain: $s',
          );
        }

        // 5. Wall clock. Deliberately loose — this runs on whatever machine is
        //    to hand — but an O(n^2) table shows up as late windows taking
        //    several times an early one for the same pump budget.
        final early =
            samples.take(3).map((s) => s.micros).reduce((a, b) => a + b) / 3;
        final late =
            samples.reversed
                .take(3)
                .map((s) => s.micros)
                .reduce((a, b) => a + b) /
            3;
        expect(
          late,
          lessThan(early * 4 + 2000000),
          reason:
              'later play got much slower for the same work: '
              '${early ~/ 1000}ms -> ${late ~/ 1000}ms',
        );

        // Close the table the way leaving the screen does. `Get.reset()` in
        // tearDown runs after the binding's own "no pending timers" check, so
        // the persist coalescer has to be stood down here — and this doubles as
        // an assertion that onClose really does cancel everything it armed.
        await tester.pumpWidget(const SizedBox.shrink());
        Get.delete<TableController>(force: true);
        Get.delete<GameController>(force: true);
        // Long enough to outlast the longest thing the table can have armed:
        // the 3 s guard `_present` puts on a cue it handed to the view.
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(seconds: 1));
        }
        expect(
          tester.binding.transientCallbackCount,
          0,
          reason: 'something was still animating after the table was closed',
        );
      },
      timeout: const Timeout(Duration(minutes: 12)),
    );

    testWidgets(
      'leaving the table disposes everything it armed',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final c = _seatBotTable(seats: 3, seed: 4242);
        await tester.pumpWidget(
          GetMaterialApp(
            theme: AppTheme.build(),
            home: const MediaQuery(
              data: MediaQueryData(size: Size(390, 844)),
              child: GameScreen(),
            ),
          ),
        );
        // Tear the table down mid-flight, the case that leaks a card animation
        // if the screen does not dispose what it armed.
        // Long enough that the deal has finished and the bots are playing, so
        // the teardown below really does land mid-flight.
        await _slice(tester, slices: 90);
        expect(
          c.round.version,
          greaterThan(0),
          reason: 'the table never started, so nothing was armed to leak',
        );

        await tester.pumpWidget(const SizedBox.shrink());
        Get.delete<TableController>(force: true);
        Get.delete<GameController>(force: true);
        await tester.pump(const Duration(seconds: 1));

        expect(
          tester.binding.transientCallbackCount,
          0,
          reason: 'a card flight outlived the screen that started it',
        );
      },
      timeout: const Timeout(Duration(minutes: 6)),
    );
  });

  group('Long session, engine only (§L)', () {
    test('a very long match keeps its state a fixed size', () {
      // No widgets: thousands of actions, watching the state itself. This is
      // the part that also runs on the server.
      const engine = GameEngine();
      final players = [
        for (var i = 0; i < 4; i++)
          GamePlayer(
            id: 'p$i',
            name: 'P$i',
            type: PlayerType.bot,
            avatarId: 'marco',
            difficulty: BotDifficulty.normal,
          ),
      ];
      var state = engine.createGame(
        gameId: 'long',
        players: players,
        mode: GameMode.vsComputer,
        seed: 777,
      );
      final session = GameSession(state);
      final bots = {
        for (final p in players) p.id: BotFactory.create(BotDifficulty.normal),
      };

      var actions = 0;
      var rounds = 0;
      final sizes = <int>[];
      while (!session.state.isFinished && actions < 6000) {
        if (session.state.status == GameStatus.roundOver) {
          rounds++;
          sizes.add(session.state.toJson().toString().length);
          session.apply(
            const StartNextRoundAction(playerId: GameEngine.systemActorId),
          );
          continue;
        }
        final s = session.state;
        final bot = bots[s.currentPlayerId]!;
        final view = BotViewFactory.forCurrentPlayer(s);
        if (s.status == GameStatus.awaitingSuitChoice) {
          session.chooseSuit(bot.chooseSuit(view));
          actions++;
          continue;
        }
        final d = bot.decide(view);
        switch (d.action) {
          case BotAction.play:
            session.autoPlayCard(d.card!, chosenSuit: d.suit);
          case BotAction.draw:
            session.drawCard();
          case BotAction.endTurn:
            if (session.canEndTurn) {
              session.endTurn();
            } else if (session.canDraw) {
              session.drawCard();
            }
        }
        actions++;
      }

      expect(rounds, greaterThan(3), reason: 'the match must have run on');
      state = session.state;
      expect(state.history.length, lessThanOrEqualTo(GameState.historyLimit));
      expect(state.playedCards.length, lessThanOrEqualTo(40));
      expect(state.totalCards, 40);
      expect(state.drawsByPlayer.length, lessThanOrEqualTo(4));
      expect(state.voidSuits.length, lessThanOrEqualTo(4));
      // The serialized state — what a save file and every server write costs
      // — must not grow with the number of rounds played.
      if (sizes.length >= 3) {
        expect(
          sizes.last,
          lessThan(sizes.first * 2),
          reason: 'the saved state grew with the rounds: $sizes',
        );
      }
    });
  });
}
