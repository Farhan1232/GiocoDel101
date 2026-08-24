import 'package:flutter/material.dart';

import '../models/card_suit.dart';

/// "Modern Napoli After Dark" (§32).
///
/// Deep, warm, Mediterranean. Nothing here is a primary UNO colour, and no
/// two accents run at full saturation in the same composition.
class AppColors {
  const AppColors._();

  // Base
  static const Color midnightNavy = Color(0xFF0B1020);
  static const Color deepAubergine = Color(0xFF21152F);
  static const Color warmIvory = Color(0xFFF5E7CF);
  static const Color antiqueGold = Color(0xFFD9A441);
  static const Color mediterraneanTeal = Color(0xFF2AA89B);
  static const Color terracottaCoral = Color(0xFFDF654B);

  // Derived surfaces
  static const Color inkDeep = Color(0xFF060911);
  static const Color surface = Color(0xFF141A2E);
  static const Color surfaceRaised = Color(0xFF1C2440);
  static const Color surfaceSunken = Color(0xFF0D1224);
  static const Color hairline = Color(0x33D9A441);

  // Gold ramp, used for the logo, rings and every embossed edge.
  static const Color goldLight = Color(0xFFF6DFA6);
  static const Color goldMid = Color(0xFFD9A441);
  static const Color goldDeep = Color(0xFF8A5F1C);
  static const Color goldShadow = Color(0xFF4A3210);

  // Text
  static const Color textPrimary = Color(0xFFF3E9D8);
  static const Color textSecondary = Color(0xFFB6AC9C);
  static const Color textMuted = Color(0xFF7A7285);

  // Fate Ring states (§17)
  static const Color fateCalm = Color(0xFF2AA89B);
  static const Color fateBright = Color(0xFF8FBF63);
  static const Color fateWarning = Color(0xFFE0A63C);
  static const Color fateDanger = Color(0xFFDF654B);
  static const Color fateFractured = Color(0xFF6B5670);

  // Card stock
  static const Color cardIvory = Color(0xFFF7EEDC);
  static const Color cardIvoryShade = Color(0xFFE6D8BE);
  static const Color cardEdge = Color(0xFFCBB68E);

  static const Color danger = Color(0xFFD1553F);
  static const Color success = Color(0xFF3FA88B);
}

/// §32/§48 — every suit carries a colour *and* a shape, so colour is never
/// the only way to tell them apart.
class SuitPalette {
  const SuitPalette({
    required this.primary,
    required this.deep,
    required this.light,
    required this.ambient,
  });

  final Color primary;
  final Color deep;
  final Color light;

  /// Tint the Tavolo Vivo layer washes across the table (§35).
  final Color ambient;

  static const SuitPalette denari = SuitPalette(
    primary: Color(0xFFD9A441),
    deep: Color(0xFF8A5F1C),
    light: Color(0xFFF6DFA6),
    ambient: Color(0xFFE8B65A),
  );

  static const SuitPalette coppe = SuitPalette(
    primary: Color(0xFFB03A4A),
    deep: Color(0xFF6B1F2E),
    light: Color(0xFFE58A78),
    ambient: Color(0xFFC7534F),
  );

  static const SuitPalette spade = SuitPalette(
    primary: Color(0xFF4A7FA8),
    deep: Color(0xFF23405C),
    light: Color(0xFF9FC6DE),
    ambient: Color(0xFF5F9AC4),
  );

  static const SuitPalette bastoni = SuitPalette(
    primary: Color(0xFF5E8A4A),
    deep: Color(0xFF2E4A26),
    light: Color(0xFFA8C98A),
    ambient: Color(0xFF6FA355),
  );

  static SuitPalette of(CardSuit suit) {
    switch (suit) {
      case CardSuit.denari:
        return denari;
      case CardSuit.coppe:
        return coppe;
      case CardSuit.spade:
        return spade;
      case CardSuit.bastoni:
        return bastoni;
    }
  }
}
