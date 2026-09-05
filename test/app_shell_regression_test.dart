import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gioco_del_101/app/app.dart';
import 'package:gioco_del_101/app/bindings/initial_binding.dart';
import 'package:gioco_del_101/app/localization/app_strings.dart';
import 'package:gioco_del_101/app/router/app_router.dart';
import 'package:gioco_del_101/core/storage/local_storage.dart';
import 'package:gioco_del_101/core/utils/motion.dart';
import 'package:gioco_del_101/features/settings/application/settings_controller.dart';

/// Boots the real `GiocoDel101App` — the shell, its root Obx and the
/// `GetMaterialApp.builder` — rather than mounting a screen directly.
///
/// The rest of the suite renders screens under a fresh `GetMaterialApp`, which
/// never exercises that combination. This file exists because a "setState()
/// called during build" escaped exactly through that gap.
Future<SettingsController> _boot(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  Get.reset();
  final storage = await LocalStorage.open();
  InitialBinding(storage).dependencies();
  Motion.reduceMotion = true;
  Strings.use(const Locale('it'));

  final settings = Get.find<SettingsController>();
  await settings.completeOnboarding();

  await tester.pumpWidget(GiocoDel101App(storage: storage));
  // Past the splash animation and onto Home.
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
  return settings;
}

Future<void> _settle(WidgetTester tester, {int frames = 25}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

void main() {
  tearDown(() {
    Motion.reduceMotion = false;
    Strings.use(const Locale('it'));
    Get.reset();
  });

  testWidgets('the shell boots to Home without throwing', (tester) async {
    await _boot(tester);
    expect(tester.takeException(), isNull);
    expect(Get.currentRoute, AppRoutes.home);
  });

  testWidgets('leaving Settings after editing the nickname does not throw', (
    tester,
  ) async {
    final settings = await _boot(tester);

    Get.toNamed<void>(AppRoutes.settings);
    await _settle(tester);
    expect(tester.takeException(), isNull);

    // The nickname field is the only text field on the settings tab.
    await tester.enterText(find.byType(TextField).first, 'Farhan');
    await _settle(tester, frames: 5);

    // Popping disposes SettingsTab, which persists the nickname.
    Get.back<void>();
    await _settle(tester);

    expect(tester.takeException(), isNull);
    expect(settings.settings.playerName, 'Farhan');
  });

  testWidgets('switching language from Settings rebuilds without throwing', (
    tester,
  ) async {
    final settings = await _boot(tester);

    Get.toNamed<void>(AppRoutes.settings);
    await _settle(tester);

    final english = find.text(Strings.s.settingsLanguageEnglish);
    await tester.scrollUntilVisible(
      english,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await _settle(tester, frames: 5);
    await tester.tap(english);
    await _settle(tester);

    expect(tester.takeException(), isNull);
    expect(settings.settings.localeCode, 'en');

    Get.back<void>();
    await _settle(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('every route can be pushed and popped inside the real shell', (
    tester,
  ) async {
    await _boot(tester);

    // Everything reachable without a live match in progress.
    const routes = <String>[
      AppRoutes.onboarding,
      AppRoutes.authLanding,
      AppRoutes.login,
      AppRoutes.signup,
      AppRoutes.forgotPassword,
      AppRoutes.online,
      AppRoutes.createRoom,
      AppRoutes.joinRoom,
      AppRoutes.roomLobby,
      AppRoutes.matchmaking,
      AppRoutes.profile,
      AppRoutes.editProfile,
      AppRoutes.leaderboard,
      AppRoutes.achievements,
      AppRoutes.dailyReward,
      AppRoutes.settings,
      AppRoutes.howToPlay,
      AppRoutes.setup,
    ];

    for (final route in routes) {
      Get.toNamed<void>(route);
      await _settle(tester, frames: 15);
      expect(tester.takeException(), isNull, reason: 'pushing $route');

      // Onboarding replaces the stack rather than pushing onto it.
      if (Get.currentRoute == route && route != AppRoutes.onboarding) {
        Get.back<void>();
        await _settle(tester, frames: 15);
        expect(tester.takeException(), isNull, reason: 'popping $route');
      }
      if (Get.currentRoute != AppRoutes.home) {
        Get.offAllNamed<void>(AppRoutes.home);
        await _settle(tester, frames: 15);
      }
    }
  });
}
