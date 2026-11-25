import 'package:turla_core/turla_core.dart';

import '../../domain/entities/participant_ticket.dart';

/// `tickets` satırı ↔ [ParticipantTicket]. RPC'lerin döndürdüğü satır da aynı biçimdedir.
abstract final class ParticipantTicketModel {
  static const String table = 'tickets';

  static const String columns =
      'id, departure_id, user_id, passenger_name, status, source, price_paid, created_at, '
      'cancelled_at, passenger_phone, scanned_at, check_in_method';

  static const String _panelSource = 'panel';
  static const String _manualCheckIn = 'manual';

  static ParticipantTicket fromRow(Map<String, dynamic> row) {
    final cancelledAt = row['cancelled_at'] as String?;
    final scannedAt = row['scanned_at'] as String?;
    return ParticipantTicket(
      id: row['id'] as String,
      departureId: row['departure_id'] as String,
      userId: row['user_id'] as String,
      passengerName: row['passenger_name'] as String,
      status: TicketStatus.fromValue(row['status'] as String),
      isFromPanel: row['source'] == _panelSource,
      pricePaid: (row['price_paid'] as num).toDouble(),
      createdAt: DateTime.parse(row['created_at'] as String),
      cancelledAt: cancelledAt == null ? null : DateTime.parse(cancelledAt),
      passengerPhone: row['passenger_phone'] as String?,
      checkedInAt: scannedAt == null ? null : DateTime.parse(scannedAt),
      isManualCheckIn: row['check_in_method'] == _manualCheckIn,
    );
  }
}
