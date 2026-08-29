import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_spacing.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// The single Material theme. The game paints most of its own surfaces, so
/// this mainly sets defaults for the handful of Material widgets in use
/// (dialogs, text fields, sliders) and keeps them on-brand (§55).
class AppTheme {
  const AppTheme._();

  static const SystemUiOverlayStyle overlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: AppColors.inkDeep,
    systemNavigationBarIconBrightness: Brightness.light,
  );

  static ThemeData build() {
    const scheme = ColorScheme.dark(
      primary: AppColors.antiqueGold,
      onPrimary: AppColors.inkDeep,
      secondary: AppColors.mediterraneanTeal,
      onSecondary: AppColors.inkDeep,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.danger,
      onError: AppColors.warmIvory,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.midnightNavy,
      fontFamily: AppText.ui,
      splashFactory: InkSparkle.splashFactory,
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.antiqueGold,
        selectionColor: Color(0x55D9A441),
        selectionHandleColor: AppColors.antiqueGold,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          side: const BorderSide(color: AppColors.hairline),
        ),
        titleTextStyle: AppText.screenTitle.copyWith(fontSize: 20),
        contentTextStyle: AppText.body,
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.antiqueGold,
        inactiveTrackColor: Color(0x33F5E7CF),
        thumbColor: AppColors.goldLight,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceSunken,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        hintStyle: AppText.body.copyWith(color: AppColors.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.antiqueGold, width: 1.6),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: AppText.heroTitle,
        titleLarge: AppText.screenTitle,
        titleMedium: AppText.sectionTitle,
        bodyLarge: AppText.body,
        bodyMedium: AppText.bodySmall,
        labelLarge: AppText.label,
        labelSmall: AppText.caption,
      ),
    );
  }
}
