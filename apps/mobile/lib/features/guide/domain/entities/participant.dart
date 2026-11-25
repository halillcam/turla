import 'package:equatable/equatable.dart';
import 'package:turla_core/turla_core.dart';

/// Katılımın nasıl işaretlendiği (`check_in_method`).
enum CheckInMethod {
  qr('qr'),
  manual('manual');

  const CheckInMethod(this.value);

  final String value;

  static CheckInMethod? fromValue(String? value) =>
      CheckInMethod.values.where((method) => method.value == value).firstOrNull;
}

/// Bir kalkışın yolcusu (iptal edilen biletler listeye gelmez).
class Participant extends Equatable {
  const Participant({
    required this.ticketId,
    required this.passengerName,
    required this.status,
    this.phone,
    this.checkedInAt,
    this.checkInMethod,
  });

  final String ticketId;
  final String passengerName;
  final String? phone;
  final TicketStatus status;
  final DateTime? checkedInAt;
  final CheckInMethod? checkInMethod;

  bool get hasArrived => status == TicketStatus.checkedIn || status == TicketStatus.completed;

  /// Elle "Geldi" işaretlenebilir mi (ödenmiş, henüz gelmemiş bilet).
  bool get canCheckIn => status.isUpcoming;

  bool get hasPhone => phone?.trim().isNotEmpty ?? false;

  Participant checkedIn(DateTime at, CheckInMethod method) => Participant(
    ticketId: ticketId,
    passengerName: passengerName,
    phone: phone,
    status: TicketStatus.checkedIn,
    checkedInAt: at,
    checkInMethod: method,
  );

  @override
  List<Object?> get props => [ticketId, passengerName, phone, status, checkedInAt, checkInMethod];
}
