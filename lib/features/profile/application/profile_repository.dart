import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../domain/remote_profile.dart';

/// Reads and edits the signed-in player's server profile.
abstract class ProfileRepository {
  /// The profile of [userId]; `null` if the row does not exist (yet).
  Future<RemoteProfile?> fetch(String userId);

  Future<RemotePlayerStats?> fetchStats(String userId);

  /// Ids of the badges the server has unlocked for [userId]
  /// (`user_achievements`). Server-written only.
  Future<List<String>> fetchAchievements(String userId);

  /// Updates the two player-editable fields. Throws [ProfileException].
  Future<RemoteProfile> updateMine({
    required String userId,
    required String nickname,
    required String avatarId,
  });

  /// Heartbeat: moves `last_seen_at` on the server clock.
  Future<void> touchPresence();
}

/// The no-backend repository: nothing to read, nothing to write.
class NoBackendProfileRepository implements ProfileRepository {
  const NoBackendProfileRepository();

  @override
  Future<RemoteProfile?> fetch(String userId) async => null;

  @override
  Future<RemotePlayerStats?> fetchStats(String userId) async => null;

  @override
  Future<List<String>> fetchAchievements(String userId) async => const [];

  @override
  Future<RemoteProfile> updateMine({
    required String userId,
    required String nickname,
    required String avatarId,
  }) async => throw const ProfileException(ProfileError.unavailable);

  @override
  Future<void> touchPresence() async {}
}

class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this._client);

  final sb.SupabaseClient _client;

  @override
  Future<RemoteProfile?> fetch(String userId) => _guard(() async {
    final row = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return row == null ? null : RemoteProfile.fromJson(row);
  });

  @override
  Future<RemotePlayerStats?> fetchStats(String userId) => _guard(() async {
    final row = await _client
        .from('player_stats')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    return row == null ? null : RemotePlayerStats.fromJson(row);
  });

  @override
  Future<List<String>> fetchAchievements(String userId) => _guard(() async {
    final rows = await _client
        .from('user_achievements')
        .select('achievement_id')
        .eq('user_id', userId);
    return [
      for (final row in rows)
        if (row['achievement_id'] is String) row['achievement_id'] as String,
    ];
  });

  @override
  Future<RemoteProfile> updateMine({
    required String userId,
    required String nickname,
    required String avatarId,
  }) => _guard(() async {
    // Only these two columns are granted to the client. Sending anything
    // else would be refused by Postgres before RLS is even consulted.
    final row = await _client
        .from('profiles')
        .update({'nickname': nickname.trim(), 'avatar_id': avatarId})
        .eq('id', userId)
        .select()
        .maybeSingle();
    if (row == null) {
      // RLS filtered the row out: not ours.
      throw const ProfileException(ProfileError.forbidden);
    }
    return RemoteProfile.fromJson(row);
  });

  @override
  Future<void> touchPresence() async {
    try {
      await _client.rpc<void>('touch_presence');
    } catch (error) {
      debugPrint('presence: $error');
    }
  }

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on ProfileException {
      rethrow;
    } on sb.PostgrestException catch (error) {
      debugPrint('profile: ${error.code} ${error.message}');
      switch (error.code) {
        case '23505':
          throw ProfileException(ProfileError.nicknameTaken, error.message);
        case '42501':
        case '42P01':
          throw ProfileException(ProfileError.forbidden, error.message);
      }
      throw ProfileException(ProfileError.unknown, error.message);
    } on SocketException catch (error) {
      throw ProfileException(ProfileError.network, error.message);
    } on TimeoutException {
      throw const ProfileException(ProfileError.network);
    } catch (error) {
      final text = error.toString();
      if (text.contains('SocketException') ||
          text.contains('ClientException')) {
        throw ProfileException(ProfileError.network, text);
      }
      throw ProfileException(ProfileError.unknown, text);
    }
  }
}
