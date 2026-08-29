import 'card_suit.dart';
import 'game_card.dart';

/// What the engine is waiting for right now.
enum TurnPhase {
  /// The current player must play a card, draw, or resolve a pending penalty.
  awaitingAction,

  /// A Cavallo was played and the active suit has not been named yet.
  awaitingSuitChoice,

  /// Somebody emptied their hand; scores are ready to be tallied.
  roundOver,

  /// Only one player is left standing.
  matchOver,
}

/// Everything that lives for exactly one round.
///
/// Hands are stored on [GamePlayer] because they belong to a seat; the piles,
/// the active suit and the turn cursor belong here.
class RoundState {
  RoundState({
    required this.drawPile,
    required this.discardPile,
    required this.activeSuit,
    required this.currentIndex,
    this.pendingPenalty = 0,
    this.chainLength = 0,
    this.hasDrawnThisTurn = false,
    this.drawnCard,
    this.phase = TurnPhase.awaitingAction,
    this.roundWinnerId,
    this.turnNumber = 0,
    Map<String, int>? drawsByPlayer,
    List<GameCard>? playedCards,
    Map<String, List<String>>? voidSuits,
  }) : drawsByPlayer = drawsByPlayer ?? <String, int>{},
       playedCards = playedCards ?? <GameCard>[],
       voidSuits = voidSuits ?? <String, List<String>>{};

  /// Face-down stock. The last element is the next card to be dealt.
  final List<GameCard> drawPile;

  /// Face-up pile. The last element is the visible top card.
  final List<GameCard> discardPile;

  /// The suit that must currently be matched. Diverges from the top card's
  /// own suit only after a Cavallo names a new one.
  CardSuit activeSuit;

  /// Index into `MatchState.players` of the seat currently to act.
  int currentIndex;

  /// §10 — cards the next player owes because of an unanswered chain of 2s.
  int pendingPenalty;

  /// §11 — how many 2s deep the current Chain Storm is.
  int chainLength;

  /// §8 — a turn may not end without playing or drawing.
  bool hasDrawnThisTurn;

  /// §8 — set when a freshly drawn card is legal and may be played at once.
  GameCard? drawnCard;

  TurnPhase phase;
  String? roundWinnerId;
  int turnNumber;

  /// §41 "Mano Perfetta" — how many cards each seat drew this round.
  final Map<String, int> drawsByPlayer;

  /// Every card played this round, in order. Survives a discard recycle, so
  /// the Hard bot's card counting keeps working (§21). Public information:
  /// anybody watching the table sees the same list.
  final List<GameCard> playedCards;

  /// Suits a seat appeared to be missing when they last had to draw.
  /// An inference from public play, not a peek at anyone's hand.
  final Map<String, List<String>> voidSuits;

  void noteVoid(String playerId, CardSuit suit) {
    final list = voidSuits.putIfAbsent(playerId, () => <String>[]);
    if (!list.contains(suit.key)) list.add(suit.key);
  }

  void clearVoid(String playerId, CardSuit suit) {
    voidSuits[playerId]?.remove(suit.key);
  }

  GameCard get topCard => discardPile.last;

  bool get isPenaltyPending => pendingPenalty > 0;

  Map<String, dynamic> toJson() => {
    'drawPile': drawPile.map((c) => c.toStorage()).toList(),
    'discardPile': discardPile.map((c) => c.toStorage()).toList(),
    'activeSuit': activeSuit.key,
    'currentIndex': currentIndex,
    'pendingPenalty': pendingPenalty,
    'chainLength': chainLength,
    'hasDrawnThisTurn': hasDrawnThisTurn,
    'drawnCard': drawnCard?.toStorage(),
    'phase': phase.name,
    'roundWinnerId': roundWinnerId,
    'turnNumber': turnNumber,
    'drawsByPlayer': drawsByPlayer,
    'playedCards': playedCards.map((c) => c.toStorage()).toList(),
    'voidSuits': voidSuits,
  };

  factory RoundState.fromJson(Map<String, dynamic> json) {
    List<GameCard> cards(Object? raw) => ((raw as List?) ?? const [])
        .map((e) => GameCard.fromStorage(e as String))
        .toList();
    final discard = cards(json['discardPile']);
    if (discard.isEmpty) {
      throw const FormatException('Round has an empty discard pile');
    }
    return RoundState(
      drawPile: cards(json['drawPile']),
      discardPile: discard,
      activeSuit: CardSuit.fromKey(json['activeSuit'] as String),
      currentIndex: (json['currentIndex'] as num?)?.toInt() ?? 0,
      pendingPenalty: (json['pendingPenalty'] as num?)?.toInt() ?? 0,
      chainLength: (json['chainLength'] as num?)?.toInt() ?? 0,
      hasDrawnThisTurn: json['hasDrawnThisTurn'] as bool? ?? false,
      drawnCard: json['drawnCard'] == null
          ? null
          : GameCard.fromStorage(json['drawnCard'] as String),
      phase: TurnPhase.values.firstWhere(
        (p) => p.name == json['phase'],
        orElse: () => TurnPhase.awaitingAction,
      ),
      roundWinnerId: json['roundWinnerId'] as String?,
      turnNumber: (json['turnNumber'] as num?)?.toInt() ?? 0,
      drawsByPlayer: ((json['drawsByPlayer'] as Map?) ?? const {}).map(
        (k, v) => MapEntry(k as String, (v as num).toInt()),
      ),
      playedCards: cards(json['playedCards']),
      voidSuits: ((json['voidSuits'] as Map?) ?? const {}).map(
        (k, v) => MapEntry(
          k as String,
          ((v as List?) ?? const []).map((e) => e as String).toList(),
        ),
      ),
    );
  }
}
