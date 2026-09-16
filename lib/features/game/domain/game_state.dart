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
    this.dealerSeat = 0,
    this.round = 1,
    this.direction = TurnDirection.clockwise,
    this.pendingDrawCount = 0,
    this.chainLength = 0,
    this.status = GameStatus.awaitingAction,
    this.winnerId,
    this.roundWinnerId,
    this.turnNumber = 0,
    this.hasDrawnThisTurn = false,
    this.penaltyResolvedThisTurn = false,
    this.lastCardDeclaredBy,
    this.drawnCard,
    this.lastAction,
    this.version = 0,
    this.turnStartedAt,
    this.turnDeadlineAt,
    this.seed = 0,
    this.isDailyChallenge = false,
    this.concealedDrawPileCount,
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

  /// 4 — the 2026-09-01 correction: only the Cavallo costs 25, the Fante is
  /// back to its printed 8. A state written under an older schema is
  /// migrated on read; see [fromJson].
  static const int schemaVersion = 4;

  /// The last schema whose `rules.scoreValues` still held a price list this
  /// build has superseded — schema ≤ 2 the printed table (Fante 8,
  /// Cavallo 9), schema 3 the short-lived Fante 25 / Cavallo 25 table.
  static const int legacyScoreSchema = 3;
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

  /// §12a — index into [players] of the seat that dealt this round. Rotates
  /// one seat clockwise (skipping eliminated seats) at every new deal, so a
  /// different player deals each round. Entirely independent of
  /// [currentSeat]: who deals and who leads are two different questions, and
  /// under [RoundStarterPolicy.previousRoundWinner] they usually differ.
  final int dealerSeat;

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

  /// §6b — set when the seat to act has just paid a pending +2 chain and is
  /// still on turn for its one legal continuation. Cleared by the next turn
  /// change and by every deal.
  final bool penaltyResolvedThisTurn;

  /// §16 — the seat that has declared "ULTIMA CARTA" for the turn now in
  /// progress, or null when nobody has. Public information: it is exactly
  /// what the other players are entitled to hear, and it says nothing about
  /// *which* cards are held.
  ///
  /// Scoped to one turn. Every turn change and every deal clears it, and so
  /// does anything that puts more cards in the declarer's hand, so a
  /// declaration can never be spent on a later hand than the one it was
  /// made for.
  final String? lastCardDeclaredBy;

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

  /// Set only on the server's *redacted* state, where the stock itself is
  /// withheld and only its size is published. Null for a real state.
  final int? concealedDrawPileCount;

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

  /// §3/§12a — the seats in the order the dealer serves them, as *indices*
  /// into [players].
  ///
  /// A dealer deals to their left first and themselves last, one card at a
  /// time, round after round. So the sequence starts one place clockwise of
  /// [dealerSeat], follows [direction], and wraps back so the dealer is
  /// served last. Eliminated seats drop out; the clockwise order of the rest
  /// is unchanged.
  ///
  ///     4 seats, dealer 0 -> [1, 2, 3, 0]
  ///     4 seats, dealer 1 -> [2, 3, 0, 1]
  ///     3 seats, dealer 2 -> [0, 1, 2]
  ///     2 seats, dealer 0 -> [1, 0]
  ///
  /// This is the **canonical** order: `GameEngine._deal` hands the cards out
  /// in exactly this sequence, and the table animates exactly this sequence.
  /// It lives on the state rather than in either of them so the cards a
  /// player receives and the cards they watch arrive can never disagree.
  ///
  /// Independent of who *leads* the round (§12): the previous round's closer
  /// starts play wherever they sit, and that is [currentSeat], not this.
  List<int> get dealingSeatOrder {
    final n = players.length;
    if (n == 0) return const [];
    final step = direction.step;
    final order = <int>[];
    var seat = dealerSeat.clamp(0, n - 1);
    // Exactly one lap: every seat is visited once, so a table of eliminated
    // seats terminates instead of spinning.
    for (var moved = 0; moved < n; moved++) {
      seat = (seat + step + n) % n;
      if (!players[seat].eliminated) order.add(seat);
    }
    return List.unmodifiable(order);
  }

  /// [dealingSeatOrder] as player ids — what the table's deal animation
  /// follows.
  List<String> get dealingOrder => [
    for (final seat in dealingSeatOrder) players[seat].id,
  ];

  Map<String, int> get scores => {for (final p in players) p.id: p.score};

  Map<String, List<GameCard>> get hands => {
    for (final p in players) p.id: p.hand,
  };

  GameCard get topCard => discardPile.last;

  /// Cards in the stock — real or, on a redacted state, as reported.
  int get drawPileCount => concealedDrawPileCount ?? drawPile.length;

  /// True for a snapshot received from the server: hidden information
  /// (seed, stock order, other hands) is absent, counts stand in for it.
  bool get isRedacted => concealedDrawPileCount != null;

  bool get isPenaltyPending => pendingDrawCount > 0;

  /// §16 — whether [playerId] currently holds a live "ULTIMA CARTA".
  bool hasDeclaredLastCard(String playerId) => lastCardDeclaredBy == playerId;

  /// §8 — whether a play this turn is confined to the card just drawn.
  ///
  /// The restriction is a consequence of choosing to draw. Penalty cards are
  /// taken under duress, so the continuation §6b grants after a chain is paid
  /// is an ordinary legal play, not a restricted one.
  bool get restrictsPlayToDrawnCard =>
      rules.restrictPlayToDrawnCard &&
      hasDrawnThisTurn &&
      !penaltyResolvedThisTurn;
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
    int? dealerSeat,
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
    bool? penaltyResolvedThisTurn,
    String? lastCardDeclaredBy,
    bool clearLastCardDeclaration = false,
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
    dealerSeat: dealerSeat ?? this.dealerSeat,
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
    penaltyResolvedThisTurn:
        penaltyResolvedThisTurn ?? this.penaltyResolvedThisTurn,
    lastCardDeclaredBy: clearLastCardDeclaration
        ? null
        : (lastCardDeclaredBy ?? this.lastCardDeclaredBy),
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
    concealedDrawPileCount: drawPile == null ? concealedDrawPileCount : null,
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
    'dealerSeat': dealerSeat,
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
    'penaltyResolvedThisTurn': penaltyResolvedThisTurn,
    'lastCardDeclaredBy': lastCardDeclaredBy,
    'drawnCard': drawnCard?.id,
    'lastAction': lastAction?.toJson(),
    'version': version,
    'turnStartedAt': turnStartedAt,
    'turnDeadlineAt': turnDeadlineAt,
    'seed': seed,
    'isDailyChallenge': isDailyChallenge,
    if (concealedDrawPileCount != null) 'drawPileCount': concealedDrawPileCount,
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
    // Saves written before the dealer rotated (§12a) carry no dealer; seat 0
    // dealt the first round of every match, so that is the safe stand-in. An
    // out-of-range value is treated the same way rather than refused: a
    // corrupt dealer must never cost a player their saved match.
    final rawDealer = (json['dealerSeat'] as num?)?.toInt() ?? 0;
    final dealerSeat = (rawDealer >= 0 && rawDealer < players.length)
        ? rawDealer
        : 0;
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
        _migrateRules(
          (json['rules'] as Map?)?.cast<String, dynamic>() ?? const {},
          (json['schema'] as num?)?.toInt() ?? 1,
        ),
      ),
      players: players,
      round: (json['round'] as num?)?.toInt() ?? 1,
      currentSeat: currentSeat,
      dealerSeat: dealerSeat,
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
      penaltyResolvedThisTurn:
          json['penaltyResolvedThisTurn'] as bool? ?? false,
      // Absent before §16: a restored match simply starts with nobody having
      // declared, which is the safe state — the seat to act can still
      // declare before it plays.
      lastCardDeclaredBy: json['lastCardDeclaredBy'] as String?,
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
      // app_private.redact_game_state drops `drawPile` for `drawPileCount`.
      concealedDrawPileCount: json['drawPile'] is List
          ? null
          : (json['drawPileCount'] as num?)?.toInt(),
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

  /// Brings a rules block written under an older [schemaVersion] up to date.
  ///
  /// Every migration so far is a price change: a save from schema ≤ 2
  /// carries the printed table (Fante 8, Cavallo 9) and one from schema 3
  /// the 2026-08-31 table (Fante 25, Cavallo 25). Resuming such a match
  /// under its own stale table would score the very cards the client
  /// re-priced at the old rate, so the table is dropped and
  /// [GameRules.defaultScoreValues] takes over.
  ///
  /// A table the *client* customised is left alone: only one that matches a
  /// superseded default exactly is treated as un-migrated.
  static Map<String, dynamic> _migrateRules(
    Map<String, dynamic> rules,
    int schema,
  ) {
    if (schema > legacyScoreSchema) return rules;
    final raw = rules['scoreValues'];
    if (raw is! Map) return rules;
    final isSupersededDefault = GameRules.supersededScoreValues.any(
      (table) => table.entries.every(
        (e) => (raw[e.key.key] as num?)?.toInt() == e.value,
      ),
    );
    if (!isSupersededDefault) return rules;
    return {...rules}..remove('scoreValues');
  }

  @override
  String toString() =>
      'GameState(v$version r$round ${status.key} seat=$currentSeat '
      'dealer=$dealerSeat top=$topCard suit=${activeSuit.key} '
      'pending=$pendingDrawCount)';
}
