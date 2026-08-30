import 'package:flutter/material.dart';

import '../localization/app_strings.dart';

/// §33 — the three table dressings. A theme changes the felt, the ambient
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
  });

  final String id;
  final String name;

  /// One line of mood under the name on the setup screen.
  String get tagline => switch (id) {
    'maiolica' => Strings.s.tableTaglineMaiolica,
    'vesuvio' => Strings.s.tableTaglineVesuvio,
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

  static const List<TableTheme> all = [napoliNotte, maiolica, vesuvio];

  static TableTheme byId(String id) =>
      all.firstWhere((t) => t.id == id, orElse: () => napoliNotte);
}
