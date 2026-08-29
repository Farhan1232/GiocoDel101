import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../game/domain/card_suit.dart';
import '../../game/domain/game_card.dart';
import '../domain/online_match_models.dart';

/// A request the table sends. The server decides whether it is legal; the
/// client never applies it locally. [actionId] makes a retry idempotent.
class MatchActionRequest {
  const MatchActionRequest({
    required this.matchId,
    required this.actionId,
    required this.expectedVersion,
    required this.type,
    this.card,
    this.chosenSuit,
    this.suit,
  });

  final String matchId;
  final String actionId;
  final int expectedVersion;

  /// `playCard` · `drawCard` · `chooseSuit` · `pass` · `startNextRound`.
  final String type;
  final GameCard? card;
  final CardSuit? chosenSuit;
  final CardSuit? suit;

  Map<String, dynamic> toJson() => {
    'op': 'action',
    'matchId': matchId,
    'actionId': actionId,
    'expectedVersion': expectedVersion,
    'action': {
      'type': type,
      if (card != null) 'card': card!.id,
      if (chosenSuit != null) 'chosenSuit': chosenSuit!.key,
      if (suit != null) 'suit': suit!.key,
    },
  };
}

/// Live signals for one match. Every callback is a *hint* to re-read the
/// authoritative snapshot — the client never assumes it saw every event.
class MatchSubscription {
  const MatchSubscription({required this.close});

  final Future<void> Function() close;
}

enum MatchChannelStatus { connecting, connected, disconnected }

/// Everything the online table needs from the backend.
abstract class OnlineMatchRepository {
  /// The current user's id, or null when signed out.
  String? get currentUserId;

  Future<String> startRoom(String roomId);
  Future<MatchSnapshot> snapshot(String matchId);
  Future<ActionOutcome> send(MatchActionRequest request);
  Future<ActionOutcome> claimTimeout(String matchId);
  Future<void> forfeit(String matchId);
  Future<RematchOutcome> requestRematch(String matchId);
  Future<void> heartbeat(String matchId);
  Future<void> sendReaction(String matchId, String key);

  /// The in-progress match this user should be put back into, if any.
  Future<String?> activeMatchId();

  /// The match a room currently points at (a rematch changes it).
  Future<String?> currentMatchOfRoom(String roomId);

  MatchSubscription subscribe(
    String matchId, {
    required void Function(int version) onStateChanged,
    required void Function(ReactionMessage message) onReaction,
    required void Function(MatchChannelStatus status) onStatus,
    void Function(Set<String> userIds)? onPresence,
  });
}

class NoBackendOnlineMatchRepository implements OnlineMatchRepository {
  const NoBackendOnlineMatchRepository();

  static const _unavailable = OnlineException(OnlineError.unavailable);

  @override
  String? get currentUserId => null;

  @override
  Future<String> startRoom(String roomId) async => throw _unavailable;

  @override
  Future<MatchSnapshot> snapshot(String matchId) async => throw _unavailable;

  @override
  Future<ActionOutcome> send(MatchActionRequest request) async =>
      throw _unavailable;

  @override
  Future<ActionOutcome> claimTimeout(String matchId) async =>
      throw _unavailable;

  @override
  Future<void> forfeit(String matchId) async {}

  @override
  Future<RematchOutcome> requestRematch(String matchId) async =>
      throw _unavailable;

  @override
  Future<void> heartbeat(String matchId) async {}

  @override
  Future<void> sendReaction(String matchId, String key) async {}

  @override
  Future<String?> activeMatchId() async => null;

  @override
  Future<String?> currentMatchOfRoom(String roomId) async => null;

  @override
  MatchSubscription subscribe(
    String matchId, {
    required void Function(int version) onStateChanged,
    required void Function(ReactionMessage message) onReaction,
    required void Function(MatchChannelStatus status) onStatus,
    void Function(Set<String> userIds)? onPresence,
  }) => MatchSubscription(close: () async {});
}

class SupabaseOnlineMatchRepository implements OnlineMatchRepository {
  SupabaseOnlineMatchRepository(this._client);

  final sb.SupabaseClient _client;

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  Future<Map<String, dynamic>> _invoke(Map<String, dynamic> body) async {
    try {
      final res = await _client.functions.invoke('match', body: body);
      final data = res.data;
      if (data is Map) return data.cast<String, dynamic>();
      throw const OnlineException(OnlineError.unknown, 'empty reply');
    } on sb.FunctionException catch (e) {
      final d = e.details;
      final code = d is Map ? d['error'] as String? : null;
      throw OnlineException(switch (e.status) {
        401 => OnlineError.notSignedIn,
        403 => OnlineError.notParticipant,
        404 => OnlineError.notFound,
        409 => OnlineError.conflict,
        _ => OnlineError.unknown,
      }, code ?? e.reasonPhrase);
    } on OnlineException {
      rethrow;
    } catch (e) {
      throw OnlineException(OnlineError.network, e.toString());
    }
  }

  @override
  Future<String> startRoom(String roomId) async {
    final r = await _invoke({'op': 'start', 'roomId': roomId});
    if (r['ok'] == true && r['matchId'] is String) {
      return r['matchId'] as String;
    }
    throw OnlineException(
      OnlineError.conflict,
      (r['failure'] ?? r['error'])?.toString(),
    );
  }

  @override
  Future<MatchSnapshot> snapshot(String matchId) async {
    try {
      final r = await _client.rpc<dynamic>(
        'match_snapshot',
        params: {'p_match_id': matchId},
      );
      return MatchSnapshot.fromJson((r as Map).cast<String, dynamic>());
    } on sb.PostgrestException catch (e) {
      throw OnlineException(
        e.message.contains('not_a_participant')
            ? OnlineError.notParticipant
            : OnlineError.unknown,
        e.message,
      );
    } on OnlineException {
      rethrow;
    } catch (e) {
      throw OnlineException(OnlineError.network, e.toString());
    }
  }

  @override
  Future<ActionOutcome> send(MatchActionRequest request) async =>
      ActionOutcome.fromJson(await _invoke(request.toJson()));

  @override
  Future<ActionOutcome> claimTimeout(String matchId) async =>
      ActionOutcome.fromJson(
        await _invoke({'op': 'timeout', 'matchId': matchId}),
      );

  @override
  Future<void> forfeit(String matchId) async {
    await _invoke({'op': 'forfeit', 'matchId': matchId});
  }

  @override
  Future<RematchOutcome> requestRematch(String matchId) async =>
      RematchOutcome.fromJson(
        await _invoke({'op': 'rematch', 'matchId': matchId}),
      );

  @override
  Future<void> heartbeat(String matchId) async {
    try {
      await _client.rpc<void>(
        'match_heartbeat',
        params: {'p_match_id': matchId},
      );
    } catch (e) {
      debugPrint('match heartbeat: $e');
    }
  }

  @override
  Future<void> sendReaction(String matchId, String key) async {
    try {
      await _client.rpc<void>(
        'send_reaction',
        params: {'p_match_id': matchId, 'p_key': key},
      );
    } on sb.PostgrestException catch (e) {
      throw OnlineException(
        e.message.contains('rate_limited')
            ? OnlineError.rateLimited
            : OnlineError.unknown,
        e.message,
      );
    }
  }

  @override
  Future<String?> activeMatchId() async {
    try {
      final r = await _client.rpc<dynamic>('my_active_match');
      if (r is Map && r['matchId'] is String) return r['matchId'] as String;
      return null;
    } catch (e) {
      debugPrint('my_active_match: $e');
      return null;
    }
  }

  @override
  Future<String?> currentMatchOfRoom(String roomId) async {
    try {
      final row = await _client
          .from('rooms')
          .select('match_id, status')
          .eq('id', roomId)
          .maybeSingle();
      return row?['match_id'] as String?;
    } catch (e) {
      debugPrint('currentMatchOfRoom: $e');
      return null;
    }
  }

  @override
  MatchSubscription subscribe(
    String matchId, {
    required void Function(int version) onStateChanged,
    required void Function(ReactionMessage message) onReaction,
    required void Function(MatchChannelStatus status) onStatus,
    void Function(Set<String> userIds)? onPresence,
  }) {
    // Two channels per match. Row changes travel on a plain channel — the
    // tables' own RLS filters them per subscriber (Postgres Changes are not
    // delivered on private channels). Presence and the server-sent
    // reactions travel on a PRIVATE channel, where joining is itself an
    // authorisation check (realtime.messages policies).
    final rows = _client.channel('match-rows:$matchId');
    void rowChanged(sb.PostgresChangePayload payload) {
      final v = payload.newRecord['version'];
      onStateChanged(v is num ? v.toInt() : -1);
    }

    rows
        .onPostgresChanges(
          event: sb.PostgresChangeEvent.all,
          schema: 'public',
          table: 'match_public_state',
          filter: sb.PostgresChangeFilter(
            type: sb.PostgresChangeFilterType.eq,
            column: 'match_id',
            value: matchId,
          ),
          callback: rowChanged,
        )
        .onPostgresChanges(
          event: sb.PostgresChangeEvent.all,
          schema: 'public',
          table: 'match_private_state',
          filter: sb.PostgresChangeFilter(
            type: sb.PostgresChangeFilterType.eq,
            column: 'match_id',
            value: matchId,
          ),
          callback: rowChanged,
        )
        .onPostgresChanges(
          event: sb.PostgresChangeEvent.update,
          schema: 'public',
          table: 'matches',
          filter: sb.PostgresChangeFilter(
            type: sb.PostgresChangeFilterType.eq,
            column: 'id',
            value: matchId,
          ),
          // Status/deadline changes carry no version: force a re-read.
          callback: (_) => onStateChanged(-1),
        )
        .subscribe((status, error) {
          if (error != null) debugPrint('match rows channel $status: $error');
          if (status == sb.RealtimeSubscribeStatus.subscribed) {
            onStateChanged(-1); // catch up on anything missed while joining
          }
        });

    final channel = _client.channel(
      'match:$matchId',
      opts: const sb.RealtimeChannelConfig(private: true),
    );
    channel.onBroadcast(
      event: 'reaction',
      callback: (payload) {
        // A database-sent message arrives as an envelope {type, event,
        // payload}; a client-sent one would be bare. Read both shapes.
        final inner = payload['payload'];
        onReaction(
          ReactionMessage.fromJson(
            (inner is Map ? inner : payload).cast<String, dynamic>(),
          ),
        );
      },
    );
    if (onPresence != null) {
      channel.onPresenceSync((_) {
        final ids = <String>{};
        for (final state in channel.presenceState()) {
          for (final p in state.presences) {
            final id = p.payload['userId'];
            if (id is String) ids.add(id);
          }
        }
        onPresence(ids);
      });
    }
    channel.subscribe((status, error) {
      switch (status) {
        case sb.RealtimeSubscribeStatus.subscribed:
          onStatus(MatchChannelStatus.connected);
          final me = currentUserId;
          if (me != null) {
            unawaited(channel.track({'userId': me}));
          }
        case sb.RealtimeSubscribeStatus.closed:
        case sb.RealtimeSubscribeStatus.channelError:
        case sb.RealtimeSubscribeStatus.timedOut:
          debugPrint('match channel $status ${error ?? ''}');
          onStatus(MatchChannelStatus.disconnected);
      }
    });
    onStatus(MatchChannelStatus.connecting);
    return MatchSubscription(
      close: () async {
        try {
          await _client.removeChannel(rows);
          await _client.removeChannel(channel);
        } catch (e) {
          debugPrint('match channel close: $e');
        }
      },
    );
  }
}

/// The quick-match queue.
abstract class MatchmakingRepository {
  Future<QueueEntry> enqueue({
    required int playerCount,
    required int turnTimerSeconds,
  });
  Future<QueueEntry?> heartbeat();
  Future<void> cancel();
}

class NoBackendMatchmakingRepository implements MatchmakingRepository {
  const NoBackendMatchmakingRepository();

  @override
  Future<QueueEntry> enqueue({
    required int playerCount,
    required int turnTimerSeconds,
  }) async => throw const OnlineException(OnlineError.unavailable);

  @override
  Future<QueueEntry?> heartbeat() async => null;

  @override
  Future<void> cancel() async {}
}

class SupabaseMatchmakingRepository implements MatchmakingRepository {
  SupabaseMatchmakingRepository(this._client);

  final sb.SupabaseClient _client;

  @override
  Future<QueueEntry> enqueue({
    required int playerCount,
    required int turnTimerSeconds,
  }) async {
    try {
      final r = await _client.rpc<Map<String, dynamic>>(
        'enqueue_quick_match',
        params: {
          'p_player_count': playerCount,
          'p_turn_timer_seconds': turnTimerSeconds,
        },
      );
      return QueueEntry.fromJson(r);
    } on sb.PostgrestException catch (e) {
      throw OnlineException(
        e.message.contains('already_in_match')
            ? OnlineError.conflict
            : e.code == '42501'
            ? OnlineError.notSignedIn
            : OnlineError.unknown,
        e.message,
      );
    } catch (e) {
      throw OnlineException(OnlineError.network, e.toString());
    }
  }

  @override
  Future<QueueEntry?> heartbeat() async {
    try {
      final r = await _client.rpc<dynamic>('quick_match_heartbeat');
      if (r is Map) return QueueEntry.fromJson(r.cast<String, dynamic>());
      return null;
    } catch (e) {
      debugPrint('queue heartbeat: $e');
      return null;
    }
  }

  @override
  Future<void> cancel() async {
    try {
      await _client.rpc<void>('cancel_quick_match');
    } catch (e) {
      debugPrint('cancel_quick_match: $e');
    }
  }
}
