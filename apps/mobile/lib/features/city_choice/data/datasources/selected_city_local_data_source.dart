import 'package:shared_preferences/shared_preferences.dart';
import 'package:turla_core/turla_core.dart';

abstract interface class SelectedCityLocalDataSource {
  Future<int?> read();

  Future<void> write(int cityId);
}

class SelectedCityLocalDataSourceImpl implements SelectedCityLocalDataSource {
  SelectedCityLocalDataSourceImpl({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  Future<int?> read() => _preferences.getInt(StorageKeys.selectedCityId);

  @override
  Future<void> write(int cityId) => _preferences.setInt(StorageKeys.selectedCityId, cityId);
}
