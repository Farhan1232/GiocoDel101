import 'package:flutter/material.dart';

import '../localization/app_strings.dart';

/// §33 — the table dressings. A theme changes the felt, the ambient
/// accent, the button tint, the particle colour and the card-back variation.
/// It never changes how readable a card face is.
class TableTheme {
  const TableTheme({
    required this.id,
    required this.name,
    required this.backdropTop,
    required this.backdropBottom,
    required this.feltInner,
    required this.feltOuter,
    required this.feltRim,
    required this.accent,
    required this.accentSoft,
    required this.particle,
    required this.pattern,
    required this.cardBackId,
    required this.isLight,
    required this.unlockAchievementId,
    this.entitlementId,
  });

  final String id;

  /// The identifier-level name. Napoli Notte, Maiolica and Vesuvio are
  /// proper names and read the same in both languages; the two shop tables
  /// are descriptive, so [displayName] translates those.
  final String name;

  /// The name as the player reads it, in the language they chose. The two
  /// paid tables reuse the shop's own translated titles so a table is never
  /// called one thing in the Negozio and another in Impostazioni.
  String get displayName => switch (id) {
    'tavolo_oro' => Strings.s.shopItemTableGold,
    'tavolo_classico' => Strings.s.shopItemTableClassic,
    _ => name,
  };

  /// One line of mood under the name on the setup screen.
  String get tagline => switch (id) {
    'maiolica' => Strings.s.tableTaglineMaiolica,
    'vesuvio' => Strings.s.tableTaglineVesuvio,
    'tavolo_oro' => Strings.s.tableTaglineOro,
    'tavolo_classico' => Strings.s.tableTaglineClassico,
    _ => Strings.s.tableTaglineNapoli,
  };

  /// Page background gradient.
  final Color backdropTop;
  final Color backdropBottom;

  /// The oval of "felt" the cards sit on.
  final Color feltInner;
  final Color feltOuter;
  final Color feltRim;

  final Color accent;
  final Color accentSoft;
  final Color particle;

  final TablePattern pattern;

  /// Card back that ships with this table.
  final String cardBackId;

  /// Drives text contrast decisions in the table layer.
  final bool isLight;

  /// null for the theme that is available from the first launch.
  final String? unlockAchievementId;

  /// Server entitlement that unlocks this theme (a paid cosmetic —
  /// docs/IAP_ARCHITECTURE.md), or null for free/achievement themes.
  final String? entitlementId;

  Color get onFelt =>
      isLight ? const Color(0xFF25324A) : const Color(0xFFF3E9D8);
}

/// The geometric motif painted faintly into the felt.
enum TablePattern { bokeh, maiolica, embers }

class TableThemes {
  const TableThemes._();

  /// §33 Theme 1 — the default. Deep navy, antique gold, distant city light.
  static const TableTheme napoliNotte = TableTheme(
    id: 'napoli_notte',
    name: 'Napoli Notte',
    backdropTop: Color(0xFF0B1020),
    backdropBottom: Color(0xFF181026),
    feltInner: Color(0xFF16304A),
    feltOuter: Color(0xFF0A1A2C),
    feltRim: Color(0xFFD9A441),
    accent: Color(0xFFD9A441),
    accentSoft: Color(0xFF2AA89B),
    particle: Color(0xFFF6DFA6),
    pattern: TablePattern.bokeh,
    cardBackId: 'oro',
    isLight: false,
    unlockAchievementId: null,
  );

  /// §33 Theme 2 — Mediterranean ceramic. Brighter, cobalt on ivory.
  static const TableTheme maiolica = TableTheme(
    id: 'maiolica',
    name: 'Maiolica',
    backdropTop: Color(0xFF1B2A4A),
    backdropBottom: Color(0xFF0F1A30),
    feltInner: Color(0xFFEDE0C6),
    feltOuter: Color(0xFFCBB68E),
    feltRim: Color(0xFF2C4E9B),
    accent: Color(0xFF2C4E9B),
    accentSoft: Color(0xFF2AA89B),
    particle: Color(0xFF4E77C8),
    pattern: TablePattern.maiolica,
    cardBackId: 'cobalto',
    isLight: true,
    unlockAchievementId: 'maestro_semi',
  );

  /// §33 Theme 3 — volcanic. Charcoal, burgundy, glowing terracotta.
  static const TableTheme vesuvio = TableTheme(
    id: 'vesuvio',
    name: 'Vesuvio',
    backdropTop: Color(0xFF16100F),
    backdropBottom: Color(0xFF2A1114),
    feltInner: Color(0xFF3A1A1C),
    feltOuter: Color(0xFF1A0D0E),
    feltRim: Color(0xFFDF654B),
    accent: Color(0xFFDF654B),
    accentSoft: Color(0xFFE0A63C),
    particle: Color(0xFFFF9A6B),
    pattern: TablePattern.embers,
    cardBackId: 'brace',
    isLight: false,
    unlockAchievementId: 'catena',
  );

  /// Shop cosmetic — `gioco101_table_gold`. Champagne-and-bronze opulence:
  /// a struck-gold felt under warm light. Unlocked by the `table.gold`
  /// entitlement (server-verified purchase), never by an achievement.
  static const TableTheme tavoloOro = TableTheme(
    id: 'tavolo_oro',
    name: 'Tavolo Oro',
    backdropTop: Color(0xFF1A1207),
    backdropBottom: Color(0xFF241505),
    feltInner: Color(0xFF8A6B25),
    feltOuter: Color(0xFF4A350F),
    feltRim: Color(0xFFF2CF7A),
    accent: Color(0xFFF2CF7A),
    accentSoft: Color(0xFFD9A441),
    particle: Color(0xFFFFE9B3),
    pattern: TablePattern.bokeh,
    cardBackId: 'oro_reale',
    isLight: false,
    unlockAchievementId: null,
    entitlementId: 'table.gold',
  );

  /// Shop cosmetic — `gioco101_table_classic`. The traditional circolo:
  /// deep green baize on dark walnut, nothing else. Unlocked by the
  /// `table.classic` entitlement.
  static const TableTheme tavoloClassico = TableTheme(
    id: 'tavolo_classico',
    name: 'Tavolo Classico',
    backdropTop: Color(0xFF221510),
    backdropBottom: Color(0xFF160D09),
    feltInner: Color(0xFF1F6B43),
    feltOuter: Color(0xFF0D3A22),
    feltRim: Color(0xFFB08D57),
    accent: Color(0xFFC9A25E),
    accentSoft: Color(0xFF2AA89B),
    particle: Color(0xFFDCC69A),
    pattern: TablePattern.bokeh,
    cardBackId: 'oro',
    isLight: false,
    unlockAchievementId: null,
    entitlementId: 'table.classic',
  );

  static const List<TableTheme> all = [
    napoliNotte,
    maiolica,
    vesuvio,
    tavoloOro,
    tavoloClassico,
  ];

  static TableTheme byId(String id) =>
      all.firstWhere((t) => t.id == id, orElse: () => napoliNotte);
}
