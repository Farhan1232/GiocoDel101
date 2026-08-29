/// The level ladder: how much XP each level costs.
///
/// **Provisional** — the client has not confirmed an online progression
/// formula (GAME_SPEC §12b). This is the same placeholder the offline profile
/// used, and `app_private.level_for_xp` in the database implements the same
/// numbers so the bar reads identically whether the source is local or remote.
class LevelLadder {
  const LevelLadder._();

  static const int xpPerMatch = 20;
  static const int xpPerWin = 45;
  static const int baseLevelCost = 120;
  static const int levelCostStep = 40;

  static LevelPosition resolve(int totalXp) {
    var xp = totalXp < 0 ? 0 : totalXp;
    var level = 1;
    var cost = baseLevelCost;
    while (xp >= cost) {
      xp -= cost;
      level++;
      cost += levelCostStep;
    }
    return LevelPosition(level: level, xpIntoLevel: xp, xpForLevel: cost);
  }
}

class LevelPosition {
  const LevelPosition({
    required this.level,
    required this.xpIntoLevel,
    required this.xpForLevel,
  });

  final int level;
  final int xpIntoLevel;
  final int xpForLevel;
}
