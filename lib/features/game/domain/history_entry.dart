import 'card_suit.dart';
import 'game_card.dart';

/// A replayable record of something that happened at the table.
///
/// The "Rivedi ultima mano" feature replays the tail of this list, so
/// entries must stay small and fully serialisable. This is the *log*; the
/// commands a player sends are [GameAction]s (see `game_action.dart`).
enum HistoryEntryType {
  play,
  draw,
  penaltyDraw,
  skip,
  suitChosen,
  chainBlocked,
  recycle,
  roundEnd,
  forfeit,
}

class HistoryEntry {
  const HistoryEntry({
    required this.type,
    required this.playerId,
    this.card,
    this.count,
    this.suit,
  });

  final HistoryEntryType type;
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

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
    type: HistoryEntryType.values.firstWhere(
      (t) => t.name == json['t'],
      orElse: () => HistoryEntryType.play,
    ),
    playerId: json['p'] as String? ?? '',
    card: json['c'] == null ? null : GameCard.fromStorage(json['c'] as String),
    count: (json['n'] as num?)?.toInt(),
    suit: json['s'] == null ? null : CardSuit.fromKey(json['s'] as String),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HistoryEntry &&
          other.type == type &&
          other.playerId == playerId &&
          other.card == card &&
          other.count == count &&
          other.suit == suit);

  @override
  int get hashCode => Object.hash(type, playerId, card, count, suit);
}
