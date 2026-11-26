/// Cihazda saklanan verilerin anahtarları.
abstract final class StorageKeys {
  static const String citiesCache = 'turla.cities.cache';
  static const String citiesCacheVersion = 'turla.cities.cache_version';

  /// Kullanıcının seçtiği il (misafir dahil, cihazda tutulur).
  static const String selectedCityId = 'turla.selected_city_id';

  /// İl bazında tur listesi önbelleği: `<önek><il_id>`.
  static const String toursByCityPrefix = 'turla.tours.city.';

  /// Kullanıcı bazında bilet önbelleği: `<önek><kullanıcı_id>`.
  static const String ticketsByUserPrefix = 'turla.tickets.user.';

  /// Rehberin kalkış listesi: `<önek><kullanıcı_id>`.
  static const String guideDeparturesPrefix = 'turla.guide.departures.';

  /// Rehberin katılımcı listesi: `<önek><kullanıcı_id>.<kalkış_id>`.
  static const String guideParticipantsPrefix = 'turla.guide.participants.';

  /// Kullanıcı bazında bildirim kutusu: `<önek><kullanıcı_id>`.
  static const String notificationsByUserPrefix = 'turla.notifications.user.';

  /// Çıkışta silinen kullanıcıya özel önbellekler (paylaşılan telefon için).
  static const List<String> userScopedPrefixes = [
    ticketsByUserPrefix,
    guideDeparturesPrefix,
    guideParticipantsPrefix,
    notificationsByUserPrefix,
  ];
}

/// Yerel önbellek sürümleri.
///
/// Sabit kabul edilen bir veri sunucuda değişirse (ör. il listesi) ilgili
/// sürüm bir artırılır; uygulama eski önbelleği atıp veriyi yeniden çeker.
abstract final class CacheVersions {
  static const int cities = 1;

  /// Tur listesi önbelleğinin biçimi değişirse artırılır.
  /// 2: Karadeniz, Batı/Doğu Karadeniz olarak ikiye ayrıldı (eski bölge değeri atılır).
  static const int tours = 2;

  /// Bilet önbelleğinin biçimi değişirse artırılır.
  static const int tickets = 1;

  /// Rehber kalkış/katılımcı önbelleğinin biçimi değişirse artırılır.
  static const int guide = 1;

  /// Bildirim kutusu önbelleğinin biçimi değişirse artırılır.
  static const int notifications = 1;
}
