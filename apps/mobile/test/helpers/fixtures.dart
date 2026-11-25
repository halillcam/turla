import 'package:turla_core/turla_core.dart';
import 'package:turla_mobile/features/tickets/domain/entities/ticket.dart';
import 'package:turla_mobile/features/tours/domain/entities/tour.dart';
import 'package:turla_mobile/features/tours/domain/entities/tour_departure.dart';
import 'package:turla_mobile/features/tours/domain/entities/tour_program_day.dart';

UserProfile profileWith(UserRole role, {int? selectedCityId, String? phone = '0532 111 22 33'}) =>
    UserProfile(
      id: 'user-1',
      email: 'test@example.com',
      fullName: 'Test Kullanıcı',
      role: role,
      isActive: true,
      selectedCityId: selectedCityId,
      phone: phone,
    );

const maras = City(id: 46, name: 'Kahramanmaraş');
const istanbul = City(id: 34, name: 'İstanbul');

Tour tourWith({
  String id = 'tour-1',
  String title = 'Kapadokya Turu',
  TourRegion region = TourRegion.centralAnatolia,
  List<DateTime>? departures,
  String companyName = 'Demo Turizm',
}) => Tour(
  id: id,
  title: title,
  description: 'Açıklama',
  extraDetail: '',
  price: 1850,
  region: region,
  cityId: 46,
  companyName: companyName,
  departures: [
    for (final (index, date) in (departures ?? [DateTime.utc(2030, 1, 1, 7)]).indexed)
      TourDeparture(id: '$id-dep-$index', departureAt: date, seatsLeft: 10, capacity: 40),
  ],
  programDays: const [
    TourProgramDay(dayNo: 1, title: 'Göreme', activities: ['Müze']),
  ],
);

Ticket ticketWith({
  String id = 'ticket-1',
  TicketStatus status = TicketStatus.paid,
  DepartureStatus departureStatus = DepartureStatus.scheduled,
  DateTime? departureAt,
  double pricePaid = 1850,
  double? refundAmount,
  String tourTitle = 'Kapadokya Turu',
}) => Ticket(
  id: id,
  qrToken: 'qr-$id',
  status: status,
  passengerName: 'Test Kullanıcı',
  pricePaid: pricePaid,
  createdAt: DateTime.utc(2026, 11, 20, 10),
  departureId: 'dep-$id',
  departureAt: departureAt ?? DateTime.utc(2026, 12, 5, 7),
  departureStatus: departureStatus,
  busPlate: '46 ABC 101',
  driverName: 'Mehmet Kaya',
  tourId: 'tour-1',
  tourTitle: tourTitle,
  companyName: 'Demo Turizm',
  companyPhone: '0344 000 00 00',
  refundAmount: refundAmount,
);
