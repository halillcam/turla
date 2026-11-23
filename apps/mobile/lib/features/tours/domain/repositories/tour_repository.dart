import '../entities/tour.dart';

/// Tur listesi sonucu. [isStale] true ise sunucuya ulaşılamadı ve önbellekteki
/// (süresi geçmiş) liste gösteriliyor.
class TourListResult {
  const TourListResult({required this.tours, this.isStale = false});

  final List<Tour> tours;
  final bool isStale;
}

abstract interface class TourRepository {
  /// İlden kalkan, yaklaşan tarihi olan turlar.
  ///
  /// Önbellekteki liste [AppDurations.tourCacheTtl] süresinden yeniyse sunucuya
  /// istek atılmaz. [forceRefresh] önbelleği atlar. Hata: [TourFailure].
  Future<TourListResult> getToursByCity(int cityId, {bool forceRefresh = false});

  /// Tur detayı her zaman sunucudan alınır (boş koltuk sayısı güncel olmalı).
  Future<Tour> getTourDetail(String tourId);
}
