/// One spacing scale for the whole game. Widgets must not invent values.
class AppSpacing {
  const AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Comfortable page gutter on a phone.
  static const double gutter = 20;
}

/// One radius scale. Consistent corners are most of what "polished" means.
class AppRadii {
  const AppRadii._();

  static const double xs = 6;
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 22;
  static const double xl = 28;
  static const double pill = 999;

  /// Playing-card corner, relative to card width.
  static const double cardCornerRatio = 0.075;
}

/// Card proportions used everywhere a card is drawn or measured.
class CardMetrics {
  const CardMetrics._();

  /// Height / width. Slightly slimmer than a poker card, like a Neapolitan
  /// deck actually is.
  static const double aspect = 1.55;

  /// Fraction of a card's width that stays visible in a tight fan.
  static const double minFanVisible = 0.28;
}
