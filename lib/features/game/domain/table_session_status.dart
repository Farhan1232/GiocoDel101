import '../../../core/widgets/network_banner.dart';

/// How the table is being played and, if online, how the connection is.
///
/// The gameplay view renders from this rather than asking a network layer
/// anything. Offline matches use [TableSessionStatus.offlineLocal], where the
/// connection is irrelevant and no indicator is drawn. Session 3 supplies a
/// live instance for online matches; the widget does not change.
class TableSessionStatus {
  const TableSessionStatus({
    required this.isOnline,
    this.connection = NetworkStatus.online,
    this.turnSecondsRemaining,
    this.turnSecondsTotal,
  });

  /// False for a local match against bots or a pass-and-play game.
  final bool isOnline;

  final NetworkStatus connection;

  /// null when the room has no turn timer, or the match is offline.
  final int? turnSecondsRemaining;
  final int? turnSecondsTotal;

  bool get hasTimer =>
      turnSecondsRemaining != null &&
      turnSecondsTotal != null &&
      turnSecondsTotal! > 0;

  /// 1.0 at the start of a turn, 0.0 when the time is up.
  double get timerProgress => hasTimer
      ? (turnSecondsRemaining! / turnSecondsTotal!).clamp(0.0, 1.0)
      : 0.0;

  /// True when the player should be told the connection is not healthy.
  bool get showsConnection =>
      isOnline && connection != NetworkStatus.online;

  /// The only value Session 1 ever produces.
  static const TableSessionStatus offlineLocal =
      TableSessionStatus(isOnline: false);
}
