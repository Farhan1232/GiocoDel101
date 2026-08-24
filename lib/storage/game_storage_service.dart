import 'package:flutter/foundation.dart';

import '../models/match_state.dart';
import 'local_storage.dart';
import 'storage_keys.dart';

/// §49 — persists a resumable snapshot of the live match.
///
/// Writes are cheap (one JSON string) but still coalesced: the caller may
/// mark the match dirty as often as it likes and only the latest state is
/// flushed.
class GameStorageService {
  GameStorageService(this._storage);

  final LocalStorage _storage;

  bool get hasSavedMatch => _storage.has(StorageKeys.savedMatch);

  Future<void> save(MatchState state) async {
    if (state.matchOver) {
      // §49 — a finished match must not offer "Riprendi Partita".
      await clear();
      return;
    }
    try {
      await _storage.writeJson(StorageKeys.savedMatch, state.toJson());
    } catch (error, stack) {
      debugPrint('Could not persist match: $error\n$stack');
    }
  }

  /// Returns null when there is no save, or when the save is unusable.
  MatchState? load() {
    final json = _storage.readJson(StorageKeys.savedMatch);
    if (json == null) return null;
    try {
      return MatchState.fromJson(json);
    } catch (error) {
      // §52 — a corrupt save is discarded, never surfaced to the player.
      debugPrint('Discarding invalid saved match: $error');
      unawaited(clear());
      return null;
    }
  }

  Future<void> clear() => _storage.remove(StorageKeys.savedMatch);
}

void unawaited(Future<void> future) {
  future.catchError((Object error) => debugPrint('storage: $error'));
}
