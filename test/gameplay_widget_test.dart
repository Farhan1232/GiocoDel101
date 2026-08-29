import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gioco_del_101/app/bindings/initial_binding.dart';
import 'package:gioco_del_101/features/game/application/game_controller.dart';
import 'package:gioco_del_101/features/settings/application/settings_controller.dart';
import 'package:gioco_del_101/features/profile/application/stats_controller.dart';
import 'package:gioco_del_101/core/utils/motion.dart';
import 'package:gioco_del_101/features/game/domain/engine/game_session.dart';
import 'package:gioco_del_101/features/game/domain/card_rank.dart';
import 'package:gioco_del_101/features/game/domain/card_suit.dart';
import 'package:gioco_del_101/features/game/domain/game_card.dart';
import 'package:gioco_del_101/features/game/domain/game_player.dart';
import 'package:gioco_del_101/features/game/domain/game_rules.dart';
import 'package:gioco_del_101/features/game/domain/game_state.dart';
import 'package:gioco_del_101/features/game/domain/player_type.dart';
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
  List<GameCard> discardBelowTop = const [],
  bool fillDeck = true,
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
  final placed = <GameCard>{
    for (final h in hands) ...h,
    ...drawPile,
    ...discardBelowTop,
    top,
  };
  final remainder = fillDeck
      ? Deck.standard.where((c) => !placed.contains(c)).toList()
      : const <GameCard>[];
  final session = GameSession(
    GameState(
      gameId: 'widget-test',
      mode: GameMode.vsComputer,
      rules: const GameRules(),
      players: players,
      // Deals from the end: the caller's draw pile sits on top.
      drawPile: [...remainder, ...drawPile],
      discardPile: [...discardBelowTop, top],
      activeSuit: activeSuit ?? top.suit,
      currentSeat: 0,
      pendingDrawCount: pendingPenalty,
      chainLength: chainLength,
    ),
  );
  return Get.put(
    GameController(
      session: session,
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
          const GameCard(CardSuit.spade, CardRank.sette),
        ],
        [const GameCard(CardSuit.denari, CardRank.tre)],
      ],
      top: const GameCard(CardSuit.coppe, CardRank.cinque),
      drawPile: const [GameCard(CardSuit.bastoni, CardRank.quattro)],
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

    expect(c.state.topCard, const GameCard(CardSuit.coppe, CardRank.re));
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
          const GameCard(CardSuit.bastoni, CardRank.sette),
          const GameCard(CardSuit.coppe, CardRank.re),
        ],
        [const GameCard(CardSuit.denari, CardRank.tre)],
      ],
      top: const GameCard(CardSuit.coppe, CardRank.cinque),
      drawPile: const [GameCard(CardSuit.bastoni, CardRank.quattro)],
    );
    await _pumpTable(tester);

    await tester.tap(find.byKey(const ValueKey('hand_bastoni_sette')));
    await _settle(tester, slices: 10);

    expect(
      c.state.playerById('p0')!.hand,
      contains(const GameCard(CardSuit.bastoni, CardRank.sette)),
    );
    expect(c.state.topCard, const GameCard(CardSuit.coppe, CardRank.cinque));
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
        [const GameCard(CardSuit.denari, CardRank.tre)],
      ],
      top: const GameCard(CardSuit.coppe, CardRank.cinque),
      drawPile: const [GameCard(CardSuit.bastoni, CardRank.quattro)],
    );
    await _pumpTable(tester);

    await tester.tap(find.byKey(const ValueKey('hand_spade_cavallo')));
    await _settle(tester, slices: 6);
    await tester.tap(find.byKey(const ValueKey('hand_spade_cavallo')));
    await _settle(tester);

    expect(find.byType(SuitRitual), findsOneWidget);
    expect(c.state.status, GameStatus.awaitingSuitChoice);

    // Pick Bastoni from the ritual by its label.
    await tester.tap(find.text('Bastoni'));
    await _settle(tester);

    expect(c.state.activeSuit, CardSuit.bastoni);
    expect(find.byType(SuitRitual), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('drawing from an empty stock recycles the discard (§18)', (
    tester,
  ) async {
    // An empty stock with a few cards buried so there is something to recycle.
    final c = _seat(
      hands: [
        [const GameCard(CardSuit.spade, CardRank.sette)],
        [const GameCard(CardSuit.denari, CardRank.tre)],
      ],
      top: const GameCard(CardSuit.coppe, CardRank.cinque),
      drawPile: const [],
      discardBelowTop: const [
        GameCard(CardSuit.bastoni, CardRank.tre),
        GameCard(CardSuit.bastoni, CardRank.quattro),
        GameCard(CardSuit.bastoni, CardRank.sei),
      ],
      fillDeck: false,
    );
    await _pumpTable(tester);

    await tester.tap(find.textContaining('Pesca').first);
    await _settle(tester, slices: 60);

    expect(
      c.state.discardPile.last,
      const GameCard(CardSuit.coppe, CardRank.cinque),
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
          const GameCard(CardSuit.spade, CardRank.sette),
        ],
        [const GameCard(CardSuit.denari, CardRank.tre)],
      ],
      top: const GameCard(CardSuit.coppe, CardRank.cinque),
      drawPile: const [GameCard(CardSuit.bastoni, CardRank.quattro)],
    );
    await _pumpTable(tester);
    await c.persistNow();

    final storage = Get.find<GameStorageService>();
    expect(storage.hasSavedMatch, isTrue);
    final restored = storage.load();
    expect(restored, isNotNull);
    expect(restored!.players.first.hand, c.state.players.first.hand);
    expect(restored.activeSuit, c.state.activeSuit);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a live +2 chain offers the penalty button', (tester) async {
    final c = _seat(
      hands: [
        [const GameCard(CardSuit.coppe, CardRank.re)],
        [const GameCard(CardSuit.denari, CardRank.tre)],
      ],
      top: const GameCard(CardSuit.coppe, CardRank.due),
      pendingPenalty: 4,
      chainLength: 2,
      drawPile: const [
        GameCard(CardSuit.bastoni, CardRank.quattro),
        GameCard(CardSuit.bastoni, CardRank.sei),
        GameCard(CardSuit.spade, CardRank.quattro),
        GameCard(CardSuit.spade, CardRank.sei),
        GameCard(CardSuit.denari, CardRank.sette),
      ],
    );
    await _pumpTable(tester);

    expect(c.session.mustTakePenalty, isTrue);
    expect(find.textContaining('+4'), findsWidgets);

    await tester.tap(find.textContaining('Prendi').first);
    await _settle(tester);

    // One card held plus the full four-card penalty.
    expect(c.state.playerById('p0')!.hand.length, 5);
    expect(c.state.pendingDrawCount, 0);
    expect(tester.takeException(), isNull);
  });
}
