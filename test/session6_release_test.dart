// Session 6 — release-readiness regressions.
//
// Each test pins a defect the final audit found and fixed:
//   • the table rebuilt once a second online (status without value equality);
//   • the offline driver was route-scoped, so a `replace: true` launch (CPU
//     fallback, offline rematch) closed it as soon as the launching screen
//     was disposed;
//   • the XP bar caption overflowed narrow screens;
//   • cards and the discard pile had no semantics at all;
//   • the platform's own reduce-motion flag was ignored;
//   • a wide (52-bit) deal seed must stay deterministic;
//   • an expired session must raise the "Sessione scaduta" notice once;
//   • a round-result sheet opened after the next round was already dealt
//     (fast opponent online) must close itself instead of hiding the table.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gioco_del_101/app/bindings/backend_services.dart';
import 'package:gioco_del_101/app/bindings/initial_binding.dart';
import 'package:gioco_del_101/app/localization/app_strings.dart';
import 'package:gioco_del_101/app/router/app_router.dart';
import 'package:gioco_del_101/app/theme/app_theme.dart';
import 'package:gioco_del_101/core/storage/local_storage.dart';
import 'package:gioco_del_101/core/utils/motion.dart';
import 'package:gioco_del_101/core/widgets/cards/card_names.dart';
import 'package:gioco_del_101/core/widgets/cards/playing_card.dart';
import 'package:gioco_del_101/core/widgets/network_banner.dart';
import 'package:gioco_del_101/core/widgets/xp_bar.dart';
import 'package:gioco_del_101/features/auth/application/session_controller.dart';
import 'package:gioco_del_101/features/auth/domain/auth_gateway.dart';
import 'package:gioco_del_101/features/auth/domain/auth_session.dart';
import 'package:gioco_del_101/features/game/application/game_controller.dart';
import 'package:gioco_del_101/features/game/application/match_launcher.dart';
import 'package:gioco_del_101/features/game/application/table_controller.dart';
import 'package:gioco_del_101/features/game/domain/card_rank.dart';
import 'package:gioco_del_101/features/game/domain/card_suit.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_engine.dart';
import 'package:gioco_del_101/features/game/domain/game_card.dart';
import 'package:gioco_del_101/features/game/domain/game_rules.dart';
import 'package:gioco_del_101/features/game/domain/match_factory.dart';
import 'package:gioco_del_101/features/game/domain/game_player.dart';
import 'package:gioco_del_101/features/game/domain/game_state.dart';
import 'package:gioco_del_101/features/game/domain/player_type.dart';
import 'package:gioco_del_101/features/online/domain/online_status.dart';
import 'package:gioco_del_101/features/game/domain/table_session_status.dart';
import 'package:gioco_del_101/features/game/presentation/round_result_screen.dart';
import 'package:gioco_del_101/features/game/presentation/widgets/table_piles.dart';

Future<void> _boot() async {
  SharedPreferences.setMockInitialValues({});
  Get.reset();
  Get.testMode = true;
  final storage = await LocalStorage.open();
  InitialBinding(storage, backend: BackendServices.none()).dependencies();
  Motion.reduceMotion = true;
  Strings.use(const Locale('it'));
}

void main() {
  tearDown(() {
    Motion.reduceMotion = false;
    Motion.systemReduceMotion = false;
    Get.reset();
  });

  group('TableSessionStatus has value semantics', () {
    test('equal fields compare equal and hash equal', () {
      const a = TableSessionStatus(
        isOnline: true,
        connection: NetworkStatus.online,
        turnSecondsRemaining: 12,
        turnSecondsTotal: 30,
      );
      const b = TableSessionStatus(
        isOnline: true,
        connection: NetworkStatus.online,
        turnSecondsRemaining: 12,
        turnSecondsTotal: 30,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(
        a,
        isNot(
          equals(
            const TableSessionStatus(
              isOnline: true,
              connection: NetworkStatus.online,
              turnSecondsRemaining: 11,
              turnSecondsTotal: 30,
            ),
          ),
        ),
      );
    });

    test('an Rx republishing the same status does not notify', () {
      final rx = Rx<TableSessionStatus>(TableSessionStatus.offlineLocal);
      var notified = 0;
      rx.listen((_) => notified++);
      rx.value = const TableSessionStatus(
        isOnline: true,
        connection: NetworkStatus.connecting,
      );
      rx.value = const TableSessionStatus(
        isOnline: true,
        connection: NetworkStatus.connecting,
      );
      rx.value = const TableSessionStatus(
        isOnline: true,
        connection: NetworkStatus.connecting,
      );
      expect(notified, 1);
    });
  });

  testWidgets(
    'MatchLauncher.launch(replace: true) keeps the driver alive after the '
    'launching route is disposed, and dismiss() closes it',
    (tester) async {
      await _boot();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.build(),
          getPages: AppPages.pages,
          initialRoute: AppRoutes.setup,
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(Get.currentRoute, AppRoutes.setup);

      MatchLauncher.launch(
        MatchFactory.vsComputer(
          playerName: 'Tu',
          avatarId: 'lucia',
          playerCount: 2,
          difficulty: BotDifficulty.easy,
          rules: const GameRules(),
        ),
        replace: true,
      );
      // Let the replaced route finish its transition and be disposed.
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(Get.currentRoute, AppRoutes.game);
      expect(Get.isRegistered<GameController>(), isTrue);
      expect(Get.isRegistered<TableController>(), isTrue);
      final game = Get.find<GameController>();
      expect(game.isClosed, isFalse);

      MatchLauncher.dismiss();
      expect(Get.isRegistered<GameController>(), isFalse);
      expect(Get.isRegistered<TableController>(), isFalse);
      // Timers armed by the bots / saves must not outlive the driver.
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    },
  );

  testWidgets('XpBar caption never overflows a narrow row', (tester) async {
    await _boot();
    final errors = <FlutterErrorDetails>[];
    final previous = FlutterError.onError;
    FlutterError.onError = errors.add;
    addTearDown(() => FlutterError.onError = previous);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: const Scaffold(
          body: Center(
            child: SizedBox(
              width: 140,
              child: XpBar(
                progress: 0.4,
                label: 'Una missione dal nome molto lungo',
                caption: '3/5 · +20 XP · solo online',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(errors.where((e) => '$e'.contains('overflowed')), isEmpty);
  });

  group('card semantics', () {
    test('cardDisplayName follows the locale', () {
      final card = GameCard(CardSuit.spade, CardRank.cavallo);
      Strings.use(const Locale('it'));
      expect(cardDisplayName(card), 'Cavallo di Spade');
      Strings.use(const Locale('en'));
      expect(cardDisplayName(card), 'Knight of Swords');
      Strings.use(const Locale('it'));
    });

    testWidgets('a face-up card and the discard pile are labelled', (
      tester,
    ) async {
      await _boot();
      final handle = tester.ensureSemantics();
      final top = GameCard(CardSuit.coppe, CardRank.sette);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.build(),
          home: Scaffold(
            body: Column(
              children: [
                PlayingCard(width: 60, card: top),
                const PlayingCard(width: 60, faceUp: false),
                DiscardPileView(top: top, beneath: const [], cardWidth: 60),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.bySemanticsLabel('7 di Coppe'), findsOneWidget);
      expect(find.bySemanticsLabel(Strings.s.cardBack), findsOneWidget);
      expect(find.bySemanticsLabel('Scarti: 7 di Coppe'), findsOneWidget);
      handle.dispose();
    });
  });

  test('the OS reduce-motion flag counts as much as the setting', () {
    Motion.reduceMotion = false;
    Motion.systemReduceMotion = false;
    expect(Motion.reduceMotion, isFalse);
    Motion.systemReduceMotion = true;
    expect(Motion.reduceMotion, isTrue);
    expect(Motion.allowAmbient, isFalse);
    Motion.systemReduceMotion = false;
    Motion.reduceMotion = true;
    expect(Motion.reduceMotion, isTrue);
  });

  group('deal seed width', () {
    GameState deal(int seed) {
      const engine = GameEngine();
      return engine.createGame(
        gameId: 'seed',
        players: [
          GamePlayer(
            id: 'p0',
            name: 'A',
            type: PlayerType.humanLocal,
            avatarId: 'lucia',
          ),
          GamePlayer(
            id: 'p1',
            name: 'B',
            type: PlayerType.humanLocal,
            avatarId: 'lucia',
          ),
        ],
        mode: GameMode.passAndPlay,
        seed: seed,
      );
    }

    test('a 52-bit seed is deterministic and differs from its low 31 bits', () {
      const wide = 4503599627370495; // 2^52 - 1
      final a = deal(wide);
      final b = deal(wide);
      expect(a.toJson(), b.toJson());
      final narrow = deal(wide % 0x80000000);
      expect(
        a.players.first.hand.map((c) => c.id).toList(),
        isNot(narrow.players.first.hand.map((c) => c.id).toList()),
      );
      // Every card is still exactly once on the table.
      final all = [
        ...a.drawPile,
        ...a.discardPile,
        for (final p in a.players) ...p.hand,
      ];
      expect(all.map((c) => c.id).toSet().length, 40);
    });
  });

  testWidgets(
    'a round-result sheet with no result to show pops back to the table',
    (tester) async {
      await _boot();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.build(),
          getPages: AppPages.pages,
          initialRoute: AppRoutes.setup,
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      MatchLauncher.launch(
        MatchFactory.vsComputer(
          playerName: 'Tu',
          avatarId: 'lucia',
          playerCount: 2,
          difficulty: BotDifficulty.easy,
          rules: const GameRules(),
        ),
      );
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(Get.currentRoute, AppRoutes.game);
      // The table's driver has no round result (the round is under way —
      // online this is the state after another seat dealt the next round).
      expect(Get.find<TableController>().lastRoundResult.value, isNull);
      unawaited(Get.toNamed<void>(AppRoutes.roundResult));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(Get.currentRoute, AppRoutes.game);
      expect(find.byType(RoundResultScreen), findsNothing);
      MatchLauncher.dismiss();
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    },
  );

  testWidgets('an expired session raises the notice once', (tester) async {
    await _boot();
    final gateway = _FlakyGateway();
    Get.delete<SessionController>(force: true);
    final sessions = Get.put(SessionController(gateway), permanent: true);
    expect(sessions.expired.value, isFalse);
    gateway.emit(
      const AuthSession(userId: 'u1', email: 'a@b.it', isGuest: false),
    );
    await tester.pump();
    gateway.emit(null); // the server refused the refresh
    await tester.pump();
    expect(sessions.expired.value, isTrue);

    // A deliberate sign-out does not count as an expiry.
    sessions.expired.value = false;
    gateway.emit(
      const AuthSession(userId: 'u1', email: 'a@b.it', isGuest: false),
    );
    await tester.pump();
    await sessions.signOut();
    await tester.pump();
    expect(sessions.expired.value, isFalse);
  });
}

class _FlakyGateway implements AuthGateway {
  final _changes = StreamController<AuthSession?>.broadcast();
  AuthSession? _current;

  void emit(AuthSession? s) {
    _current = s;
    _changes.add(s);
  }

  @override
  AuthSession? get current => _current;

  @override
  Stream<AuthSession?> get changes => _changes.stream;

  @override
  BackendAvailability get availability => BackendAvailability.ready;

  @override
  Future<AuthOutcome> signIn({
    required String email,
    required String password,
  }) async => const AuthFailed(AuthErrorCode.unavailable);

  @override
  Future<AuthOutcome> signInAsGuest() async =>
      const AuthFailed(AuthErrorCode.unavailable);

  @override
  Future<AuthOutcome> signUp({
    required String email,
    required String password,
    required String nickname,
    required String avatarId,
  }) async => const AuthFailed(AuthErrorCode.unavailable);

  @override
  Future<AuthOutcome> sendPasswordReset(String email) async =>
      const AuthFailed(AuthErrorCode.unavailable);

  @override
  Future<void> signOut() async {
    _current = null;
    _changes.add(null);
  }

  @override
  Future<AccountDeletion> deleteAccount() async {
    await signOut();
    return AccountDeletion.done;
  }
}
