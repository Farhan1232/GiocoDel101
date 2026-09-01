// §36/§39 — the round transition, which is the path a high score walks.
//
// The round-result sheet is the one screen a long match visits over and over,
// and it is where the score is settled and written to lifetime statistics. It
// used to do that from `initState` — synchronously, inside the build that was
// mounting it — and `StatsController._commit`'s first statement assigns a
// global `Rx`, so every `Obx` watching lifetime statistics (the home screen
// keeps two of them, mounted under the table) was marked dirty in the middle
// of a build. Flutter raised "setState() or markNeedsBuild() called during
// build" on every round that ended.
//
// The fix defers the write to the end of the frame. These tests hold the two
// halves of that: no build-phase mutation, and the round is still recorded —
// exactly once, with the state it was scored against.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gioco_del_101/app/bindings/initial_binding.dart';
import 'package:gioco_del_101/app/localization/app_strings.dart';
import 'package:gioco_del_101/app/router/app_router.dart';
import 'package:gioco_del_101/app/theme/app_theme.dart';
import 'package:gioco_del_101/core/storage/local_storage.dart';
import 'package:gioco_del_101/core/utils/motion.dart';
import 'package:gioco_del_101/features/game/application/game_controller.dart';
import 'package:gioco_del_101/features/game/application/table_controller.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_session.dart';
import 'package:gioco_del_101/features/game/domain/game_state.dart';
import 'package:gioco_del_101/features/game/domain/round_result.dart';
import 'package:gioco_del_101/features/game/presentation/round_result_screen.dart';
import 'package:gioco_del_101/features/home/presentation/home_screen.dart';
import 'package:gioco_del_101/features/profile/application/stats_controller.dart';
import 'package:gioco_del_101/features/settings/application/settings_controller.dart';
import 'package:gioco_del_101/core/storage/game_storage_service.dart';
import 'package:gioco_del_101/features/game/domain/match_factory.dart';
import 'package:gioco_del_101/features/game/domain/player_type.dart';

import 'dart:math';

GameController _table({int seats = 3, int seed = 909}) {
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
      session: GameSession(setup.session.state),
      storage: Get.find<GameStorageService>(),
      settings: Get.find<SettingsController>(),
      stats: Get.find<StatsController>(),
      humanIds: setup.humanIds,
      random: Random(seed),
    ),
    permanent: true,
  );
  Get.put<TableController>(c, permanent: true);
  return c;
}

RoundResult _resultFor(GameState state, {required bool humanWins}) {
  final human = state.players.first;
  final other = state.players[1];
  return RoundResult(
    roundNumber: state.round,
    winnerId: humanWins ? human.id : other.id,
    winnerName: humanWins ? human.name : other.name,
    rows: [
      for (final p in state.players)
        PlayerRoundResult(
          playerId: p.id,
          name: p.name,
          cardsLeft: p.id == (humanWins ? human.id : other.id) ? 0 : 3,
          penalty: p.id == (humanWins ? human.id : other.id) ? 0 : 12,
          previousScore: p.score,
          newScore:
              p.score + (p.id == (humanWins ? human.id : other.id) ? 0 : 12),
          hitExact101: false,
          eliminated: false,
        ),
    ],
    matchOver: false,
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Get.reset();
    InitialBinding(await LocalStorage.open()).dependencies();
    Strings.use(const Locale('it'));
    Motion.reduceMotion = true;
  });

  tearDown(() {
    Motion.reduceMotion = false;
    Get.reset();
  });

  group('The round result settles exactly once (§36/§39)', () {
    testWidgets(
      'scoring a round raises no build-phase mutation, even with the home '
      'screen watching lifetime statistics',
      (tester) async {
        final c = _table();
        c.lastRoundResult.value = _resultFor(c.state, humanWins: true);

        // The home screen is what actually sits under the table in the app,
        // and two of its `Obx`s watch `StatsController`. Mount it, then open
        // the sheet over it exactly as the table does.
        await tester.pumpWidget(
          GetMaterialApp(
            theme: AppTheme.build(),
            initialRoute: AppRoutes.home,
            getPages: AppPages.pages,
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byType(HomeScreen), findsOneWidget);

        Get.toNamed<void>(AppRoutes.roundResult);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(
          tester.takeException(),
          isNull,
          reason:
              'settling the round mutated reactive state during a build — '
              'this fired on every round the client ever finished',
        );
        expect(find.byType(RoundResultScreen), findsOneWidget);
      },
    );

    testWidgets('the round is recorded, once, against the state it was '
        'scored on', (tester) async {
      final stats = Get.find<StatsController>();
      final c = _table();
      final scoredOn = c.state;
      c.lastRoundResult.value = _resultFor(scoredOn, humanWins: true);

      expect(stats.stats.roundsPlayed, 0);

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.build(),
          initialRoute: AppRoutes.home,
          getPages: AppPages.pages,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      Get.toNamed<void>(AppRoutes.roundResult);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        stats.stats.roundsPlayed,
        1,
        reason: 'the round was never recorded — deferring the write lost it',
      );
      expect(
        stats.stats.roundsWon,
        1,
        reason: 'the human won this round and the record should say so',
      );

      // Frames keep coming while the sheet is up; none of them may record the
      // round a second time.
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(
        stats.stats.roundsPlayed,
        1,
        reason: 'the round was settled more than once',
      );
    });

    testWidgets('a second round settles once more, and no more', (
      tester,
    ) async {
      final stats = Get.find<StatsController>();
      final c = _table();
      c.lastRoundResult.value = _resultFor(c.state, humanWins: false);

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.build(),
          initialRoute: AppRoutes.home,
          getPages: AppPages.pages,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      for (var round = 1; round <= 3; round++) {
        Get.toNamed<void>(AppRoutes.roundResult);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(
          stats.stats.roundsPlayed,
          round,
          reason: 'round $round did not settle exactly once',
        );
        Get.back<void>();
        await tester.pump(const Duration(milliseconds: 300));
      }
      expect(stats.stats.roundsWon, 0, reason: 'the human won none of them');
    });
  });
}
