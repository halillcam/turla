import 'package:turla_core/turla_core.dart';

import '../../domain/entities/tour.dart';
import '../../domain/entities/tour_departure.dart';
import '../../domain/entities/tour_program_day.dart';

/// Supabase satırı ↔ [Tour] dönüşümü. Önbellek de aynı JSON biçimini kullanır.
abstract final class TourModel {
  static const String listColumns =
      'id, title, description, extra_detail, price, image_url, region, city_id, '
      'company:companies(name, phone), '
      'departures:tour_departures(id, departure_at, seats_left, capacity, status)';

  static const String detailColumns =
      '$listColumns, program:tour_program_days(day_no, title, activities, sort_order)';

  static Tour fromRow(Map<String, dynamic> row) {
    final company = row['company'] as Map<String, dynamic>?;
    final departures =
        ((row['departures'] as List<dynamic>?) ?? const [])
            .cast<Map<String, dynamic>>()
            .map(_departureFromRow)
            .toList()
          ..sort((left, right) => left.departureAt.compareTo(right.departureAt));
    final programDays =
        ((row['program'] as List<dynamic>?) ?? const [])
            .cast<Map<String, dynamic>>()
            .map(_programDayFromRow)
            .toList()
          ..sort((left, right) => left.dayNo.compareTo(right.dayNo));

    return Tour(
      id: row['id'] as String,
      title: row['title'] as String,
      description: (row['description'] as String?) ?? '',
      extraDetail: (row['extra_detail'] as String?) ?? '',
      price: (row['price'] as num).toDouble(),
      imageUrl: row['image_url'] as String?,
      region: TourRegion.fromValue(row['region'] as String),
      cityId: (row['city_id'] as num).toInt(),
      companyName: (company?['name'] as String?) ?? '',
      companyPhone: company?['phone'] as String?,
      departures: departures,
      programDays: programDays,
    );
  }

  static Map<String, dynamic> toRow(Tour tour) => {
    'id': tour.id,
    'title': tour.title,
    'description': tour.description,
    'extra_detail': tour.extraDetail,
    'price': tour.price,
    'image_url': tour.imageUrl,
    'region': tour.region.value,
    'city_id': tour.cityId,
    'company': {'name': tour.companyName, 'phone': tour.companyPhone},
    'departures': [
      for (final departure in tour.departures)
        {
          'id': departure.id,
          'departure_at': departure.departureAt.toUtc().toIso8601String(),
          'seats_left': departure.seatsLeft,
          'capacity': departure.capacity,
        },
    ],
    'program': [
      for (final day in tour.programDays)
        {'day_no': day.dayNo, 'title': day.title, 'activities': day.activities},
    ],
  };

  static TourDeparture _departureFromRow(Map<String, dynamic> row) => TourDeparture(
    id: row['id'] as String,
    departureAt: DateTime.parse(row['departure_at'] as String),
    seatsLeft: (row['seats_left'] as num).toInt(),
    capacity: (row['capacity'] as num).toInt(),
  );

  static TourProgramDay _programDayFromRow(Map<String, dynamic> row) => TourProgramDay(
    dayNo: (row['day_no'] as num).toInt(),
    title: (row['title'] as String?) ?? '',
    activities: ((row['activities'] as List<dynamic>?) ?? const []).cast<String>(),
  );
}
