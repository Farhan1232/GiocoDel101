import 'card_rank.dart';
import 'card_suit.dart';

/// A single immutable card. The 40-card deck contains no duplicates, so
/// [id] doubles as a stable widget key across every animation.
class GameCard {
  const GameCard(this.suit, this.rank);

  final CardSuit suit;
  final CardRank rank;

  /// Unique within a deck, e.g. `denari_cavallo`.
  String get id => '${suit.key}_${rank.key}';

  /// Numeric rank convenience accessor, 1..10.
  int get value => rank.value;

  bool get isAce => rank == CardRank.ace;
  bool get isTwo => rank == CardRank.two;
  bool get isCavallo => rank == CardRank.cavallo;

  /// True for any card carrying a special action under the default rules.
  bool get isAction => isAce || isTwo || isCavallo;

  String toStorage() => id;

  static GameCard fromStorage(String raw) {
    final parts = raw.split('_');
    if (parts.length != 2) {
      throw FormatException('Malformed card token: $raw');
    }
    return GameCard(CardSuit.fromKey(parts[0]), CardRank.fromKey(parts[1]));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GameCard && other.suit == suit && other.rank == rank);

  @override
  int get hashCode => Object.hash(suit, rank);

  @override
  String toString() => id;
}
