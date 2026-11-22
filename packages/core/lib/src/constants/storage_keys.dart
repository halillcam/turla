/// Cihazda saklanan verilerin anahtarları.
abstract final class StorageKeys {
  static const String citiesCache = 'turla.cities.cache';
  static const String citiesCacheVersion = 'turla.cities.cache_version';
}

/// Yerel önbellek sürümleri.
///
/// Sabit kabul edilen bir veri sunucuda değişirse (ör. il listesi) ilgili
/// sürüm bir artırılır; uygulama eski önbelleği atıp veriyi yeniden çeker.
abstract final class CacheVersions {
  static const int cities = 1;
}
