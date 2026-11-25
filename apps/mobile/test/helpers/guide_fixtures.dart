import 'package:turla_core/turla_core.dart';
import 'package:turla_mobile/features/guide/domain/entities/guide_departure.dart';
import 'package:turla_mobile/features/guide/domain/entities/participant.dart';

GuideDeparture departureWith({
  String id = 'dep-1',
  String tourTitle = 'Yerköprü Şelalesi',
  DateTime? departureAt,
  DepartureStatus status = DepartureStatus.scheduled,
  int ticketCount = 3,
  int checkedInCount = 1,
  CompletionRequestStatus? lastRequestStatus,
}) => GuideDeparture(
  id: id,
  tourId: 'tour-1',
  tourTitle: tourTitle,
  companyName: 'Demo Turizm',
  departureAt: departureAt ?? DateTime.utc(2026, 11, 26, 5, 30),
  status: status,
  capacity: 25,
  busPlate: '46 ABC 101',
  driverName: 'Mehmet Kaya',
  driverPhone: '0532 000 00 00',
  ticketCount: ticketCount,
  checkedInCount: checkedInCount,
  lastRequestStatus: lastRequestStatus,
);

Participant participantWith({
  String id = 't1',
  String name = 'Ali Veli',
  TicketStatus status = TicketStatus.paid,
  String? phone = '0532 111 22 33',
  DateTime? checkedInAt,
  CheckInMethod? method,
}) => Participant(
  ticketId: id,
  passengerName: name,
  phone: phone,
  status: status,
  checkedInAt: checkedInAt,
  checkInMethod: method,
);
