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
import 'package:gioco_del_101/core/widgets/network_banner.dart';
import 'package:gioco_del_101/core/widgets/premium_button.dart';
import 'package:gioco_del_101/features/achievements/presentation/achievements_screen.dart';
import 'package:gioco_del_101/features/auth/presentation/auth_landing_screen.dart';
import 'package:gioco_del_101/features/auth/presentation/forgot_password_screen.dart';
import 'package:gioco_del_101/features/auth/presentation/login_screen.dart';
import 'package:gioco_del_101/features/auth/presentation/signup_screen.dart';
import 'package:gioco_del_101/features/home/presentation/home_screen.dart';
import 'package:gioco_del_101/features/leaderboard/presentation/leaderboard_screen.dart';
import 'package:gioco_del_101/features/onboarding/presentation/onboarding_screen.dart';
import 'package:gioco_del_101/features/online/presentation/online_mode_screen.dart';
import 'package:gioco_del_101/features/profile/presentation/edit_profile_screen.dart';
import 'package:gioco_del_101/features/profile/presentation/profile_screen.dart';
import 'package:gioco_del_101/features/rewards/presentation/daily_reward_screen.dart';
import 'package:gioco_del_101/features/rooms/presentation/create_room_screen.dart';
import 'package:gioco_del_101/features/rooms/presentation/join_room_screen.dart';
import 'package:gioco_del_101/features/rooms/presentation/matchmaking_screen.dart';
import 'package:gioco_del_101/features/rooms/presentation/room_lobby_screen.dart';
import 'package:gioco_del_101/features/settings/application/settings_controller.dart';

/// §7 — the same three sizes the existing suite uses: a modern phone, the
/// small-Android floor, and a tablet.
const sizes = <Size>[Size(390, 844), Size(360, 640), Size(834, 1112)];

Future<void> _boot() async {
  SharedPreferences.setMockInitialValues({});
  Get.reset();
  final storage = await LocalStorage.open();
  InitialBinding(storage).dependencies();
  Motion.reduceMotion = true;
  Strings.use(const Locale('it'));
}

Future<void> _render(
  WidgetTester tester,
  Widget child,
  Size size, {
  int frames = 12,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      // The real route table, so a screen that navigates actually can.
      getPages: AppPages.pages,
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: child,
      ),
    ),
  );
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

/// Every screen this session added, built the same way the router builds it.
final screens = <String, Widget Function()>{
  'onboarding': () => const OnboardingScreen(),
  'auth landing': () => const AuthLandingScreen(),
  'login': () => const LoginScreen(),
  'signup': () => const SignupScreen(),
  'forgot password': () => const ForgotPasswordScreen(),
  'home': () => const HomeScreen(),
  'online mode': () => const OnlineModeScreen(),
  'create room': () => const CreateRoomScreen(),
  'join room': () => const JoinRoomScreen(),
  'room lobby': () => const RoomLobbyScreen(),
  'matchmaking': () => const MatchmakingScreen(),
  'profile': () => const ProfileScreen(),
  'edit profile': () => const EditProfileScreen(),
  'leaderboard': () => const LeaderboardScreen(),
  'achievements': () => const AchievementsScreen(),
  'daily reward': () => const DailyRewardScreen(),
};

void main() {
  setUp(_boot);

  tearDown(() {
    Motion.reduceMotion = false;
    Strings.use(const Locale('it'));
    Get.reset();
  });

  group('Every new screen renders clean at three sizes (§7)', () {
    for (final entry in screens.entries) {
      for (final size in sizes) {
        testWidgets(
          '${entry.key} at ${size.width.toInt()}x${size.height.toInt()}',
          (tester) async {
            await _render(tester, entry.value(), size);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  });

  group('Both languages render (§9)', () {
    for (final code in const ['it', 'en']) {
      testWidgets('the account and online screens in $code', (tester) async {
        Strings.use(Locale(code));
        for (final key in const [
          'auth landing',
          'signup',
          'online mode',
          'create room',
          'profile',
        ]) {
          await _render(tester, screens[key]!(), sizes.first);
          expect(tester.takeException(), isNull, reason: '$key in $code');
        }
      });
    }

    testWidgets('switching locale changes what the tree shows', (tester) async {
      final settings = Get.find<SettingsController>();

      Strings.use(const Locale('it'));
      await _render(tester, const AuthLandingScreen(), sizes.first);
      expect(find.text('GIOCA COME OSPITE'), findsOneWidget);

      await settings.setLocale(const Locale('en'));
      await _render(tester, const AuthLandingScreen(), sizes.first);
      expect(find.text('PLAY AS GUEST'), findsOneWidget);
      expect(settings.settings.localeCode, 'en');
    });
  });

  group('Forms validate before they submit (§D, §E)', () {
    testWidgets('login rejects a bad email and a short password', (
      tester,
    ) async {
      await _render(tester, const LoginScreen(), sizes.first);
      final s = Strings.s;

      await tester.enterText(find.byType(TextFormField).first, 'not-an-email');
      await tester.enterText(find.byType(TextFormField).last, 'short');
      await tester.pump();

      await tester.tap(find.text(s.loginCta));
      await tester.pump();

      expect(find.text(s.valEmailInvalid), findsOneWidget);
      expect(find.text(s.valPasswordShort), findsOneWidget);
    });

    testWidgets('signup catches mismatched passwords', (tester) async {
      await _render(tester, const SignupScreen(), sizes.first);
      final s = Strings.s;
      final fields = find.byType(TextFormField);

      await tester.enterText(fields.at(0), 'Farhan');
      await tester.enterText(fields.at(1), 'farhan@example.com');
      await tester.enterText(fields.at(2), 'password123');
      await tester.enterText(fields.at(3), 'password124');
      await tester.pump();

      await tester.tap(find.text(s.signupCta));
      await tester.pump();

      expect(find.text(s.valPasswordMismatch), findsOneWidget);
    });

    testWidgets('a valid submission is told the service is not connected', (
      tester,
    ) async {
      await _render(tester, const ForgotPasswordScreen(), sizes.first);
      final s = Strings.s;

      await tester.enterText(
        find.byType(TextFormField).first,
        'farhan@example.com',
      );
      await tester.pump();
      await tester.tap(find.text(s.forgotCta));
      // Long enough for the submit cycle to settle.
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 60));
      }

      // The honest outcome, not a fabricated success.
      expect(find.text(s.authBackendPending), findsOneWidget);
    });
  });

  group('Nothing pretends to be online (§H, §K, §L, §R)', () {
    testWidgets('the lobby seats only the player and cannot start', (
      tester,
    ) async {
      await _render(tester, const RoomLobbyScreen(), sizes.first);
      final s = Strings.s;

      expect(find.text(s.authBackendPending), findsOneWidget);
      // The host's Start button exists but is disabled.
      final start = tester.widget<PremiumButton>(
        find.widgetWithText(PremiumButton, s.lobbyStart),
      );
      expect(start.onPressed, isNull);
    });

    testWidgets('matchmaking never announces a found opponent', (tester) async {
      await _render(tester, const MatchmakingScreen(), sizes.first);
      final s = Strings.s;
      // One seat filled out of two (the default table), and it is the
      // local player; without a backend the search cannot even start.
      expect(find.text(s.matchmakingFound(1, 2)), findsOneWidget);
      final search = tester.widget<PremiumButton>(
        find.widgetWithText(PremiumButton, s.matchmakingSearch),
      );
      expect(search.onPressed, isNull);
    });

    testWidgets('both leaderboards show the empty state', (tester) async {
      await _render(tester, const LeaderboardScreen(), sizes.first);
      final s = Strings.s;
      expect(find.text(s.leaderboardEmpty), findsOneWidget);

      await tester.tap(find.text(s.leaderboardAllTime));
      await tester.pump();
      expect(find.text(s.leaderboardEmpty), findsOneWidget);
    });

    testWidgets('the daily reward says why it cannot be claimed yet', (
      tester,
    ) async {
      await _render(tester, const DailyRewardScreen(), sizes.first);
      final s = Strings.s;
      // Pressable on purpose: a button that does nothing explains nothing,
      // so the refusal is spoken instead of being a greyed-out rectangle.
      final claim = tester.widget<PremiumButton>(
        find.widgetWithText(PremiumButton, s.dailyRewardClaim),
      );
      expect(claim.onPressed, isNotNull);
      expect(find.text(s.authBackendPending), findsOneWidget);
    });
  });

  group('Onboarding runs once (§B)', () {
    testWidgets('skipping marks it complete', (tester) async {
      final settings = Get.find<SettingsController>();
      expect(settings.onboardingComplete, isFalse);

      await _render(tester, const OnboardingScreen(), sizes.first);
      await tester.tap(find.text(Strings.s.commonSkip));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(settings.onboardingComplete, isTrue);
    });

    testWidgets('paging to the last page swaps Next for Start', (tester) async {
      await _render(tester, const OnboardingScreen(), sizes.first);
      final s = Strings.s;

      expect(find.text(s.commonNext), findsOneWidget);
      for (var page = 0; page < 2; page++) {
        await tester.tap(find.text(s.commonNext));
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 60));
        }
      }
      expect(find.text(s.commonStart), findsOneWidget);
    });
  });

  group('Room code entry (§J)', () {
    testWidgets('Join stays disabled until six characters are typed', (
      tester,
    ) async {
      await _render(tester, const JoinRoomScreen(), sizes.first);
      final s = Strings.s;

      PremiumButton joinButton() => tester.widget<PremiumButton>(
        find.widgetWithText(PremiumButton, s.joinRoomCta),
      );

      expect(joinButton().onPressed, isNull);

      await tester.enterText(find.byType(TextFormField).first, 'abcde');
      await tester.pump();
      expect(joinButton().onPressed, isNull);

      await tester.enterText(find.byType(TextFormField).first, 'abcdef');
      await tester.pump();
      expect(joinButton().onPressed, isNotNull);
    });
  });

  group('The network banner shell (§6)', () {
    testWidgets('collapses when online and shows when not', (tester) async {
      for (final status in NetworkStatus.values) {
        await _render(
          tester,
          Scaffold(
            body: NetworkStatusBanner(
              status: status,
              connectingLabel: 'connecting',
              offlineLabel: 'offline',
            ),
          ),
          sizes.first,
          frames: 6,
        );
        expect(tester.takeException(), isNull);
        expect(
          find.text('offline'),
          status == NetworkStatus.offline ? findsOneWidget : findsNothing,
        );
        expect(
          find.text('connecting'),
          status == NetworkStatus.connecting ? findsOneWidget : findsNothing,
        );
      }
    });
  });
}
