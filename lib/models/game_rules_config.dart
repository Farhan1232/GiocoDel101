import 'card_rank.dart';

/// The single source of truth for every adjustable rule in Gioco del 101.
///
/// Nothing in this file may be duplicated inside widgets, controllers or the
/// engine. If the client asks to change a house rule, it changes here and
/// nowhere else (see README "Where game rules are configured").
class GameRulesConfig {
  const GameRulesConfig({
    this.startingHandSize = 5,
    this.allowVoluntaryDraw = true,
    this.playDrawnCardImmediately = true,
    this.stackDrawTwos = true,
    this.wildNineCanAlwaysPlay = true,
    this.exact101ResetsToZero = true,
    this.eliminateAbove101 = true,
    this.targetScore = 101,
    this.mustDrawBeforePassing = true,
    this.drawTwoPenalty = 2,
    this.pendingPenaltyAppliesAfterWin = false,
    this.scoreValues = defaultScoreValues,
  });

  /// §19 — cards dealt to each player at the start of a round.
  final int startingHandSize;

  /// §8 — a player holding a playable card may still choose to draw instead.
  final bool allowVoluntaryDraw;

  /// §8 — a drawn card that happens to be legal may be played straight away.
  final bool playDrawnCardImmediately;

  /// §10 — a 2 may be answered with another 2, compounding the penalty.
  final bool stackDrawTwos;

  /// §12 — the Cavallo ignores the active suit and may always be played.
  final bool wildNineCanAlwaysPlay;

  /// §15 — landing on exactly [targetScore] resets the player to zero.
  final bool exact101ResetsToZero;

  /// §16 — passing [targetScore] knocks the player out of the match.
  /// When false the match instead ends as soon as anyone overshoots, and the
  /// lowest score wins.
  final bool eliminateAbove101;

  /// §15/§16 — the number the whole game is named after.
  final int targetScore;

  /// §8 — a turn cannot end without either playing or drawing.
  final bool mustDrawBeforePassing;

  /// §10 — cards added to the pending penalty by each 2 played.
  final int drawTwoPenalty;

  /// §52 — whether an unresolved +2 chain still hits the next player when the
  /// winning card ends the round. Off by default: the round simply stops.
  final bool pendingPenaltyAppliesAfterWin;

  /// §14/§71 — penalty value of every rank left in hand at round end.
  final Map<CardRank, int> scoreValues;

  /// Ace 1 … Re 10, matching the printed rank of each card.
  static const Map<CardRank, int> defaultScoreValues = {
    CardRank.ace: 1,
    CardRank.two: 2,
    CardRank.three: 3,
    CardRank.four: 4,
    CardRank.five: 5,
    CardRank.six: 6,
    CardRank.seven: 7,
    CardRank.fante: 8,
    CardRank.cavallo: 9,
    CardRank.re: 10,
  };

  int valueOf(CardRank rank) => scoreValues[rank] ?? rank.value;

  GameRulesConfig copyWith({
    int? startingHandSize,
    bool? allowVoluntaryDraw,
    bool? playDrawnCardImmediately,
    bool? stackDrawTwos,
    bool? wildNineCanAlwaysPlay,
    bool? exact101ResetsToZero,
    bool? eliminateAbove101,
    int? targetScore,
    bool? mustDrawBeforePassing,
    int? drawTwoPenalty,
    bool? pendingPenaltyAppliesAfterWin,
    Map<CardRank, int>? scoreValues,
  }) {
    return GameRulesConfig(
      startingHandSize: startingHandSize ?? this.startingHandSize,
      allowVoluntaryDraw: allowVoluntaryDraw ?? this.allowVoluntaryDraw,
      playDrawnCardImmediately:
          playDrawnCardImmediately ?? this.playDrawnCardImmediately,
      stackDrawTwos: stackDrawTwos ?? this.stackDrawTwos,
      wildNineCanAlwaysPlay:
          wildNineCanAlwaysPlay ?? this.wildNineCanAlwaysPlay,
      exact101ResetsToZero: exact101ResetsToZero ?? this.exact101ResetsToZero,
      eliminateAbove101: eliminateAbove101 ?? this.eliminateAbove101,
      targetScore: targetScore ?? this.targetScore,
      mustDrawBeforePassing:
          mustDrawBeforePassing ?? this.mustDrawBeforePassing,
      drawTwoPenalty: drawTwoPenalty ?? this.drawTwoPenalty,
      pendingPenaltyAppliesAfterWin:
          pendingPenaltyAppliesAfterWin ?? this.pendingPenaltyAppliesAfterWin,
      scoreValues: scoreValues ?? this.scoreValues,
    );
  }

  Map<String, dynamic> toJson() => {
        'startingHandSize': startingHandSize,
        'allowVoluntaryDraw': allowVoluntaryDraw,
        'playDrawnCardImmediately': playDrawnCardImmediately,
        'stackDrawTwos': stackDrawTwos,
        'wildNineCanAlwaysPlay': wildNineCanAlwaysPlay,
        'exact101ResetsToZero': exact101ResetsToZero,
        'eliminateAbove101': eliminateAbove101,
        'targetScore': targetScore,
        'mustDrawBeforePassing': mustDrawBeforePassing,
        'drawTwoPenalty': drawTwoPenalty,
        'pendingPenaltyAppliesAfterWin': pendingPenaltyAppliesAfterWin,
        'scoreValues': {
          for (final e in scoreValues.entries) e.key.key: e.value,
        },
      };

  factory GameRulesConfig.fromJson(Map<String, dynamic> json) {
    const fallback = GameRulesConfig();
    final rawScores = json['scoreValues'];
    Map<CardRank, int> scores = defaultScoreValues;
    if (rawScores is Map) {
      scores = {
        for (final rank in CardRank.values)
          rank: (rawScores[rank.key] as num?)?.toInt() ?? rank.value,
      };
    }
    return GameRulesConfig(
      startingHandSize:
          (json['startingHandSize'] as num?)?.toInt() ?? fallback.startingHandSize,
      allowVoluntaryDraw:
          json['allowVoluntaryDraw'] as bool? ?? fallback.allowVoluntaryDraw,
      playDrawnCardImmediately: json['playDrawnCardImmediately'] as bool? ??
          fallback.playDrawnCardImmediately,
      stackDrawTwos: json['stackDrawTwos'] as bool? ?? fallback.stackDrawTwos,
      wildNineCanAlwaysPlay: json['wildNineCanAlwaysPlay'] as bool? ??
          fallback.wildNineCanAlwaysPlay,
      exact101ResetsToZero:
          json['exact101ResetsToZero'] as bool? ?? fallback.exact101ResetsToZero,
      eliminateAbove101:
          json['eliminateAbove101'] as bool? ?? fallback.eliminateAbove101,
      targetScore: (json['targetScore'] as num?)?.toInt() ?? fallback.targetScore,
      mustDrawBeforePassing: json['mustDrawBeforePassing'] as bool? ??
          fallback.mustDrawBeforePassing,
      drawTwoPenalty:
          (json['drawTwoPenalty'] as num?)?.toInt() ?? fallback.drawTwoPenalty,
      pendingPenaltyAppliesAfterWin:
          json['pendingPenaltyAppliesAfterWin'] as bool? ??
              fallback.pendingPenaltyAppliesAfterWin,
      scoreValues: scores,
    );
  }
}
