import 'package:turla_core/turla_core.dart';
import 'package:turla_mobile/features/tours/domain/entities/tour.dart';
import 'package:turla_mobile/features/tours/domain/entities/tour_departure.dart';
import 'package:turla_mobile/features/tours/domain/entities/tour_program_day.dart';

UserProfile profileWith(UserRole role, {int? selectedCityId}) => UserProfile(
  id: 'user-1',
  email: 'test@example.com',
  fullName: 'Test Kullanıcı',
  role: role,
  isActive: true,
  selectedCityId: selectedCityId,
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
