import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../domain/leaderboard_models.dart';

/// Loads a board. One RPC (`public.leaderboard`) serves both scopes.
abstract class LeaderboardRepository {
  Future<LeaderboardBoard> load(LeaderboardScope scope, {int limit = 50});
}

class NoBackendLeaderboardRepository implements LeaderboardRepository {
  const NoBackendLeaderboardRepository();

  @override
  Future<LeaderboardBoard> load(
    LeaderboardScope scope, {
    int limit = 50,
  }) async => LeaderboardBoard(scope: scope);
}

class SupabaseLeaderboardRepository implements LeaderboardRepository {
  SupabaseLeaderboardRepository(this._client);

  final sb.SupabaseClient _client;

  @override
  Future<LeaderboardBoard> load(
    LeaderboardScope scope, {
    int limit = 50,
  }) async {
    final rows = await _client.rpc<List<dynamic>>(
      'leaderboard',
      params: {
        'p_scope': switch (scope) {
          LeaderboardScope.weekly => 'weekly',
          LeaderboardScope.allTime => 'all_time',
        },
        'p_limit': limit,
      },
    );
    final entries = <LeaderboardEntry>[];
    for (final raw in rows) {
      final row = raw as Map<String, dynamic>;
      entries.add(
        LeaderboardEntry(
          rank: (row['rank'] as num).toInt(),
          nickname: row['nickname'] as String? ?? '',
          avatarId: row['avatar_id'] as String? ?? 'lucia',
          points: (row['points'] as num?)?.toInt() ?? 0,
          isSelf: row['is_self'] as bool? ?? false,
        ),
      );
    }
    debugPrint('leaderboard: ${scope.name} ${entries.length} rows');
    return LeaderboardBoard(scope: scope, entries: entries, isAvailable: true);
  }
}
