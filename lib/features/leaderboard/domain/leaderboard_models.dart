/// Which board is on screen.
enum LeaderboardScope { weekly, allTime }

/// One row. Built by the backend in Session 3; until then no rows exist and
/// the screen shows its empty state rather than invented names.
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.nickname,
    required this.avatarId,
    required this.points,
    this.isSelf = false,
  });

  final int rank;
  final String nickname;
  final String avatarId;
  final int points;
  final bool isSelf;
}

/// A board plus the state it is in.
class LeaderboardBoard {
  const LeaderboardBoard({
    required this.scope,
    this.entries = const [],
    this.isAvailable = false,
    this.hasMore = false,
  });

  final LeaderboardScope scope;
  final List<LeaderboardEntry> entries;

  /// False while there is no backend to rank anyone.
  final bool isAvailable;

  /// True when the page was full, so another page may follow.
  final bool hasMore;

  bool get isEmpty => entries.isEmpty;

  LeaderboardBoard append(LeaderboardBoard next) => LeaderboardBoard(
    scope: scope,
    entries: [...entries, ...next.entries],
    isAvailable: isAvailable || next.isAvailable,
    hasMore: next.hasMore,
  );
}
