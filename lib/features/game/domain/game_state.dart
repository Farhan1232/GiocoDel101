import 'card_suit.dart';
import 'game_action.dart';
import 'game_card.dart';
import 'game_player.dart';
import 'game_rules.dart';
import 'history_entry.dart';
import 'match_stats.dart';
import 'round_result.dart';

/// How the seats are filled. Online play will add a value here; the engine
/// never branches on it.
enum GameMode {
  vsComputer,
  passAndPlay;

  String get key => name;

  static GameMode fromKey(String key) => GameMode.values.firstWhere(
    (m) => m.key == key,
    orElse: () => GameMode.vsComputer,
  );
}

/// What the engine is waiting for right now.
enum GameStatus {
  /// The current player must play a card, draw, or resolve a pending penalty.
  awaitingAction,

  /// A Cavallo was played and the active suit has not been named yet.
  awaitingSuitChoice,

  /// Somebody emptied their hand; scores are tallied; the next round has not
  /// been dealt.
  roundOver,

  /// The match has a winner. No further action is legal.
  finished;

  String get key => name;

  static GameStatus fromKey(String key) => GameStatus.values.firstWhere(
    (s) => s.key == key,
    // Pre-Session-2 saves used `TurnPhase` names; `matchOver` maps to finished.
    orElse: () =>
        key == 'matchOver' ? GameStatus.finished : GameStatus.awaitingAction,
  );
}

/// The complete, immutable state of one match.
///
/// This is the *only* thing the engine reads and the only thing it produces.
/// It has no Flutter types, no timers and no I/O, and it round-trips through
/// [toJson] / [GameState.fromJson] without semantic loss, so the same object
/// can be persisted locally today and stored by an authoritative server
/// later. `version` increases by one for every applied action.
class GameState {
  GameState({
    required this.gameId,
    required this.mode,
    required this.rules,
    required List<GamePlayer> players,
    required List<GameCard> drawPile,
    required List<GameCard> discardPile,
    required this.activeSuit,
    required this.currentSeat,
    this.round = 1,
    this.direction = TurnDirection.clockwise,
    this.pendingDrawCount = 0,
    this.chainLength = 0,
    this.status = GameStatus.awaitingAction,
    this.winnerId,
    this.roundWinnerId,
    this.turnNumber = 0,
    this.hasDrawnThisTurn = false,
    this.drawnCard,
    this.lastAction,
    this.version = 0,
    this.turnStartedAt,
    this.turnDeadlineAt,
    this.seed = 0,
    this.isDailyChallenge = false,
    MatchStats? stats,
    List<HistoryEntry> history = const [],
    List<GameCard> playedCards = const [],
    Map<String, int> drawsByPlayer = const {},
    Map<String, List<String>> voidSuits = const {},
    this.lastRoundResult,
  }) : players = List.unmodifiable(players),
       drawPile = List.unmodifiable(drawPile),
       discardPile = List.unmodifiable(discardPile),
       stats = stats ?? MatchStats(),
       history = List.unmodifiable(history),
       playedCards = List.unmodifiable(playedCards),
       drawsByPlayer = Map.unmodifiable(drawsByPlayer),
       voidSuits = Map.unmodifiable({
         for (final e in voidSuits.entries)
           e.key: List<String>.unmodifiable(e.value),
       });

  static const int schemaVersion = 2;
  static const int historyLimit = 40;

  /// Stable identifier of this match. Locally a random token; online, the
  /// server's row id.
  final String gameId;

  final GameMode mode;
  final GameRules rules;

  /// Seat order, fixed for the whole match. Index 0 is the local human in
  /// `vsComputer` mode. Each player's hand and score live on the player.
  final List<GamePlayer> players;

  /// 1-based round counter.
  final int round;

  /// Index into [players] of the seat currently to act.
  final int currentSeat;

  final TurnDirection direction;

  /// Face-down stock. The last element is the next card to be dealt.
  final List<GameCard> drawPile;

  /// Face-up pile. The last element is the visible top card.
  final List<GameCard> discardPile;

  /// The suit that must currently be matched. Diverges from the top card's
  /// own suit only after a Cavallo names a new one.
  final CardSuit activeSuit;

  /// §6 — cards the next player owes because of an unanswered chain of 2s.
  final int pendingDrawCount;

  /// §6 — how many 2s deep the current chain is.
  final int chainLength;

  final GameStatus status;

  /// Match winner, set once [status] is [GameStatus.finished].
  final String? winnerId;

  /// Winner of the most recently finished round.
  final String? roundWinnerId;

  /// Turns taken this round.
  final int turnNumber;

  /// §8 — a turn may not end without playing or drawing.
  final bool hasDrawnThisTurn;

  /// §8 — set when a freshly drawn card is legal and may be played at once.
  final GameCard? drawnCard;

  /// The last action successfully applied.
  final GameAction? lastAction;

  /// Increments by one for every applied action. Actions carry the version
  /// they were built against so stale or duplicate submissions are refused.
  final int version;

  /// Epoch milliseconds, supplied by the caller — the engine has no clock.
  final int? turnStartedAt;
  final int? turnDeadlineAt;

  /// Shuffle seed. Every deal and every reshuffle derives from it and from
  /// [version], so the same state always produces the same next state.
  final int seed;
  final bool isDailyChallenge;

  final MatchStats stats;

  /// Bounded tail of recent events, replayed by "Rivedi ultima mano".
  final List<HistoryEntry> history;

  /// Every card played this round, in order. Public information.
  final List<GameCard> playedCards;

  /// How many cards each seat drew this round ("Mano Perfetta").
  final Map<String, int> drawsByPlayer;

  /// Suits a seat appeared to be missing when they last had to draw. An
  /// inference from public play, not a peek at anyone's hand.
  final Map<String, List<String>> voidSuits;

  /// Populated while [status] is [GameStatus.roundOver] or finished.
  final RoundResult? lastRoundResult;

  // ---------------------------------------------------------------- derived

  GamePlayer get currentPlayer => players[currentSeat];
  String get currentPlayerId => currentPlayer.id;

  List<String> get seatOrder => players.map((p) => p.id).toList();

  Map<String, int> get scores => {for (final p in players) p.id: p.score};

  Map<String, List<GameCard>> get hands => {
    for (final p in players) p.id: p.hand,
  };

  GameCard get topCard => discardPile.last;

  bool get isPenaltyPending => pendingDrawCount > 0;
  bool get isRoundOver =>
      status == GameStatus.roundOver || status == GameStatus.finished;
  bool get isFinished => status == GameStatus.finished;

  int get playerCount => players.length;

  Iterable<GamePlayer> get activePlayers => players.where((p) => !p.eliminated);

  GamePlayer? playerById(String id) {
    for (final p in players) {
      if (p.id == id) return p;
    }
    return null;
  }

  int seatOf(String playerId) => players.indexWhere((p) => p.id == playerId);

  List<GameCard> handOf(String playerId) =>
      playerById(playerId)?.hand ?? const [];

  /// Every card in play, wherever it is. Always 40 for a valid state.
  int get totalCards =>
      drawPile.length +
      discardPile.length +
      players.fold(0, (n, p) => n + p.hand.length);

  // --------------------------------------------------------------- copying

  GameState copyWith({
    List<GamePlayer>? players,
    int? round,
    int? currentSeat,
    TurnDirection? direction,
    List<GameCard>? drawPile,
    List<GameCard>? discardPile,
    CardSuit? activeSuit,
    int? pendingDrawCount,
    int? chainLength,
    GameStatus? status,
    String? winnerId,
    String? roundWinnerId,
    bool clearRoundWinner = false,
    int? turnNumber,
    bool? hasDrawnThisTurn,
    GameCard? drawnCard,
    bool clearDrawnCard = false,
    GameAction? lastAction,
    int? version,
    int? turnStartedAt,
    int? turnDeadlineAt,
    bool clearTurnClock = false,
    MatchStats? stats,
    List<HistoryEntry>? history,
    List<GameCard>? playedCards,
    Map<String, int>? drawsByPlayer,
    Map<String, List<String>>? voidSuits,
    RoundResult? lastRoundResult,
    bool clearLastRoundResult = false,
  }) => GameState(
    gameId: gameId,
    mode: mode,
    rules: rules,
    players: players ?? this.players,
    round: round ?? this.round,
    currentSeat: currentSeat ?? this.currentSeat,
    direction: direction ?? this.direction,
    drawPile: drawPile ?? this.drawPile,
    discardPile: discardPile ?? this.discardPile,
    activeSuit: activeSuit ?? this.activeSuit,
    pendingDrawCount: pendingDrawCount ?? this.pendingDrawCount,
    chainLength: chainLength ?? this.chainLength,
    status: status ?? this.status,
    winnerId: winnerId ?? this.winnerId,
    roundWinnerId: clearRoundWinner
        ? null
        : (roundWinnerId ?? this.roundWinnerId),
    turnNumber: turnNumber ?? this.turnNumber,
    hasDrawnThisTurn: hasDrawnThisTurn ?? this.hasDrawnThisTurn,
    drawnCard: clearDrawnCard ? null : (drawnCard ?? this.drawnCard),
    lastAction: lastAction ?? this.lastAction,
    version: version ?? this.version,
    turnStartedAt: clearTurnClock
        ? null
        : (turnStartedAt ?? this.turnStartedAt),
    turnDeadlineAt: clearTurnClock
        ? null
        : (turnDeadlineAt ?? this.turnDeadlineAt),
    seed: seed,
    isDailyChallenge: isDailyChallenge,
    stats: stats ?? this.stats,
    history: history ?? this.history,
    playedCards: playedCards ?? this.playedCards,
    drawsByPlayer: drawsByPlayer ?? this.drawsByPlayer,
    voidSuits: voidSuits ?? this.voidSuits,
    lastRoundResult: clearLastRoundResult
        ? null
        : (lastRoundResult ?? this.lastRoundResult),
  );

  /// Returns a copy with [player] replacing the seat that shares its id.
  GameState withPlayer(GamePlayer player) => copyWith(
    players: [for (final p in players) p.id == player.id ? player : p],
  );

  GameState withHistory(HistoryEntry entry) {
    final next = [...history, entry];
    return copyWith(
      history: next.length > historyLimit
          ? next.sublist(next.length - historyLimit)
          : next,
    );
  }

  // --------------------------------------------------------------- json

  Map<String, dynamic> toJson() => {
    'schema': schemaVersion,
    'gameId': gameId,
    'mode': mode.key,
    'rules': rules.toJson(),
    'players': players.map((p) => p.toJson()).toList(),
    'round': round,
    'currentSeat': currentSeat,
    'direction': direction.key,
    'drawPile': drawPile.map((c) => c.id).toList(),
    'discardPile': discardPile.map((c) => c.id).toList(),
    'activeSuit': activeSuit.key,
    'pendingDrawCount': pendingDrawCount,
    'chainLength': chainLength,
    'status': status.key,
    'winnerId': winnerId,
    'roundWinnerId': roundWinnerId,
    'turnNumber': turnNumber,
    'hasDrawnThisTurn': hasDrawnThisTurn,
    'drawnCard': drawnCard?.id,
    'lastAction': lastAction?.toJson(),
    'version': version,
    'turnStartedAt': turnStartedAt,
    'turnDeadlineAt': turnDeadlineAt,
    'seed': seed,
    'isDailyChallenge': isDailyChallenge,
    'stats': stats.toJson(),
    'history': history.map((h) => h.toJson()).toList(),
    'playedCards': playedCards.map((c) => c.id).toList(),
    'drawsByPlayer': drawsByPlayer,
    'voidSuits': voidSuits,
    'lastRoundResult': lastRoundResult?.toJson(),
  };

  /// Throws [FormatException] on structurally invalid data so the caller can
  /// discard a corrupt save rather than booting into a broken table.
  factory GameState.fromJson(Map<String, dynamic> json) {
    List<GameCard> cards(Object? raw) =>
        ((raw as List?) ?? const []).map((e) => GameCard.fromJson(e)).toList();

    final players = ((json['players'] as List?) ?? const [])
        .map((e) => GamePlayer.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
    if (players.length < 2) {
      throw const FormatException('A match needs at least two seats');
    }
    final ids = players.map((p) => p.id).toSet();
    if (ids.length != players.length) {
      throw const FormatException('Duplicate player id');
    }
    final discard = cards(json['discardPile']);
    if (discard.isEmpty) {
      throw const FormatException('Empty discard pile');
    }
    final currentSeat = (json['currentSeat'] as num?)?.toInt() ?? 0;
    if (currentSeat < 0 || currentSeat >= players.length) {
      throw const FormatException('Turn cursor points outside the table');
    }
    final rawActiveSuit = json['activeSuit'];
    if (rawActiveSuit is! String) {
      throw const FormatException('Missing active suit');
    }
    final rawLast = json['lastAction'];
    final rawResult = json['lastRoundResult'];

    return GameState(
      gameId: json['gameId'] as String? ?? '',
      mode: GameMode.fromKey(json['mode'] as String? ?? 'vsComputer'),
      rules: GameRules.fromJson(
        (json['rules'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      players: players,
      round: (json['round'] as num?)?.toInt() ?? 1,
      currentSeat: currentSeat,
      direction: TurnDirection.fromKey(
        json['direction'] as String? ?? 'clockwise',
      ),
      drawPile: cards(json['drawPile']),
      discardPile: discard,
      activeSuit: CardSuit.fromKey(rawActiveSuit),
      pendingDrawCount: (json['pendingDrawCount'] as num?)?.toInt() ?? 0,
      chainLength: (json['chainLength'] as num?)?.toInt() ?? 0,
      status: GameStatus.fromKey(json['status'] as String? ?? 'awaitingAction'),
      winnerId: json['winnerId'] as String?,
      roundWinnerId: json['roundWinnerId'] as String?,
      turnNumber: (json['turnNumber'] as num?)?.toInt() ?? 0,
      hasDrawnThisTurn: json['hasDrawnThisTurn'] as bool? ?? false,
      drawnCard: json['drawnCard'] == null
          ? null
          : GameCard.fromJson(json['drawnCard']),
      lastAction: rawLast is Map
          ? GameAction.fromJson(rawLast.cast<String, dynamic>())
          : null,
      version: (json['version'] as num?)?.toInt() ?? 0,
      turnStartedAt: (json['turnStartedAt'] as num?)?.toInt(),
      turnDeadlineAt: (json['turnDeadlineAt'] as num?)?.toInt(),
      seed: (json['seed'] as num?)?.toInt() ?? 0,
      isDailyChallenge: json['isDailyChallenge'] as bool? ?? false,
      stats: MatchStats.fromJson(
        (json['stats'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      history: ((json['history'] as List?) ?? const [])
          .map((e) => HistoryEntry.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      playedCards: cards(json['playedCards']),
      drawsByPlayer: ((json['drawsByPlayer'] as Map?) ?? const {}).map(
        (k, v) => MapEntry(k as String, (v as num).toInt()),
      ),
      voidSuits: ((json['voidSuits'] as Map?) ?? const {}).map(
        (k, v) => MapEntry(
          k as String,
          ((v as List?) ?? const []).map((e) => e as String).toList(),
        ),
      ),
      lastRoundResult: rawResult is Map
          ? RoundResult.fromJson(rawResult.cast<String, dynamic>())
          : null,
    );
  }

  @override
  String toString() =>
      'GameState(v$version r$round ${status.key} seat=$currentSeat '
      'top=$topCard suit=${activeSuit.key} pending=$pendingDrawCount)';
}
