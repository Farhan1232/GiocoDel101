import 'package:flutter/material.dart';

import 'app_colors.dart';

/// §60 — two families, no more. Cinzel is the Italian editorial voice used
/// for titles and the 101 itself; Manrope carries every piece of UI text and
/// every number that has to be read at a glance.
class AppText {
  const AppText._();

  static const String display = 'Cinzel';
  static const String ui = 'Manrope';

  static const TextStyle heroTitle = TextStyle(
    fontFamily: display,
    fontSize: 40,
    fontWeight: FontWeight.w700,
    letterSpacing: 4,
    height: 1.05,
    color: AppColors.textPrimary,
  );

  static const TextStyle screenTitle = TextStyle(
    fontFamily: display,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: 2.4,
    color: AppColors.textPrimary,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontFamily: display,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 2.0,
    color: AppColors.antiqueGold,
  );

  static const TextStyle button = TextStyle(
    fontFamily: display,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    letterSpacing: 2.6,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontFamily: ui,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: ui,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.45,
    color: AppColors.textSecondary,
  );

  static const TextStyle label = TextStyle(
    fontFamily: ui,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.1,
    color: AppColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: ui,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
    color: AppColors.textMuted,
  );

  /// Score digits: Manrope, never the display serif — legibility wins (§60).
  static const TextStyle scoreLarge = TextStyle(
    fontFamily: ui,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle scoreSmall = TextStyle(
    fontFamily: ui,
    fontSize: 15,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );

  /// Short bursts over the table: TOCCA A TE, TURNO SALTATO, SALVO!
  static const TextStyle tableShout = TextStyle(
    fontFamily: display,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: 4,
    color: AppColors.textPrimary,
  );
}
