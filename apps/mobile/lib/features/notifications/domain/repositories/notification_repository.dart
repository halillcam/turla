import '../entities/app_notification.dart';

/// Oturumdaki kullanıcının bildirim kutusu.
///
/// Son liste cihazda saklanır; sunucuya sadece [refresh] (ekran açılınca, aşağı
/// çekince, push gelince, girişte) ve okundu işaretlerken gidilir.
/// Hatalar [NotificationFailure] olarak fırlatılır.
abstract interface class NotificationRepository {
  /// Bir yenilemede çekilen en fazla bildirim.
  static const int pageSize = 50;

  /// Cihazdaki liste (istek atmaz). Kayıt yoksa null.
  Future<List<AppNotification>?> getCached();

  /// Sunucudan çeker ve cihaza yazar.
  Future<List<AppNotification>> refresh();

  Future<void> markRead(AppNotification notification);

  Future<void> markAllRead();

  /// Cihazdaki liste her değişince yeni listeyi yayar (rozet buradan beslenir).
  Stream<List<AppNotification>> get changes;
}
