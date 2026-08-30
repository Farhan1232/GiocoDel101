import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gioco_del_101/app/bindings/initial_binding.dart';
import 'package:gioco_del_101/app/localization/app_strings.dart';
import 'package:gioco_del_101/core/storage/game_storage_service.dart';
import 'package:gioco_del_101/core/storage/local_storage.dart';
import 'package:gioco_del_101/core/storage/statistics_storage.dart';
import 'package:gioco_del_101/core/utils/motion.dart';
import 'package:gioco_del_101/features/game/application/game_controller.dart';
import 'package:gioco_del_101/features/game/application/table_controller.dart';
import 'package:gioco_del_101/features/game/application/table_cue.dart';
import 'package:gioco_del_101/features/game/domain/card_rank.dart';
import 'package:gioco_del_101/features/game/domain/card_suit.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_session.dart';
import 'package:gioco_del_101/features/game/domain/game_player.dart';
import 'package:gioco_del_101/features/game/domain/game_state.dart';
import 'package:gioco_del_101/features/game/domain/match_factory.dart';
import 'package:gioco_del_101/features/game/domain/player_type.dart';
import 'package:gioco_del_101/features/missions/domain/mission.dart';
import 'package:gioco_del_101/features/profile/application/stats_controller.dart';
import 'package:gioco_del_101/features/profile/domain/level_ladder.dart';
import 'package:gioco_del_101/features/profile/domain/statistics_model.dart';
import 'package:gioco_del_101/features/settings/application/settings_controller.dart';

import 'support/engine_harness.dart';

GameController _controller(
  GameSession session, {
  List<String>? humans,
  DateTime Function()? clock,
}) {
  final c = Get.put(
    GameController(
      session: session,
      storage: Get.find<GameStorageService>(),
      settings: Get.find<SettingsController>(),
      stats: Get.find<StatsController>(),
      humanIds: humans ?? const ['p0'],
      random: Random(1),
      clock: clock,
    ),
  );
  Get.put<TableController>(c);
  return c;
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Get.reset();
    InitialBinding(await LocalStorage.open()).dependencies();
    Motion.reduceMotion = true;
    Strings.use(const Locale('it'));
  });

  tearDown(() {
    Motion.reduceMotion = false;
    Get.reset();
  });

  group('Resuming a saved match (§49)', () {
    testWidgets('a save taken during the Suit Ritual reopens it', (
      tester,
    ) async {
      // The human played a Cavallo and the app was killed before the suit
      // was named: the Cavallo is the top card, status awaitingSuitChoice.
      final state = buildState(
        hands: [
          [c(CardSuit.coppe, CardRank.tre), c(CardSuit.denari, CardRank.re)],
          [c(CardSuit.spade, CardRank.sei)],
        ],
        top: c(CardSuit.spade, CardRank.cavallo),
        status: GameStatus.awaitingSuitChoice,
        version: 7,
      );
      final json = state.toJson();
      final restored = GameState.fromJson(json);
      expect(restored.status, GameStatus.awaitingSuitChoice);

      final controller = _controller(GameSession(restored));
      expect(
        controller.pendingSuitChoice.value,
        c(CardSuit.spade, CardRank.cavallo),
        reason: 'the ritual must reopen or the table is stuck',
      );
      controller.start();
      await tester.pump(const Duration(milliseconds: 50));
      // Not awaited: the cue delay needs the test clock pumped forward.
      unawaited(controller.chooseSuit(CardSuit.denari));
      await tester.pump(const Duration(seconds: 2));
      expect(controller.state.activeSuit, CardSuit.denari);
      expect(controller.state.status, isNot(GameStatus.awaitingSuitChoice));
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    });

    testWidgets('a fresh match is dealt on screen, a resumed one is not', (
      tester,
    ) async {
      final cues = <TableCue>[];
      final fresh = _controller(
        MatchFactory.vsComputer(
          playerName: 'Tu',
          avatarId: 'lucia',
          playerCount: 2,
          difficulty: BotDifficulty.easy,
          seed: 3,
        ).session,
      );
      fresh.cuePlayer = (cue) async => cues.add(cue);
      fresh.start();
      await tester.pump(const Duration(milliseconds: 20));
      expect(cues.first, isA<DealCue>());
      expect((cues.first as DealCue).seatIds, ['p0', 'b1']);
      expect((cues.first as DealCue).handSize, 5);
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      Get.delete<GameController>(force: true);
      Get.delete<TableController>(force: true);

      cues.clear();
      final resumed = _controller(
        GameSession(
          buildState(
            hands: [
              [c(CardSuit.coppe, CardRank.tre)],
              [c(CardSuit.spade, CardRank.sei)],
            ],
            top: c(CardSuit.coppe, CardRank.cinque),
            version: 12,
          ),
        ),
      );
      resumed.cuePlayer = (cue) async => cues.add(cue);
      resumed.start();
      await tester.pump(const Duration(milliseconds: 20));
      expect(cues.whereType<DealCue>(), isEmpty);
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    });
  });

  group('Pause (§W)', () {
    testWidgets('bots do not move while paused and carry on after resume', (
      tester,
    ) async {
      // The bot is on turn with a legal card in hand.
      final controller = _controller(
        GameSession(
          buildState(
            hands: [
              [
                c(CardSuit.coppe, CardRank.tre),
                c(CardSuit.denari, CardRank.re),
              ],
              [
                c(CardSuit.coppe, CardRank.sette),
                c(CardSuit.spade, CardRank.sei),
              ],
            ],
            top: c(CardSuit.coppe, CardRank.cinque),
            currentIndex: 1,
            version: 3,
          ),
        ),
      );
      expect(controller.canPause, isTrue);
      controller.pause();
      expect(controller.paused.value, isTrue);
      controller.start();
      // Far longer than the bot's think time: nothing may have happened.
      await tester.pump(const Duration(seconds: 5));
      expect(controller.state.version, 3);
      expect(controller.canInteract, isFalse);

      controller.resume();
      expect(controller.paused.value, isFalse);
      await tester.pump(const Duration(seconds: 3));
      expect(controller.state.version, greaterThan(3));
      expect(controller.currentPlayer.id, 'p0');
      expect(controller.canInteract, isTrue);
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    });
  });

  group('Reactions (§23)', () {
    testWidgets('one reaction per two seconds at the local table', (
      tester,
    ) async {
      var now = DateTime(2026, 8, 30, 12);
      final controller = _controller(
        GameSession(
          buildState(
            hands: [
              [c(CardSuit.coppe, CardRank.tre)],
              [c(CardSuit.spade, CardRank.sei)],
            ],
            top: c(CardSuit.coppe, CardRank.cinque),
          ),
        ),
        clock: () => now,
      );
      controller.sendReaction('Bravo!');
      expect(controller.reactions['p0'], 'Bravo!');
      now = now.add(const Duration(milliseconds: 800));
      controller.sendReaction('Vai!');
      expect(controller.reactions['p0'], 'Bravo!', reason: 'inside cooldown');
      expect(controller.banner.value, Strings.s.reactionRateLimited);
      now = now.add(GameController.reactionCooldown);
      controller.sendReaction('Vai!');
      expect(controller.reactions['p0'], 'Vai!');
      await tester.pump(const Duration(seconds: 3));
    });
  });

  group('Offline missions and XP (§V)', () {
    late StatsController stats;
    final today = DateTime(2026, 8, 31); // a Monday

    setUp(() {
      stats = StatsController(
        StatisticsStorage(Get.find<LocalStorage>()),
        Get.find<SettingsController>(),
      )..onInit();
      stats.clock = () => today;
    });

    test('the rotation covers seven days with three missions each', () {
      for (var d = 1; d <= 7; d++) {
        expect(MissionCatalog.rotation[d], hasLength(3), reason: 'day $d');
      }
      final keys = MissionCatalog.rotation.values
          .expand((l) => l)
          .map((m) => m.key)
          .toSet();
      expect(keys, containsAll(MissionKey.values));
      expect(MissionCatalog.forDate(today).map((m) => m.key), [
        MissionKey.playMatches,
        MissionKey.playAces,
        MissionKey.useNine,
      ]);
    });

    test('the human\'s own plays advance today\'s counters', () async {
      await stats.noteCardPlayed(c(CardSuit.coppe, CardRank.asso));
      await stats.noteCardPlayed(c(CardSuit.coppe, CardRank.asso));
      await stats.noteCardPlayed(c(CardSuit.spade, CardRank.cavallo));
      await stats.noteCardPlayed(c(CardSuit.spade, CardRank.sette));
      final rows = {for (final m in stats.todayMissions()) m.mission.key: m};
      expect(rows[MissionKey.playAces]!.progress, 2);
      expect(rows[MissionKey.playAces]!.completed, isFalse);
      expect(rows[MissionKey.useNine]!.progress, 1);
      expect(rows[MissionKey.useNine]!.claimable, isTrue);
      expect(rows[MissionKey.playMatches]!.progress, 0);
      // Not today's mission: recorded but not shown.
      await stats.noteChainBlocked();
      expect(
        stats.todayMissions().map((m) => m.mission.key),
        isNot(contains(MissionKey.blockTwo)),
      );
    });

    test('claiming pays XP once; the next day starts clean', () async {
      await stats.noteCardPlayed(c(CardSuit.spade, CardRank.cavallo));
      final xp = stats.stats.xp;
      expect(await stats.claimOfflineMission(MissionKey.useNine), isTrue);
      expect(stats.stats.xp, xp + 20);
      expect(await stats.claimOfflineMission(MissionKey.useNine), isFalse);
      expect(await stats.claimOfflineMission(MissionKey.playAces), isFalse);

      stats.clock = () => today.add(const Duration(days: 1));
      final rows = stats.todayMissions();
      expect(rows.map((m) => m.mission.key), [
        MissionKey.winMatch,
        MissionKey.playTwos,
        MissionKey.onlineMatch,
      ]);
      expect(rows.every((m) => m.progress == 0 && !m.claimed), isTrue);
    });

    test('a finished match awards offline XP and match missions', () async {
      final winner = buildState(
        hands: [
          [],
          [c(CardSuit.spade, CardRank.sei)],
        ],
        top: c(CardSuit.coppe, CardRank.cinque),
        status: GameStatus.finished,
      ).copyWith(winnerId: 'p0');
      final before = stats.stats.xp;
      await stats.recordMatch(match: winner, humanId: 'p0');
      expect(
        stats.stats.xp,
        before + LevelLadder.xpPerMatch + LevelLadder.xpPerWin,
      );
      final rows = {for (final m in stats.todayMissions()) m.mission.key: m};
      expect(rows[MissionKey.playMatches]!.progress, 1);
      expect(stats.stats.unlockedAchievements, contains('prima_vittoria'));
    });

    test('a record written before offline XP existed keeps its level', () {
      final old = StatisticsModel.fromJson({
        'matchesPlayed': 10,
        'matchesWon': 4,
      });
      expect(old.xp, 10 * LevelLadder.xpPerMatch + 4 * LevelLadder.xpPerWin);
      final roundTrip = StatisticsModel.fromJson(old.toJson());
      expect(roundTrip.xp, old.xp);
      expect(roundTrip.missionDateKey, 0);
    });
  });

  test('GamePlayer.isBot drives the thinking indicator, never the engine', () {
    final bot = GamePlayer(
      id: 'b1',
      name: 'Marco',
      type: PlayerType.bot,
      avatarId: 'marco',
    );
    expect(bot.isBot, isTrue);
  });
}
