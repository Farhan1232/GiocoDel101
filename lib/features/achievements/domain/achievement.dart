import '../../../core/widgets/app_icons.dart';

/// §41 — a badge the player earns locally.
///
/// Deliberately carries **no copy**. Titles and descriptions live in the ARB
/// files and are resolved through [AchievementCopy], so the catalogue cannot
/// leak untranslated Italian into the English interface.
class Achievement {
  const Achievement({
    required this.id,
    required this.icon,
    this.unlocksThemeId,
    this.unlocksCardBackId,
  });

  final String id;

  /// From the game's own icon set, never a Material icon.
  final AppIcon icon;

  /// §33 — what earning this unlocks, if anything. Always cosmetic.
  final String? unlocksThemeId;
  final String? unlocksCardBackId;
}
