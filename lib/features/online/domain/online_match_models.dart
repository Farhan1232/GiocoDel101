import '../../game/domain/game_card.dart';
import '../../game/domain/game_state.dart';

/// One seat of an online match, as `match_snapshot` reports it.
class OnlineSeat {
  const OnlineSeat({
    required this.userId,
    required this.seat,
    required this.enginePlayerId,
    required this.nickname,
    required this.avatarId,
    required this.connection,
    this.lastSeenAt,
    this.forfeitedAt,
    this.rematchRequestedAt,
    this.isWinner = false,
    this.placement,
    this.finalScore,
    this.xpAwarded = 0,
  });

  final String userId;
  final int seat;
  final String enginePlayerId;
  final String nickname;
  final String avatarId;
  final String connection;
  final DateTime? lastSeenAt;
  final DateTime? forfeitedAt;
  final DateTime? rematchRequestedAt;
  final bool isWinner;
  final int? placement;
  final int? finalScore;
  final int xpAwarded;

  bool get hasForfeited => forfeitedAt != null;
  bool get wantsRematch => rematchRequestedAt != null;

  /// "Connected" is derived from the heartbeat, not trusted from a flag.
  bool isConnectedAt(DateTime now) =>
      lastSeenAt != null && now.difference(lastSeenAt!).inSeconds < 20;

  factory OnlineSeat.fromJson(Map<String, dynamic> j) => OnlineSeat(
    userId: j['userId'] as String,
    seat: (j['seat'] as num).toInt(),
    enginePlayerId: j['enginePlayerId'] as String,
    nickname: j['nickname'] as String? ?? '',
    avatarId: j['avatarId'] as String? ?? 'lucia',
    connection: j['connection'] as String? ?? 'online',
    lastSeenAt: _ts(j['lastSeenAt']),
    forfeitedAt: _ts(j['forfeitedAt']),
    rematchRequestedAt: _ts(j['rematchRequestedAt']),
    isWinner: j['isWinner'] as bool? ?? false,
    placement: (j['placement'] as num?)?.toInt(),
    finalScore: (j['finalScore'] as num?)?.toInt(),
    xpAwarded: (j['xpAwarded'] as num?)?.toInt() ?? 0,
  );
}

/// The authoritative picture of a match for ONE viewer: the redacted public
/// state, that viewer's own hand, the server clock and the seats.
class MatchSnapshot {
  const MatchSnapshot({
    required this.matchId,
    required this.roomId,
    required this.status,
    required this.version,
    required this.publicState,
    required this.hand,
    required this.seats,
    required this.serverNow,
    this.winnerUserId,
    this.currentUserId,
    this.turnTimerSeconds = 0,
    this.turnStartedAt,
    this.turnDeadlineAt,
    this.drawnCard,
    this.abandonedBy,
    this.rematchOf,
  });

  final String matchId;
  final String? roomId;

  /// `in_progress` / `finished` / `abandoned` — the row, not the engine.
  final String status;
  final int version;
  final GameState publicState;
  final List<GameCard> hand;
  final List<OnlineSeat> seats;
  final DateTime serverNow;
  final String? winnerUserId;
  final String? currentUserId;
  final int turnTimerSeconds;
  final DateTime? turnStartedAt;
  final DateTime? turnDeadlineAt;
  final GameCard? drawnCard;
  final String? abandonedBy;
  final String? rematchOf;

  bool get isInProgress => status == 'in_progress';

  OnlineSeat? seatOf(String userId) {
    for (final s in seats) {
      if (s.userId == userId) return s;
    }
    return null;
  }

  OnlineSeat? seatByEngineId(String enginePlayerId) {
    for (final s in seats) {
      if (s.enginePlayerId == enginePlayerId) return s;
    }
    return null;
  }

  /// The table as the viewer may see it: public state + own cards.
  GameState viewFor(String userId) {
    final seat = seatOf(userId);
    if (seat == null) return publicState;
    final me = publicState.playerById(seat.enginePlayerId);
    if (me == null) return publicState;
    return publicState.withPlayer(me.copyWith(hand: hand));
  }

  factory MatchSnapshot.fromJson(Map<String, dynamic> j) {
    final m = (j['match'] as Map).cast<String, dynamic>();
    return MatchSnapshot(
      matchId: m['id'] as String,
      roomId: m['roomId'] as String?,
      status: m['status'] as String? ?? 'in_progress',
      version: (j['version'] as num?)?.toInt() ?? 0,
      publicState: GameState.fromJson(
        (j['state'] as Map).cast<String, dynamic>(),
      ),
      hand: ((j['hand'] as List?) ?? const [])
          .map((e) => GameCard.fromJson(e))
          .toList(),
      seats: ((j['players'] as List?) ?? const [])
          .map((e) => OnlineSeat.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      serverNow: _ts(j['serverNow']) ?? DateTime.now(),
      winnerUserId: m['winnerId'] as String?,
      currentUserId: m['currentUserId'] as String?,
      turnTimerSeconds: (m['turnTimerSeconds'] as num?)?.toInt() ?? 0,
      turnStartedAt: _ts(m['turnStartedAt']),
      turnDeadlineAt: _ts(m['turnDeadlineAt']),
      drawnCard: j['drawnCard'] == null
          ? null
          : GameCard.fromJson(j['drawnCard']),
      abandonedBy: m['abandonedBy'] as String?,
      rematchOf: m['rematchOf'] as String?,
    );
  }
}

/// What the `match` function answered to an action request.
class ActionOutcome {
  const ActionOutcome({
    required this.accepted,
    required this.version,
    this.failure,
    this.duplicate = false,
    this.publicState,
    this.hand,
    this.drawnCard,
    this.events = const [],
    this.status,
    this.turnDeadlineAt,
  });

  final bool accepted;

  /// After the action when accepted; the server's current version when
  /// refused as stale.
  final int version;
  final String? failure;
  final bool duplicate;
  final GameState? publicState;
  final List<GameCard>? hand;
  final GameCard? drawnCard;
  final List<String> events;
  final String? status;
  final DateTime? turnDeadlineAt;

  bool get isStale => failure == 'staleState';

  factory ActionOutcome.fromJson(Map<String, dynamic> j) => ActionOutcome(
    accepted: j['accepted'] == true,
    version: (j['version'] as num?)?.toInt() ?? -1,
    failure: j['failure'] as String? ?? j['error'] as String?,
    duplicate: j['duplicate'] == true,
    publicState: j['publicState'] is Map
        ? GameState.fromJson((j['publicState'] as Map).cast<String, dynamic>())
        : null,
    hand: j['hand'] is List
        ? (j['hand'] as List).map((e) => GameCard.fromJson(e)).toList()
        : null,
    drawnCard: j['drawnCard'] == null
        ? null
        : GameCard.fromJson(j['drawnCard']),
    events: ((j['events'] as List?) ?? const []).cast<String>(),
    status: j['status'] as String?,
    turnDeadlineAt: _ts(j['turnDeadlineAt']),
  );
}

/// Reply to a rematch vote.
class RematchOutcome {
  const RematchOutcome({
    required this.started,
    this.matchId,
    this.votes = 0,
    this.needed = 0,
    this.roomId,
  });

  final bool started;
  final String? matchId;
  final int votes;
  final int needed;
  final String? roomId;

  factory RematchOutcome.fromJson(Map<String, dynamic> j) => RematchOutcome(
    started: j['status'] == 'started',
    matchId: j['matchId'] as String?,
    votes: (j['votes'] as num?)?.toInt() ?? 0,
    needed: (j['needed'] as num?)?.toInt() ?? 0,
    roomId: j['roomId'] as String?,
  );
}

/// A preset reaction as it travels: only the key crosses the network; the
/// text is looked up locally in the viewer's language.
class ReactionMessage {
  const ReactionMessage({
    required this.userId,
    required this.seat,
    required this.key,
  });

  final String userId;
  final int seat;
  final String key;

  /// The eight keys `public.reaction_presets` accepts, in display order.
  static const List<String> presetKeys = [
    'ciao',
    'bravo',
    'bella_mossa',
    'mamma_mia',
    'ahahaha',
    'che_fortuna',
    'rivincita',
    'gg',
  ];

  factory ReactionMessage.fromJson(Map<String, dynamic> j) => ReactionMessage(
    userId: j['userId'] as String? ?? '',
    seat: (j['seat'] as num?)?.toInt() ?? 0,
    key: j['key'] as String? ?? '',
  );
}

/// The player's own queue row.
class QueueEntry {
  const QueueEntry({
    required this.status,
    required this.playerCount,
    required this.turnTimerSeconds,
    this.roomId,
    this.enqueuedAt,
  });

  final String status;
  final int playerCount;
  final int turnTimerSeconds;
  final String? roomId;
  final DateTime? enqueuedAt;

  bool get isMatched => status == 'matched' && roomId != null;

  factory QueueEntry.fromJson(Map<String, dynamic> j) => QueueEntry(
    status: j['status'] as String? ?? 'waiting',
    playerCount: (j['player_count'] as num?)?.toInt() ?? 2,
    turnTimerSeconds: (j['turn_timer_seconds'] as num?)?.toInt() ?? 30,
    roomId: j['room_id'] as String?,
    enqueuedAt: _ts(j['enqueued_at']),
  );
}

/// Where an online request failed, mapped from HTTP/PostgREST/function
/// answers so screens branch on a type.
enum OnlineError {
  notSignedIn,
  notParticipant,
  notFound,
  conflict,
  rateLimited,
  network,
  unavailable,
  unknown,
}

class OnlineException implements Exception {
  const OnlineException(this.error, [this.detail]);

  final OnlineError error;
  final String? detail;

  @override
  String toString() => 'OnlineException(${error.name}: $detail)';
}

DateTime? _ts(Object? v) {
  if (v is! String || v.isEmpty) return null;
  return DateTime.tryParse(v)?.toUtc();
}
