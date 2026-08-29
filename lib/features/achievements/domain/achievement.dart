/// §41 — small, local, and shown inside Statistics rather than on a screen
/// of their own.
class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.unlocksThemeId,
    this.unlocksCardBackId,
  });

  final String id;
  final String title;
  final String description;

  /// Key into the game's own icon set, never a Material icon name.
  final String icon;

  /// §33 — what earning this unlocks, if anything.
  final String? unlocksThemeId;
  final String? unlocksCardBackId;
}
