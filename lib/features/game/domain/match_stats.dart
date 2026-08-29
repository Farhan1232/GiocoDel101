import 'card_suit.dart';

/// Counters accumulated across a whole match, surfaced on the match-result
/// screen (§37) and folded into lifetime statistics (§39) when it ends.
class MatchStats {
  MatchStats({
    this.cardsPlayed = 0,
    this.acesPlayed = 0,
    this.twosPlayed = 0,
    this.longestChain = 0,
    this.resets101 = 0,
    this.bestComeback = 0,
    Map<String, int>? roundsWon,
    Map<String, List<String>>? cavalloSuits,
    Map<String, int>? suitsPlayed,
  }) : roundsWon = roundsWon ?? <String, int>{},
       cavalloSuits = cavalloSuits ?? <String, List<String>>{},
       suitsPlayed = suitsPlayed ?? <String, int>{};

  int cardsPlayed;
  int acesPlayed;
  int twosPlayed;

  /// §11/§37 — deepest Chain Storm reached, measured in stacked 2s.
  int longestChain;

  /// §15 — how many times a player landed on exactly 101.
  int resets101;

  /// §37 — largest points deficit the eventual winner came back from.
  int bestComeback;

  final Map<String, int> roundsWon;

  /// §41 "Maestro dei Semi" — suits each player has named with a Cavallo.
  final Map<String, List<String>> cavalloSuits;

  /// §39 "favourite suit" — how often the human played each suit.
  final Map<String, int> suitsPlayed;

  void recordCavalloSuit(String playerId, CardSuit suit) {
    final list = cavalloSuits.putIfAbsent(playerId, () => <String>[]);
    if (!list.contains(suit.key)) list.add(suit.key);
  }

  Map<String, dynamic> toJson() => {
    'cardsPlayed': cardsPlayed,
    'acesPlayed': acesPlayed,
    'twosPlayed': twosPlayed,
    'longestChain': longestChain,
    'resets101': resets101,
    'bestComeback': bestComeback,
    'roundsWon': roundsWon,
    'cavalloSuits': cavalloSuits,
    'suitsPlayed': suitsPlayed,
  };

  factory MatchStats.fromJson(Map<String, dynamic> json) => MatchStats(
    cardsPlayed: (json['cardsPlayed'] as num?)?.toInt() ?? 0,
    acesPlayed: (json['acesPlayed'] as num?)?.toInt() ?? 0,
    twosPlayed: (json['twosPlayed'] as num?)?.toInt() ?? 0,
    longestChain: (json['longestChain'] as num?)?.toInt() ?? 0,
    resets101: (json['resets101'] as num?)?.toInt() ?? 0,
    bestComeback: (json['bestComeback'] as num?)?.toInt() ?? 0,
    roundsWon: ((json['roundsWon'] as Map?) ?? const {}).map(
      (k, v) => MapEntry(k as String, (v as num).toInt()),
    ),
    cavalloSuits: ((json['cavalloSuits'] as Map?) ?? const {}).map(
      (k, v) => MapEntry(
        k as String,
        ((v as List?) ?? const []).map((e) => e as String).toList(),
      ),
    ),
    suitsPlayed: ((json['suitsPlayed'] as Map?) ?? const {}).map(
      (k, v) => MapEntry(k as String, (v as num).toInt()),
    ),
  );
}
