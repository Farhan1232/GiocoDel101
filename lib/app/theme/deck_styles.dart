import '../localization/app_strings.dart';

/// §5 — how the card FACES are printed.
///
/// The default (and always free) deck is the authentic Carte Napoletane
/// artwork in `assets/cards/`. The one paid alternative, "Mazzo Inciso Oro"
/// (`gioco101_deck_special` → entitlement `deck.special`), renders the app's
/// own original engraved vector deck — the hand-drawn painter that predates
/// the printed assets — finished in warm gold. Original in-house art only;
/// no third-party deck is copied, and the Napoletane deck is never replaced,
/// only optionally restyled for the player who bought it.
class DeckStyle {
  const DeckStyle({
    required this.id,
    required this.name,
    required this.entitlementId,
  });

  final String id;
  final String name;

  /// Server entitlement that unlocks this style; null = free.
  final String? entitlementId;

  String get tagline => switch (id) {
    'inciso_oro' => Strings.s.deckTaglineIncisoOro,
    _ => Strings.s.deckTaglineNapoletane,
  };
}

class DeckStyles {
  const DeckStyles._();

  /// The authentic printed deck — the default, free forever.
  static const DeckStyle napoletane = DeckStyle(
    id: 'napoletane',
    name: 'Napoletane',
    entitlementId: null,
  );

  /// Shop cosmetic — the engraved deck, gilded.
  static const DeckStyle incisoOro = DeckStyle(
    id: 'inciso_oro',
    name: 'Mazzo Inciso Oro',
    entitlementId: 'deck.special',
  );

  static const List<DeckStyle> all = [napoletane, incisoOro];

  static DeckStyle byId(String id) =>
      all.firstWhere((d) => d.id == id, orElse: () => napoletane);
}

/// The deck style the table paints with, pushed by SettingsController the
/// same way Motion and Strings are configured — card widgets are built in
/// too many places to thread a parameter through every one, and tests that
/// never touch settings get the free default.
class CardStyle {
  const CardStyle._();

  static String deckStyleId = 'napoletane';

  static bool get gilded => deckStyleId == 'inciso_oro';
}
