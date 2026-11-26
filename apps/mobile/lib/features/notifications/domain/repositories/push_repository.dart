/// Telefondaki push bildirimleri (sadece Android, FCM).
///
/// Firebase yapılandırılmamışsa (google-services.json yok) her şey sessizce
/// devre dışıdır; uygulama içi bildirim kutusu yine çalışır.
abstract interface class PushRepository {
  /// Bildirim izni ister, cihaz token'ını oturumdaki hesaba bağlar ve
  /// token yenilenirse yeniden kaydeder. İzin verilmezse false.
  Future<bool> registerDevice();

  /// Çıkıştan önce: token'ı hesaptan ayırır (bu telefona artık o hesabın push'u gelmez).
  Future<void> unregisterDevice();

  /// Bildirim izni verilmiş mi (ekrandaki uyarı için).
  Future<bool> hasPermission();

  /// Kullanıcı bir bildirime dokundu: duyurunun tur tarihi (yoksa null).
  Stream<String?> get openedNotifications;

  /// Uygulama açıkken gelen bildirim (başlık, metin).
  Stream<({String title, String body, String? departureId})> get foregroundMessages;
}
