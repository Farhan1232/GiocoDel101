import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../domain/mission.dart';

enum MissionsError {
  notCompleted,
  alreadyClaimed,
  expired,
  unavailable,
  unknown,
}

class MissionsException implements Exception {
  const MissionsException(this.error, [this.detail]);

  final MissionsError error;
  final String? detail;

  @override
  String toString() =>
      'MissionsException($error${detail == null ? '' : ': $detail'})';
}

/// The server's view of today's missions for the signed-in player.
///
/// Progress is written only by server code that watched the play happen
/// (`srv_commit_action`, `settle_match`); claiming is judged on the
/// database clock. The client asks and displays — nothing more.
abstract class MissionsRepository {
  Future<List<MissionProgress>> today();

  /// Throws [MissionsException].
  Future<MissionProgress> claim(String missionId);
}

class NoBackendMissionsRepository implements MissionsRepository {
  const NoBackendMissionsRepository();

  @override
  Future<List<MissionProgress>> today() async => const [];

  @override
  Future<MissionProgress> claim(String missionId) async =>
      throw const MissionsException(MissionsError.unavailable);
}

class SupabaseMissionsRepository implements MissionsRepository {
  SupabaseMissionsRepository(this._client);

  final sb.SupabaseClient _client;

  @override
  Future<List<MissionProgress>> today() async {
    final rows = await _client.rpc<List<dynamic>>('my_daily_missions');
    final out = <MissionProgress>[];
    for (final raw in rows) {
      final row = parseRow((raw as Map).cast<String, dynamic>());
      if (row != null) out.add(row);
    }
    return out;
  }

  @override
  Future<MissionProgress> claim(String missionId) async {
    try {
      final r = await _client.rpc<dynamic>(
        'claim_mission_reward',
        params: {'p_mission_id': missionId},
      );
      final rows = r is List ? r : [r];
      if (rows.isEmpty) throw const MissionsException(MissionsError.unknown);
      final row = parseRow((rows.first as Map).cast<String, dynamic>());
      if (row == null) throw const MissionsException(MissionsError.unknown);
      return row;
    } on sb.PostgrestException catch (error) {
      debugPrint('missions: ${error.code} ${error.message}');
      final m = error.message;
      if (m.contains('not_completed')) {
        throw MissionsException(MissionsError.notCompleted, m);
      }
      if (m.contains('already_claimed')) {
        throw MissionsException(MissionsError.alreadyClaimed, m);
      }
      if (m.contains('mission_expired')) {
        throw MissionsException(MissionsError.expired, m);
      }
      throw MissionsException(MissionsError.unknown, m);
    }
  }

  /// One `my_daily_missions` row → the app's model. Unknown keys (a newer
  /// server) are skipped rather than crashing the screen.
  static MissionProgress? parseRow(Map<String, dynamic> row) {
    final key = MissionKey.fromKey(row['mission_key'] as String? ?? '');
    if (key == null) return null;
    return MissionProgress(
      mission: Mission(
        key,
        target: (row['target'] as num?)?.toInt() ?? 1,
        rewardXp: (row['reward_xp'] as num?)?.toInt() ?? 0,
      ),
      progress: (row['progress'] as num?)?.toInt() ?? 0,
      claimed: row['claimed_at'] != null,
      isOnline: true,
      remoteId: row['mission_id'] as String?,
    );
  }
}
