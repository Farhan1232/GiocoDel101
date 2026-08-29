/// The ten ranks of a Neapolitan suit, named in Italian as the client names
/// them.
///
/// [value] is the numeric rank used by both the matching rules and the
/// default penalty scoring table. Keep the numeric value here and never
/// re-derive it from [index] at call sites.
///
/// The Cavallo *is* the "9" of the brief: `CardRank.cavallo.value == 9`.
enum CardRank {
  asso(1),
  due(2),
  tre(3),
  quattro(4),
  cinque(5),
  sei(6),
  sette(7),
  fante(8),
  cavallo(9),
  re(10);

  const CardRank(this.value);

  /// Numeric rank, 1..10.
  final int value;

  /// Stable key used for persistence and card ids. Never localise this.
  String get key => name;

  /// Accepts the current Italian keys and the English keys used by saves
  /// written before Session 2 (`ace`, `two`, … `seven`).
  static CardRank fromKey(String key) {
    final legacy = _legacyKeys[key];
    if (legacy != null) return legacy;
    return CardRank.values.firstWhere(
      (r) => r.key == key,
      orElse: () => throw FormatException('Unknown rank key: $key'),
    );
  }

  static CardRank fromValue(int value) =>
      CardRank.values.firstWhere((r) => r.value == value);

  /// Face cards carry bespoke centre artwork rather than pip layouts.
  bool get isFigure =>
      this == CardRank.fante || this == CardRank.cavallo || this == CardRank.re;

  static const Map<String, CardRank> _legacyKeys = {
    'ace': CardRank.asso,
    'two': CardRank.due,
    'three': CardRank.tre,
    'four': CardRank.quattro,
    'five': CardRank.cinque,
    'six': CardRank.sei,
    'seven': CardRank.sette,
  };
}
