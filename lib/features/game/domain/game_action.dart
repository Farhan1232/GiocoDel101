import 'card_suit.dart';
import 'game_card.dart';

/// A replayable record of something that happened at the table.
///
/// §36 — the "Rivedi ultima mano" feature replays the tail of this list, so
/// entries must stay small and fully serialisable.
enum GameActionType {
  play,
  draw,
  penaltyDraw,
  skip,
  suitChosen,
  recycle,
  roundEnd,
}

class GameAction {
  const GameAction({
    required this.type,
    required this.playerId,
    this.card,
    this.count,
    this.suit,
  });

  final GameActionType type;
  final String playerId;
  final GameCard? card;
  final int? count;
  final CardSuit? suit;

  Map<String, dynamic> toJson() => {
        't': type.name,
        'p': playerId,
        if (card != null) 'c': card!.toStorage(),
        if (count != null) 'n': count,
        if (suit != null) 's': suit!.key,
      };

  factory GameAction.fromJson(Map<String, dynamic> json) => GameAction(
        type: GameActionType.values.firstWhere(
          (t) => t.name == json['t'],
          orElse: () => GameActionType.play,
        ),
        playerId: json['p'] as String? ?? '',
        card: json['c'] == null ? null : GameCard.fromStorage(json['c'] as String),
        count: (json['n'] as num?)?.toInt(),
        suit: json['s'] == null ? null : CardSuit.fromKey(json['s'] as String),
      );
}
