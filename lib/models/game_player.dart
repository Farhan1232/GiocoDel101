import 'game_card.dart';
import 'player_type.dart';

/// A seat at the table. [score] and [eliminated] live for the whole match;
/// [hand] is reset at the start of every round.
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
    List<GameCard>? hand,
  }) : hand = hand ?? <GameCard>[];

  final String id;
  final String name;
  final PlayerType type;
  final String avatarId;

  /// Only meaningful for [PlayerType.bot].
  final BotDifficulty? difficulty;
  final BotPersonality? personality;

  /// Cumulative penalty points. Lower is better; 101 is the danger line.
  int score;

  /// §16 — knocked out of the match after overshooting the target score.
  bool eliminated;

  final List<GameCard> hand;

  bool get isHuman => type == PlayerType.humanLocal;
  bool get isBot => type == PlayerType.bot;
  int get cardCount => hand.length;

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
            .map((e) => GameCard.fromStorage(e as String))
            .toList(),
      );
}
