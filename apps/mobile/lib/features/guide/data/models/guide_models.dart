import 'package:turla_core/turla_core.dart';

import '../../domain/entities/check_in_result.dart';
import '../../domain/entities/guide_departure.dart';
import '../../domain/entities/participant.dart';

/// `guide_departures()` satırı ↔ [GuideDeparture]. Cihazdaki önbellek de aynı biçimi kullanır.
abstract final class GuideDepartureModel {
  static GuideDeparture fromRow(Map<String, dynamic> row) => GuideDeparture(
    id: row['id'] as String,
    tourId: row['tour_id'] as String,
    tourTitle: row['tour_title'] as String,
    companyName: (row['company_name'] as String?) ?? '',
    departureAt: DateTime.parse(row['departure_at'] as String),
    status: DepartureStatus.fromValue(row['status'] as String),
    capacity: (row['capacity'] as num).toInt(),
    busPlate: row['bus_plate'] as String?,
    driverName: row['driver_name'] as String?,
    driverPhone: row['driver_phone'] as String?,
    ticketCount: (row['ticket_count'] as num).toInt(),
    checkedInCount: (row['checked_in_count'] as num).toInt(),
    lastRequestStatus: CompletionRequestStatus.fromValue(row['last_request_status'] as String?),
  );

  static Map<String, dynamic> toRow(GuideDeparture departure) => {
    'id': departure.id,
    'tour_id': departure.tourId,
    'tour_title': departure.tourTitle,
    'company_name': departure.companyName,
    'departure_at': departure.departureAt.toUtc().toIso8601String(),
    'status': departure.status.value,
    'capacity': departure.capacity,
    'bus_plate': departure.busPlate,
    'driver_name': departure.driverName,
    'driver_phone': departure.driverPhone,
    'ticket_count': departure.ticketCount,
    'checked_in_count': departure.checkedInCount,
    'last_request_status': departure.lastRequestStatus?.value,
  };
}

/// `tickets` satırı ↔ [Participant]. Rehber sadece bu sütunları okur.
abstract final class ParticipantModel {
  static const String columns =
      'id, passenger_name, passenger_phone, status, scanned_at, check_in_method';

  static Participant fromRow(Map<String, dynamic> row) {
    final scannedAt = row['scanned_at'] as String?;
    return Participant(
      ticketId: row['id'] as String,
      passengerName: row['passenger_name'] as String,
      phone: row['passenger_phone'] as String?,
      status: TicketStatus.fromValue(row['status'] as String),
      checkedInAt: scannedAt == null ? null : DateTime.parse(scannedAt),
      checkInMethod: CheckInMethod.fromValue(row['check_in_method'] as String?),
    );
  }

  static Map<String, dynamic> toRow(Participant participant) => {
    'id': participant.ticketId,
    'passenger_name': participant.passengerName,
    'passenger_phone': participant.phone,
    'status': participant.status.value,
    'scanned_at': participant.checkedInAt?.toUtc().toIso8601String(),
    'check_in_method': participant.checkInMethod?.value,
  };
}

/// `scan_ticket` / `check_in_manually` jsonb yanıtı → [CheckInResult].
abstract final class CheckInResultModel {
  static CheckInResult fromJson(Map<String, dynamic> json) {
    final scannedAt = json['scanned_at'] as String?;
    return CheckInResult(
      code: CheckInCode.fromValue(json['code'] as String?),
      ticketId: json['ticket_id'] as String?,
      passengerName: json['passenger_name'] as String?,
      scannedAt: scannedAt == null ? null : DateTime.parse(scannedAt),
    );
  }
}
