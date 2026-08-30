/// §V — daily missions on a seven-day cycle.
///
/// The rotation below is the single definition of "what is today's
/// mission". The database carries the same table
/// (`app_private.mission_rotation`) so the server hands out exactly these
/// missions for online play; the app keeps this copy so the offline table can
/// track the same goals without a network. The two must be edited together.
enum MissionKey {
  playMatches('play_matches'),
  winMatch('win_match'),
  playAces('play_aces'),
  playTwos('play_twos'),
  useNine('use_nine'),
  blockTwo('block_two'),
  onlineMatch('online_match');

  const MissionKey(this.key);

  /// Wire form, identical to `daily_missions.mission_key`.
  final String key;

  /// True when only the server can observe progress (an online match).
  bool get isOnlineOnly => this == MissionKey.onlineMatch;

  static MissionKey? fromKey(String key) {
    for (final k in MissionKey.values) {
      if (k.key == key) return k;
    }
    return null;
  }
}

/// One mission as the rotation defines it.
class Mission {
  const Mission(this.key, {required this.target, required this.rewardXp});

  final MissionKey key;
  final int target;
  final int rewardXp;

  /// Stable id inside a day, used as the local claim key.
  String get id => key.key;
}

/// The seven-day cycle. Index by ISO weekday (Monday = 1 … Sunday = 7).
class MissionCatalog {
  const MissionCatalog._();

  static const Map<int, List<Mission>> rotation = {
    1: [
      Mission(MissionKey.playMatches, target: 2, rewardXp: 30),
      Mission(MissionKey.playAces, target: 3, rewardXp: 25),
      Mission(MissionKey.useNine, target: 1, rewardXp: 20),
    ],
    2: [
      Mission(MissionKey.winMatch, target: 1, rewardXp: 40),
      Mission(MissionKey.playTwos, target: 3, rewardXp: 25),
      Mission(MissionKey.onlineMatch, target: 1, rewardXp: 30),
    ],
    3: [
      Mission(MissionKey.playMatches, target: 3, rewardXp: 35),
      Mission(MissionKey.blockTwo, target: 1, rewardXp: 30),
      Mission(MissionKey.useNine, target: 2, rewardXp: 25),
    ],
    4: [
      Mission(MissionKey.winMatch, target: 1, rewardXp: 40),
      Mission(MissionKey.playAces, target: 4, rewardXp: 30),
      Mission(MissionKey.playMatches, target: 2, rewardXp: 30),
    ],
    5: [
      Mission(MissionKey.playTwos, target: 4, rewardXp: 30),
      Mission(MissionKey.useNine, target: 2, rewardXp: 25),
      Mission(MissionKey.onlineMatch, target: 1, rewardXp: 30),
    ],
    6: [
      Mission(MissionKey.playMatches, target: 3, rewardXp: 35),
      Mission(MissionKey.winMatch, target: 2, rewardXp: 50),
      Mission(MissionKey.blockTwo, target: 1, rewardXp: 30),
    ],
    7: [
      Mission(MissionKey.playAces, target: 3, rewardXp: 25),
      Mission(MissionKey.useNine, target: 3, rewardXp: 30),
      Mission(MissionKey.onlineMatch, target: 2, rewardXp: 45),
    ],
  };

  /// Missions for [date] (local calendar day; the server uses Europe/Rome).
  static List<Mission> forDate(DateTime date) =>
      rotation[date.weekday] ?? const [];

  /// `yyyyMMdd` — the same key the daily challenge uses.
  static int dateKeyFor(DateTime date) =>
      date.year * 10000 + date.month * 100 + date.day;
}

/// A mission with where the player stands on it.
class MissionProgress {
  const MissionProgress({
    required this.mission,
    required this.progress,
    required this.claimed,
    required this.isOnline,
    this.remoteId,
  });

  final Mission mission;
  final int progress;
  final bool claimed;

  /// True when this row came from the server (online progression).
  final bool isOnline;

  /// `daily_missions.id`, needed to claim an online reward.
  final String? remoteId;

  int get clamped => progress > mission.target ? mission.target : progress;
  bool get completed => progress >= mission.target;
  bool get claimable => completed && !claimed;
  double get fraction =>
      mission.target == 0 ? 1 : (clamped / mission.target).clamp(0.0, 1.0);
}
