/// Per-player outcome of a finished round, used to drive the animated
/// score presentation on Screen 5 (§36).
class PlayerRoundResult {
  const PlayerRoundResult({
    required this.playerId,
    required this.name,
    required this.cardsLeft,
    required this.penalty,
    required this.previousScore,
    required this.newScore,
    required this.hitExact101,
    required this.eliminated,
  });

  final String playerId;
  final String name;
  final int cardsLeft;
  final int penalty;
  final int previousScore;

  /// Already reflects the 101 reset when [hitExact101] is true.
  final int newScore;
  final bool hitExact101;
  final bool eliminated;

  Map<String, dynamic> toJson() => {
    'playerId': playerId,
    'name': name,
    'cardsLeft': cardsLeft,
    'penalty': penalty,
    'previousScore': previousScore,
    'newScore': newScore,
    'hitExact101': hitExact101,
    'eliminated': eliminated,
  };

  factory PlayerRoundResult.fromJson(Map<String, dynamic> json) =>
      PlayerRoundResult(
        playerId: json['playerId'] as String,
        name: json['name'] as String,
        cardsLeft: (json['cardsLeft'] as num).toInt(),
        penalty: (json['penalty'] as num).toInt(),
        previousScore: (json['previousScore'] as num).toInt(),
        newScore: (json['newScore'] as num).toInt(),
        hitExact101: json['hitExact101'] as bool? ?? false,
        eliminated: json['eliminated'] as bool? ?? false,
      );
}

class RoundResult {
  const RoundResult({
    required this.roundNumber,
    required this.winnerId,
    required this.winnerName,
    required this.rows,
    required this.matchOver,
    this.matchWinnerId,
  });

  final int roundNumber;
  final String winnerId;
  final String winnerName;
  final List<PlayerRoundResult> rows;
  final bool matchOver;
  final String? matchWinnerId;

  Map<String, dynamic> toJson() => {
    'roundNumber': roundNumber,
    'winnerId': winnerId,
    'winnerName': winnerName,
    'rows': rows.map((r) => r.toJson()).toList(),
    'matchOver': matchOver,
    'matchWinnerId': matchWinnerId,
  };

  factory RoundResult.fromJson(Map<String, dynamic> json) => RoundResult(
    roundNumber: (json['roundNumber'] as num).toInt(),
    winnerId: json['winnerId'] as String,
    winnerName: json['winnerName'] as String,
    rows: ((json['rows'] as List?) ?? const [])
        .map((e) => PlayerRoundResult.fromJson(e as Map<String, dynamic>))
        .toList(),
    matchOver: json['matchOver'] as bool? ?? false,
    matchWinnerId: json['matchWinnerId'] as String?,
  );
}
