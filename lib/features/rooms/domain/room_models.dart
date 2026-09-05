import '../../game/domain/game_rules.dart';

/// How long a player has to move before the turn passes.
enum TurnTimer {
  off(0),
  fifteen(15),
  thirty(30),
  sixty(60);

  const TurnTimer(this.seconds);

  final int seconds;

  String get key => name;

  static TurnTimer fromKey(String key) => TurnTimer.values.firstWhere(
    (t) => t.key == key,
    orElse: () => TurnTimer.thirty,
  );
}

/// Everything the Create Room screen collects.
///
/// A plain value object: it is built by the UI and will later be handed to the
/// backend untouched. It carries the house rules as a [GameRules] so the
/// single-source-of-truth rule still holds online.
class RoomConfig {
  const RoomConfig({
    this.name = '',
    this.playerCount = 4,
    this.isPrivate = true,
    this.turnTimer = TurnTimer.thirty,
    this.rules = const GameRules(),
  });

  final String name;

  /// 2, 3 or 4.
  final int playerCount;

  final bool isPrivate;
  final TurnTimer turnTimer;
  final GameRules rules;

  RoomConfig copyWith({
    String? name,
    int? playerCount,
    bool? isPrivate,
    TurnTimer? turnTimer,
    GameRules? rules,
  }) => RoomConfig(
    name: name ?? this.name,
    playerCount: playerCount ?? this.playerCount,
    isPrivate: isPrivate ?? this.isPrivate,
    turnTimer: turnTimer ?? this.turnTimer,
    rules: rules ?? this.rules,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'playerCount': playerCount,
    'isPrivate': isPrivate,
    'turnTimer': turnTimer.key,
    'rules': rules.toJson(),
  };
}

/// One seat in a lobby. [nickname] null means the seat is still open.
class RoomSeat {
  const RoomSeat({
    required this.index,
    this.nickname,
    this.avatarId,
    this.isHost = false,
    this.isReady = false,
    this.isSelf = false,
  });

  final int index;
  final String? nickname;
  final String? avatarId;
  final bool isHost;
  final bool isReady;
  final bool isSelf;

  bool get isEmpty => nickname == null;
}

/// The lobby as the screen needs to draw it.
class RoomLobbyState {
  const RoomLobbyState({
    required this.code,
    required this.config,
    required this.seats,
    this.selfIsHost = false,
  });

  /// Six characters, uppercase. Empty while no room exists.
  final String code;

  final RoomConfig config;
  final List<RoomSeat> seats;
  final bool selfIsHost;

  int get filledSeats => seats.where((s) => !s.isEmpty).length;

  bool get everyoneReady =>
      filledSeats == seats.length &&
      seats.every((s) => s.isEmpty || s.isReady || s.isHost);

  /// A lobby with the host seated and the rest open — what the screen shows
  /// before any networking exists.
  factory RoomLobbyState.pending({
    required RoomConfig config,
    required String hostNickname,
    required String hostAvatarId,
    String code = '',
  }) {
    return RoomLobbyState(
      code: code,
      config: config,
      selfIsHost: true,
      seats: [
        RoomSeat(
          index: 0,
          nickname: hostNickname,
          avatarId: hostAvatarId,
          isHost: true,
          isReady: true,
          isSelf: true,
        ),
        for (var i = 1; i < config.playerCount; i++) RoomSeat(index: i),
      ],
    );
  }
}

/// Room codes are six characters from an alphabet with no look-alikes.
class RoomCode {
  const RoomCode._();

  static const int length = 6;

  /// No O/0, no I/1 — codes get read aloud and retyped.
  static const String alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  static bool isValid(String raw) {
    final value = normalise(raw);
    if (value.length != length) return false;
    return value.split('').every(alphabet.contains);
  }

  /// Uppercases and strips anything that cannot be part of a code, so a
  /// pasted "abc-123" still lands correctly.
  static String normalise(String raw) {
    final upper = raw.toUpperCase();
    return upper.split('').where(alphabet.contains).take(length).join();
  }
}
