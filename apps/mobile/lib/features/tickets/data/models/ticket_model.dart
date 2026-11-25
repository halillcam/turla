import 'package:turla_core/turla_core.dart';

import '../../domain/entities/ticket.dart';

/// Supabase satırı ↔ [Ticket] dönüşümü. Cihazdaki önbellek de aynı biçimi kullanır.
abstract final class TicketModel {
  static const String columns =
      'id, qr_token, status, passenger_name, passenger_phone, price_paid, created_at, '
      'cancelled_at, scanned_at, '
      'departure:tour_departures(id, departure_at, status, bus_plate, driver_name, driver_phone, '
      'tour:tours(id, title, image_url, company:companies(name, phone))), '
      'payments(type, amount)';

  static const String _refund = 'refund';

  static Ticket fromRow(Map<String, dynamic> row) {
    final departure = row['departure'] as Map<String, dynamic>;
    final tour = departure['tour'] as Map<String, dynamic>;
    final company = tour['company'] as Map<String, dynamic>?;
    final payments = ((row['payments'] as List<dynamic>?) ?? const []).cast<Map<String, dynamic>>();
    final refund = payments.where((payment) => payment['type'] == _refund).firstOrNull;
    final cancelledAt = row['cancelled_at'] as String?;
    final scannedAt = row['scanned_at'] as String?;

    return Ticket(
      id: row['id'] as String,
      qrToken: row['qr_token'] as String,
      status: TicketStatus.fromValue(row['status'] as String),
      passengerName: row['passenger_name'] as String,
      passengerPhone: row['passenger_phone'] as String?,
      pricePaid: (row['price_paid'] as num).toDouble(),
      createdAt: DateTime.parse(row['created_at'] as String),
      cancelledAt: cancelledAt == null ? null : DateTime.parse(cancelledAt),
      scannedAt: scannedAt == null ? null : DateTime.parse(scannedAt),
      departureId: departure['id'] as String,
      departureAt: DateTime.parse(departure['departure_at'] as String),
      departureStatus: DepartureStatus.fromValue(departure['status'] as String),
      busPlate: departure['bus_plate'] as String?,
      driverName: departure['driver_name'] as String?,
      driverPhone: departure['driver_phone'] as String?,
      tourId: tour['id'] as String,
      tourTitle: tour['title'] as String,
      tourImageUrl: tour['image_url'] as String?,
      companyName: (company?['name'] as String?) ?? '',
      companyPhone: company?['phone'] as String?,
      refundAmount: (refund?['amount'] as num?)?.toDouble(),
    );
  }

  static Map<String, dynamic> toRow(Ticket ticket) => {
    'id': ticket.id,
    'qr_token': ticket.qrToken,
    'status': ticket.status.value,
    'passenger_name': ticket.passengerName,
    'passenger_phone': ticket.passengerPhone,
    'price_paid': ticket.pricePaid,
    'created_at': ticket.createdAt.toUtc().toIso8601String(),
    'cancelled_at': ticket.cancelledAt?.toUtc().toIso8601String(),
    'scanned_at': ticket.scannedAt?.toUtc().toIso8601String(),
    'departure': {
      'id': ticket.departureId,
      'departure_at': ticket.departureAt.toUtc().toIso8601String(),
      'status': ticket.departureStatus.value,
      'bus_plate': ticket.busPlate,
      'driver_name': ticket.driverName,
      'driver_phone': ticket.driverPhone,
      'tour': {
        'id': ticket.tourId,
        'title': ticket.tourTitle,
        'image_url': ticket.tourImageUrl,
        'company': {'name': ticket.companyName, 'phone': ticket.companyPhone},
      },
    },
    'payments': [
      if (ticket.refundAmount != null) {'type': _refund, 'amount': ticket.refundAmount},
    ],
  };
}
