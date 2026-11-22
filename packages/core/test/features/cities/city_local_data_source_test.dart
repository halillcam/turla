import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:turla_core/turla_core.dart';

void main() {
  late SharedPreferencesAsync preferences;
  late CityLocalDataSourceImpl dataSource;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    preferences = SharedPreferencesAsync();
    dataSource = CityLocalDataSourceImpl(preferences: preferences);
  });

  test('kaydedilen liste aynen geri okunur', () async {
    const cities = [CityModel(id: 46, name: 'Kahramanmaraş'), CityModel(id: 34, name: 'İstanbul')];

    await dataSource.saveCities(cities);
    final read = await dataSource.readCities();

    expect(read!.map((city) => city.toJson()), cities.map((city) => city.toJson()));
  });

  test('hiç kayıt yoksa null döner', () async {
    expect(await dataSource.readCities(), isNull);
  });

  test('önbellek sürümü eskiyse null döner (yeniden çekilsin diye)', () async {
    await dataSource.saveCities(const [CityModel(id: 1, name: 'Adana')]);
    await preferences.setInt(StorageKeys.citiesCacheVersion, CacheVersions.cities - 1);

    expect(await dataSource.readCities(), isNull);
  });

  test('bozuk veri varsa null döner, uygulama çökmez', () async {
    await preferences.setInt(StorageKeys.citiesCacheVersion, CacheVersions.cities);
    await preferences.setString(StorageKeys.citiesCache, '{bozuk json');

    expect(await dataSource.readCities(), isNull);
  });
}
