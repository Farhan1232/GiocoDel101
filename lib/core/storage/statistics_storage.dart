import '../../features/profile/domain/statistics_model.dart';
import 'local_storage.dart';
import 'storage_keys.dart';

class StatisticsStorage {
  StatisticsStorage(this._storage);

  final LocalStorage _storage;

  StatisticsModel load() {
    final json = _storage.readJson(StorageKeys.statistics);
    if (json == null) return const StatisticsModel();
    try {
      return StatisticsModel.fromJson(json);
    } catch (_) {
      return const StatisticsModel();
    }
  }

  Future<void> save(StatisticsModel stats) =>
      _storage.writeJson(StorageKeys.statistics, stats.toJson());

  Future<void> reset() => _storage.remove(StorageKeys.statistics);
}
