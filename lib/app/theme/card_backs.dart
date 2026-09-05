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
    this.entitlementId,
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

  /// Server entitlement that unlocks this back (a paid cosmetic), or null
  /// for free/achievement backs. The card FACES never change with a back.
  final String? entitlementId;
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

  /// Shop cosmetic — `gioco101_cardback_gold`. A back of solid struck gold:
  /// gilded ground, deep-ink line work, ivory medallion. Unlocked by the
  /// `cardback.gold` entitlement (server-verified purchase). Backs only —
  /// the card faces are untouched.
  static const CardBackDesign oroReale = CardBackDesign(
    id: 'oro_reale',
    name: 'Dorso Oro',
    baseTop: Color(0xFFB8902F),
    baseBottom: Color(0xFF6E4F12),
    ink: Color(0xFF2C1F08),
    medallion: Color(0xFFFFF3D0),
    unlockAchievementId: null,
    entitlementId: 'cardback.gold',
  );

  static const List<CardBackDesign> all = [
    oro,
    cobalto,
    brace,
    notturno,
    oroReale,
  ];

  static CardBackDesign byId(String id) =>
      all.firstWhere((b) => b.id == id, orElse: () => oro);
}
