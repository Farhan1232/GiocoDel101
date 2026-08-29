/// One day of the seven-day reward run.
class DailyRewardDay {
  const DailyRewardDay({
    required this.day,
    required this.amount,
    required this.isClaimed,
    required this.isToday,
  });

  /// 1..7.
  final int day;

  /// Coins the day is worth. Cosmetic currency only.
  final int amount;

  final bool isClaimed;
  final bool isToday;

  bool get isLocked => !isClaimed && !isToday;
}

/// The seven-day calendar as the screen draws it.
///
/// The ladder is fixed and local. Nothing here talks to a server, and no day
/// is marked claimed unless the player actually claimed it.
class DailyRewardCalendar {
  const DailyRewardCalendar({required this.days, required this.streak});

  final List<DailyRewardDay> days;

  /// How many consecutive days have been claimed, 0..7.
  final int streak;

  /// Day seven is the one worth coming back for.
  static const List<int> ladder = [10, 15, 20, 30, 40, 60, 120];

  bool get canClaimToday => days.any((d) => d.isToday && !d.isClaimed);

  factory DailyRewardCalendar.forStreak(
    int streak, {
    bool claimedToday = false,
  }) {
    final safe = streak.clamp(0, ladder.length);
    return DailyRewardCalendar(
      streak: safe,
      days: [
        for (var i = 0; i < ladder.length; i++)
          DailyRewardDay(
            day: i + 1,
            amount: ladder[i],
            isClaimed: i < safe,
            isToday: i == safe && !claimedToday,
          ),
      ],
    );
  }
}
