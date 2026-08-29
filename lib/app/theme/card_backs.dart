import 'package:flutter/material.dart';

/// §5 — the reverse of every card. Each back is a deep base with a gold
/// geometric weave and a small 101 medallion at its centre.
class CardBackDesign {
  const CardBackDesign({
    required this.id,
    required this.name,
    required this.baseTop,
    required this.baseBottom,
    required this.ink,
    required this.medallion,
    required this.unlockAchievementId,
  });

  final String id;
  final String name;
  final Color baseTop;
  final Color baseBottom;

  /// Colour of the ornamental line work.
  final Color ink;

  /// Colour of the central 101 medallion.
  final Color medallion;

  final String? unlockAchievementId;
}

class CardBacks {
  const CardBacks._();

  static const CardBackDesign oro = CardBackDesign(
    id: 'oro',
    name: 'Oro Antico',
    baseTop: Color(0xFF17233F),
    baseBottom: Color(0xFF0B1327),
    ink: Color(0xFFD9A441),
    medallion: Color(0xFFF6DFA6),
    unlockAchievementId: null,
  );

  static const CardBackDesign cobalto = CardBackDesign(
    id: 'cobalto',
    name: 'Cobalto',
    baseTop: Color(0xFF1E3A73),
    baseBottom: Color(0xFF0E1C3C),
    ink: Color(0xFFE7EDF8),
    medallion: Color(0xFFF0C464),
    unlockAchievementId: 'maestro_semi',
  );

  static const CardBackDesign brace = CardBackDesign(
    id: 'brace',
    name: 'Brace',
    baseTop: Color(0xFF44161A),
    baseBottom: Color(0xFF1C0A0C),
    ink: Color(0xFFE8845F),
    medallion: Color(0xFFFFD9A0),
    unlockAchievementId: 'catena',
  );

  static const CardBackDesign notturno = CardBackDesign(
    id: 'notturno',
    name: 'Notturno',
    baseTop: Color(0xFF2A1F3C),
    baseBottom: Color(0xFF120C1D),
    ink: Color(0xFF9C86C4),
    medallion: Color(0xFFD9A441),
    unlockAchievementId: 'sfida_giorno',
  );

  static const List<CardBackDesign> all = [oro, cobalto, brace, notturno];

  static CardBackDesign byId(String id) =>
      all.firstWhere((b) => b.id == id, orElse: () => oro);
}
