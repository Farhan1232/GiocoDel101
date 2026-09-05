/// The four suits of the Neapolitan deck.
///
/// Order is meaningful: it drives the clockwise layout of the Suit Ritual
/// selector and the deterministic build order of [Deck].
enum CardSuit {
  denari,
  coppe,
  spade,
  bastoni;

  /// Stable key used for persistence and card ids. Never localise this.
  String get key => name;

  static CardSuit fromKey(String key) => CardSuit.values.firstWhere(
    (s) => s.key == key,
    orElse: () => throw FormatException('Unknown suit key: $key'),
  );
}
