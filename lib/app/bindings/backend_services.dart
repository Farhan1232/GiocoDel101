import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

import '../../features/auth/application/supabase_auth_gateway.dart';
import '../../features/auth/domain/auth_gateway.dart';
import '../../features/leaderboard/application/leaderboard_repository.dart';
import '../../features/profile/application/profile_repository.dart';
import '../../features/rewards/application/daily_reward_repository.dart';
import '../../features/rooms/application/rooms_repository.dart';

/// Every backend seam the app has, built once at boot.
///
/// [BackendServices.none] is what runs without credentials and in tests:
/// every gateway reports "unavailable" and nothing is faked.
/// [BackendServices.supabase] wires the same seams to a real client.
class BackendServices {
  const BackendServices({
    required this.auth,
    required this.profiles,
    required this.leaderboards,
    required this.dailyRewards,
    required this.rooms,
  });

  factory BackendServices.none() => BackendServices(
    auth: NoBackendAuthGateway(),
    profiles: const NoBackendProfileRepository(),
    leaderboards: const NoBackendLeaderboardRepository(),
    dailyRewards: const NoBackendDailyRewardRepository(),
    rooms: const NoBackendRoomsRepository(),
  );

  factory BackendServices.supabase(SupabaseClient client) => BackendServices(
    auth: SupabaseAuthGateway(client),
    profiles: SupabaseProfileRepository(client),
    leaderboards: SupabaseLeaderboardRepository(client),
    dailyRewards: SupabaseDailyRewardRepository(client),
    rooms: SupabaseRoomsRepository(client),
  );

  final AuthGateway auth;
  final ProfileRepository profiles;
  final LeaderboardRepository leaderboards;
  final DailyRewardRepository dailyRewards;
  final RoomsRepository rooms;
}
