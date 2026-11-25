import '../entities/check_in_result.dart';
import '../entities/guide_departure.dart';
import '../entities/participant.dart';

/// Tur sorumlusunun kalkışları, katılımcıları ve okutma işlemleri.
///
/// Okutma ve elle işaretleme internet ister (karar: çevrimdışı kuyruk yok).
/// Kalkış ve katılımcı listeleri son çekilen haliyle cihazda tutulur; internet
/// yokken liste yine görünür. Hatalar [GuideFailure] olarak fırlatılır.
abstract interface class GuideRepository {
  /// Cihazdaki kalkışlar (istek atmaz). Kayıt yoksa null.
  Future<List<GuideDeparture>?> getCachedDepartures();

  /// Atanmış kalkışları sunucudan çeker (`guide_departures`) ve cihaza yazar.
  Future<List<GuideDeparture>> refreshDepartures();

  /// Cihazdaki katılımcılar (istek atmaz). Kayıt yoksa null.
  Future<List<Participant>?> getCachedParticipants(String departureId);

  /// Kalkışın yolcularını çeker (iptaller hariç) ve cihaza yazar.
  Future<List<Participant>> refreshParticipants(String departureId);

  /// QR kodunu okutur (`scan_ticket`).
  Future<CheckInResult> scanTicket({required String departureId, required String code});

  /// Yolcuyu elle "Geldi" işaretler (`check_in_manually`).
  Future<CheckInResult> checkInManually(String ticketId);

  /// Turu bitirme talebi açar (`request_departure_completion`). Firma onaylayınca kapanır.
  Future<void> requestCompletion(String departureId);

  /// Cihazdaki kalkış listesi değişince (yenileme, okutma, bitirme talebi) yeni listeyi yayar.
  /// Ana ekran ve kalkış ekranı böylece ek istek atmadan güncel kalır.
  Stream<List<GuideDeparture>> get departureChanges;
}
