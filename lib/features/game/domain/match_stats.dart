import 'card_suit.dart';

/// Counters accumulated across a whole match, surfaced on the match-result
/// screen and folded into lifetime statistics when it ends. Immutable.
class MatchStats {
  MatchStats({
    this.cardsPlayed = 0,
    this.acesPlayed = 0,
    this.twosPlayed = 0,
    this.longestChain = 0,
    this.resets101 = 0,
    this.bestComeback = 0,
    Map<String, int> roundsWon = const {},
    Map<String, List<String>> cavalloSuits = const {},
    Map<String, int> suitsPlayed = const {},
  }) : roundsWon = Map.unmodifiable(roundsWon),
       cavalloSuits = Map.unmodifiable({
         for (final e in cavalloSuits.entries)
           e.key: List<String>.unmodifiable(e.value),
       }),
       suitsPlayed = Map.unmodifiable(suitsPlayed);

  final int cardsPlayed;
  final int acesPlayed;
  final int twosPlayed;

  /// Deepest chain reached, measured in stacked 2s.
  final int longestChain;

  /// How many times a player landed on exactly 101.
  final int resets101;

  /// Largest points deficit the eventual winner came back from.
  final int bestComeback;

  final Map<String, int> roundsWon;

  /// "Maestro dei Semi" — suits each player has named with a Cavallo.
  final Map<String, List<String>> cavalloSuits;

  /// "favourite suit" — how often each suit was played.
  final Map<String, int> suitsPlayed;

  MatchStats copyWith({
    int? cardsPlayed,
    int? acesPlayed,
    int? twosPlayed,
    int? longestChain,
    int? resets101,
    int? bestComeback,
    Map<String, int>? roundsWon,
    Map<String, List<String>>? cavalloSuits,
    Map<String, int>? suitsPlayed,
  }) => MatchStats(
    cardsPlayed: cardsPlayed ?? this.cardsPlayed,
    acesPlayed: acesPlayed ?? this.acesPlayed,
    twosPlayed: twosPlayed ?? this.twosPlayed,
    longestChain: longestChain ?? this.longestChain,
    resets101: resets101 ?? this.resets101,
    bestComeback: bestComeback ?? this.bestComeback,
    roundsWon: roundsWon ?? this.roundsWon,
    cavalloSuits: cavalloSuits ?? this.cavalloSuits,
    suitsPlayed: suitsPlayed ?? this.suitsPlayed,
  );

  MatchStats withCavalloSuit(String playerId, CardSuit suit) {
    final current = List<String>.of(cavalloSuits[playerId] ?? const []);
    if (!current.contains(suit.key)) current.add(suit.key);
    return copyWith(cavalloSuits: {...cavalloSuits, playerId: current});
  }

  MatchStats withSuitPlayed(CardSuit suit) => copyWith(
    suitsPlayed: {...suitsPlayed, suit.key: (suitsPlayed[suit.key] ?? 0) + 1},
  );

  MatchStats withRoundWon(String playerId) => copyWith(
    roundsWon: {...roundsWon, playerId: (roundsWon[playerId] ?? 0) + 1},
  );

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
