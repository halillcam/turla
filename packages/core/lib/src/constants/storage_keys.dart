/// Cihazda saklanan verilerin anahtarları.
abstract final class StorageKeys {
  static const String citiesCache = 'turla.cities.cache';
  static const String citiesCacheVersion = 'turla.cities.cache_version';

  /// Kullanıcının seçtiği il (misafir dahil, cihazda tutulur).
  static const String selectedCityId = 'turla.selected_city_id';

  /// İl bazında tur listesi önbelleği: `<önek><il_id>`.
  static const String toursByCityPrefix = 'turla.tours.city.';
}

/// Yerel önbellek sürümleri.
///
/// Sabit kabul edilen bir veri sunucuda değişirse (ör. il listesi) ilgili
/// sürüm bir artırılır; uygulama eski önbelleği atıp veriyi yeniden çeker.
abstract final class CacheVersions {
  static const int cities = 1;

  /// Tur listesi önbelleğinin biçimi değişirse artırılır.
  static const int tours = 1;
}
