/// The ten ranks of a Neapolitan suit.
///
/// [value] is the numeric rank used by both the matching rules and the
/// default penalty scoring table. Keep the numeric value here and never
/// re-derive it from [index] at call sites.
enum CardRank {
  ace(1),
  two(2),
  three(3),
  four(4),
  five(5),
  six(6),
  seven(7),
  fante(8),
  cavallo(9),
  re(10);

  const CardRank(this.value);

  /// Numeric rank, 1..10.
  final int value;

  /// Stable key used for persistence. Never localise this.
  String get key => name;

  static CardRank fromKey(String key) =>
      CardRank.values.firstWhere((r) => r.key == key);

  static CardRank fromValue(int value) =>
      CardRank.values.firstWhere((r) => r.value == value);

  /// Face cards carry bespoke centre artwork rather than pip layouts.
  bool get isFigure =>
      this == CardRank.fante || this == CardRank.cavallo || this == CardRank.re;
}
