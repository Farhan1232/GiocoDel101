import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../domain/remote_room.dart';
import '../domain/room_models.dart';

/// Closes a live room watch.
typedef RoomWatch = Future<void> Function();

/// The lobby lifecycle, each call an RPC the database validates.
abstract class RoomsRepository {
  Future<RemoteRoom> create(RoomConfig config);
  Future<RemoteRoom> join(String code);
  Future<RemoteRoom?> load(String roomId);
  Future<void> leave(String roomId);
  Future<void> setReady(String roomId, bool ready);
  Future<void> heartbeat(String roomId);

  /// Fires whenever the room row or any of its seats changes (Realtime,
  /// RLS-filtered). The callback is a hint to [load] again — the lobby never
  /// assumes it saw every event and keeps a slow poll as well.
  RoomWatch watch(String roomId, void Function() onChanged);
}

class NoBackendRoomsRepository implements RoomsRepository {
  const NoBackendRoomsRepository();

  static const _unavailable = RoomException(RoomError.unavailable);

  @override
  Future<RemoteRoom> create(RoomConfig config) async => throw _unavailable;

  @override
  Future<RemoteRoom> join(String code) async => throw _unavailable;

  @override
  Future<RemoteRoom?> load(String roomId) async => null;

  @override
  Future<void> leave(String roomId) async {}

  @override
  Future<void> setReady(String roomId, bool ready) async {}

  @override
  Future<void> heartbeat(String roomId) async {}

  @override
  RoomWatch watch(String roomId, void Function() onChanged) => () async {};
}

class SupabaseRoomsRepository implements RoomsRepository {
  SupabaseRoomsRepository(this._client);

  final sb.SupabaseClient _client;

  @override
  Future<RemoteRoom> create(RoomConfig config) => _guard(() async {
    final row = await _client.rpc<Map<String, dynamic>>(
      'create_room',
      params: {
        'p_name': config.name,
        'p_max_players': config.playerCount,
        'p_is_private': config.isPrivate,
        'p_turn_timer_seconds': config.turnTimer.seconds,
        'p_rules': config.rules.toJson(),
      },
    );
    final room = RemoteRoom.fromJson(row);
    return (await load(room.id)) ?? room;
  });

  @override
  Future<RemoteRoom> join(String code) => _guard(() async {
    final row = await _client.rpc<Map<String, dynamic>>(
      'join_room',
      params: {'p_code': code},
    );
    final room = RemoteRoom.fromJson(row);
    return (await load(room.id)) ?? room;
  });

  @override
  Future<RemoteRoom?> load(String roomId) => _guard(() async {
    final row = await _client
        .from('rooms')
        .select()
        .eq('id', roomId)
        .maybeSingle();
    if (row == null) return null;
    final seats = await _client
        .from('room_players')
        .select(
          'user_id, seat, is_host, is_ready, connection, last_seen_at, '
          'profiles(nickname, avatar_id)',
        )
        .eq('room_id', roomId)
        .order('seat');
    return RemoteRoom.fromJson(
      row,
    ).withSeats([for (final s in seats) RemoteSeat.fromJson(s)]);
  });

  @override
  Future<void> leave(String roomId) => _guard(
    () => _client.rpc<void>('leave_room', params: {'p_room_id': roomId}),
  );

  @override
  Future<void> setReady(String roomId, bool ready) => _guard(
    () => _client.rpc<void>(
      'set_ready',
      params: {'p_room_id': roomId, 'p_ready': ready},
    ),
  );

  @override
  Future<void> heartbeat(String roomId) async {
    try {
      await _client.rpc<void>('room_heartbeat', params: {'p_room_id': roomId});
    } catch (error) {
      debugPrint('room heartbeat: $error');
    }
  }

  @override
  RoomWatch watch(String roomId, void Function() onChanged) {
    final channel = _client.channel('room:$roomId');
    channel
        .onPostgresChanges(
          event: sb.PostgresChangeEvent.all,
          schema: 'public',
          table: 'room_players',
          filter: sb.PostgresChangeFilter(
            type: sb.PostgresChangeFilterType.eq,
            column: 'room_id',
            value: roomId,
          ),
          callback: (_) => onChanged(),
        )
        .onPostgresChanges(
          event: sb.PostgresChangeEvent.update,
          schema: 'public',
          table: 'rooms',
          filter: sb.PostgresChangeFilter(
            type: sb.PostgresChangeFilterType.eq,
            column: 'id',
            value: roomId,
          ),
          callback: (_) => onChanged(),
        )
        .subscribe((status, error) {
          if (status == sb.RealtimeSubscribeStatus.subscribed) onChanged();
          if (error != null) debugPrint('room channel $status: $error');
        });
    return () async {
      try {
        await _client.removeChannel(channel);
      } catch (error) {
        debugPrint('room channel close: $error');
      }
    };
  }

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on sb.PostgrestException catch (error) {
      debugPrint('rooms: ${error.code} ${error.message}');
      final m = error.message;
      if (m.contains('room_not_found')) {
        throw RoomException(RoomError.notFound, m);
      }
      if (m.contains('room_full')) throw RoomException(RoomError.full, m);
      if (m.contains('invalid_code')) {
        throw RoomException(RoomError.invalidCode, m);
      }
      if (m.contains('not_authenticated') || error.code == '42501') {
        throw RoomException(RoomError.notSignedIn, m);
      }
      throw RoomException(RoomError.unknown, m);
    } on RoomException {
      rethrow;
    } catch (error) {
      throw RoomException(RoomError.unknown, error.toString());
    }
  }
}
