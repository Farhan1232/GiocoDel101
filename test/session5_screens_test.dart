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
import 'package:gioco_del_101/core/storage/game_storage_service.dart';
import 'package:gioco_del_101/core/storage/local_storage.dart';
import 'package:gioco_del_101/core/utils/motion.dart';
import 'package:gioco_del_101/core/widgets/premium_button.dart';
import 'package:gioco_del_101/features/achievements/presentation/achievements_screen.dart';
import 'package:gioco_del_101/features/auth/domain/auth_gateway.dart';
import 'package:gioco_del_101/features/auth/domain/auth_session.dart';
import 'package:gioco_del_101/features/game/application/game_controller.dart';
import 'package:gioco_del_101/features/game/application/table_controller.dart';
import 'package:gioco_del_101/features/game/domain/card_rank.dart';
import 'package:gioco_del_101/features/game/domain/card_suit.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_session.dart';
import 'package:gioco_del_101/features/game/domain/game_card.dart';
import 'package:gioco_del_101/features/game/presentation/game_screen.dart';
import 'package:gioco_del_101/features/game/presentation/widgets/pause_overlay.dart';
import 'package:gioco_del_101/features/leaderboard/application/leaderboard_repository.dart';
import 'package:gioco_del_101/features/leaderboard/domain/leaderboard_models.dart';
import 'package:gioco_del_101/features/leaderboard/presentation/leaderboard_screen.dart';
import 'package:gioco_del_101/features/missions/application/missions_controller.dart';
import 'package:gioco_del_101/features/missions/presentation/missions_screen.dart';
import 'package:gioco_del_101/features/online/application/online_match_repository.dart';
import 'package:gioco_del_101/features/online/domain/online_match_models.dart';
import 'package:gioco_del_101/features/online/domain/online_status.dart';
import 'package:gioco_del_101/features/profile/application/profile_controller.dart';
import 'package:gioco_del_101/features/profile/application/stats_controller.dart';
import 'package:gioco_del_101/features/rooms/presentation/matchmaking_screen.dart';
import 'package:gioco_del_101/features/settings/application/settings_controller.dart';
import 'package:gioco_del_101/features/tutorial/application/tutorial_controller.dart';
import 'package:gioco_del_101/features/tutorial/domain/tutorial_lessons.dart';
import 'package:gioco_del_101/features/tutorial/presentation/tutorial_screen.dart';

import 'support/engine_harness.dart';

// ------------------------------------------------------------------ fakes

class _SignedInGateway implements AuthGateway {
  static const session = AuthSession(
    userId: 'user-a',
    email: 'a@example.com',
    isGuest: false,
  );
  final _changes = StreamController<AuthSession?>.broadcast();
  @override
  BackendAvailability get availability => BackendAvailability.ready;
  @override
  AuthSession? get current => session;
  @override
  Stream<AuthSession?> get changes => _changes.stream;
  @override
  Future<AuthOutcome> signUp({
    required String email,
    required String password,
    required String nickname,
    required String avatarId,
  }) async => const AuthSuccess(session);
  @override
  Future<AuthOutcome> signIn({
    required String email,
    required String password,
  }) async => const AuthSuccess(session);
  @override
  Future<AuthOutcome> signInAsGuest() async => const AuthSuccess(session);
  @override
  Future<AuthOutcome> sendPasswordReset(String email) async =>
      const AuthSuccess(session);
  @override
  Future<void> signOut() async {}

  @override
  Future<AccountDeletion> deleteAccount() async => AccountDeletion.done;
}

/// A queue where nobody else ever shows up.
class _LonelyQueue implements MatchmakingRepository {
  int cancels = 0;
  @override
  Future<QueueEntry> enqueue({
    required int playerCount,
    required int turnTimerSeconds,
  }) async => QueueEntry(
    status: 'waiting',
    playerCount: playerCount,
    turnTimerSeconds: turnTimerSeconds,
  );
  @override
  Future<QueueEntry?> heartbeat() async =>
      const QueueEntry(status: 'waiting', playerCount: 2, turnTimerSeconds: 30);
  @override
  Future<void> cancel() async => cancels++;
}

class _PagedBoard implements LeaderboardRepository {
  _PagedBoard(this.total, {this.selfRank});
  final int total;
  final int? selfRank;
  final List<(int, int)> requests = [];
  @override
  Future<LeaderboardBoard> load(
    LeaderboardScope scope, {
    int limit = 50,
    int offset = 0,
  }) async {
    requests.add((limit, offset));
    final entries = [
      for (var r = offset + 1; r <= total && r <= offset + limit; r++)
        LeaderboardEntry(
          rank: r,
          nickname: 'Giocatore-$r',
          avatarId: 'lucia',
          points: 2000 - r,
          isSelf: r == selfRank,
        ),
    ];
    return LeaderboardBoard(
      scope: scope,
      entries: entries,
      isAvailable: true,
      hasMore: entries.length >= limit,
    );
  }

  @override
  Future<LeaderboardEntry?> myRank(LeaderboardScope scope) async =>
      selfRank == null
      ? null
      : LeaderboardEntry(
          rank: selfRank!,
          nickname: 'Tu',
          avatarId: 'lucia',
          points: 2000 - selfRank!,
          isSelf: true,
        );
}

Future<void> _boot({BackendServices? backend}) async {
  SharedPreferences.setMockInitialValues({});
  Get.reset();
  OnlineStatus.reset();
  final storage = await LocalStorage.open();
  InitialBinding(storage, backend: backend).dependencies();
  // A backend was handed in: the app reports it reachable, as main() does.
  if (backend != null) OnlineStatus.report(BackendAvailability.ready);
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
}

BackendServices _online({
  MatchmakingRepository? matchmaking,
  LeaderboardRepository? leaderboards,
}) {
  final none = BackendServices.none();
  return BackendServices(
    auth: _SignedInGateway(),
    profiles: none.profiles,
    leaderboards: leaderboards ?? none.leaderboards,
    dailyRewards: none.dailyRewards,
    rooms: none.rooms,
    matches: none.matches,
    matchmaking: matchmaking ?? none.matchmaking,
  );
}

/// Advances time in slices so chained delays (bot pacing, cue playback,
/// coalesced saves) all run out before the test ends.
Future<void> _settle(WidgetTester tester, {int slices = 40}) async {
  for (var i = 0; i < slices; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _render(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      getPages: AppPages.pages,
      home: MediaQuery(
        data: const MediaQueryData(size: Size(390, 844)),
        child: child,
      ),
    ),
  );
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

void main() {
  tearDown(() {
    Motion.reduceMotion = false;
    OnlineStatus.reset();
    Get.reset();
  });

  group('Matchmaking offers the CPU honestly (§L)', () {
    testWidgets('after 30 s of waiting: leave the queue, play offline bots', (
      tester,
    ) async {
      final queue = _LonelyQueue();
      await _boot(backend: _online(matchmaking: queue));
      await _render(tester, const MatchmakingScreen());
      final s = Strings.s;

      expect(find.text(s.matchmakingCpuOffer), findsNothing);
      await tester.tap(find.text(s.matchmakingSearch));
      await tester.pump();
      // Before the threshold nothing is offered — and no opponent is faked.
      await tester.pump(const Duration(seconds: 10));
      expect(find.text(s.matchmakingCpuOffer), findsNothing);
      expect(find.text(s.matchmakingFound(1, 2)), findsOneWidget);

      await tester.pump(
        Duration(seconds: MatchmakingScreen.cpuOfferAfterSeconds),
      );
      expect(find.text(s.matchmakingCpuOffer), findsOneWidget);
      expect(find.text(s.matchmakingCpuHint), findsOneWidget);

      await tester.tap(find.text(s.matchmakingCpuOffer));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(queue.cancels, 1, reason: 'really left the queue');
      expect(Get.isRegistered<GameController>(), isTrue);
      final game = Get.find<GameController>();
      expect(game.isOnline, isFalse);
      expect(game.state.players, hasLength(2));
      expect(game.state.players.where((p) => p.isBot), hasLength(1));
      // Drain the table's timers before the test zone closes.
      await _settle(tester);
      Get.find<GameController>().onClose();
      await _settle(tester, slices: 5);
    });
  });

  group('Leaderboard paging and own rank (§R)', () {
    testWidgets('loads a page, appends the next, pins the player', (
      tester,
    ) async {
      final board = _PagedBoard(60, selfRank: 57);
      await _boot(backend: _online(leaderboards: board));
      await _render(tester, const LeaderboardScreen());
      final s = Strings.s;

      expect(board.requests.first, (25, 0));
      expect(find.text('Giocatore-1'), findsOneWidget);
      // Rank 57 is not on the page: the pinned row says where the player is.
      expect(find.text(s.leaderboardYourRank.toUpperCase()), findsOneWidget);
      expect(find.text('57'), findsOneWidget);
      // The button sits at the foot of the list.
      await tester.drag(find.byType(ListView), const Offset(0, -3000));
      await tester.pump();
      expect(find.text(s.leaderboardLoadMore), findsOneWidget);

      await tester.tap(find.text(s.leaderboardLoadMore));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(board.requests.last, (25, 25));
      await tester.scrollUntilVisible(
        find.text('Giocatore-26'),
        -200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Giocatore-26'), findsOneWidget);
    });

    testWidgets('an unranked player is told so, not given a fake row', (
      tester,
    ) async {
      await _boot(backend: _online(leaderboards: _PagedBoard(3)));
      await _render(tester, const LeaderboardScreen());
      expect(find.text(Strings.s.leaderboardNotRanked), findsOneWidget);
      expect(find.text(Strings.s.leaderboardLoadMore), findsNothing);
    });

    testWidgets('a failing board shows the error and a retry', (tester) async {
      await _boot(backend: _online(leaderboards: _FailingBoard()));
      await _render(tester, const LeaderboardScreen());
      expect(find.text(Strings.s.leaderboardLoadFailed), findsOneWidget);
      expect(find.text(Strings.s.commonRetry), findsOneWidget);
    });
  });

  group('Missions screen (§V)', () {
    testWidgets('offline missions show, complete and pay local XP', (
      tester,
    ) async {
      await _boot();
      final stats = Get.find<StatsController>();
      stats.clock = () => DateTime(2026, 8, 31); // Monday: use_nine ×1
      await stats.noteCardPlayed(
        const GameCard(CardSuit.spade, CardRank.cavallo),
      );
      MissionsController.ensure();
      await _render(tester, const MissionsScreen());
      final s = Strings.s;

      expect(find.text(s.missionsOffline.toUpperCase()), findsOneWidget);
      expect(find.text(s.missionUseNine(1)), findsOneWidget);
      // Without a backend the online half says so instead of inventing rows.
      expect(find.text(s.authBackendPending), findsOneWidget);

      final xp = stats.stats.xp;
      final claim = find.widgetWithText(PremiumButton, s.missionsClaim);
      final enabled = tester
          .widgetList<PremiumButton>(claim)
          .where((b) => b.onPressed != null);
      expect(enabled, hasLength(1));
      await tester.tap(find.byWidget(enabled.first));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(stats.stats.xp, xp + 20);
      expect(find.text(s.missionsClaimed), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Tutorial on the real table (§X)', () {
    testWidgets('the first lesson renders over the table and advances', (
      tester,
    ) async {
      await _boot();
      final settings = Get.find<SettingsController>().settings;
      final c = Get.put<TutorialController>(
        TutorialController(
          seats: TutorialSeats(
            playerName: settings.playerName,
            avatarId: settings.avatarId,
          ),
        ),
      );
      Get.put<TableController>(c);
      await _render(tester, const TutorialScreen());
      final s = Strings.s;
      // The deal cue plays first; then the lesson waits on the player.
      await tester.pump(const Duration(seconds: 3));
      expect(find.text(s.tutFirstCardTitle), findsOneWidget);
      expect(find.text(s.tutFirstCardPrompt), findsOneWidget);
      expect(c.phase.value, TutorialPhase.waiting);
      expect(c.showsCoachMarks, isFalse);
      expect(c.canPause, isFalse);

      // Not awaited: the table's card flight needs the test clock pumped.
      unawaited(c.playCard(c.playableForViewer.first));
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(c.phase.value, TutorialPhase.lessonDone);
      expect(find.text(s.tutFirstCardDone), findsOneWidget);
      await tester.tap(find.text(s.commonNext));
      await tester.pump(const Duration(seconds: 3));
      expect(c.lessonIndex.value, 1);
      expect(find.text(s.tutDrawingPrompt), findsOneWidget);
      await _settle(tester);
    });
  });

  group('Pause overlay (§W)', () {
    testWidgets('the pause button freezes the table; Riprendi releases it', (
      tester,
    ) async {
      await _boot();
      final session = GameSession(
        buildState(
          hands: [
            [c(CardSuit.coppe, CardRank.tre), c(CardSuit.denari, CardRank.re)],
            [
              c(CardSuit.spade, CardRank.sei),
              c(CardSuit.coppe, CardRank.sette),
            ],
          ],
          top: c(CardSuit.coppe, CardRank.cinque),
        ),
      );
      final game = Get.put(
        GameController(
          session: session,
          storage: Get.find<GameStorageService>(),
          settings: Get.find<SettingsController>(),
          stats: Get.find<StatsController>(),
          humanIds: const ['p0'],
        ),
      );
      Get.put<TableController>(game);
      await _render(tester, const GameScreen());
      await tester.pump(const Duration(seconds: 2));
      final s = Strings.s;

      expect(find.byType(PauseOverlay), findsNothing);
      await tester.tap(find.byTooltip(s.pauseTitle));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(PauseOverlay), findsOneWidget);
      expect(game.paused.value, isTrue);
      expect(game.canInteract, isFalse);

      await tester.tap(find.text(s.pauseResume));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(PauseOverlay), findsNothing);
      expect(game.paused.value, isFalse);
      expect(game.canInteract, isTrue);
      await _settle(tester);
    });
  });

  group('Achievements union (§S)', () {
    testWidgets('a server-unlocked badge shows as unlocked online', (
      tester,
    ) async {
      await _boot(backend: _online());
      await _render(tester, const AchievementsScreen());
      // The (empty) server load has completed by now; a badge arrives.
      Get.find<ProfileController>().achievements.add('veterano');
      await tester.pump();
      final s = Strings.s;
      expect(find.text(s.achOnline), findsOneWidget);
      expect(find.text(s.achServerHint), findsOneWidget);
    });
  });
}

class _FailingBoard implements LeaderboardRepository {
  @override
  Future<LeaderboardBoard> load(
    LeaderboardScope scope, {
    int limit = 50,
    int offset = 0,
  }) async => throw StateError('offline');
  @override
  Future<LeaderboardEntry?> myRank(LeaderboardScope scope) async =>
      throw StateError('offline');
}
