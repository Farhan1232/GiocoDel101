import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Thin, typed wrapper over SharedPreferences.
///
/// Every read is defensive: a corrupt or half-written value is treated as
/// "not there" rather than being allowed to crash the launch (§52).
class LocalStorage {
  LocalStorage(this._prefs);

  final SharedPreferences _prefs;

  static Future<LocalStorage> open() async =>
      LocalStorage(await SharedPreferences.getInstance());

  Map<String, dynamic>? readJson(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      // Unparseable leftovers are worse than nothing — drop them.
      _prefs.remove(key);
      return null;
    }
  }

  Future<bool> writeJson(String key, Map<String, dynamic> value) =>
      _prefs.setString(key, jsonEncode(value));

  Future<bool> remove(String key) => _prefs.remove(key);

  bool has(String key) => _prefs.containsKey(key);
}
