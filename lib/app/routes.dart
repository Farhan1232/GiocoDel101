import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/constants/app_durations.dart';
import '../screens/game/game_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/how_to_play/how_to_play_screen.dart';
import '../screens/match_result/match_result_screen.dart';
import '../screens/round_result/round_result_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/setup/setup_screen.dart';
import '../screens/splash/splash_screen.dart';

/// §24 — exactly eight destinations. Nothing else exists.
class AppRoutes {
  const AppRoutes._();

  static const String splash = '/';
  static const String home = '/home';
  static const String setup = '/setup';
  static const String game = '/game';
  static const String roundResult = '/round-result';
  static const String matchResult = '/match-result';
  static const String howToPlay = '/how-to-play';
  static const String settings = '/settings';
}

/// §59 — every transition is authored; none of them is the platform default.
class _DepthTransition extends CustomTransition {
  _DepthTransition({this.from = 0.92, this.slide = 0.0});

  /// Starting scale: below 1 the incoming screen zooms forward.
  final double from;

  /// Fraction of the height the incoming screen rises through.
  final double slide;

  @override
  Widget buildTransition(
    BuildContext context,
    Curve? curve,
    Alignment? alignment,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final eased = CurvedAnimation(
      parent: animation,
      curve: curve ?? Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: eased,
      child: SlideTransition(
        position: Tween(begin: Offset(0, slide), end: Offset.zero)
            .animate(eased),
        child: ScaleTransition(
          scale: Tween(begin: from, end: 1.0).animate(eased),
          child: child,
        ),
      ),
    );
  }
}

class AppPages {
  const AppPages._();

  static const Duration _d = AppDurations.screenTransition;

  static final List<GetPage<dynamic>> pages = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashScreen(),
      transition: Transition.fade,
      transitionDuration: _d,
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeScreen(),
      customTransition: _DepthTransition(from: 1.04),
      transitionDuration: _d,
    ),
    GetPage(
      // Home → Setup: the table steps toward the player.
      name: AppRoutes.setup,
      page: () => const SetupScreen(),
      customTransition: _DepthTransition(from: 0.90),
      transitionDuration: _d,
    ),
    GetPage(
      // Setup → Gameplay: the chosen configuration opens out into the table.
      name: AppRoutes.game,
      page: () => const GameScreen(),
      customTransition: _DepthTransition(from: 0.86),
      transitionDuration: _d,
      opaque: true,
    ),
    GetPage(
      // Gameplay → Round result: the score panel rises over a darker table.
      name: AppRoutes.roundResult,
      page: () => const RoundResultScreen(),
      customTransition: _DepthTransition(from: 0.97, slide: 0.06),
      transitionDuration: _d,
      opaque: false,
    ),
    GetPage(
      name: AppRoutes.matchResult,
      page: () => const MatchResultScreen(),
      customTransition: _DepthTransition(from: 0.82),
      transitionDuration: const Duration(milliseconds: 450),
    ),
    GetPage(
      name: AppRoutes.howToPlay,
      page: () => const HowToPlayScreen(),
      customTransition: _DepthTransition(from: 0.95, slide: 0.05),
      transitionDuration: _d,
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsScreen(),
      customTransition: _DepthTransition(from: 0.95, slide: 0.05),
      transitionDuration: _d,
    ),
  ];
}
