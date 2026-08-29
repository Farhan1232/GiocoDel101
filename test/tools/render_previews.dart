// Renders the game's screens into `preview/` as PNG contact sheets.
//
// This is a development tool, not part of the test suite: it drives the
// widget layer headlessly and then calls `exit`, which `flutter test` reports
// as a non-clean shell exit. Run one sheet at a time:
//
//   PREVIEW=menus   flutter test test/tools/render_previews.dart
//   PREVIEW=table   flutter test test/tools/render_previews.dart
//   PREVIEW=results flutter test test/tools/render_previews.dart
//   PREVIEW=deck    flutter test test/tools/render_previews.dart
//   PREVIEW=account flutter test test/tools/render_previews.dart
//   PREVIEW=rooms   flutter test test/tools/render_previews.dart
//   PREVIEW=player  flutter test test/tools/render_previews.dart
//
// Each writes preview/<name>_gallery.png.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gioco_del_101/app/bindings/initial_binding.dart';
import 'package:gioco_del_101/features/game/application/game_controller.dart';
import 'package:gioco_del_101/features/settings/application/settings_controller.dart';
import 'package:gioco_del_101/features/profile/application/stats_controller.dart';
import 'package:gioco_del_101/core/utils/motion.dart';
import 'package:gioco_del_101/features/game/domain/engine/deck_factory.dart';
import 'package:gioco_del_101/features/game/domain/match_factory.dart';
import 'package:gioco_del_101/features/game/domain/card_rank.dart';
import 'package:gioco_del_101/features/game/domain/card_suit.dart';
import 'package:gioco_del_101/features/game/domain/game_card.dart';
import 'package:gioco_del_101/features/game/domain/player_type.dart';
import 'package:gioco_del_101/features/game/domain/round_result.dart';
import 'package:gioco_del_101/features/home/presentation/home_screen.dart';
import 'package:gioco_del_101/features/game/presentation/how_to_play_screen.dart';
import 'package:gioco_del_101/features/game/presentation/match_result_screen.dart';
import 'package:gioco_del_101/features/game/presentation/round_result_screen.dart';
import 'package:gioco_del_101/features/settings/presentation/settings_screen.dart';
import 'package:gioco_del_101/features/game/presentation/setup_screen.dart';
import 'package:gioco_del_101/features/game/presentation/game_screen.dart';
import 'package:gioco_del_101/core/storage/game_storage_service.dart';
import 'package:gioco_del_101/core/storage/local_storage.dart';
import 'package:gioco_del_101/app/theme/app_theme.dart';
import 'package:gioco_del_101/app/theme/card_backs.dart';
import 'package:gioco_del_101/core/widgets/cards/playing_card.dart';
import 'package:gioco_del_101/features/achievements/presentation/achievements_screen.dart';
import 'package:gioco_del_101/features/auth/presentation/auth_landing_screen.dart';
import 'package:gioco_del_101/features/auth/presentation/login_screen.dart';
import 'package:gioco_del_101/features/auth/presentation/signup_screen.dart';
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

const Size phone = Size(390, 844);

Future<void> _fonts() async {
  for (final e in const [
    (
      'Cinzel',
      [
        'assets/fonts/Cinzel-Regular.ttf',
        'assets/fonts/Cinzel-SemiBold.ttf',
        'assets/fonts/Cinzel-Bold.ttf',
      ],
    ),
    (
      'Manrope',
      [
        'assets/fonts/Manrope-Regular.ttf',
        'assets/fonts/Manrope-Medium.ttf',
        'assets/fonts/Manrope-SemiBold.ttf',
        'assets/fonts/Manrope-Bold.ttf',
        'assets/fonts/Manrope-ExtraBold.ttf',
      ],
    ),
  ]) {
    final loader = FontLoader(e.$1);
    for (final path in e.$2) {
      loader.addFont(
        Future.value(ByteData.sublistView(File(path).readAsBytesSync())),
      );
    }
    await loader.load();
  }
}

Widget _frame(Widget screen) => SizedBox(
  width: phone.width,
  height: phone.height,
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.build(),
    home: MediaQuery(
      data: const MediaQueryData(size: phone),
      child: screen,
    ),
  ),
);

Future<void> _sheet(
  WidgetTester tester,
  String name,
  List<Widget> panels, {
  double? panelWidth,
  double? panelHeight,
  int frames = 40,
  double scale = 1.4,
}) async {
  final width = panelWidth ?? phone.width;
  final height = panelHeight ?? phone.height;
  final key = GlobalKey();
  final total = Size(
    width * panels.length + 40 * (panels.length + 1),
    height + 80,
  );
  tester.view.physicalSize = total;
  tester.view.devicePixelRatio = 1.0;

  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: RepaintBoundary(
        key: key,
        child: Container(
          width: total.width,
          height: total.height,
          color: const Color(0xFF05070E),
          padding: const EdgeInsets.all(40),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: panels,
          ),
        ),
      ),
    ),
  );
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }

  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: scale);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  Directory('preview').createSync(recursive: true);
  File(
    'preview/${name}_gallery.png',
  ).writeAsBytesSync(bytes!.buffer.asUint8List());
  stdout.writeln('wrote preview/${name}_gallery.png');
}

Future<SettingsController> _boot() async {
  SharedPreferences.setMockInitialValues({});
  Get.reset();
  await _fonts();
  final storage = await LocalStorage.open();
  InitialBinding(storage).dependencies();
  final settings = Get.find<SettingsController>();
  await settings.setPlayerName('Farhan');
  for (final id in const [
    'coach_match',
    'coach_draw',
    'coach_specials',
    'coach_ring',
  ]) {
    await settings.markCoachMarkSeen(id);
  }
  Motion.reduceMotion = true;
  return settings;
}

GameController _seatTable(
  SettingsController settings, {
  int players = 3,
  bool finished = false,
  int penalty = 0,
  int chain = 0,
}) {
  final setup = MatchFactory.vsComputer(
    playerName: 'Farhan',
    avatarId: 'lucia',
    playerCount: players,
    difficulty: BotDifficulty.normal,
  );
  final s = setup.engine.state;
  s.players.first
    ..hand.clear()
    ..hand.addAll(const [
      GameCard(CardSuit.coppe, CardRank.re),
      GameCard(CardSuit.denari, CardRank.five),
      GameCard(CardSuit.spade, CardRank.two),
      GameCard(CardSuit.bastoni, CardRank.cavallo),
      GameCard(CardSuit.coppe, CardRank.seven),
    ])
    ..score = 82;
  if (s.players.length > 1) s.players[1].score = 44;
  if (s.players.length > 2) s.players[2].score = 97;
  s.roundNumber = 3;
  s.stats
    ..cardsPlayed = 63
    ..longestChain = 3
    ..bestComeback = 27;
  s.round
    ..activeSuit = CardSuit.coppe
    ..currentIndex = 0
    ..pendingPenalty = penalty
    ..chainLength = chain;
  s.round.discardPile
    ..clear()
    ..add(const GameCard(CardSuit.coppe, CardRank.five));
  if (finished) {
    s.matchOver = true;
    s.matchWinnerId = s.players.first.id;
    s.players.first.score = 0;
    for (var i = 1; i < s.players.length; i++) {
      s.players[i]
        ..score = 104
        ..eliminated = true;
    }
  }
  return Get.put(
    GameController(
      engine: setup.engine,
      storage: Get.find<GameStorageService>(),
      settings: settings,
      stats: Get.find<StatsController>(),
      humanIds: setup.humanIds,
    ),
  );
}

void main() {
  final which = Platform.environment['PREVIEW'] ?? 'menus';

  testWidgets('render $which', (tester) async {
    final settings = await _boot();

    switch (which) {
      case 'table':
        _seatTable(settings, penalty: 6, chain: 3);
        await _sheet(tester, 'table', [
          _frame(const GameScreen()),
          _frame(const GameScreen()),
        ], scale: 1.6);

      case 'results':
        final c = _seatTable(settings, finished: true);
        c.lastRoundResult.value = RoundResult(
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
              previousScore: 0,
              newScore: 0,
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
        await _sheet(
          tester,
          'results',
          [
            _frame(const RoundResultScreen()),
            _frame(const MatchResultScreen()),
          ],
          frames: 60,
          scale: 1.6,
        );

      case 'deck':
        final deck = DeckFactory.ordered();
        await _sheet(
          tester,
          'deck',
          [
            SizedBox(
              width: 1180,
              height: 1000,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var row = 0; row < 4; row++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var col = 0; col < 10; col++)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                              ),
                              child: PlayingCard(
                                width: 104,
                                card: deck[row * 10 + col],
                              ),
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final back in CardBacks.all)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: PlayingCard(
                            width: 104,
                            faceUp: false,
                            backId: back.id,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          panelWidth: 1180,
          panelHeight: 1000,
          frames: 6,
          scale: 1.5,
        );

      case 'account':
        await _sheet(tester, 'account', [
          _frame(const OnboardingScreen()),
          _frame(const AuthLandingScreen()),
          _frame(const LoginScreen()),
          _frame(const SignupScreen()),
        ]);

      case 'rooms':
        await _sheet(tester, 'rooms', [
          _frame(const OnlineModeScreen()),
          _frame(const CreateRoomScreen()),
          _frame(const JoinRoomScreen()),
          _frame(const RoomLobbyScreen()),
          _frame(const MatchmakingScreen()),
        ]);

      case 'player':
        await _sheet(tester, 'player', [
          _frame(const ProfileScreen()),
          _frame(const EditProfileScreen()),
          _frame(const AchievementsScreen()),
          _frame(const LeaderboardScreen()),
          _frame(const DailyRewardScreen()),
        ]);

      default:
        await _sheet(tester, 'menus', [
          _frame(const HomeScreen()),
          _frame(const SetupScreen()),
          _frame(const HowToPlayScreen()),
          _frame(const SettingsScreen()),
        ]);
    }
    exit(0);
  });
}
