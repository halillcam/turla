import '../entities/ticket.dart';

/// Oturumdaki müşterinin biletleri.
///
/// Biletler cihazda saklanır: QR ve bilet bilgisi internetsiz açılır. Sunucuya
/// sadece [refreshTickets] (ekran açılınca / aşağı çekince), [bookTicket] ve
/// [cancelTicket] ile gidilir. Hatalar [TicketFailure] olarak fırlatılır.
abstract interface class TicketRepository {
  /// Cihazdaki biletler (istek atmaz). Kayıt yoksa boş liste.
  Future<List<Ticket>> getCachedTickets();

  /// Biletleri sunucudan çeker ve cihaza yazar.
  Future<List<Ticket>> refreshTickets();

  /// Demo ödemeyle bilet alır (`book_ticket`), cihazdaki listeye ekler. Telefon bilete
  /// kopyalanır (rehber arayabilsin); profilde telefon yoksa sunucu oraya da yazar.
  Future<Ticket> bookTicket({
    required String departureId,
    required String passengerName,
    required String passengerPhone,
  });

  /// Bileti iptal eder (`cancel_ticket`), cihazdaki kaydı günceller.
  Future<Ticket> cancelTicket(Ticket ticket);

  /// Bilet detayı açıkken o biletin sunucudaki değişiklikleri (Realtime). Gelen hal cihaza
  /// da yazılır. Dinleme bitince kanal kapanır (ücretsiz plan kotası için sadece detayda).
  Stream<Ticket> watchTicket(Ticket ticket);

  /// Cihazdaki liste her değiştiğinde (alma, iptal, yenileme) yeni listeyi yayar.
  Stream<List<Ticket>> get changes;
}
