import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../domain/leaderboard_models.dart';
import '../../../core/utils/log.dart';

/// Loads a board. One RPC (`public.leaderboard`) serves both scopes, one
/// page at a time; `my_leaderboard_rank` answers "where am I" even when the
/// player is far below the loaded pages.
abstract class LeaderboardRepository {
  Future<LeaderboardBoard> load(
    LeaderboardScope scope, {
    int limit = 50,
    int offset = 0,
  });

  /// The signed-in player's own row, or null when not ranked in [scope].
  Future<LeaderboardEntry?> myRank(LeaderboardScope scope);
}

class NoBackendLeaderboardRepository implements LeaderboardRepository {
  const NoBackendLeaderboardRepository();

  @override
  Future<LeaderboardBoard> load(
    LeaderboardScope scope, {
    int limit = 50,
    int offset = 0,
  }) async => LeaderboardBoard(scope: scope);

  @override
  Future<LeaderboardEntry?> myRank(LeaderboardScope scope) async => null;
}

String _scopeKey(LeaderboardScope scope) => switch (scope) {
  LeaderboardScope.weekly => 'weekly',
  LeaderboardScope.allTime => 'all_time',
};

LeaderboardEntry _entry(Map<String, dynamic> row) => LeaderboardEntry(
  rank: (row['rank'] as num).toInt(),
  nickname: row['nickname'] as String? ?? '',
  avatarId: row['avatar_id'] as String? ?? 'lucia',
  points: (row['points'] as num?)?.toInt() ?? 0,
  isSelf: row['is_self'] as bool? ?? false,
);

class SupabaseLeaderboardRepository implements LeaderboardRepository {
  SupabaseLeaderboardRepository(this._client);

  final sb.SupabaseClient _client;

  @override
  Future<LeaderboardBoard> load(
    LeaderboardScope scope, {
    int limit = 50,
    int offset = 0,
  }) async {
    final rows = await _client.rpc<List<dynamic>>(
      'leaderboard',
      params: {
        'p_scope': _scopeKey(scope),
        'p_limit': limit,
        'p_offset': offset,
      },
    );
    final entries = [
      for (final raw in rows) _entry((raw as Map).cast<String, dynamic>()),
    ];
    Log.d('leaderboard: ${scope.name} +${entries.length} @ $offset');
    return LeaderboardBoard(
      scope: scope,
      entries: entries,
      isAvailable: true,
      hasMore: entries.length >= limit,
    );
  }

  @override
  Future<LeaderboardEntry?> myRank(LeaderboardScope scope) async {
    final rows = await _client.rpc<List<dynamic>>(
      'my_leaderboard_rank',
      params: {'p_scope': _scopeKey(scope)},
    );
    if (rows.isEmpty) return null;
    final row = (rows.first as Map).cast<String, dynamic>();
    if (row['rank'] == null) return null;
    return _entry(row);
  }
}
