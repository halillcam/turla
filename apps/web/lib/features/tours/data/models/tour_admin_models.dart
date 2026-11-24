import 'package:turla_core/turla_core.dart';

import '../../domain/entities/departure.dart';
import '../../domain/entities/managed_tour.dart';
import '../../domain/entities/program_day.dart';

/// `tours` satırı ↔ [ManagedTour].
abstract final class ManagedTourModel {
  static const String table = 'tours';
  static const String columns =
      'id, company_id, title, description, extra_detail, price, city_id, region, image_url, '
      'is_active';

  /// Listede tarih sayısı da istenir.
  static const String listColumns = '$columns, tour_departures(count)';

  static ManagedTour fromRow(Map<String, dynamic> row) {
    final departures = row['tour_departures'];
    final count = departures is List && departures.isNotEmpty
        ? ((departures.first as Map)['count'] as num?)?.toInt() ?? 0
        : 0;
    return ManagedTour(
      id: row['id'] as String,
      companyId: row['company_id'] as String,
      title: row['title'] as String,
      description: (row['description'] as String?) ?? '',
      extraDetail: (row['extra_detail'] as String?) ?? '',
      price: (row['price'] as num).toDouble(),
      cityId: (row['city_id'] as num).toInt(),
      region: TourRegion.fromValue(row['region'] as String),
      isActive: (row['is_active'] as bool?) ?? true,
      imageUrl: row['image_url'] as String?,
      departureCount: count,
    );
  }

  static Map<String, dynamic> toRow(TourDraft draft) => {
    'title': draft.title.trim(),
    'description': draft.description.trim(),
    'extra_detail': draft.extraDetail.trim(),
    'price': draft.price,
    'city_id': draft.cityId,
    'region': draft.region.value,
    'is_active': draft.isActive,
  };
}

/// `tour_program_days` satırı ↔ [ProgramDay].
abstract final class ProgramDayModel {
  static const String table = 'tour_program_days';
  static const String columns = 'day_no, title, activities';

  static ProgramDay fromRow(Map<String, dynamic> row) => ProgramDay(
    title: (row['title'] as String?) ?? '',
    activities: [for (final item in (row['activities'] as List?) ?? const []) item as String],
  );

  /// `save_tour_program` RPC'sinin beklediği biçim.
  static Map<String, dynamic> toJson(ProgramDay day) => {
    'title': day.title.trim(),
    'activities': [
      for (final activity in day.activities)
        if (activity.trim().isNotEmpty) activity.trim(),
    ],
  };
}

/// `tour_departures` satırı ↔ [Departure].
abstract final class DepartureModel {
  static const String table = 'tour_departures';
  static const String columns =
      'id, tour_id, departure_at, capacity, seats_left, status, guide_id, bus_plate, '
      'driver_name, driver_phone';

  static Departure fromRow(Map<String, dynamic> row) => Departure(
    id: row['id'] as String,
    tourId: row['tour_id'] as String,
    departureAt: DateTime.parse(row['departure_at'] as String),
    capacity: (row['capacity'] as num).toInt(),
    seatsLeft: (row['seats_left'] as num).toInt(),
    status: DepartureStatus.fromValue(row['status'] as String),
    guideId: row['guide_id'] as String?,
    busPlate: row['bus_plate'] as String?,
    driverName: row['driver_name'] as String?,
    driverPhone: row['driver_phone'] as String?,
  );

  /// Sadece istemcinin yazabildiği kolonlar (bkz. migration 3 GRANT).
  static Map<String, dynamic> toRow(DepartureDraft draft) => {
    'departure_at': draft.departureAt.toUtc().toIso8601String(),
    'capacity': draft.capacity,
    'guide_id': draft.guideId,
    'bus_plate': _blankToNull(draft.busPlate),
    'driver_name': _blankToNull(draft.driverName),
    'driver_phone': _blankToNull(draft.driverPhone),
  };

  static String? _blankToNull(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? null : text;
  }
}
