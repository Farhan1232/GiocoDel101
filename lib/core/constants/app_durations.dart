/// Every animation length in the game, in one table.
///
/// Read these through `MotionScale` rather than directly, so the animation
/// speed setting and Reduce Motion apply everywhere (§30, §48).
class AppDurations {
  const AppDurations._();

  static const Duration micro = Duration(milliseconds: 120);
  static const Duration quick = Duration(milliseconds: 200);
  static const Duration cardPlay = Duration(milliseconds: 340);
  static const Duration cardDraw = Duration(milliseconds: 300);
  static const Duration penaltyStagger = Duration(milliseconds: 90);
  static const Duration suitRitual = Duration(milliseconds: 520);
  static const Duration aceFlash = Duration(milliseconds: 700);
  static const Duration chainPulse = Duration(milliseconds: 460);
  static const Duration ambientShift = Duration(milliseconds: 500);
  static const Duration screenTransition = Duration(milliseconds: 380);
  static const Duration fateRingReset = Duration(milliseconds: 1900);
  static const Duration turnBanner = Duration(milliseconds: 1100);

  /// §53 — how long a bot appears to think.
  static const Duration botThinkMin = Duration(milliseconds: 420);
  static const Duration botThinkMax = Duration(milliseconds: 900);
}
