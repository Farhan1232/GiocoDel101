import 'dart:math';

import '../card_rank.dart';
import '../card_suit.dart';
import '../game_card.dart';

/// Builds and shuffles the 40-card Neapolitan deck (§4).
class DeckFactory {
  const DeckFactory._();

  static const int deckSize = 40;

  /// A fresh, ordered deck: every suit crossed with every rank, exactly once.
  static List<GameCard> ordered() => <GameCard>[
    for (final suit in CardSuit.values)
      for (final rank in CardRank.values) GameCard(suit, rank),
  ];

  /// A shuffled deck. Pass a seeded [Random] to make the shuffle reproducible
  /// (used by the daily challenge, §68).
  static List<GameCard> shuffled(Random random) {
    final deck = ordered();
    // Fisher-Yates: unbiased and independent of Dart's List.shuffle internals,
    // which keeps seeded challenges stable across SDK upgrades.
    for (var i = deck.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final tmp = deck[i];
      deck[i] = deck[j];
      deck[j] = tmp;
    }
    return deck;
  }
}
