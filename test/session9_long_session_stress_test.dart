// §L2 — the deep long-session guard.
//
// `long_session_performance_test.dart` already drives many rounds and watches
// tickers, elements and engine collections. It missed the defect that
// explained the client's crash for two reasons, and this file exists to close
// both:
//
//  1. **It played in silence.** `AudioService.init()` cannot reach a platform
//     under `flutter test`, so `play()` returned immediately and the sound
//     path — where the leak was — never ran. Here a fake platform stands in
//     and every cue really plays.
//  2. **It never left the table.** With no route table the round-result sheet
//     never opened, so the per-round path a player actually walks (score
//     sheet, "Prossima Mano", next deal) was never exercised in a loop.
//
// It measures, per window, everything whose cost could grow with the length
// of a session, and asserts that none of it does.
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gioco_del_101/app/bindings/initial_binding.dart';
import 'package:gioco_del_101/app/localization/app_strings.dart';
import 'package:gioco_del_101/app/router/app_router.dart';
import 'package:gioco_del_101/app/theme/app_theme.dart';
import 'package:gioco_del_101/core/storage/local_storage.dart';
import 'package:gioco_del_101/core/utils/motion.dart';
import 'package:gioco_del_101/features/game/application/match_launcher.dart';
import 'package:gioco_del_101/features/game/application/table_controller.dart';
import 'package:gioco_del_101/features/game/domain/game_state.dart';
import 'package:gioco_del_101/features/game/domain/match_factory.dart';
import 'package:gioco_del_101/features/game/domain/player_type.dart';
import 'package:gioco_del_101/features/settings/application/settings_controller.dart';
import 'support/fake_audio_platform.dart';

/// One reading of a long session.
class Reading {
  Reading({
    required this.window,
    required this.version,
    required this.round,
    required this.topScore,
    required this.elements,
    required this.frameCallbacks,
    required this.liveImages,
    required this.routes,
    required this.stateBytes,
    required this.encodeMicros,
    required this.history,
    required this.playedCards,
    required this.soundsPlayed,
    required this.positionQueries,
    required this.micros,
  });

  final int window;
  final int version;
  final int round;
  final int topScore;
  final int elements;

  /// Transient frame callbacks: one per running ticker, and one per stranded
  /// audio position poller. The number that gave the defect away.
  final int frameCallbacks;
  final int liveImages;

  /// Live routes, by name.
  final Map<String, int> routes;

  final int stateBytes;
  final int encodeMicros;
  final int history;
  final int playedCards;
  final int soundsPlayed;

  /// Platform-channel position polls. Must stay at zero: one per player per
  /// frame is what pinned the app at the refresh rate all session.
  final int positionQueries;

  final int micros;

  @override
  String toString() =>
      'w$window v$version r$round score=$topScore els=$elements '
      'frameCbs=$frameCallbacks imgs=$liveImages routes=$routes '
      'state=${stateBytes}B encode=${encodeMicros}us hist=$history '
      'played=$playedCards sfx=$soundsPlayed poll=$positionQueries '
      '${micros ~/ 1000}ms';
}

class _RouteCensus extends NavigatorObserver {
  final Map<String, int> live = {};

  void _add(Route<dynamic> r) =>
      live.update(r.settings.name ?? '?', (v) => v + 1, ifAbsent: () => 1);

  void _drop(Route<dynamic> r) {
    final name = r.settings.name ?? '?';
    final next = (live[name] ?? 1) - 1;
    if (next <= 0) {
      live.remove(name);
    } else {
      live[name] = next;
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _add(route);
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _drop(route);
  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _drop(route);
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute != null) _drop(oldRoute);
    if (newRoute != null) _add(newRoute);
  }
}

void main() {
  late FakeAudioPlatform audio;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Get.reset();
    audio = await startFakeAudio(FakeAudioPlatform(), false);
    InitialBinding(await LocalStorage.open()).dependencies();
    Strings.use(const Locale('it'));
    // Reduce Motion keeps the run quick and makes anything still ticking
    // after a round louder, not quieter.
    Motion.reduceMotion = true;
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

  testWidgets(
    'a long session with the sound on accumulates nothing (§L2)',
    (tester) async {
      // A real phone's pixel ratio, not the 1.0 the older harness ran at.
      // 2.0 rather than 3.0 on purpose: the decode-key behaviour across the
      // whole size x DPR matrix is already pinned by
      // `session7_stability_test.dart`, and every extra physical pixel here
      // is software-rastered wall clock that buys this test nothing. What it
      // needs is *table time*, and that is what the budget below spends.
      tester.view.physicalSize = const Size(720, 1280);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      final routes = _RouteCensus();
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.build(),
          initialRoute: AppRoutes.home,
          getPages: AppPages.pages,
          navigatorObservers: [routes],
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));

      // A table that plays itself: no seat is a person, so the bots drive
      // every turn through the whole cue, animation, sound and persistence
      // path a player would.
      MatchSetup table(int seed) {
        final setup = MatchFactory.vsComputer(
          playerName: 'Tu',
          avatarId: 'lucia',
          playerCount: 4,
          difficulty: BotDifficulty.normal,
          seed: seed,
          random: Random(seed),
        );
        return MatchSetup(setup.session, const ['spectator']);
      }

      MatchLauncher.launch(table(20260901));
      await tester.pump(const Duration(milliseconds: 400));

      final readings = <Reading>[];
      final watch = Stopwatch()..start();
      var last = 0;
      var roundsPlayed = 0;
      var matchesPlayed = 1;
      final baselineFrameCallbacks =
          SchedulerBinding.instance.transientCallbackCount;

      for (var window = 1; window <= 170; window++) {
        for (var i = 0; i < 26; i++) {
          // 100 ms a step: with Reduce Motion on, every cue and every bot
          // pause is shorter than that, so the table advances a move per
          // step and the run covers minutes of play instead of seconds.
          await tester.pump(const Duration(milliseconds: 100));

          if (Get.currentRoute == AppRoutes.roundResult) {
            // Let the score reveal finish, then take the next round exactly
            // as a person does.
            for (var j = 0; j < 24; j++) {
              await tester.pump(const Duration(milliseconds: 100));
            }
            final next = find.text(Strings.s.nextRound);
            if (next.evaluate().isNotEmpty) {
              await tester.tap(next.first, warnIfMissed: false);
              roundsPlayed++;
              await tester.pump(const Duration(milliseconds: 400));
            } else {
              final toResult = find.text(Strings.s.matchWinner);
              if (toResult.evaluate().isNotEmpty) {
                await tester.tap(toResult.first, warnIfMissed: false);
                await tester.pump(const Duration(milliseconds: 400));
              }
            }
          }

          if (Get.currentRoute == AppRoutes.matchResult) {
            // A fresh match, the way "Rivincita" starts one.
            matchesPlayed++;
            MatchLauncher.launch(
              table(20260901 + matchesPlayed),
              replace: true,
            );
            await tester.pump(const Duration(milliseconds: 400));
          }
        }

        final state = Get.find<TableController>().state;
        final encode = Stopwatch()..start();
        final encoded = jsonEncode(state.toJson());
        encode.stop();
        final now = watch.elapsedMicroseconds;
        readings.add(
          Reading(
            window: window,
            version: state.version,
            round: state.round,
            topScore: state.players.map((p) => p.score).reduce(max),
            elements: tester.allElements.length,
            frameCallbacks: SchedulerBinding.instance.transientCallbackCount,
            liveImages: PaintingBinding.instance.imageCache.liveImageCount,
            routes: Map.of(routes.live),
            stateBytes: encoded.length,
            encodeMicros: encode.elapsedMicroseconds,
            history: state.history.length,
            playedCards: state.playedCards.length,
            soundsPlayed: audio.resumed.length,
            positionQueries: audio.positionQueries,
            micros: now - last,
          ),
        );
        last = now;
      }

      for (final r in readings) {
        // ignore: avoid_print
        print(r);
      }
      // ignore: avoid_print
      print(
        'rounds=$roundsPlayed matches=$matchesPlayed '
        'sounds=${audio.resumed.length}',
      );

      final first = readings.first;
      final lastReading = readings.last;

      // The session has to have been a session.
      // The table makes roughly one noise a second, which is the rate that
      // turned into one stranded frame-callback chain a second on a phone.
      expect(
        audio.resumed.length,
        greaterThan(400),
        reason: 'the table barely made a sound, so nothing was measured',
      );
      expect(
        roundsPlayed,
        greaterThanOrEqualTo(5),
        reason:
            'the session never crossed enough round transitions to be a '
            'long session',
      );

      // 1. The defect itself. Every sound effect used to strand one
      //    self-rescheduling frame callback — after several hundred, the app
      //    could never idle, each frame ran them all, and each posted a
      //    platform-channel round trip. The count must stay at table level
      //    however long the session runs, and nothing may poll the native
      //    player position at all.
      for (final r in readings) {
        expect(
          r.frameCallbacks,
          lessThanOrEqualTo(baselineFrameCallbacks + 24),
          reason: 'frame callbacks accumulated by window ${r.window}: $r',
        );
      }
      expect(
        lastReading.frameCallbacks,
        lessThanOrEqualTo(first.frameCallbacks + 8),
        reason:
            'frame callbacks grew across the session: '
            '${first.frameCallbacks} -> ${lastReading.frameCallbacks}',
      );
      expect(
        lastReading.positionQueries,
        0,
        reason:
            'something polled the native audio position '
            '${lastReading.positionQueries} times — that is one platform '
            'message per player per frame, all session',
      );

      // 2. Routes. One table and one home, whatever happened in between.
      for (final r in readings) {
        expect(
          r.routes[AppRoutes.game] ?? 0,
          lessThanOrEqualTo(1),
          reason: 'more than one table is mounted at window ${r.window}: $r',
        );
        expect(
          r.routes.values.fold<int>(0, (a, b) => a + b),
          lessThanOrEqualTo(4),
          reason: 'the route stack grew at window ${r.window}: $r',
        );
      }

      // 3. The widget tree.
      final peak = readings.map((r) => r.elements).reduce(max);
      expect(
        peak,
        lessThan(first.elements * 2),
        reason: 'the tree grew as play went on: ${first.elements} -> $peak',
      );

      // 4. The saved state — what autosave encodes and writes on every
      //    settled action. Neither its size nor the cost of producing it may
      //    depend on how long the match has run or how high the score is.
      for (final r in readings) {
        expect(
          r.history,
          lessThanOrEqualTo(GameState.historyLimit),
          reason: 'history is unbounded at window ${r.window}: $r',
        );
        expect(
          r.playedCards,
          lessThanOrEqualTo(40),
          reason: 'playedCards outgrew the deck at window ${r.window}: $r',
        );
        expect(
          r.stateBytes,
          lessThan(32 * 1024),
          reason: 'the saved state is far larger than a match needs: $r',
        );
      }
      final maxBytes = readings.map((r) => r.stateBytes).reduce(max);
      expect(
        maxBytes,
        lessThan(first.stateBytes * 2),
        reason:
            'the saved state grew with the session: '
            '${first.stateBytes} -> $maxBytes',
      );

      // 5. Wall clock. Loose — this runs on whatever machine is to hand — but
      //    a session that gets slower the longer it goes shows up here.
      final early =
          readings.take(5).map((r) => r.micros).reduce((a, b) => a + b) / 5;
      final late =
          readings.reversed
              .take(5)
              .map((r) => r.micros)
              .reduce((a, b) => a + b) /
          5;
      expect(
        late,
        lessThan(early * 4 + 2000000),
        reason:
            'later windows cost far more than early ones for the same budget: '
            '${early ~/ 1000}ms -> ${late ~/ 1000}ms',
      );

      // Leaving the table must give everything back.
      await tester.pumpWidget(const SizedBox.shrink());
      Get.delete<TableController>(force: true);
      MatchLauncher.dismiss();
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      expect(
        SchedulerBinding.instance.transientCallbackCount,
        0,
        reason: 'something was still animating after the table was closed',
      );
    },
    timeout: const Timeout(Duration(minutes: 20)),
  );
}
