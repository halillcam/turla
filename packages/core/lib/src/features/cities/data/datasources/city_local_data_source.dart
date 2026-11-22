import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../constants/storage_keys.dart';
import '../models/city_model.dart';

/// İl listesini cihazda saklar. 81 il için birkaç KB yer kaplar.
abstract interface class CityLocalDataSource {
  /// Önbellekteki listeyi döndürür. Önbellek yoksa, bozuksa veya sürümü eskiyse null.
  Future<List<CityModel>?> readCities();

  Future<void> saveCities(List<CityModel> cities);
}

class CityLocalDataSourceImpl implements CityLocalDataSource {
  CityLocalDataSourceImpl({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  Future<List<CityModel>?> readCities() async {
    final version = await _preferences.getInt(StorageKeys.citiesCacheVersion);
    if (version != CacheVersions.cities) return null;

    final raw = await _preferences.getString(StorageKeys.citiesCache);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final cities = decoded
          .map((item) => CityModel.fromJson(item as Map<String, dynamic>))
          .toList();
      return cities.isEmpty ? null : cities;
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  @override
  Future<void> saveCities(List<CityModel> cities) async {
    final encoded = jsonEncode(cities.map((city) => city.toJson()).toList());
    await _preferences.setString(StorageKeys.citiesCache, encoded);
    await _preferences.setInt(StorageKeys.citiesCacheVersion, CacheVersions.cities);
  }
}
