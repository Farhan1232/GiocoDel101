import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:gioco_del_101/features/auth/application/auth_controller.dart';
import 'package:gioco_del_101/features/auth/application/session_controller.dart';
import 'package:gioco_del_101/features/auth/application/supabase_auth_gateway.dart';
import 'package:gioco_del_101/features/auth/domain/auth_gateway.dart';
import 'package:gioco_del_101/features/auth/domain/auth_session.dart';
import 'package:gioco_del_101/features/auth/domain/auth_validators.dart';
import 'package:gioco_del_101/features/online/domain/online_status.dart';
import 'package:gioco_del_101/features/profile/domain/level_ladder.dart';
import 'package:gioco_del_101/features/profile/domain/profile_summary.dart';
import 'package:gioco_del_101/features/profile/domain/remote_profile.dart';
import 'package:gioco_del_101/features/profile/domain/statistics_model.dart';
import 'package:gioco_del_101/features/settings/domain/settings_model.dart';
import 'package:gioco_del_101/features/splash/domain/boot_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

/// A scripted gateway: every call answers with what the test queued.
class FakeAuthGateway implements AuthGateway {
  FakeAuthGateway({this.initial});

  final AuthSession? initial;
  final StreamController<AuthSession?> _changes =
      StreamController<AuthSession?>.broadcast();
  final List<String> calls = [];
  AuthOutcome next = const AuthFailed(AuthErrorCode.unknown);
  AuthSession? _current;

  @override
  BackendAvailability get availability => BackendAvailability.ready;

  @override
  AuthSession? get current => _current ?? initial;

  @override
  Stream<AuthSession?> get changes => _changes.stream;

  void emit(AuthSession? session) {
    _current = session;
    _changes.add(session);
  }

  @override
  Future<AuthOutcome> signUp({
    required String email,
    required String password,
    required String nickname,
    required String avatarId,
  }) async {
    calls.add('signUp:$email:$nickname:$avatarId');
    return next;
  }

  @override
  Future<AuthOutcome> signIn({
    required String email,
    required String password,
  }) async {
    calls.add('signIn:$email');
    return next;
  }

  @override
  Future<AuthOutcome> signInAsGuest() async {
    calls.add('guest');
    return next;
  }

  @override
  Future<AuthOutcome> sendPasswordReset(String email) async {
    calls.add('reset:$email');
    return next;
  }

  @override
  Future<void> signOut() async {
    calls.add('signOut');
    _current = null;
  }
}

const _guest = AuthSession(userId: 'u-guest', isGuest: true);
const _member = AuthSession(
  userId: 'u-member',
  isGuest: false,
  email: 'a@b.it',
);

void main() {
  tearDown(() {
    Get.reset();
    OnlineStatus.reset();
  });

  group('BootRouter', () {
    test('first run always goes to onboarding', () {
      for (final availability in BackendAvailability.values) {
        for (final session in [null, _guest, _member]) {
          expect(
            BootRouter.resolve(
              onboardingComplete: false,
              availability: availability,
              session: session,
            ),
            BootDestination.onboarding,
          );
        }
      }
    });

    test('no backend: straight home, whatever the session', () {
      for (final session in [null, _guest, _member]) {
        expect(
          BootRouter.resolve(
            onboardingComplete: true,
            availability: BackendAvailability.notConfigured,
            session: session,
          ),
          BootDestination.home,
        );
      }
    });

    test('backend configured and logged out: account choice', () {
      for (final availability in [
        BackendAvailability.ready,
        BackendAvailability.unreachable,
      ]) {
        expect(
          BootRouter.resolve(
            onboardingComplete: true,
            availability: availability,
            session: null,
          ),
          BootDestination.authLanding,
        );
      }
    });

    test('guest and signed-in users go home', () {
      for (final session in [_guest, _member]) {
        expect(
          BootRouter.resolve(
            onboardingComplete: true,
            availability: BackendAvailability.ready,
            session: session,
          ),
          BootDestination.home,
        );
      }
    });
  });

  group('OnlineStatus', () {
    test('defaults to not configured and reports what boot observed', () {
      expect(OnlineStatus.availability, BackendAvailability.notConfigured);
      expect(OnlineStatus.isConfigured, isFalse);
      OnlineStatus.report(BackendAvailability.ready);
      expect(OnlineStatus.isConfigured, isTrue);
      expect(OnlineStatus.isReady, isTrue);
      OnlineStatus.report(BackendAvailability.unreachable);
      expect(OnlineStatus.isConfigured, isTrue);
      expect(OnlineStatus.isReady, isFalse);
    });
  });

  group('NoBackendAuthGateway', () {
    test('never signs anyone in', () async {
      final gateway = NoBackendAuthGateway();
      expect(gateway.current, isNull);
      expect(gateway.availability, BackendAvailability.notConfigured);
      final outcomes = [
        await gateway.signInAsGuest(),
        await gateway.signIn(email: 'a@b.it', password: 'password1'),
        await gateway.signUp(
          email: 'a@b.it',
          password: 'password1',
          nickname: 'Anna',
          avatarId: 'lucia',
        ),
        await gateway.sendPasswordReset('a@b.it'),
      ];
      for (final outcome in outcomes) {
        expect(outcome, isA<AuthFailed>());
        expect((outcome as AuthFailed).code, AuthErrorCode.unavailable);
      }
    });
  });

  group('SessionController', () {
    test('adopts the restored session at init', () {
      final controller = Get.put(
        SessionController(FakeAuthGateway(initial: _member)),
      );
      expect(controller.isSignedIn, isTrue);
      expect(controller.isPermanent, isTrue);
      expect(controller.isGuest, isFalse);
    });

    test('guest sign-in yields a real anonymous session', () async {
      final gateway = FakeAuthGateway()..next = const AuthSuccess(_guest);
      final controller = Get.put(SessionController(gateway));
      expect(controller.isSignedIn, isFalse);
      final outcome = await controller.signInAsGuest();
      expect(outcome, isA<AuthSuccess>());
      expect(controller.isGuest, isTrue);
      expect(controller.current?.userId, 'u-guest');
      expect(gateway.calls, ['guest']);
    });

    test('a failure leaves the session untouched', () async {
      final gateway = FakeAuthGateway()
        ..next = const AuthFailed(AuthErrorCode.invalidCredentials);
      final controller = Get.put(SessionController(gateway));
      await controller.signIn(email: 'a@b.it', password: 'wrong-pass');
      expect(controller.isSignedIn, isFalse);
    });

    test('follows gateway changes and clears on sign-out', () async {
      final gateway = FakeAuthGateway();
      final controller = Get.put(SessionController(gateway));
      gateway.emit(_member);
      await Future<void>.delayed(Duration.zero);
      expect(controller.current, _member);
      await controller.signOut();
      expect(controller.isSignedIn, isFalse);
      expect(gateway.calls, ['signOut']);
    });

    test(
      'sign-up forwards nickname and avatar for the profile trigger',
      () async {
        final gateway = FakeAuthGateway()..next = const AuthSuccess(_member);
        final controller = Get.put(SessionController(gateway));
        await controller.signUp(
          email: 'a@b.it',
          password: 'password1',
          nickname: 'Anna',
          avatarId: 'sofia',
        );
        expect(gateway.calls, ['signUp:a@b.it:Anna:sofia']);
        expect(controller.isPermanent, isTrue);
      },
    );
  });

  group('AuthController', () {
    test('reports the real outcome through the form status', () async {
      final gateway = FakeAuthGateway();
      final session = Get.put(SessionController(gateway));
      final auth = AuthController(session);

      gateway.next = const AuthFailed(AuthErrorCode.unavailable);
      await auth.run(session.signInAsGuest);
      expect(auth.status.value, AuthFormStatus.unavailable);

      gateway.next = const AuthFailed(AuthErrorCode.network);
      await auth.run(session.signInAsGuest);
      expect(auth.status.value, AuthFormStatus.failed);

      gateway.next = const AuthNeedsConfirmation('a@b.it');
      await auth.run(() => session.sendPasswordReset('a@b.it'));
      expect(auth.status.value, AuthFormStatus.succeeded);

      gameOn(auth);
    });

    test('a second submit while one is in flight is ignored', () async {
      final gateway = FakeAuthGateway()..next = const AuthSuccess(_guest);
      final session = Get.put(SessionController(gateway));
      final auth = AuthController(session);
      final first = auth.run(session.signInAsGuest);
      final second = await auth.run(session.signInAsGuest);
      expect(second, isNull);
      expect(await first, isA<AuthSuccess>());
      expect(gateway.calls, ['guest']);
    });
  });

  group('SupabaseAuthGateway error mapping', () {
    test('maps Supabase auth error codes to UI codes', () {
      AuthErrorCode map(String? code, [String? status]) =>
          SupabaseAuthGateway.mapError(
            AuthException('x', code: code, statusCode: status),
          );
      expect(map('invalid_credentials'), AuthErrorCode.invalidCredentials);
      expect(map('email_not_confirmed'), AuthErrorCode.invalidCredentials);
      expect(map('user_already_exists'), AuthErrorCode.emailTaken);
      expect(map('weak_password'), AuthErrorCode.weakPassword);
      expect(map('over_request_rate_limit'), AuthErrorCode.rateLimited);
      expect(map('anonymous_provider_disabled'), AuthErrorCode.guestDisabled);
      expect(map(null, '429'), AuthErrorCode.rateLimited);
      expect(map(null, '500'), AuthErrorCode.unknown);
    });
  });

  group('Remote profile', () {
    final json = <String, dynamic>{
      'id': 'u-member',
      'nickname': 'Anna',
      'avatar_id': 'sofia',
      'is_guest': false,
      'level': 3,
      'xp': 300,
      'wins': 4,
      'losses': 2,
      'matches': 6,
      'rating': 1024,
      'current_streak': 2,
      'best_streak': 3,
      'created_at': '2026-08-29T10:00:00Z',
      'updated_at': '2026-08-29T10:00:00Z',
      'last_seen_at': null,
    };

    test('parses a profiles row', () {
      final profile = RemoteProfile.fromJson(json);
      expect(profile.nickname, 'Anna');
      expect(profile.level, 3);
      expect(profile.rating, 1024);
      expect(profile.isOnline, isFalse);
    });

    test('summary from the server keeps server progression', () {
      final summary = ProfileSummary.fromRemote(
        RemoteProfile.fromJson(json),
        const RemotePlayerStats(resets101: 1, longestChain: 3),
        const StatisticsModel(largestComeback: 40),
      );
      expect(summary.isPlaceholderProgression, isFalse);
      expect(summary.level, 3);
      expect(summary.matchesPlayed, 6);
      expect(summary.matchesWon, 4);
      expect(summary.matchesLost, 2);
      expect(summary.rating, 1024);
      expect(summary.resets101, 1);
      expect(summary.longestChain, 3);
      // A server stats row exists, so its (zero) counter wins; the local
      // number is only a fallback while the row is missing.
      expect(summary.largestComeback, 0);
      final withoutStats = ProfileSummary.fromRemote(
        RemoteProfile.fromJson(json),
        null,
        const StatisticsModel(largestComeback: 40),
      );
      expect(withoutStats.largestComeback, 40);
      // 300 xp: level 1 costs 120, level 2 costs 160 → 20 into level 3.
      expect(summary.xpIntoLevel, 20);
      expect(summary.xpForLevel, 200);
    });

    test('local and remote ladders agree', () {
      final local = ProfileSummary.fromLocal(
        const SettingsModel(),
        const StatisticsModel(matchesPlayed: 10, matchesWon: 4),
      );
      final xp = 10 * LevelLadder.xpPerMatch + 4 * LevelLadder.xpPerWin;
      final position = LevelLadder.resolve(xp);
      expect(local.level, position.level);
      expect(local.xpIntoLevel, position.xpIntoLevel);
      expect(local.xpForLevel, position.xpForLevel);
    });
  });
}

/// Placeholder so the status test reads as a sequence; nothing to do.
void gameOn(AuthController auth) => auth.reset();
