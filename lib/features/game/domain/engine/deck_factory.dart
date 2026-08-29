import 'dart:math';

import '../game_card.dart';

/// Builds and shuffles the 40-card Neapolitan deck.
class DeckFactory {
  const DeckFactory._();

  static const int deckSize = Deck.size;

  /// A fresh, ordered deck: every suit crossed with every rank, exactly once.
  static List<GameCard> ordered() => List.of(Deck.standard);

  /// A shuffled deck. Pass a seeded [Random] to make the shuffle reproducible.
  static List<GameCard> shuffled(Random random) => shuffle(ordered(), random);

  /// Fisher-Yates in place: unbiased and independent of Dart's
  /// `List.shuffle` internals, which keeps seeded deals stable across SDK
  /// upgrades. Returns [cards] for chaining.
  static List<GameCard> shuffle(List<GameCard> cards, Random random) {
    for (var i = cards.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final tmp = cards[i];
      cards[i] = cards[j];
      cards[j] = tmp;
    }
    return cards;
  }
}
