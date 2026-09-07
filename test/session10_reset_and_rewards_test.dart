// Session 10 — the password-reset round trip, and the daily-reward screen.
//
// Two client reports: "there is no way to actually reset a password" and
// "the reward screen is not aligned and claim does nothing". The first was
// real — the app asked Supabase to send the email and had nowhere for the
// link to land; the second was a screen whose only answer to a refusal was a
// dead button.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import 'package:gioco_del_101/app/app.dart';
import 'package:gioco_del_101/app/bindings/backend_services.dart';
import 'package:gioco_del_101/app/bindings/initial_binding.dart';
import 'package:gioco_del_101/app/localization/app_strings.dart';
import 'package:gioco_del_101/app/router/app_router.dart';
import 'package:gioco_del_101/app/theme/app_theme.dart';
import 'package:gioco_del_101/core/config/supabase_env.dart';
import 'package:gioco_del_101/core/storage/local_storage.dart';
import 'package:gioco_del_101/core/utils/motion.dart';
import 'package:gioco_del_101/core/widgets/premium_button.dart';
import 'package:gioco_del_101/features/auth/application/password_reset_link.dart';
import 'package:gioco_del_101/features/auth/application/session_controller.dart';
import 'package:gioco_del_101/features/auth/application/supabase_auth_gateway.dart';
import 'package:gioco_del_101/features/auth/domain/auth_gateway.dart';
import 'package:gioco_del_101/features/auth/domain/auth_session.dart';
import 'package:gioco_del_101/features/auth/presentation/auth_error_copy.dart';
import 'package:gioco_del_101/features/auth/presentation/forgot_password_screen.dart';
import 'package:gioco_del_101/features/auth/presentation/reset_password_screen.dart';
import 'package:gioco_del_101/features/online/domain/online_status.dart';
import 'package:gioco_del_101/features/rewards/application/daily_reward_repository.dart';
import 'package:gioco_del_101/features/rewards/presentation/daily_reward_screen.dart';
import 'package:gioco_del_101/features/settings/application/settings_controller.dart';

// ------------------------------------------------------------------ fakes

/// A gateway that answers with whatever the test queued and remembers how it
/// was called.
class _Gateway implements AuthGateway {
  _Gateway({this.session});

  AuthSession? session;
  AuthOutcome next = const AuthFailed(AuthErrorCode.unknown);
  final List<String> calls = [];
  final _changes = StreamController<AuthSession?>.broadcast();
  final _recovery = StreamController<PasswordRecovery>.broadcast();

  void emitRecovery(PasswordRecovery event) => _recovery.add(event);

  @override
  BackendAvailability get availability => BackendAvailability.ready;

  @override
  AuthSession? get current => session;

  @override
  Stream<AuthSession?> get changes => _changes.stream;

  @override
  Stream<PasswordRecovery> get passwordRecovery => _recovery.stream;

  @override
  Future<AuthOutcome> signUp({
    required String email,
    required String password,
    required String nickname,
    required String avatarId,
  }) async => next;

  @override
  Future<AuthOutcome> signIn({
    required String email,
    required String password,
  }) async => next;

  @override
  Future<AuthOutcome> signInAsGuest() async => next;

  @override
  Future<AuthOutcome> sendPasswordReset(String email) async {
    calls.add('sendPasswordReset:${email.trim()}');
    return next;
  }

  @override
  Future<AuthOutcome> updatePassword(String password) async {
    calls.add('updatePassword:$password');
    return next;
  }

  @override
  Future<void> signOut() async => session = null;

  @override
  Future<AccountDeletion> deleteAccount() async => AccountDeletion.done;
}

/// A reward ladder the test drives.
class _Rewards implements DailyRewardRepository {
  _Rewards(this.current);

  DailyRewardStatus? current;
  DailyRewardException? refuse;
  int claims = 0;

  @override
  Future<DailyRewardStatus?> status() async => current;

  @override
  Future<DailyRewardStatus> claim() async {
    claims++;
    final refusal = refuse;
    if (refusal != null) throw refusal;
    final before = current!;
    return current = DailyRewardStatus(
      streak: before.streak + 1,
      claimedToday: true,
      canClaim: false,
      coins: before.coins + 20,
    );
  }
}

const _member = AuthSession(
  userId: 'u-1',
  isGuest: false,
  email: 'gioco@example.it',
);

// ----------------------------------------------------------------- harness

const _phone = Size(390, 844);

LocalStorage? _storage;

Future<_Gateway> _boot({
  AuthSession? session,
  DailyRewardRepository? rewards,
  bool online = true,
}) async {
  SharedPreferences.setMockInitialValues({});
  Get.reset();
  PasswordResetLink.reset();
  final gateway = _Gateway(session: session);
  final none = BackendServices.none();
  final backend = BackendServices(
    auth: gateway,
    profiles: none.profiles,
    leaderboards: none.leaderboards,
    dailyRewards: rewards ?? none.dailyRewards,
    rooms: none.rooms,
    matches: none.matches,
    matchmaking: none.matchmaking,
  );
  final storage = _storage = await LocalStorage.open();
  InitialBinding(storage, backend: backend).dependencies();
  OnlineStatus.report(
    online ? BackendAvailability.ready : BackendAvailability.notConfigured,
  );
  Motion.reduceMotion = true;
  Strings.use(const Locale('it'));
  return gateway;
}

Future<void> _render(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = _phone;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      getPages: AppPages.pages,
      home: MediaQuery(data: const MediaQueryData(size: _phone), child: child),
    ),
  );
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

void main() {
  tearDown(() {
    Motion.reduceMotion = false;
    Strings.use(const Locale('it'));
    PasswordResetLink.reset();
    OnlineStatus.reset();
    Get.reset();
  });

  // --------------------------------------------------- the link comes back

  group('The reset link has somewhere to land', () {
    test('the redirect, the manifest and the allow-list name one URL', () {
      final redirect = Uri.parse(SupabaseEnv.passwordResetRedirect);
      expect(redirect.scheme, isNotEmpty);
      expect(redirect.host, isNotEmpty);

      // Android hands the link back to the app only if it claims the scheme.
      final manifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();
      expect(
        manifest,
        contains(
          '<data android:scheme="${redirect.scheme}" '
          'android:host="${redirect.host}"/>',
        ),
      );

      // iOS the same, through its URL types.
      final plist = File('ios/Runner/Info.plist').readAsStringSync();
      expect(plist, contains('CFBundleURLSchemes'));
      expect(plist, contains('<string>${redirect.scheme}</string>'));

      // And Supabase substitutes the Site URL for any redirect it was not
      // told about, which is exactly how this flow died before.
      final config = File('supabase/config.toml').readAsStringSync();
      expect(
        config,
        contains('additional_redirect_urls = '
            '["${SupabaseEnv.passwordResetRedirect}"]'),
      );
    });

    test('an auth deep link is recognised, an ordinary one is not', () {
      expect(
        PasswordResetLink.isAuthCallback(
          Uri.parse('${SupabaseEnv.passwordResetRedirect}?code=abc123'),
        ),
        isTrue,
      );
      expect(
        PasswordResetLink.isAuthCallback(
          Uri.parse('${SupabaseEnv.passwordResetRedirect}#access_token=t'),
        ),
        isTrue,
      );
      expect(
        PasswordResetLink.isAuthCallback(
          Uri.parse('${SupabaseEnv.passwordResetRedirect}?error=expired'),
        ),
        isTrue,
      );
      expect(
        PasswordResetLink.isAuthCallback(Uri.parse('https://example.com/x')),
        isFalse,
      );
    });

    test('a link only explains an error while it is fresh', () {
      var now = DateTime(2026, 9, 7, 12);
      PasswordResetLink.clock = () => now;
      expect(PasswordResetLink.isPending, isFalse);

      PasswordResetLink.observe();
      expect(PasswordResetLink.isPending, isTrue);

      now = now.add(const Duration(seconds: 5));
      expect(PasswordResetLink.isPending, isTrue);

      now = now.add(PasswordResetLink.window);
      expect(PasswordResetLink.isPending, isFalse);
    });

    test('a spent link and a reused password are named, not lumped in', () {
      AuthErrorCode map(String code) => SupabaseAuthGateway.mapError(
        AuthException('x', statusCode: '400', code: code),
      );
      expect(map('same_password'), AuthErrorCode.samePassword);
      expect(map('otp_expired'), AuthErrorCode.resetLinkExpired);
      expect(map('flow_state_not_found'), AuthErrorCode.resetLinkExpired);
      expect(map('invalid_credentials'), AuthErrorCode.invalidCredentials);
    });

    test('every AuthErrorCode still has copy', () {
      for (final code in AuthErrorCode.values) {
        expect(Strings.s.authError(code), isNotEmpty, reason: code.name);
      }
    });
  });

  // ------------------------------------------------------- the app reacts

  group('The shell, booted for real', () {
    testWidgets('a link opened from cold survives the splash', (tester) async {
      final gateway = await _boot(session: _member);
      await Get.find<SettingsController>().completeOnboarding();
      await tester.pumpWidget(GiocoDel101App(storage: _storage!));
      await tester.pump();

      // The link lands while the splash is still running. The splash ends by
      // replacing the top route, so a screen pushed now would be thrown away.
      expect(Get.currentRoute, AppRoutes.splash);
      gateway.emitRecovery(PasswordRecovery.ready);

      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 60));
      }

      expect(Get.currentRoute, AppRoutes.resetPassword);
      expect(find.text(Strings.s.resetPasswordTitle), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a spent link is named rather than dropped', (tester) async {
      final gateway = await _boot(session: _member);
      await Get.find<SettingsController>().completeOnboarding();
      await tester.pumpWidget(GiocoDel101App(storage: _storage!));
      await tester.pump();

      gateway.emitRecovery(PasswordRecovery.linkInvalid);
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 60));
      }

      expect(find.text(Strings.s.resetLinkExpiredBody), findsOneWidget);
    });
  });

  group('SessionController', () {
    test('passes a recovery event on for the shell to act on', () async {
      final gateway = await _boot();
      final sessions = Get.find<SessionController>();
      expect(sessions.recovery.value, isNull);

      gateway.emitRecovery(PasswordRecovery.ready);
      await Future<void>.delayed(Duration.zero);
      expect(sessions.recovery.value, PasswordRecovery.ready);

      sessions.recovery.value = null;
      gateway.emitRecovery(PasswordRecovery.linkInvalid);
      await Future<void>.delayed(Duration.zero);
      expect(sessions.recovery.value, PasswordRecovery.linkInvalid);
    });

    test('adopts the session a password change returns', () async {
      final gateway = await _boot();
      gateway.next = const AuthSuccess(_member);
      final sessions = Get.find<SessionController>();

      final outcome = await sessions.updatePassword('nuova-password');

      expect(outcome, isA<AuthSuccess>());
      expect(gateway.calls, contains('updatePassword:nuova-password'));
      expect(sessions.current, _member);
    });

    test('without a backend there is nothing to change', () async {
      final gateway = NoBackendAuthGateway();
      final outcome = await gateway.updatePassword('whatever-it-is');
      expect(
        outcome,
        isA<AuthFailed>().having(
          (f) => f.code,
          'code',
          AuthErrorCode.unavailable,
        ),
      );
      expect(await gateway.passwordRecovery.toList(), isEmpty);
    });
  });

  // ---------------------------------------------------------- the screens

  group('Forgot password', () {
    testWidgets('sends the email and says where to open the link', (
      tester,
    ) async {
      final gateway = await _boot();
      gateway.next = const AuthNeedsConfirmation('');
      await _render(tester, const ForgotPasswordScreen());
      final s = Strings.s;

      await tester.enterText(find.byType(TextField), 'gioco@example.it');
      await tester.tap(find.widgetWithText(PremiumButton, s.forgotCta));
      await tester.pumpAndSettle();

      expect(gateway.calls, ['sendPasswordReset:gioco@example.it']);
      expect(find.text(s.forgotSentTitle), findsOneWidget);
      // The link is bound to this device and expires — both said up front.
      expect(find.textContaining(s.forgotSentHint), findsOneWidget);
    });
  });

  group('New password', () {
    testWidgets('refuses a short password and a mismatched pair', (
      tester,
    ) async {
      final gateway = await _boot(session: _member);
      await _render(tester, const ResetPasswordScreen());
      final s = Strings.s;
      final fields = find.byType(TextField);

      await tester.enterText(fields.at(0), 'corta');
      await tester.enterText(fields.at(1), 'corta');
      await tester.tap(find.widgetWithText(PremiumButton, s.resetPasswordCta));
      await tester.pumpAndSettle();
      expect(find.text(s.valPasswordShort), findsWidgets);
      expect(gateway.calls, isEmpty);

      await tester.enterText(fields.at(0), 'password-lunga');
      await tester.enterText(fields.at(1), 'password-diversa');
      await tester.tap(find.widgetWithText(PremiumButton, s.resetPasswordCta));
      await tester.pumpAndSettle();
      expect(find.text(s.valPasswordMismatch), findsOneWidget);
      expect(gateway.calls, isEmpty);
    });

    testWidgets('saves the new password and confirms it', (tester) async {
      final gateway = await _boot(session: _member);
      gateway.next = const AuthSuccess(_member);
      await _render(tester, const ResetPasswordScreen());
      final s = Strings.s;
      final fields = find.byType(TextField);

      await tester.enterText(fields.at(0), 'password-nuova');
      await tester.enterText(fields.at(1), 'password-nuova');
      await tester.tap(find.widgetWithText(PremiumButton, s.resetPasswordCta));
      await tester.pumpAndSettle();

      expect(gateway.calls, ['updatePassword:password-nuova']);
      expect(find.text(s.resetPasswordDoneTitle), findsOneWidget);
    });

    testWidgets('a refusal from the server is shown by name', (tester) async {
      final gateway = await _boot(session: _member);
      gateway.next = const AuthFailed(AuthErrorCode.samePassword);
      await _render(tester, const ResetPasswordScreen());
      final s = Strings.s;
      final fields = find.byType(TextField);

      await tester.enterText(fields.at(0), 'password-nuova');
      await tester.enterText(fields.at(1), 'password-nuova');
      await tester.tap(find.widgetWithText(PremiumButton, s.resetPasswordCta));
      await tester.pumpAndSettle();

      expect(find.text(s.authErrorSamePassword), findsOneWidget);
    });
  });

  // ----------------------------------------------------------- the ladder

  group('Daily reward', () {
    testWidgets('the seven tiles sit in two centred rows', (tester) async {
      await _boot(
        session: _member,
        rewards: _Rewards(
          const DailyRewardStatus(
            streak: 2,
            claimedToday: false,
            canClaim: true,
            coins: 45,
          ),
        ),
      );
      await _render(tester, const DailyRewardScreen());
      final s = Strings.s;

      final tiles = [
        for (var day = 1; day <= 7; day++)
          tester.getRect(find.text(s.dailyRewardDay(day))),
      ];
      final top = tiles.sublist(0, 4);
      final bottom = tiles.sublist(4);

      // Four across, then three — and the short row is centred under the
      // long one rather than left against the gutter.
      expect(top.every((r) => r.top == top.first.top), isTrue);
      expect(bottom.every((r) => r.top == bottom.first.top), isTrue);
      expect(bottom.first.top, greaterThan(top.first.top));

      final topCentre = (top.first.left + top.last.right) / 2;
      final bottomCentre = (bottom.first.left + bottom.last.right) / 2;
      expect((topCentre - bottomCentre).abs(), lessThan(1.0));
      expect(bottom.first.left, greaterThan(top.first.left));
    });

    testWidgets('the claim button is not left floating mid-screen', (
      tester,
    ) async {
      await _boot(session: _member);
      await _render(tester, const DailyRewardScreen());

      final button = tester.getRect(
        find.widgetWithText(PremiumButton, Strings.s.dailyRewardClaim),
      );
      // Anchored near the bottom of the phone, not stranded halfway down.
      expect(button.bottom, greaterThan(_phone.height * 0.75));
      expect(button.bottom, lessThan(_phone.height));
    });

    testWidgets('nothing says the same thing twice', (tester) async {
      await _boot(
        session: _member,
        rewards: _Rewards(
          const DailyRewardStatus(
            streak: 1,
            claimedToday: false,
            canClaim: true,
            coins: 10,
          ),
        ),
      );
      await _render(tester, const DailyRewardScreen());

      // The caption under the button used to repeat the line above the
      // ladder whenever the reward was actually claimable.
      expect(find.text(Strings.s.dailyRewardBody), findsOneWidget);
    });

    testWidgets('claiming says what was won', (tester) async {
      final rewards = _Rewards(
        const DailyRewardStatus(
          streak: 2,
          claimedToday: false,
          canClaim: true,
          coins: 45,
        ),
      );
      await _boot(session: _member, rewards: rewards);
      await _render(tester, const DailyRewardScreen());
      final s = Strings.s;

      await tester.tap(
        find.widgetWithText(PremiumButton, s.dailyRewardClaim),
      );
      await tester.pumpAndSettle();

      expect(rewards.claims, 1);
      expect(find.text(s.dailyRewardWonTitle), findsOneWidget);
      expect(find.text(s.dailyRewardWonBody(20)), findsOneWidget);
      expect(find.text(s.dailyRewardBalance(65)), findsOneWidget);
    });

    testWidgets('a guest is told why, instead of pressing a dead button', (
      tester,
    ) async {
      const guest = AuthSession(userId: 'u-guest', isGuest: true);
      await _boot(session: guest);
      await _render(tester, const DailyRewardScreen());
      final s = Strings.s;

      final claim = tester.widget<PremiumButton>(
        find.widgetWithText(PremiumButton, s.dailyRewardClaim),
      );
      expect(claim.onPressed, isNotNull);

      await tester.tap(find.widgetWithText(PremiumButton, s.dailyRewardClaim));
      await tester.pumpAndSettle();
      expect(find.text(s.dailyRewardGuestHint), findsWidgets);
    });

    testWidgets('signed out, the button offers the way in', (tester) async {
      await _boot();
      await _render(tester, const DailyRewardScreen());
      final s = Strings.s;

      await tester.tap(find.widgetWithText(PremiumButton, s.dailyRewardClaim));
      await tester.pumpAndSettle();

      // Once under the button as the reason, once in the offer itself.
      expect(find.text(s.onlineSignInRequired), findsWidgets);
      expect(find.widgetWithText(PremiumButton, s.authSignIn), findsOneWidget);
    });

    testWidgets('with no backend at all it says so', (tester) async {
      await _boot(online: false);
      await _render(tester, const DailyRewardScreen());
      final s = Strings.s;

      await tester.tap(find.widgetWithText(PremiumButton, s.dailyRewardClaim));
      await tester.pumpAndSettle();
      expect(find.text(s.authBackendPending), findsWidgets);
    });
  });
}
