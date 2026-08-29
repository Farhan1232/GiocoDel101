import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_durations.dart';
import '../../features/game/presentation/game_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/game/presentation/how_to_play_screen.dart';
import '../../features/game/presentation/match_result_screen.dart';
import '../../features/game/presentation/round_result_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/game/presentation/setup_screen.dart';
import '../../features/achievements/presentation/achievements_screen.dart';
import '../../features/auth/presentation/auth_landing_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/leaderboard/presentation/leaderboard_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/online/presentation/online_mode_screen.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/rewards/presentation/daily_reward_screen.dart';
import '../../features/rooms/presentation/create_room_screen.dart';
import '../../features/rooms/presentation/join_room_screen.dart';
import '../../features/rooms/presentation/matchmaking_screen.dart';
import '../../features/rooms/presentation/room_lobby_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';

/// Every destination in the app, in one place.
class AppRoutes {
  const AppRoutes._();

  // Boot
  static const String splash = '/';
  static const String onboarding = '/onboarding';

  // Account
  static const String authLanding = '/auth';
  static const String login = '/auth/login';
  static const String signup = '/auth/signup';
  static const String forgotPassword = '/auth/forgot-password';

  static const String home = '/home';

  // Online
  static const String online = '/online';
  static const String createRoom = '/online/create';
  static const String joinRoom = '/online/join';
  static const String roomLobby = '/online/lobby';
  static const String matchmaking = '/online/matchmaking';

  // Player
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String leaderboard = '/leaderboard';
  static const String achievements = '/achievements';
  static const String dailyReward = '/rewards/daily';
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
        position: Tween(
          begin: Offset(0, slide),
          end: Offset.zero,
        ).animate(eased),
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

    // First run.
    GetPage(
      name: AppRoutes.onboarding,
      page: () => const OnboardingScreen(),
      transition: Transition.fade,
      transitionDuration: _d,
    ),

    // Account.
    GetPage(
      name: AppRoutes.authLanding,
      page: () => const AuthLandingScreen(),
      customTransition: _DepthTransition(from: 0.95, slide: 0.05),
      transitionDuration: _d,
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
      customTransition: _DepthTransition(from: 0.96, slide: 0.05),
      transitionDuration: _d,
    ),
    GetPage(
      name: AppRoutes.signup,
      page: () => const SignupScreen(),
      customTransition: _DepthTransition(from: 0.96, slide: 0.05),
      transitionDuration: _d,
    ),
    GetPage(
      name: AppRoutes.forgotPassword,
      page: () => const ForgotPasswordScreen(),
      customTransition: _DepthTransition(from: 0.96, slide: 0.05),
      transitionDuration: _d,
    ),

    // Online.
    GetPage(
      name: AppRoutes.online,
      page: () => const OnlineModeScreen(),
      customTransition: _DepthTransition(from: 0.94, slide: 0.04),
      transitionDuration: _d,
    ),
    GetPage(
      name: AppRoutes.createRoom,
      page: () => const CreateRoomScreen(),
      customTransition: _DepthTransition(from: 0.95, slide: 0.05),
      transitionDuration: _d,
    ),
    GetPage(
      name: AppRoutes.joinRoom,
      page: () => const JoinRoomScreen(),
      customTransition: _DepthTransition(from: 0.95, slide: 0.05),
      transitionDuration: _d,
    ),
    GetPage(
      name: AppRoutes.roomLobby,
      page: () => const RoomLobbyScreen(),
      customTransition: _DepthTransition(from: 0.92),
      transitionDuration: _d,
    ),
    GetPage(
      name: AppRoutes.matchmaking,
      page: () => const MatchmakingScreen(),
      customTransition: _DepthTransition(from: 0.92),
      transitionDuration: _d,
    ),

    // Player.
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfileScreen(),
      customTransition: _DepthTransition(from: 0.95, slide: 0.05),
      transitionDuration: _d,
    ),
    GetPage(
      name: AppRoutes.editProfile,
      page: () => const EditProfileScreen(),
      customTransition: _DepthTransition(from: 0.96, slide: 0.05),
      transitionDuration: _d,
    ),
    GetPage(
      name: AppRoutes.leaderboard,
      page: () => const LeaderboardScreen(),
      customTransition: _DepthTransition(from: 0.95, slide: 0.05),
      transitionDuration: _d,
    ),
    GetPage(
      name: AppRoutes.achievements,
      page: () => const AchievementsScreen(),
      customTransition: _DepthTransition(from: 0.95, slide: 0.05),
      transitionDuration: _d,
    ),
    GetPage(
      name: AppRoutes.dailyReward,
      page: () => const DailyRewardScreen(),
      customTransition: _DepthTransition(from: 0.94, slide: 0.05),
      transitionDuration: _d,
    ),
  ];
}
