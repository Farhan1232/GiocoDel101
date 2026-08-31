import 'card_rank.dart';
import 'card_suit.dart';

/// A single immutable card of the 40-card Neapolitan deck.
///
/// Identity is `(suit, rank)`; [id] is the stable string form of that pair
/// (`denari_asso`, `spade_cavallo`, …). Nothing — not persistence, not the
/// network, not a widget key — identifies a card by an image filename:
/// [asset] is a *mapping* from identity to what the renderer needs, never the
/// other way round.
class GameCard {
  const GameCard(this.suit, this.rank);

  final CardSuit suit;
  final CardRank rank;

  /// Unique within a deck, e.g. `denari_cavallo`. Stable across versions.
  String get id => '${suit.key}_${rank.key}';

  /// Numeric rank convenience accessor, 1..10.
  int get value => rank.value;

  bool get isAsso => rank == CardRank.asso;
  bool get isDue => rank == CardRank.due;
  bool get isCavallo => rank == CardRank.cavallo;

  /// Legacy aliases kept for the painters and bots. Prefer the Italian names.
  bool get isAce => isAsso;
  bool get isTwo => isDue;

  /// True for any card carrying a special action under the default rules.
  bool get isAction => isAsso || isDue || isCavallo;

  /// What the renderer needs to draw this card.
  CardAsset get asset => CardAsset(this);

  String toStorage() => id;

  /// Parses an [id]. Accepts the pre-Session-2 English rank keys too.
  static GameCard fromStorage(String raw) {
    final parts = raw.split('_');
    if (parts.length != 2) {
      throw FormatException('Malformed card token: $raw');
    }
    return GameCard(CardSuit.fromKey(parts[0]), CardRank.fromKey(parts[1]));
  }

  static GameCard fromId(String id) => fromStorage(id);

  Map<String, dynamic> toJson() => {
    'id': id,
    'suit': suit.key,
    'rank': rank.key,
  };

  factory GameCard.fromJson(Object? json) {
    if (json is String) return fromStorage(json);
    if (json is Map) {
      final suit = json['suit'];
      final rank = json['rank'];
      if (suit is String && rank is String) {
        return GameCard(CardSuit.fromKey(suit), CardRank.fromKey(rank));
      }
      final id = json['id'];
      if (id is String) return fromStorage(id);
    }
    throw FormatException('Malformed card json: $json');
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

/// Identity → rendering mapping for one card.
///
/// [imagePath] is the single place a card's identity is turned into an asset
/// path; the identity itself never changes. The engraved painters are kept as
/// the fallback face and still take a suit key, a rank key and whether the
/// card is a court figure (see `docs/ASSET_INVENTORY.md`).
class CardAsset {
  const CardAsset(this.card);

  final GameCard card;

  String get suitKey => card.suit.key;
  String get rankKey => card.rank.key;

  /// Court figures (Fante, Cavallo, Re) use bespoke artwork; the rest use
  /// pip layouts driven by [pipCount].
  bool get isFigure => card.rank.isFigure;
  int get pipCount => card.rank.isFigure ? 0 : card.rank.value;

  /// Where this card's printed face lives. The traditional Carte Napoletane
  /// deck ships as one WebP per card, named by [GameCard.id] — see
  /// `assets/cards/LICENSE.txt` and `docs/ASSET_INVENTORY.md`.
  String get imagePath => 'assets/cards/${card.id}.webp';
}

/// The complete 40-card deck, in a fixed, deterministic order.
class Deck {
  const Deck._();

  static const int size = 40;

  /// Every suit crossed with every rank, exactly once, in enum order.
  static final List<GameCard> standard = List.unmodifiable(<GameCard>[
    for (final suit in CardSuit.values)
      for (final rank in CardRank.values) GameCard(suit, rank),
  ]);

  static final Map<String, GameCard> _byId = {
    for (final c in standard) c.id: c,
  };

  static GameCard? byId(String id) => _byId[id];

  static bool contains(GameCard card) => _byId.containsKey(card.id);
}
