import 'package:flutter/foundation.dart';

/// Diagnostic output that exists only in debug builds.
///
/// `debugPrint` itself keeps printing in release mode; the game has nothing
/// to say to logcat on a player's phone.
class Log {
  const Log._();

  static void d(String message) {
    if (kDebugMode) debugPrint(message);
  }
}
