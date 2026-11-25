import '../entities/participant_ticket.dart';

/// Tarih bazında bilet işlemleri (firma admini / super admin).
/// Kurallar sunucuda: `cancel_ticket`, `admin_issue_ticket`. Hatalar `PanelFailure`.
abstract interface class TicketAdminRepository {
  /// Tarihin tüm biletleri (iptaller dahil), alış sırasına göre.
  Future<List<ParticipantTicket>> listDepartureTickets(String departureId);

  /// Yönetici iptali (1 saat kuralından muaf). Koltuk geri açılır, tam iade kaydedilir.
  Future<ParticipantTicket> cancelTicket(String ticketId);

  /// Firmanın panelden eklediği müşteriye bilet keser (ödeme `manual`).
  /// [passengerName] boşsa müşterinin adı yazılır.
  Future<ParticipantTicket> issueTicket({
    required String departureId,
    required String customerId,
    String? passengerName,
  });
}
