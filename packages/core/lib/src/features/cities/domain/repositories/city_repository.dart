import '../entities/city.dart';

/// İl listesine erişim.
///
/// İller sabit olduğu için liste bir kez sunucudan çekilir ve cihazda saklanır;
/// sonraki açılışlarda sunucuya istek atılmaz.
abstract interface class CityRepository {
  /// İlleri plaka koduna göre sıralı döndürür.
  ///
  /// [forceRefresh] true ise önbellek atlanır ve liste sunucudan yeniden çekilir.
  /// Hiçbir kaynaktan liste alınamazsa [CitiesUnavailableException] fırlatır.
  Future<List<City>> getCities({bool forceRefresh = false});
}

/// İl listesi ne önbellekte ne de sunucuda bulunamadığında fırlatılır.
class CitiesUnavailableException implements Exception {
  const CitiesUnavailableException([this.cause]);

  final Object? cause;
}
