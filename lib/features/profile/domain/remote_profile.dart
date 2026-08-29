/// A row of `public.profiles` as the client may read it.
///
/// Every progression field here is **server-owned**: the database refuses a
/// client update to anything but [nickname] and [avatarId] (column-level
/// grant + trigger + RLS — see `docs/SUPABASE_SECURITY.md`).
class RemoteProfile {
  const RemoteProfile({
    required this.id,
    required this.nickname,
    required this.avatarId,
    required this.isGuest,
    required this.level,
    required this.xp,
    required this.wins,
    required this.losses,
    required this.matches,
    required this.rating,
    required this.currentStreak,
    required this.bestStreak,
    required this.createdAt,
    required this.updatedAt,
    this.lastSeenAt,
  });

  final String id;
  final String nickname;
  final String avatarId;
  final bool isGuest;
  final int level;
  final int xp;
  final int wins;
  final int losses;
  final int matches;
  final int rating;
  final int currentStreak;
  final int bestStreak;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastSeenAt;

  /// Online if seen within the last two minutes (presence is a heartbeat).
  bool get isOnline =>
      lastSeenAt != null &&
      DateTime.now().toUtc().difference(lastSeenAt!.toUtc()) <
          const Duration(minutes: 2);

  factory RemoteProfile.fromJson(Map<String, dynamic> json) {
    int i(String key) => (json[key] as num?)?.toInt() ?? 0;
    DateTime? t(String key) {
      final raw = json[key];
      return raw is String ? DateTime.tryParse(raw) : null;
    }

    return RemoteProfile(
      id: json['id'] as String,
      nickname: json['nickname'] as String? ?? '',
      avatarId: json['avatar_id'] as String? ?? 'lucia',
      isGuest: json['is_guest'] as bool? ?? false,
      level: i('level') == 0 ? 1 : i('level'),
      xp: i('xp'),
      wins: i('wins'),
      losses: i('losses'),
      matches: i('matches'),
      rating: i('rating'),
      currentStreak: i('current_streak'),
      bestStreak: i('best_streak'),
      createdAt: t('created_at') ?? DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: t('updated_at') ?? DateTime.fromMillisecondsSinceEpoch(0),
      lastSeenAt: t('last_seen_at'),
    );
  }

  RemoteProfile copyWith({String? nickname, String? avatarId}) => RemoteProfile(
    id: id,
    nickname: nickname ?? this.nickname,
    avatarId: avatarId ?? this.avatarId,
    isGuest: isGuest,
    level: level,
    xp: xp,
    wins: wins,
    losses: losses,
    matches: matches,
    rating: rating,
    currentStreak: currentStreak,
    bestStreak: bestStreak,
    createdAt: createdAt,
    updatedAt: updatedAt,
    lastSeenAt: lastSeenAt,
  );
}

/// A row of `public.player_stats` — the extra lifetime counters.
class RemotePlayerStats {
  const RemotePlayerStats({
    this.roundsPlayed = 0,
    this.roundsWon = 0,
    this.cardsPlayed = 0,
    this.longestChain = 0,
    this.resets101 = 0,
    this.largestComeback = 0,
    this.dailyChallengesCompleted = 0,
    this.onlineMatches = 0,
    this.coins = 0,
  });

  final int roundsPlayed;
  final int roundsWon;
  final int cardsPlayed;
  final int longestChain;
  final int resets101;
  final int largestComeback;
  final int dailyChallengesCompleted;
  final int onlineMatches;
  final int coins;

  factory RemotePlayerStats.fromJson(Map<String, dynamic> json) {
    int i(String key) => (json[key] as num?)?.toInt() ?? 0;
    return RemotePlayerStats(
      roundsPlayed: i('rounds_played'),
      roundsWon: i('rounds_won'),
      cardsPlayed: i('cards_played'),
      longestChain: i('longest_chain'),
      resets101: i('resets_101'),
      largestComeback: i('largest_comeback'),
      dailyChallengesCompleted: i('daily_challenges_completed'),
      onlineMatches: i('online_matches'),
      coins: i('coins'),
    );
  }
}

/// Why a profile write was refused.
enum ProfileError { nicknameTaken, forbidden, network, unavailable, unknown }

class ProfileException implements Exception {
  const ProfileException(this.error, [this.detail]);

  final ProfileError error;
  final String? detail;

  @override
  String toString() =>
      'ProfileException($error${detail == null ? '' : ': $detail'})';
}
