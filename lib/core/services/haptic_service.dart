import 'package:flutter/services.dart';

import '../utils/motion.dart';

/// §44 — three weights of feedback, gated by the player's settings.
///
/// Every call is fire-and-forget and swallows platform errors: a device
/// without a vibrator must never take the game down with it.
class HapticService {
  HapticService._();

  static final HapticService instance = HapticService._();

  bool _enabled = true;

  void configure({required bool enabled}) {
    _enabled = enabled;
    Motion.hapticsEnabled = enabled;
  }

  bool get enabled => _enabled;

  /// Button taps, card selection.
  void light() => _run(HapticFeedback.selectionClick);

  /// Playing and drawing cards.
  void medium() => _run(HapticFeedback.lightImpact);

  /// Chain escalation, the 101 reset, victory.
  void strong() => _run(HapticFeedback.mediumImpact);

  /// Rejected moves.
  void error() => _run(HapticFeedback.heavyImpact);

  void _run(Future<void> Function() action) {
    if (!_enabled) return;
    action().catchError((_) {});
  }
}
