/// Derleme anında `.env` dosyasından okunan ayarlar.
///
/// Uygulama şu şekilde çalıştırılır:
/// `flutter run --dart-define-from-file=../../.env`
///
/// Değerler koda gömülmez; `.env` git'e eklenmez.
abstract final class Env {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabasePublishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  /// Gerekli tüm değerler tanımlı mı?
  static bool get isConfigured => supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
}
