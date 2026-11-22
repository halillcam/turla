/// Animasyon, önbellek ve iş kuralı süreleri.
abstract final class AppDurations {
  // Animasyon
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);

  // Arama kutusu gecikmesi
  static const Duration searchDebounce = Duration(milliseconds: 350);

  // Yerel önbellek: tur listesi/detayı bu süreden eskiyse sunucudan yenilenir.
  static const Duration tourCacheTtl = Duration(minutes: 20);

  // Görsel önbelleği: bu süreden eski görseller cihazdan silinir.
  static const Duration imageCacheStale = Duration(days: 7);

  // İş kuralı: bilet kalkıştan bu kadar önceye kadar iptal edilebilir.
  // Asıl kontrol sunucudaki `cancel_ticket` fonksiyonundadır; bu değer sadece arayüz içindir.
  static const Duration cancellationCutoff = Duration(hours: 1);
}
