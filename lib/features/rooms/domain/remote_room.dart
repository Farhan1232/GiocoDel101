/// A row of `public.rooms` plus its seats, as the lobby draws it.
class RemoteRoom {
  const RemoteRoom({
    required this.id,
    required this.code,
    required this.hostId,
    required this.name,
    required this.maxPlayers,
    required this.isPrivate,
    required this.turnTimerSeconds,
    required this.status,
    this.seats = const [],
  });

  final String id;
  final String code;
  final String hostId;
  final String name;
  final int maxPlayers;
  final bool isPrivate;
  final int turnTimerSeconds;
  final String status;
  final List<RemoteSeat> seats;

  bool get isOpen => status == 'lobby';

  factory RemoteRoom.fromJson(Map<String, dynamic> json) => RemoteRoom(
    id: json['id'] as String,
    code: json['code'] as String? ?? '',
    hostId: json['host_id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    maxPlayers: (json['max_players'] as num?)?.toInt() ?? 4,
    isPrivate: json['is_private'] as bool? ?? true,
    turnTimerSeconds: (json['turn_timer_seconds'] as num?)?.toInt() ?? 30,
    status: json['status'] as String? ?? 'lobby',
  );

  RemoteRoom withSeats(List<RemoteSeat> value) => RemoteRoom(
    id: id,
    code: code,
    hostId: hostId,
    name: name,
    maxPlayers: maxPlayers,
    isPrivate: isPrivate,
    turnTimerSeconds: turnTimerSeconds,
    status: status,
    seats: value,
  );
}

/// One row of `public.room_players`, joined with the seat's public profile.
class RemoteSeat {
  const RemoteSeat({
    required this.userId,
    required this.seat,
    required this.isHost,
    required this.isReady,
    required this.nickname,
    required this.avatarId,
    required this.connection,
  });

  final String userId;
  final int seat;
  final bool isHost;
  final bool isReady;
  final String nickname;
  final String avatarId;
  final String connection;

  factory RemoteSeat.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>? ?? const {};
    return RemoteSeat(
      userId: json['user_id'] as String,
      seat: (json['seat'] as num?)?.toInt() ?? 0,
      isHost: json['is_host'] as bool? ?? false,
      isReady: json['is_ready'] as bool? ?? false,
      nickname: profile['nickname'] as String? ?? '',
      avatarId: profile['avatar_id'] as String? ?? 'lucia',
      connection: json['connection'] as String? ?? 'online',
    );
  }
}

enum RoomError {
  notFound,
  full,
  invalidCode,
  notSignedIn,
  unavailable,
  unknown,
}

class RoomException implements Exception {
  const RoomException(this.error, [this.detail]);

  final RoomError error;
  final String? detail;
}
