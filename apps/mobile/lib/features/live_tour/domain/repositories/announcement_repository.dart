import '../entities/announcement.dart';

/// Bir tarihin duyuruları, yeniden eskiye. Duyuru sadece QR'ı okutulmuş yolculara
/// bildirim olarak gider (sunucu tetikleyicisi). Hatalar [LiveTourFailure] olarak fırlatılır.
abstract interface class AnnouncementRepository {
  Future<List<Announcement>> fetchAnnouncements(String departureId);

  /// Tur sorumlusu duyuru gönderir.
  Future<Announcement> sendAnnouncement(String departureId, String body);
}
