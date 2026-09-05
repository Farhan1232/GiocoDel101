import 'game_card.dart';
import 'player_type.dart';

/// A seat at the table. Immutable: the engine produces a new [GamePlayer]
/// whenever a hand, a score or the eliminated flag changes.
///
/// [score] and [eliminated] live for the whole match; [hand] is reset at the
/// start of every round.
class GamePlayer {
  GamePlayer({
    required this.id,
    required this.name,
    required this.type,
    required this.avatarId,
    this.difficulty,
    this.personality,
    this.score = 0,
    this.eliminated = false,
    List<GameCard> hand = const [],
    this.concealedCount,
  }) : hand = List.unmodifiable(hand);

  final String id;
  final String name;
  final PlayerType type;
  final String avatarId;

  /// Only meaningful for [PlayerType.bot].
  final BotDifficulty? difficulty;
  final BotPersonality? personality;

  /// Cumulative penalty points. Lower is better; 101 is the danger line.
  final int score;

  /// Knocked out of the match after overshooting the target score.
  final bool eliminated;

  /// Private hand. Only the owner (and the engine) may see it.
  final List<GameCard> hand;

  /// Set only on a seat received from the server's *redacted* state: the
  /// number of cards this player holds when the cards themselves are not
  /// ours to see. Null whenever [hand] is the real hand.
  final int? concealedCount;

  bool get isHuman => type == PlayerType.humanLocal;
  bool get isBot => type == PlayerType.bot;
  int get cardCount => concealedCount ?? hand.length;

  /// True when this seat's cards are hidden from the viewer (online).
  bool get isConcealed => concealedCount != null;

  GamePlayer copyWith({
    String? name,
    String? avatarId,
    int? score,
    bool? eliminated,
    List<GameCard>? hand,
  }) => GamePlayer(
    id: id,
    name: name ?? this.name,
    type: type,
    avatarId: avatarId ?? this.avatarId,
    difficulty: difficulty,
    personality: personality,
    score: score ?? this.score,
    eliminated: eliminated ?? this.eliminated,
    hand: hand ?? this.hand,
    // Giving a seat its real hand un-conceals it.
    concealedCount: hand == null ? concealedCount : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.key,
    'avatarId': avatarId,
    'difficulty': difficulty?.key,
    'personality': personality?.key,
    'score': score,
    'eliminated': eliminated,
    'hand': hand.map((c) => c.toStorage()).toList(),
    if (concealedCount != null) 'handCount': concealedCount,
  };

  factory GamePlayer.fromJson(Map<String, dynamic> json) => GamePlayer(
    id: json['id'] as String,
    name: json['name'] as String,
    type: PlayerType.fromKey(json['type'] as String? ?? 'bot'),
    avatarId: json['avatarId'] as String? ?? 'marco',
    difficulty: json['difficulty'] == null
        ? null
        : BotDifficulty.fromKey(json['difficulty'] as String),
    personality: json['personality'] == null
        ? null
        : BotPersonality.fromKey(json['personality'] as String),
    score: (json['score'] as num?)?.toInt() ?? 0,
    eliminated: json['eliminated'] as bool? ?? false,
    hand: ((json['hand'] as List?) ?? const [])
        .map((e) => GameCard.fromJson(e))
        .toList(),
    // The server's redacted state replaces `hand` with `handCount`
    // (app_private.redact_game_state); a real hand always wins.
    concealedCount: json['hand'] is List
        ? null
        : (json['handCount'] as num?)?.toInt(),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GamePlayer &&
          other.id == id &&
          other.name == name &&
          other.type == type &&
          other.avatarId == avatarId &&
          other.difficulty == difficulty &&
          other.personality == personality &&
          other.score == score &&
          other.eliminated == eliminated &&
          other.concealedCount == concealedCount &&
          _sameCards(other.hand, hand));

  @override
  int get hashCode =>
      Object.hash(id, name, type, score, eliminated, Object.hashAll(hand));

  static bool _sameCards(List<GameCard> a, List<GameCard> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() => 'GamePlayer($id, score: $score, hand: $hand)';
}
