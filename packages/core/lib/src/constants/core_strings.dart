/// Mobil ve web uygulamalarında ortak kullanılan sabit metinler.
/// Uygulamaya özel metinler her uygulamanın kendi `strings.dart` dosyasındadır.
abstract final class CoreStrings {
  static const String appName = 'Turla';

  // Ortam ayarları
  static const String missingEnvTitle = 'Ortam ayarları eksik';
  static const String missingEnvMessage =
      'SUPABASE_URL ve SUPABASE_PUBLISHABLE_KEY tanımlı değil. '
      'Kök dizindeki .env.example dosyasını .env olarak kopyalayıp doldurun ve '
      'uygulamayı --dart-define-from-file=../../.env ile çalıştırın.';

  // Genel hatalar
  static const String unexpectedError = 'Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.';
  static const String networkError = 'İnternet bağlantısı yok. Bağlantınızı kontrol edin.';
  static const String sessionExpired = 'Oturumunuzun süresi doldu. Lütfen tekrar giriş yapın.';

  // Roller
  static const String roleSuperAdmin = 'Super Admin';
  static const String roleAdmin = 'Şirket Yöneticisi';
  static const String roleGuide = 'Tur Sorumlusu';
  static const String roleCustomer = 'Müşteri';

  // Bölgeler
  static const String regionMediterranean = 'Akdeniz';
  static const String regionBlackSea = 'Karadeniz';
  static const String regionMarmara = 'Marmara';
  static const String regionAegean = 'Ege';
  static const String regionCentralAnatolia = 'İç Anadolu';
  static const String regionEasternAnatolia = 'Doğu Anadolu';
  static const String regionSoutheasternAnatolia = 'Güneydoğu Anadolu';
  static const String regionDayTrip = 'Günübirlik';
  static const String regionAbroad = 'Yurtdışı';

  // Bilet durumları
  static const String ticketReserved = 'Rezerve';
  static const String ticketPaid = 'Ödendi';
  static const String ticketCheckedIn = 'Tura katıldı';
  static const String ticketCancelled = 'İptal edildi';
  static const String ticketCompleted = 'Tamamlandı';
  static const String ticketNoShow = 'Gelmedi';

  // Tur tarihi durumları
  static const String departureScheduled = 'Planlandı';
  static const String departureFinishRequested = 'Bitiş onayı bekliyor';
  static const String departureCompleted = 'Tamamlandı';
  static const String departureCancelled = 'İptal edildi';
}
