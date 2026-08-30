import 'dart:math' as math;

/// §30/§44/§48 — one place that knows how fast the game is allowed to move.
///
/// [SettingsController] pushes the player's choices in here so that widgets
/// can scale a duration without a lookup on every frame.
class Motion {
  const Motion._();

  static double speedFactor = 1.0;
  static bool hapticsEnabled = true;

  static bool _userReduceMotion = false;

  /// The platform's own "reduce motion" accessibility flag
  /// (`MediaQuery.disableAnimations`), pushed in by the app shell.
  static bool systemReduceMotion = false;

  /// True when either the player or the operating system asked for it.
  static bool get reduceMotion => _userReduceMotion || systemReduceMotion;
  static set reduceMotion(bool value) => _userReduceMotion = value;

  /// Scales an authored duration by the animation-speed setting. With Reduce
  /// Motion on, everything collapses to a short cross-fade instead.
  static Duration scale(Duration base) {
    if (reduceMotion) {
      final ms = math.min(120, (base.inMilliseconds * 0.28).round());
      return Duration(milliseconds: math.max(1, ms));
    }
    return Duration(
      milliseconds: math.max(1, (base.inMilliseconds * speedFactor).round()),
    );
  }

  /// Decorative motion (particles, ambient drift, shimmer) is dropped
  /// entirely under Reduce Motion rather than merely shortened.
  static bool get allowAmbient => !reduceMotion;

  /// Screen shake and similar displacement effects (§11).
  static double get shakeScale => reduceMotion ? 0.0 : 1.0;
}
