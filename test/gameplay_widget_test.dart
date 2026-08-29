import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gioco_del_101/app/bindings/initial_binding.dart';
import 'package:gioco_del_101/features/game/application/game_controller.dart';
import 'package:gioco_del_101/features/settings/application/settings_controller.dart';
import 'package:gioco_del_101/features/profile/application/stats_controller.dart';
import 'package:gioco_del_101/core/utils/motion.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_engine.dart';
import 'package:gioco_del_101/features/game/domain/card_rank.dart';
import 'package:gioco_del_101/features/game/domain/card_suit.dart';
import 'package:gioco_del_101/features/game/domain/game_card.dart';
import 'package:gioco_del_101/features/game/domain/game_player.dart';
import 'package:gioco_del_101/features/game/domain/game_rules_config.dart';
import 'package:gioco_del_101/features/game/domain/match_state.dart';
import 'package:gioco_del_101/features/game/domain/player_type.dart';
import 'package:gioco_del_101/features/game/domain/round_state.dart';
import 'package:gioco_del_101/features/game/presentation/game_screen.dart';
import 'package:gioco_del_101/core/storage/game_storage_service.dart';
import 'package:gioco_del_101/core/storage/local_storage.dart';
import 'package:gioco_del_101/app/theme/app_theme.dart';
import 'package:gioco_del_101/features/game/presentation/widgets/suit_ritual.dart';

/// §66/§73 — drives the real table through the real widgets: taps a card and
/// checks the engine actually played it, takes a penalty, and completes the
/// Cavallo's Suit Ritual.
GameController _seat({
  required List<List<GameCard>> hands,
  required GameCard top,
  CardSuit? activeSuit,
  List<GameCard> drawPile = const [],
  int pendingPenalty = 0,
  int chainLength = 0,
}) {
  final players = [
    for (var i = 0; i < hands.length; i++)
      GamePlayer(
        id: 'p$i',
        name: 'P$i',
        type: i == 0 ? PlayerType.humanLocal : PlayerType.bot,
        avatarId: 'lucia',
        difficulty: BotDifficulty.normal,
        hand: List.of(hands[i]),
      ),
  ];
  final engine = GameEngine.fromState(
    MatchState(
      players: players,
      rules: const GameRulesConfig(),
      round: RoundState(
        drawPile: List.of(drawPile),
        discardPile: [top],
        activeSuit: activeSuit ?? top.suit,
        currentIndex: 0,
        pendingPenalty: pendingPenalty,
        chainLength: chainLength,
      ),
      mode: GameMode.vsComputer,
    ),
  );
  return Get.put(
    GameController(
      engine: engine,
      storage: Get.find<GameStorageService>(),
      settings: Get.find<SettingsController>(),
      stats: Get.find<StatsController>(),
      humanIds: const ['p0'],
    ),
  );
}

Future<void> _pumpTable(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    GetMaterialApp(
      theme: AppTheme.build(),
      home: const MediaQuery(
        data: MediaQueryData(size: Size(390, 844)),
        child: GameScreen(),
      ),
    ),
  );
  await _settle(tester);
}

/// Advances time in slices: the table waits on real delays for bot pacing,
/// which `pumpAndSettle` cannot see past.
Future<void> _settle(WidgetTester tester, {int slices = 40}) async {
  for (var i = 0; i < slices; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Get.reset();
    final storage = await LocalStorage.open();
    InitialBinding(storage).dependencies();
    // Coach marks would sit over the table and swallow the first tap.
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
  });

  tearDown(() {
    Motion.reduceMotion = false;
    Get.delete<GameController>(force: true);
  });

  testWidgets('tapping a playable card plays it', (tester) async {
    final c = _seat(
      hands: [
        [
          const GameCard(CardSuit.coppe, CardRank.re),
          const GameCard(CardSuit.spade, CardRank.seven),
        ],
        [const GameCard(CardSuit.denari, CardRank.three)],
      ],
      top: const GameCard(CardSuit.coppe, CardRank.five),
      drawPile: const [GameCard(CardSuit.bastoni, CardRank.four)],
    );
    await _pumpTable(tester);

    expect(c.canInteract, isTrue);
    final target = find.byKey(const ValueKey('hand_coppe_re'));
    expect(target, findsOneWidget);

    // First tap selects, second commits — the same two-step a player uses.
    await tester.tap(target);
    await _settle(tester, slices: 6);
    expect(c.selectedCard.value, const GameCard(CardSuit.coppe, CardRank.re));

    await tester.tap(find.byKey(const ValueKey('hand_coppe_re')));
    await _settle(tester);

    expect(c.round.topCard, const GameCard(CardSuit.coppe, CardRank.re));
    expect(
      c.state.playerById('p0')!.hand,
      isNot(contains(const GameCard(CardSuit.coppe, CardRank.re))),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('an illegal card is refused and stays in hand', (tester) async {
    final c = _seat(
      hands: [
        [
          const GameCard(CardSuit.bastoni, CardRank.seven),
          const GameCard(CardSuit.coppe, CardRank.re),
        ],
        [const GameCard(CardSuit.denari, CardRank.three)],
      ],
      top: const GameCard(CardSuit.coppe, CardRank.five),
      drawPile: const [GameCard(CardSuit.bastoni, CardRank.four)],
    );
    await _pumpTable(tester);

    await tester.tap(find.byKey(const ValueKey('hand_bastoni_seven')));
    await _settle(tester, slices: 10);

    expect(
      c.state.playerById('p0')!.hand,
      contains(const GameCard(CardSuit.bastoni, CardRank.seven)),
    );
    expect(c.round.topCard, const GameCard(CardSuit.coppe, CardRank.five));
    expect(c.currentPlayer.id, 'p0', reason: 'the turn must not move on');
    expect(tester.takeException(), isNull);
  });

  testWidgets('the Suit Ritual opens for a Cavallo and sets the suit', (
    tester,
  ) async {
    final c = _seat(
      hands: [
        [
          const GameCard(CardSuit.spade, CardRank.cavallo),
          const GameCard(CardSuit.spade, CardRank.re),
        ],
        [const GameCard(CardSuit.denari, CardRank.three)],
      ],
      top: const GameCard(CardSuit.coppe, CardRank.five),
      drawPile: const [GameCard(CardSuit.bastoni, CardRank.four)],
    );
    await _pumpTable(tester);

    await tester.tap(find.byKey(const ValueKey('hand_spade_cavallo')));
    await _settle(tester, slices: 6);
    await tester.tap(find.byKey(const ValueKey('hand_spade_cavallo')));
    await _settle(tester);

    expect(find.byType(SuitRitual), findsOneWidget);
    expect(c.round.phase, TurnPhase.awaitingSuitChoice);

    // Pick Bastoni from the ritual by its label.
    await tester.tap(find.text('Bastoni'));
    await _settle(tester);

    expect(c.round.activeSuit, CardSuit.bastoni);
    expect(find.byType(SuitRitual), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('drawing from an empty stock recycles the discard (§18)', (
    tester,
  ) async {
    final c = _seat(
      hands: [
        [const GameCard(CardSuit.spade, CardRank.seven)],
        [const GameCard(CardSuit.denari, CardRank.three)],
      ],
      top: const GameCard(CardSuit.coppe, CardRank.five),
      drawPile: const [],
    );
    // Bury a few cards so there is something to recycle.
    c.round.discardPile.insertAll(0, const [
      GameCard(CardSuit.bastoni, CardRank.three),
      GameCard(CardSuit.bastoni, CardRank.four),
      GameCard(CardSuit.bastoni, CardRank.six),
    ]);
    await _pumpTable(tester);

    await tester.tap(find.textContaining('Pesca').first);
    await _settle(tester, slices: 60);

    expect(
      c.round.discardPile.last,
      const GameCard(CardSuit.coppe, CardRank.five),
      reason: 'the visible top card must survive the recycle',
    );
    expect(c.state.playerById('p0')!.hand.length, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the match is written and restorable (§49)', (tester) async {
    final c = _seat(
      hands: [
        [
          const GameCard(CardSuit.coppe, CardRank.re),
          const GameCard(CardSuit.spade, CardRank.seven),
        ],
        [const GameCard(CardSuit.denari, CardRank.three)],
      ],
      top: const GameCard(CardSuit.coppe, CardRank.five),
      drawPile: const [GameCard(CardSuit.bastoni, CardRank.four)],
    );
    await _pumpTable(tester);
    await c.persistNow();

    final storage = Get.find<GameStorageService>();
    expect(storage.hasSavedMatch, isTrue);
    final restored = storage.load();
    expect(restored, isNotNull);
    expect(restored!.players.first.hand, c.state.players.first.hand);
    expect(restored.round.activeSuit, c.round.activeSuit);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a live +2 chain offers the penalty button', (tester) async {
    final c = _seat(
      hands: [
        [const GameCard(CardSuit.coppe, CardRank.re)],
        [const GameCard(CardSuit.denari, CardRank.three)],
      ],
      top: const GameCard(CardSuit.coppe, CardRank.two),
      pendingPenalty: 4,
      chainLength: 2,
      drawPile: const [
        GameCard(CardSuit.bastoni, CardRank.four),
        GameCard(CardSuit.bastoni, CardRank.six),
        GameCard(CardSuit.spade, CardRank.four),
        GameCard(CardSuit.spade, CardRank.six),
        GameCard(CardSuit.denari, CardRank.seven),
      ],
    );
    await _pumpTable(tester);

    expect(c.engine.mustTakePenalty, isTrue);
    expect(find.textContaining('+4'), findsWidgets);

    await tester.tap(find.textContaining('Prendi').first);
    await _settle(tester);

    // One card held plus the full four-card penalty.
    expect(c.state.playerById('p0')!.hand.length, 5);
    expect(c.round.pendingPenalty, 0);
    expect(tester.takeException(), isNull);
  });
}
