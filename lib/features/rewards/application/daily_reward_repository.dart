import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// What the server says about the player's daily reward run.
class DailyRewardStatus {
  const DailyRewardStatus({
    required this.streak,
    required this.claimedToday,
    required this.canClaim,
    required this.coins,
  });

  /// Days claimed in the current run (0..7). With `claimedToday` false this is
  /// yesterday's run, which today's claim extends.
  final int streak;
  final bool claimedToday;
  final bool canClaim;
  final int coins;
}

enum DailyRewardError { guestNotAllowed, alreadyClaimed, unavailable, unknown }

class DailyRewardException implements Exception {
  const DailyRewardException(this.error, [this.detail]);

  final DailyRewardError error;
  final String? detail;
}

abstract class DailyRewardRepository {
  Future<DailyRewardStatus?> status();

  /// Claims today's reward. The ladder day and the amount are decided by the
  /// database; the client only asks. Throws [DailyRewardException].
  Future<DailyRewardStatus> claim();
}

class NoBackendDailyRewardRepository implements DailyRewardRepository {
  const NoBackendDailyRewardRepository();

  @override
  Future<DailyRewardStatus?> status() async => null;

  @override
  Future<DailyRewardStatus> claim() async =>
      throw const DailyRewardException(DailyRewardError.unavailable);
}

class SupabaseDailyRewardRepository implements DailyRewardRepository {
  SupabaseDailyRewardRepository(this._client);

  final sb.SupabaseClient _client;

  @override
  Future<DailyRewardStatus?> status() async {
    final rows = await _client.rpc<List<dynamic>>('my_daily_reward_status');
    if (rows.isEmpty) return null;
    final row = rows.first as Map<String, dynamic>;
    return DailyRewardStatus(
      streak: (row['streak'] as num?)?.toInt() ?? 0,
      claimedToday: row['claimed_today'] as bool? ?? false,
      canClaim: row['can_claim'] as bool? ?? false,
      coins: (row['coins'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Future<DailyRewardStatus> claim() async {
    try {
      await _client.rpc<dynamic>('claim_daily_reward');
    } on sb.PostgrestException catch (error) {
      if (error.message.contains('guest_not_allowed')) {
        throw DailyRewardException(
          DailyRewardError.guestNotAllowed,
          error.message,
        );
      }
      if (error.message.contains('already_claimed')) {
        throw DailyRewardException(
          DailyRewardError.alreadyClaimed,
          error.message,
        );
      }
      throw DailyRewardException(DailyRewardError.unknown, error.message);
    }
    final next = await status();
    if (next == null) {
      throw const DailyRewardException(DailyRewardError.unknown);
    }
    return next;
  }
}
