import 'card_rank.dart';

/// How a Cavallo ("9") behaves when a +2 chain is pending.
///
/// `NEEDS_FINAL_RULE_CONFIRMATION` — see GAME_SPEC §6a. The brief says the 9
/// "can block a pending +2 according to the client's requested rules"; the
/// exact behaviour has not been confirmed, so every candidate is expressed
/// here and the default is provisional.
enum NineBlockMode {
  /// A Cavallo is not playable into a live chain (Session 1 behaviour).
  disabled,

  /// The Cavallo cancels the whole pending total. Nobody draws.
  cancel,

  /// The Cavallo passes the pending total on unchanged to the next player,
  /// who may stack a 2, block again, or draw it.
  passOn;

  String get key => name;

  static NineBlockMode fromKey(String key) => NineBlockMode.values.firstWhere(
    (m) => m.key == key,
    orElse: () => NineBlockMode.cancel,
  );
}

/// Which card may open the discard pile at the start of a round.
enum StarterCardPolicy {
  /// Deal until a non-action card (not Asso, 2 or Cavallo) can be turned up.
  /// The first player therefore never inherits a penalty nobody played.
  avoidActionCards,

  /// Turn up whatever comes. Its special effect is *not* applied.
  anyCard;

  String get key => name;

  static StarterCardPolicy fromKey(String key) =>
      StarterCardPolicy.values.firstWhere(
        (p) => p.key == key,
        orElse: () => StarterCardPolicy.avoidActionCards,
      );
}

/// Who leads the next round.
enum RoundStarterPolicy {
  /// The previous round's winner leads (falls back to the next surviving seat
  /// if the winner has been eliminated).
  previousRoundWinner,

  /// The seat after the previous round's winner leads (the winner "deals").
  seatAfterPreviousWinner;

  String get key => name;

  static RoundStarterPolicy fromKey(String key) =>
      RoundStarterPolicy.values.firstWhere(
        (p) => p.key == key,
        orElse: () => RoundStarterPolicy.previousRoundWinner,
      );
}

/// Direction of play around the table.
enum TurnDirection {
  clockwise,
  counterClockwise;

  String get key => name;

  int get step => this == TurnDirection.clockwise ? 1 : -1;

  static TurnDirection fromKey(String key) => TurnDirection.values.firstWhere(
    (d) => d.key == key,
    orElse: () => TurnDirection.clockwise,
  );
}

/// The single source of truth for every adjustable rule in Gioco del 101.
///
/// Nothing in this file may be duplicated inside widgets, controllers, bots
/// or the engine. If the client changes a house rule, it changes here and
/// nowhere else. Anything GAME_SPEC.md leaves open is a field here, with a
/// documented provisional default, rather than an assumption buried in code.
class GameRules {
  const GameRules({
    this.minPlayers = 2,
    this.maxPlayers = 4,
    this.startingHandSize = 5,
    this.allowVoluntaryDraw = true,
    this.playDrawnCardImmediately = true,
    this.restrictPlayToDrawnCard = false,
    this.stackDrawTwos = true,
    this.wildNineCanAlwaysPlay = true,
    this.nineBlockMode = NineBlockMode.cancel,
    this.nineBlockChangesSuit = true,
    this.exact101ResetsToZero = true,
    this.eliminateAbove101 = true,
    this.targetScore = 101,
    this.mustDrawBeforePassing = true,
    this.drawTwoPenalty = 2,
    this.pendingPenaltyAppliesAfterWin = false,
    this.starterCardPolicy = StarterCardPolicy.avoidActionCards,
    this.roundStarterPolicy = RoundStarterPolicy.previousRoundWinner,
    this.initialDirection = TurnDirection.clockwise,
    this.turnTimeLimitSeconds,
    this.scoreValues = defaultScoreValues,
  });

  /// §2 — seats at the table.
  final int minPlayers;
  final int maxPlayers;

  /// §3 — cards dealt to each player at the start of a round.
  final int startingHandSize;

  /// §8 — a player holding a playable card may still choose to draw instead.
  final bool allowVoluntaryDraw;

  /// §8 — a drawn card that happens to be legal may be played straight away.
  final bool playDrawnCardImmediately;

  /// §8 — after drawing, only the drawn card may be played this turn.
  /// `NEEDS_FINAL_RULE_CONFIRMATION`; provisional default: any legal card.
  final bool restrictPlayToDrawnCard;

  /// §6 — a 2 may be answered with another 2, compounding the penalty.
  final bool stackDrawTwos;

  /// §4 — the Cavallo ignores the active suit and may always be played.
  final bool wildNineCanAlwaysPlay;

  /// §6a — what a Cavallo does against a pending +2. Provisional.
  final NineBlockMode nineBlockMode;

  /// §6a — whether a blocking Cavallo still lets its player name the suit.
  /// Provisional default: yes, like any other Cavallo.
  final bool nineBlockChangesSuit;

  /// §11 — landing on exactly [targetScore] resets the player to zero.
  final bool exact101ResetsToZero;

  /// §11 — passing [targetScore] knocks the player out of the match.
  /// When false the match instead ends as soon as anyone overshoots, and the
  /// lowest score wins.
  final bool eliminateAbove101;

  /// §11 — the number the whole game is named after.
  final int targetScore;

  /// §8 — a turn cannot end without either playing or drawing.
  final bool mustDrawBeforePassing;

  /// §6 — cards added to the pending penalty by each 2 played.
  final int drawTwoPenalty;

  /// §10a — whether an unresolved +2 chain still hits the next player when the
  /// winning card ends the round. Off by default: the round simply stops.
  final bool pendingPenaltyAppliesAfterWin;

  /// §3 — which card may open the discard pile. Provisional.
  final StarterCardPolicy starterCardPolicy;

  /// §12 — who leads each new round. Provisional.
  final RoundStarterPolicy roundStarterPolicy;

  /// Direction of play. No card reverses it under the confirmed rules; it is
  /// carried in state so a server or a future house rule can flip it.
  final TurnDirection initialDirection;

  /// §14.4 — optional per-turn clock. The engine never reads the wall clock;
  /// it only stamps `turnDeadlineAt` when a caller supplies the time. What
  /// happens on expiry is *undefined* by the client and not implemented.
  final int? turnTimeLimitSeconds;

  /// §10 — penalty value of every rank left in hand at round end.
  final Map<CardRank, int> scoreValues;

  /// Asso 1 … Re 10, matching the printed rank of each card.
  static const Map<CardRank, int> defaultScoreValues = {
    CardRank.asso: 1,
    CardRank.due: 2,
    CardRank.tre: 3,
    CardRank.quattro: 4,
    CardRank.cinque: 5,
    CardRank.sei: 6,
    CardRank.sette: 7,
    CardRank.fante: 8,
    CardRank.cavallo: 9,
    CardRank.re: 10,
  };

  int valueOf(CardRank rank) => scoreValues[rank] ?? rank.value;

  bool get nineCanBlock => nineBlockMode != NineBlockMode.disabled;

  GameRules copyWith({
    int? minPlayers,
    int? maxPlayers,
    int? startingHandSize,
    bool? allowVoluntaryDraw,
    bool? playDrawnCardImmediately,
    bool? restrictPlayToDrawnCard,
    bool? stackDrawTwos,
    bool? wildNineCanAlwaysPlay,
    NineBlockMode? nineBlockMode,
    bool? nineBlockChangesSuit,
    bool? exact101ResetsToZero,
    bool? eliminateAbove101,
    int? targetScore,
    bool? mustDrawBeforePassing,
    int? drawTwoPenalty,
    bool? pendingPenaltyAppliesAfterWin,
    StarterCardPolicy? starterCardPolicy,
    RoundStarterPolicy? roundStarterPolicy,
    TurnDirection? initialDirection,
    int? turnTimeLimitSeconds,
    bool clearTurnTimeLimit = false,
    Map<CardRank, int>? scoreValues,
  }) {
    return GameRules(
      minPlayers: minPlayers ?? this.minPlayers,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      startingHandSize: startingHandSize ?? this.startingHandSize,
      allowVoluntaryDraw: allowVoluntaryDraw ?? this.allowVoluntaryDraw,
      playDrawnCardImmediately:
          playDrawnCardImmediately ?? this.playDrawnCardImmediately,
      restrictPlayToDrawnCard:
          restrictPlayToDrawnCard ?? this.restrictPlayToDrawnCard,
      stackDrawTwos: stackDrawTwos ?? this.stackDrawTwos,
      wildNineCanAlwaysPlay:
          wildNineCanAlwaysPlay ?? this.wildNineCanAlwaysPlay,
      nineBlockMode: nineBlockMode ?? this.nineBlockMode,
      nineBlockChangesSuit: nineBlockChangesSuit ?? this.nineBlockChangesSuit,
      exact101ResetsToZero: exact101ResetsToZero ?? this.exact101ResetsToZero,
      eliminateAbove101: eliminateAbove101 ?? this.eliminateAbove101,
      targetScore: targetScore ?? this.targetScore,
      mustDrawBeforePassing:
          mustDrawBeforePassing ?? this.mustDrawBeforePassing,
      drawTwoPenalty: drawTwoPenalty ?? this.drawTwoPenalty,
      pendingPenaltyAppliesAfterWin:
          pendingPenaltyAppliesAfterWin ?? this.pendingPenaltyAppliesAfterWin,
      starterCardPolicy: starterCardPolicy ?? this.starterCardPolicy,
      roundStarterPolicy: roundStarterPolicy ?? this.roundStarterPolicy,
      initialDirection: initialDirection ?? this.initialDirection,
      turnTimeLimitSeconds: clearTurnTimeLimit
          ? null
          : (turnTimeLimitSeconds ?? this.turnTimeLimitSeconds),
      scoreValues: scoreValues ?? this.scoreValues,
    );
  }

  Map<String, dynamic> toJson() => {
    'minPlayers': minPlayers,
    'maxPlayers': maxPlayers,
    'startingHandSize': startingHandSize,
    'allowVoluntaryDraw': allowVoluntaryDraw,
    'playDrawnCardImmediately': playDrawnCardImmediately,
    'restrictPlayToDrawnCard': restrictPlayToDrawnCard,
    'stackDrawTwos': stackDrawTwos,
    'wildNineCanAlwaysPlay': wildNineCanAlwaysPlay,
    'nineBlockMode': nineBlockMode.key,
    'nineBlockChangesSuit': nineBlockChangesSuit,
    'exact101ResetsToZero': exact101ResetsToZero,
    'eliminateAbove101': eliminateAbove101,
    'targetScore': targetScore,
    'mustDrawBeforePassing': mustDrawBeforePassing,
    'drawTwoPenalty': drawTwoPenalty,
    'pendingPenaltyAppliesAfterWin': pendingPenaltyAppliesAfterWin,
    'starterCardPolicy': starterCardPolicy.key,
    'roundStarterPolicy': roundStarterPolicy.key,
    'initialDirection': initialDirection.key,
    'turnTimeLimitSeconds': turnTimeLimitSeconds,
    'scoreValues': {
      for (final rank in CardRank.values)
        if (scoreValues.containsKey(rank)) rank.key: scoreValues[rank],
    },
  };

  factory GameRules.fromJson(Map<String, dynamic> json) {
    const fallback = GameRules();
    final rawScores = json['scoreValues'];
    Map<CardRank, int> scores = defaultScoreValues;
    if (rawScores is Map) {
      // Keep only the keys that were supplied so encode → decode → encode is
      // a fixed point; [valueOf] falls back to the printed value anyway.
      scores = {
        for (final rank in CardRank.values)
          if (rawScores.containsKey(rank.key))
            rank: (rawScores[rank.key] as num).toInt()
          else if (rawScores.containsKey(_legacyScoreKey(rank)))
            rank: (rawScores[_legacyScoreKey(rank)] as num).toInt(),
      };
    }
    return GameRules(
      minPlayers: (json['minPlayers'] as num?)?.toInt() ?? fallback.minPlayers,
      maxPlayers: (json['maxPlayers'] as num?)?.toInt() ?? fallback.maxPlayers,
      startingHandSize:
          (json['startingHandSize'] as num?)?.toInt() ??
          fallback.startingHandSize,
      allowVoluntaryDraw:
          json['allowVoluntaryDraw'] as bool? ?? fallback.allowVoluntaryDraw,
      playDrawnCardImmediately:
          json['playDrawnCardImmediately'] as bool? ??
          fallback.playDrawnCardImmediately,
      restrictPlayToDrawnCard:
          json['restrictPlayToDrawnCard'] as bool? ??
          fallback.restrictPlayToDrawnCard,
      stackDrawTwos: json['stackDrawTwos'] as bool? ?? fallback.stackDrawTwos,
      wildNineCanAlwaysPlay:
          json['wildNineCanAlwaysPlay'] as bool? ??
          fallback.wildNineCanAlwaysPlay,
      nineBlockMode: json['nineBlockMode'] == null
          ? fallback.nineBlockMode
          : NineBlockMode.fromKey(json['nineBlockMode'] as String),
      nineBlockChangesSuit:
          json['nineBlockChangesSuit'] as bool? ??
          fallback.nineBlockChangesSuit,
      exact101ResetsToZero:
          json['exact101ResetsToZero'] as bool? ??
          fallback.exact101ResetsToZero,
      eliminateAbove101:
          json['eliminateAbove101'] as bool? ?? fallback.eliminateAbove101,
      targetScore:
          (json['targetScore'] as num?)?.toInt() ?? fallback.targetScore,
      mustDrawBeforePassing:
          json['mustDrawBeforePassing'] as bool? ??
          fallback.mustDrawBeforePassing,
      drawTwoPenalty:
          (json['drawTwoPenalty'] as num?)?.toInt() ?? fallback.drawTwoPenalty,
      pendingPenaltyAppliesAfterWin:
          json['pendingPenaltyAppliesAfterWin'] as bool? ??
          fallback.pendingPenaltyAppliesAfterWin,
      starterCardPolicy: json['starterCardPolicy'] == null
          ? fallback.starterCardPolicy
          : StarterCardPolicy.fromKey(json['starterCardPolicy'] as String),
      roundStarterPolicy: json['roundStarterPolicy'] == null
          ? fallback.roundStarterPolicy
          : RoundStarterPolicy.fromKey(json['roundStarterPolicy'] as String),
      initialDirection: json['initialDirection'] == null
          ? fallback.initialDirection
          : TurnDirection.fromKey(json['initialDirection'] as String),
      turnTimeLimitSeconds: (json['turnTimeLimitSeconds'] as num?)?.toInt(),
      scoreValues: scores,
    );
  }

  static String _legacyScoreKey(CardRank rank) => switch (rank) {
    CardRank.asso => 'ace',
    CardRank.due => 'two',
    CardRank.tre => 'three',
    CardRank.quattro => 'four',
    CardRank.cinque => 'five',
    CardRank.sei => 'six',
    CardRank.sette => 'seven',
    _ => rank.key,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! GameRules) return false;
    if (other.minPlayers != minPlayers ||
        other.maxPlayers != maxPlayers ||
        other.startingHandSize != startingHandSize ||
        other.allowVoluntaryDraw != allowVoluntaryDraw ||
        other.playDrawnCardImmediately != playDrawnCardImmediately ||
        other.restrictPlayToDrawnCard != restrictPlayToDrawnCard ||
        other.stackDrawTwos != stackDrawTwos ||
        other.wildNineCanAlwaysPlay != wildNineCanAlwaysPlay ||
        other.nineBlockMode != nineBlockMode ||
        other.nineBlockChangesSuit != nineBlockChangesSuit ||
        other.exact101ResetsToZero != exact101ResetsToZero ||
        other.eliminateAbove101 != eliminateAbove101 ||
        other.targetScore != targetScore ||
        other.mustDrawBeforePassing != mustDrawBeforePassing ||
        other.drawTwoPenalty != drawTwoPenalty ||
        other.pendingPenaltyAppliesAfterWin != pendingPenaltyAppliesAfterWin ||
        other.starterCardPolicy != starterCardPolicy ||
        other.roundStarterPolicy != roundStarterPolicy ||
        other.initialDirection != initialDirection ||
        other.turnTimeLimitSeconds != turnTimeLimitSeconds) {
      return false;
    }
    for (final rank in CardRank.values) {
      if (other.valueOf(rank) != valueOf(rank)) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    startingHandSize,
    stackDrawTwos,
    nineBlockMode,
    targetScore,
    drawTwoPenalty,
    eliminateAbove101,
    exact101ResetsToZero,
  );
}
