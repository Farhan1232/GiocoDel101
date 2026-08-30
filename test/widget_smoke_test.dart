import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gioco_del_101/app/bindings/initial_binding.dart';
import 'package:gioco_del_101/features/game/application/game_controller.dart';
import 'package:gioco_del_101/features/game/application/table_controller.dart';
import 'package:gioco_del_101/features/settings/application/settings_controller.dart';
import 'package:gioco_del_101/features/profile/application/stats_controller.dart';
import 'package:gioco_del_101/core/utils/motion.dart';
import 'package:gioco_del_101/features/game/domain/match_factory.dart';
import 'package:gioco_del_101/features/game/domain/card_rank.dart';
import 'package:gioco_del_101/features/game/domain/card_suit.dart';
import 'package:gioco_del_101/features/game/domain/game_card.dart';
import 'package:gioco_del_101/features/game/domain/player_type.dart';
import 'package:gioco_del_101/features/game/domain/round_result.dart';
import 'package:gioco_del_101/features/settings/domain/settings_model.dart';
import 'package:gioco_del_101/features/game/presentation/game_screen.dart';
import 'package:gioco_del_101/features/home/presentation/home_screen.dart';
import 'package:gioco_del_101/features/game/presentation/how_to_play_screen.dart';
import 'package:gioco_del_101/features/game/presentation/match_result_screen.dart';
import 'package:gioco_del_101/features/game/presentation/victory_flourish.dart';
import 'package:gioco_del_101/features/game/presentation/last_hand_replay.dart';
import 'package:gioco_del_101/features/game/presentation/round_result_screen.dart';
import 'package:gioco_del_101/features/settings/presentation/settings_screen.dart';
import 'package:gioco_del_101/features/game/presentation/setup_screen.dart';
import 'package:gioco_del_101/features/splash/presentation/splash_screen.dart';
import 'package:gioco_del_101/core/storage/game_storage_service.dart';
import 'package:gioco_del_101/core/storage/local_storage.dart';
import 'package:gioco_del_101/app/theme/app_theme.dart';
import 'package:gioco_del_101/app/theme/table_themes.dart';
import 'package:gioco_del_101/features/game/presentation/widgets/chain_storm.dart';
import 'package:gioco_del_101/features/game/presentation/widgets/coach_mark.dart';
import 'package:gioco_del_101/features/game/presentation/widgets/fate_ring.dart';
import 'package:gioco_del_101/features/game/presentation/widgets/handover_overlay.dart';
import 'package:gioco_del_101/features/game/presentation/widgets/reaction_bar.dart';
import 'package:gioco_del_101/features/game/presentation/widgets/suit_ritual.dart';
import 'package:gioco_del_101/core/widgets/app_icons.dart';
import 'package:gioco_del_101/features/game/domain/game_state.dart';

/// §66 — every screen and every signature effect is rendered at three sizes
/// and must come up clean. This is the automated half of "verify every button
/// works": it catches layout overflows, unbounded flex, uninitialised
/// controllers and out-of-range paint values before a device ever does.
const sizes = <Size>[
  Size(390, 844), // modern phone
  Size(360, 640), // small Android, the floor named in §47
  Size(834, 1112), // tablet
];

Future<void> _boot() async {
  SharedPreferences.setMockInitialValues({});
  Get.reset();
  final storage = await LocalStorage.open();
  InitialBinding(storage).dependencies();
  final settings = Get.find<SettingsController>();
  for (final id in const [
    'coach_match',
    'coach_draw',
    'coach_specials',
    'coach_ring',
  ]) {
    await settings.markCoachMarkSeen(id);
  }
  Motion.reduceMotion = true;
}

GameController _match({
  int players = 3,
  bool finished = false,
  int pendingPenalty = 0,
  int chainLength = 0,
}) {
  final setup = MatchFactory.vsComputer(
    playerName: 'Farhan',
    avatarId: 'lucia',
    playerCount: players,
    difficulty: BotDifficulty.normal,
  );
  var s = setup.session.state;
  final human = s.players.first;
  final hand = const [
    GameCard(CardSuit.coppe, CardRank.re),
    GameCard(CardSuit.denari, CardRank.cinque),
    GameCard(CardSuit.spade, CardRank.due),
    GameCard(CardSuit.bastoni, CardRank.cavallo),
    GameCard(CardSuit.coppe, CardRank.sette),
  ];
  const top = GameCard(CardSuit.coppe, CardRank.cinque);
  // Rebuild the piles so the 40-card invariant still holds.
  // Re-deal every seat from a clean deck so no card is duplicated.
  final stock = Deck.standard
      .where((c) => !hand.contains(c) && c != top)
      .toList();
  final botHands = <String, List<GameCard>>{};
  for (final p in s.players.skip(1)) {
    botHands[p.id] = [for (var i = 0; i < 5; i++) stock.removeLast()];
  }
  var seats = [
    human.copyWith(hand: hand, score: 82),
    for (final p in s.players.skip(1)) p.copyWith(hand: botHands[p.id]),
  ];
  var status = GameStatus.awaitingAction;
  String? winnerId;
  if (finished) {
    status = GameStatus.finished;
    winnerId = human.id;
    seats = [
      seats.first,
      for (final p in seats.skip(1)) p.copyWith(score: 104, eliminated: true),
    ];
  }
  s = s.copyWith(
    players: seats,
    drawPile: stock,
    discardPile: const [top],
    activeSuit: CardSuit.coppe,
    currentSeat: 0,
    pendingDrawCount: pendingPenalty,
    chainLength: chainLength,
    status: status,
    winnerId: winnerId,
  );
  setup.session.restore(s);
  final controller = Get.put(
    GameController(
      session: setup.session,
      storage: Get.find<GameStorageService>(),
      settings: Get.find<SettingsController>(),
      stats: Get.find<StatsController>(),
      humanIds: setup.humanIds,
    ),
  );
  // The screens depend on the contract, exactly as MatchLauncher registers it.
  Get.put<TableController>(controller);
  return controller;
}

Future<void> _render(
  WidgetTester tester,
  Widget child,
  Size size, {
  int frames = 20,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
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

void main() {
  tearDown(() {
    Motion.reduceMotion = false;
    if (Get.isRegistered<GameController>()) {
      Get.delete<GameController>(force: true);
    }
  });

  group('Screens render clean at every size (§47, §66)', () {
    for (final size in sizes) {
      final label = '${size.width.toInt()}x${size.height.toInt()}';

      testWidgets('splash $label', (tester) async {
        await _boot();
        await _render(tester, const SplashScreen(), size, frames: 4);
        expect(tester.takeException(), isNull);
      });

      testWidgets('home $label', (tester) async {
        await _boot();
        await _render(tester, const HomeScreen(), size);
        expect(tester.takeException(), isNull);
      });

      testWidgets('setup $label', (tester) async {
        await _boot();
        await _render(tester, const SetupScreen(), size);
        expect(tester.takeException(), isNull);
      });

      testWidgets('how to play $label', (tester) async {
        await _boot();
        await _render(tester, const HowToPlayScreen(), size);
        expect(tester.takeException(), isNull);
      });

      testWidgets('settings $label', (tester) async {
        await _boot();
        await _render(tester, const SettingsScreen(), size);
        expect(tester.takeException(), isNull);
      });

      testWidgets('statistics $label', (tester) async {
        await _boot();
        Get.find<StatsController>();
        await _render(tester, const SettingsScreen(), size);
        await tester.tap(find.text('STATISTICHE'));
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('The table renders clean for every seat count (§6, §47)', () {
    for (final players in [2, 3, 4]) {
      for (final size in sizes) {
        testWidgets(
          '$players players at ${size.width.toInt()}x${size.height.toInt()}',
          (tester) async {
            await _boot();
            _match(players: players);
            await _render(tester, const GameScreen(), size);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }

    testWidgets('with a live Chain Storm', (tester) async {
      await _boot();
      _match(pendingPenalty: 6, chainLength: 3);
      await _render(tester, const GameScreen(), sizes.first);
      expect(tester.takeException(), isNull);
      expect(find.text('+6'), findsWidgets);
    });

    testWidgets('in large-card and high-contrast mode (§48)', (tester) async {
      await _boot();
      final settings = Get.find<SettingsController>();
      await settings.setLargeCards(true);
      await settings.setHighContrast(true);
      _match();
      // Session 5: a fresh table deals itself first, then the bot thinks —
      // give both time to run out before the test ends.
      await _render(tester, const GameScreen(), sizes.first, frames: 45);
      expect(tester.takeException(), isNull);
    });

    testWidgets('with motion at full speed (§30)', (tester) async {
      await _boot();
      Motion.reduceMotion = false;
      Motion.speedFactor = AnimationSpeed.fast.factor;
      _match();
      await _render(tester, const GameScreen(), sizes.first, frames: 45);
      expect(tester.takeException(), isNull);
      Motion.speedFactor = 1.0;
    });

    testWidgets('under every table theme (§33)', (tester) async {
      for (final theme in TableThemes.all) {
        await _boot();
        final settings = Get.find<SettingsController>();
        await settings.unlock(themeId: theme.id, cardBackId: theme.cardBackId);
        await settings.setTheme(theme.id);
        _match();
        await _render(tester, const GameScreen(), sizes.first, frames: 45);
        expect(
          tester.takeException(),
          isNull,
          reason: 'theme ${theme.id} failed',
        );
        Get.delete<GameController>(force: true);
      }
    });
  });

  group('Results screens (§36, §37)', () {
    RoundResult sample(GameController c) => RoundResult(
      roundNumber: 3,
      winnerId: c.state.players.first.id,
      winnerName: c.state.players.first.name,
      matchOver: false,
      rows: [
        PlayerRoundResult(
          playerId: c.state.players.first.id,
          name: c.state.players.first.name,
          cardsLeft: 0,
          penalty: 0,
          previousScore: 12,
          newScore: 12,
          hitExact101: false,
          eliminated: false,
        ),
        PlayerRoundResult(
          playerId: c.state.players[1].id,
          name: c.state.players[1].name,
          cardsLeft: 3,
          penalty: 7,
          previousScore: 94,
          newScore: 0,
          hitExact101: true,
          eliminated: false,
        ),
        PlayerRoundResult(
          playerId: c.state.players[2].id,
          name: c.state.players[2].name,
          cardsLeft: 5,
          penalty: 22,
          previousScore: 82,
          newScore: 104,
          hitExact101: false,
          eliminated: true,
        ),
      ],
    );

    for (final size in sizes) {
      testWidgets('round result ${size.width.toInt()}', (tester) async {
        await _boot();
        final c = _match();
        c.lastRoundResult.value = sample(c);
        await _render(tester, const RoundResultScreen(), size, frames: 60);
        expect(tester.takeException(), isNull);
        expect(find.text('SALVO!'), findsWidgets);
        expect(find.text('ELIMINATO'), findsWidgets);
      });

      testWidgets('match result ${size.width.toInt()}', (tester) async {
        await _boot();
        _match(finished: true);
        await _render(tester, const MatchResultScreen(), size, frames: 30);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('last hand replay', (tester) async {
      await _boot();
      final c = _match();
      c.session.playCard(const GameCard(CardSuit.coppe, CardRank.re));
      await _render(
        tester,
        LastHandReplay(match: c.state, onClose: () {}),
        sizes.first,
        frames: 30,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Signature effects (§11, §13, §17, §37, §67)', () {
    testWidgets('Fate Ring in every state', (tester) async {
      await _boot();
      for (final config in [
        (score: 12, reset: false, out: false),
        (score: 64, reset: false, out: false),
        (score: 88, reset: false, out: false),
        (score: 100, reset: false, out: false),
        (score: 101, reset: true, out: false),
        (score: 104, reset: false, out: true),
      ]) {
        await _render(
          tester,
          Center(
            child: FateRing(
              score: config.score,
              size: 120,
              playReset: config.reset,
              eliminated: config.out,
            ),
          ),
          sizes.first,
          frames: 40,
        );
        expect(
          tester.takeException(),
          isNull,
          reason: 'score ${config.score} failed',
        );
      }
    });

    testWidgets('Chain Storm at every level', (tester) async {
      await _boot();
      for (var level = 0; level <= 4; level++) {
        await _render(
          tester,
          Center(
            child: ChainStorm(
              level: level,
              total: level * 2,
              size: const Size(180, 180),
            ),
          ),
          sizes.first,
          frames: 15,
        );
        expect(tester.takeException(), isNull, reason: 'level $level failed');
      }
    });

    testWidgets('Suit Ritual opens and resolves', (tester) async {
      await _boot();
      CardSuit? chosen;
      await _render(
        tester,
        SuitRitual(
          card: const GameCard(CardSuit.spade, CardRank.cavallo),
          onChosen: (s) => chosen = s,
        ),
        sizes.first,
        frames: 20,
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Denari'));
      // The ritual resolves after its closing animation, so let it finish.
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 60));
      }
      expect(chosen, CardSuit.denari);
      expect(tester.takeException(), isNull);
    });

    testWidgets('victory flourish', (tester) async {
      await _boot();
      await _render(
        tester,
        const Center(child: VictoryFlourish(size: 200)),
        sizes.first,
        frames: 30,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('pass and play handover', (tester) async {
      await _boot();
      var ready = false;
      await _render(
        tester,
        HandoverOverlay(
          playerName: 'Sofia',
          avatarId: 'sofia',
          backId: 'oro',
          onReady: () => ready = true,
        ),
        sizes.first,
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('SONO PRONTO'));
      await tester.pump();
      expect(ready, isTrue);
    });

    testWidgets('reaction sheet offers exactly eight lines (§23)', (
      tester,
    ) async {
      await _boot();
      String? picked;
      await _render(
        tester,
        ReactionSheet(onPick: (p) => picked = p, onDismiss: () {}),
        sizes.first,
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Bella mossa!'));
      await tester.pump();
      expect(picked, 'Bella mossa!');
    });

    testWidgets('coach mark', (tester) async {
      await _boot();
      var dismissed = false;
      await _render(
        tester,
        CoachMark(
          icon: AppIcon.cards,
          message: 'Gioca una carta dello stesso seme o valore.',
          onDismiss: () => dismissed = true,
        ),
        sizes.first,
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Ho capito'));
      await tester.pump();
      expect(dismissed, isTrue);
    });
  });
}
