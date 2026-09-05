import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

import '../../features/auth/application/supabase_auth_gateway.dart';
import '../../features/auth/domain/auth_gateway.dart';
import '../../features/leaderboard/application/leaderboard_repository.dart';
import '../../features/missions/application/missions_repository.dart';
import '../../features/online/application/online_match_repository.dart';
import '../../features/profile/application/profile_repository.dart';
import '../../features/purchases/application/entitlement_repository.dart';
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
    required this.matches,
    required this.matchmaking,
    this.missions = const NoBackendMissionsRepository(),
    this.entitlements = const NoBackendEntitlementRepository(),
  });

  factory BackendServices.none() => BackendServices(
    auth: NoBackendAuthGateway(),
    profiles: const NoBackendProfileRepository(),
    leaderboards: const NoBackendLeaderboardRepository(),
    dailyRewards: const NoBackendDailyRewardRepository(),
    rooms: const NoBackendRoomsRepository(),
    matches: const NoBackendOnlineMatchRepository(),
    matchmaking: const NoBackendMatchmakingRepository(),
  );

  factory BackendServices.supabase(SupabaseClient client) => BackendServices(
    auth: SupabaseAuthGateway(client),
    profiles: SupabaseProfileRepository(client),
    leaderboards: SupabaseLeaderboardRepository(client),
    dailyRewards: SupabaseDailyRewardRepository(client),
    rooms: SupabaseRoomsRepository(client),
    matches: SupabaseOnlineMatchRepository(client),
    matchmaking: SupabaseMatchmakingRepository(client),
    missions: SupabaseMissionsRepository(client),
    entitlements: SupabaseEntitlementRepository(client),
  );

  final AuthGateway auth;
  final ProfileRepository profiles;
  final LeaderboardRepository leaderboards;
  final DailyRewardRepository dailyRewards;
  final RoomsRepository rooms;

  /// The authoritative match: requests in, snapshots and live signals out.
  final OnlineMatchRepository matches;
  final MatchmakingRepository matchmaking;

  /// §V — today's online missions and their server-judged claims.
  final MissionsRepository missions;

  /// Premium: reads the player's own entitlement row; grants only ever come
  /// from the `verify-purchase` Edge Function.
  final EntitlementRepository entitlements;
}
