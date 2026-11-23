import '../../../../core/constants/strings.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/tour.dart';
import '../../domain/entities/tour_departure.dart';
import '../../domain/entities/tour_program_day.dart';

/// Turun ekranda gösterilecek metinleri.
extension TourDisplay on Tour {
  /// "İlk kalkış: 12 Ara 08:30  ·  3 tarih"
  String get nextDepartureLabel {
    final next = nextDeparture;
    if (next == null) return AppStrings.noUpcomingDepartures;
    final base = '${AppStrings.nextDeparture}: ${next.shortLabel}';
    return departures.length > 1
        ? '$base  ·  ${departures.length} ${AppStrings.departureCountSuffix}'
        : base;
  }
}

extension TourProgramDayDisplay on TourProgramDay {
  /// "1. Gün: Kapadokya" veya başlık yoksa "1. Gün"
  String get heading {
    final dayLabel = '$dayNo. ${AppStrings.dayPrefix}';
    return title.isEmpty ? dayLabel : '$dayLabel: $title';
  }
}

extension TourDepartureDisplay on TourDeparture {
  /// "12 Ara 08:30"
  String get shortLabel => '${Formatters.shortDate(departureAt)} ${Formatters.time(departureAt)}';
}
