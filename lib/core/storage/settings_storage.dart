import '../../features/settings/domain/settings_model.dart';
import 'local_storage.dart';
import 'storage_keys.dart';

class SettingsStorage {
  SettingsStorage(this._storage);

  final LocalStorage _storage;

  SettingsModel load() {
    final json = _storage.readJson(StorageKeys.settings);
    if (json == null) return const SettingsModel();
    try {
      return SettingsModel.fromJson(json);
    } catch (_) {
      return const SettingsModel();
    }
  }

  Future<void> save(SettingsModel settings) =>
      _storage.writeJson(StorageKeys.settings, settings.toJson());
}
