// Session 7 — long-session stability regressions.
//
// The client's report: "at first the game works well; while playing it
// gradually slows down and eventually force-closes", reproduced on more than
// one physical phone. Each test here pins one of the defects behind that:
//
//   • the offline "Rivincita" left the previous `/game` route mounted under
//     the new one — a whole retained table per rematch;
//   • card decodes could be keyed above the 360-px source, so one card held
//     up to seven byte-identical full-resolution cache entries;
//   • a stale `TableController` registration silently blocked the next
//     launcher's `Get.put` (GetX keeps the old instance for an occupied
//     key), leaving a live driver no screen could reach or dismiss;
//   • the tutorial's Home/Play-now exits never released its controller;
//   • `AudioService.init` was not safe to call twice.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gioco_del_101/app/bindings/backend_services.dart';
import 'package:gioco_del_101/app/bindings/initial_binding.dart';
import 'package:gioco_del_101/app/localization/app_strings.dart';
import 'package:gioco_del_101/app/router/app_router.dart';
import 'package:gioco_del_101/app/theme/app_theme.dart';
import 'package:gioco_del_101/core/services/audio_service.dart';
import 'package:gioco_del_101/core/storage/local_storage.dart';
import 'package:gioco_del_101/core/utils/motion.dart';
import 'package:gioco_del_101/core/widgets/cards/card_face_image.dart';
import 'package:gioco_del_101/features/game/application/game_controller.dart';
import 'package:gioco_del_101/features/game/application/match_launcher.dart';
import 'package:gioco_del_101/features/game/application/table_controller.dart';
import 'package:gioco_del_101/features/game/domain/match_factory.dart';
import 'package:gioco_del_101/features/game/domain/player_type.dart';
import 'package:gioco_del_101/features/tutorial/application/tutorial_controller.dart';
import 'package:gioco_del_101/features/tutorial/application/tutorial_launcher.dart';

Future<void> _boot() async {
  SharedPreferences.setMockInitialValues({});
  Get.reset();
  Get.testMode = true;
  final storage = await LocalStorage.open();
  InitialBinding(storage, backend: BackendServices.none()).dependencies();
  Motion.reduceMotion = true;
  Strings.use(const Locale('it'));
}

MatchSetup _setup({int seats = 2}) => MatchFactory.vsComputer(
  playerName: 'Tu',
  avatarId: 'lucia',
  playerCount: seats,
  difficulty: BotDifficulty.easy,
);

/// Watches the navigator and keeps the names of the routes that are live.
class _StackSpy extends NavigatorObserver {
  final List<String?> live = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      live.add(route.settings.name);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      live.remove(route.settings.name);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      live.remove(route.settings.name);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    live.remove(oldRoute?.settings.name);
    live.add(newRoute?.settings.name);
  }

  int count(String name) => live.where((n) => n == name).length;
}

void main() {
  tearDown(() {
    Motion.reduceMotion = false;
    Get.reset();
  });

  group('decodeWidth is bounded by the source artwork (§L)', () {
    test('never keys a decode above the 360-px source', () {
      for (final width in [46.0, 84.0, 96.8, 104.0, 130.0, 200.0]) {
        for (final dpr in [1.0, 2.0, 2.625, 3.0, 3.5, 4.0]) {
          final key = CardFaceImage.decodeWidth(width, dpr);
          expect(
            key,
            lessThanOrEqualTo(CardFaceImage.sourceWidth),
            reason:
                'width $width @ ${dpr}x asked for a $key-px decode of a '
                '${CardFaceImage.sourceWidth}-px file: the cache would hold '
                'a duplicate full-resolution bitmap under this key',
          );
        }
      }
    });

    test(
      'every near-full-size request shares the single source-size entry',
      () {
        // 84 dp at 3.0×, 96.8 dp at 3.5×, 96 dp at 4.0× … all the ordinary
        // hand/table sizes on modern phones land in one band. Before the fix
        // they produced keys 256, 320, 384, 448 — four decodes per card.
        final keys = <int>{
          for (final width in [84.0, 92.0, 96.0, 96.8, 104.0])
            for (final dpr in [2.625, 3.0, 3.5, 4.0])
              CardFaceImage.decodeWidth(width, dpr),
        };
        expect(keys, {CardFaceImage.sourceWidth});
      },
    );

    test('small decodes still step, so thumbnails stay cheap', () {
      expect(CardFaceImage.decodeWidth(40, 1.0), 64);
      expect(CardFaceImage.decodeWidth(84, 1.0), 128);
      expect(CardFaceImage.decodeWidth(84, 2.0), 192);
      // A card can produce at most four distinct cache keys across every
      // size and ratio the app uses: 64, 128, 192 and the source width.
      final possible = <int>{
        for (var w = 20.0; w <= 200; w += 1)
          for (final dpr in [1.0, 2.0, 2.625, 3.0, 3.5, 4.0])
            CardFaceImage.decodeWidth(w, dpr),
      };
      expect(possible.length, lessThanOrEqualTo(4), reason: '$possible');
    });
  });

  testWidgets(
    'Rivincita replaces the old table instead of stacking a new one on it',
    (tester) async {
      await _boot();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final spy = _StackSpy();
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.build(),
          getPages: AppPages.pages,
          initialRoute: AppRoutes.setup,
          navigatorObservers: [spy],
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      MatchLauncher.launch(_setup());
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 120));
      }
      expect(spy.count(AppRoutes.game), 1);
      final firstDriver = Get.find<TableController>();
      final firstElements = tester.allElements.length;

      // Three consecutive rematches, the way an evening of play stacks up.
      for (var rematch = 1; rematch <= 3; rematch++) {
        MatchLauncher.launch(_setup(), replace: true);
        for (var i = 0; i < 8; i++) {
          await tester.pump(const Duration(milliseconds: 120));
        }
        expect(
          spy.count(AppRoutes.game),
          1,
          reason:
              'rematch $rematch left ${spy.count(AppRoutes.game)} /game '
              'routes mounted: each stranded one retains a full table',
        );
      }
      expect(
        Get.find<TableController>(),
        isNot(same(firstDriver)),
        reason: 'the rematch must seat a fresh driver',
      );
      // The element tree must not grow with the rematches: a retained route
      // keeps every one of its ~900 elements mounted underneath the new one.
      expect(tester.allElements.length, lessThan(firstElements * 2));

      await tester.pumpWidget(const SizedBox.shrink());
      MatchLauncher.dismiss();
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      expect(tester.binding.transientCallbackCount, 0);
    },
  );

  testWidgets('a stale TableController key cannot capture the next launch', (
    tester,
  ) async {
    await _boot();
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.build(),
        getPages: AppPages.pages,
        initialRoute: AppRoutes.setup,
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // A leaked registration from an exit path that forgot to clean up.
    // `Get.put` keeps the OLD instance when the key is occupied, so before
    // the launchers deleted the key defensively the new driver ran live —
    // timers, session listener and all — while every screen kept reading
    // the stale one, and no dismiss() could ever reach it.
    final stale = GameController(
      session: _setup().session,
      storage: Get.find(),
      settings: Get.find(),
      stats: Get.find(),
      humanIds: const ['p0'],
    );
    Get.put<TableController>(stale, permanent: true);

    MatchLauncher.launch(_setup());
    await tester.pump(const Duration(milliseconds: 200));
    expect(
      Get.find<TableController>(),
      isNot(same(stale)),
      reason: 'the launch must replace a stale registration, never lose to it',
    );
    expect(
      identical(Get.find<TableController>(), Get.find<GameController>()),
      isTrue,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    MatchLauncher.dismiss();
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('TutorialLauncher.dismiss releases both registrations', (
    tester,
  ) async {
    await _boot();
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.build(),
        getPages: AppPages.pages,
        initialRoute: AppRoutes.home,
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    TutorialLauncher.launch();
    await tester.pump(const Duration(milliseconds: 300));
    expect(Get.isRegistered<TutorialController>(), isTrue);
    expect(Get.find<TableController>(), isA<TutorialController>());

    // The "Home" button's path: leave the route, then release the driver.
    Get.until((r) => r.settings.name == AppRoutes.home);
    TutorialLauncher.dismiss();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      Get.isRegistered<TutorialController>(),
      isFalse,
      reason: 'the tutorial driver must not survive leaving the tutorial',
    );
    expect(
      Get.isRegistered<TableController>(),
      isFalse,
      reason:
          'a stale TableController key would silently block the next '
          "launcher's Get.put",
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(tester.binding.transientCallbackCount, 0);
  });

  test('AudioService.init is safe to call concurrently', () async {
    // Two racing calls must coalesce into one initialisation — a second
    // pass would build a second set of native players.
    await Future.wait([
      AudioService.instance.init(),
      AudioService.instance.init(),
      AudioService.instance.init(),
    ]);
    // In the test environment the platform channel is missing, so the
    // service simply reports itself unready — and play() must be a no-op
    // rather than a crash.
    AudioService.instance.play(Sfx.click);
  });
}
