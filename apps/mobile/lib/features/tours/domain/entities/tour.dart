import 'package:equatable/equatable.dart';
import 'package:turla_core/turla_core.dart';

import 'tour_departure.dart';
import 'tour_program_day.dart';

/// Müşterinin gördüğü tur. Listede [programDays] boştur; detayda doldurulur.
class Tour extends Equatable {
  const Tour({
    required this.id,
    required this.title,
    required this.description,
    required this.extraDetail,
    required this.price,
    required this.region,
    required this.cityId,
    required this.companyName,
    required this.departures,
    this.imageUrl,
    this.companyPhone,
    this.programDays = const [],
  });

  final String id;
  final String title;
  final String description;
  final String extraDetail;
  final double price;
  final TourRegion region;
  final int cityId;
  final String companyName;
  final String? companyPhone;
  final String? imageUrl;

  /// Yaklaşan, satışa açık kalkışlar (tarihe göre sıralı).
  final List<TourDeparture> departures;
  final List<TourProgramDay> programDays;

  TourDeparture? get nextDeparture => departures.isEmpty ? null : departures.first;

  bool get hasAvailableSeats => departures.any((departure) => !departure.isSoldOut);

  /// Kalkışları [now] sonrası olanlarla sınırlar (önbellekten okunan eski veri için).
  Tour withDeparturesAfter(DateTime now) => Tour(
    id: id,
    title: title,
    description: description,
    extraDetail: extraDetail,
    price: price,
    region: region,
    cityId: cityId,
    companyName: companyName,
    companyPhone: companyPhone,
    imageUrl: imageUrl,
    departures: departures.where((departure) => departure.departureAt.isAfter(now)).toList(),
    programDays: programDays,
  );

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    extraDetail,
    price,
    region,
    cityId,
    companyName,
    companyPhone,
    imageUrl,
    departures,
    programDays,
  ];
}
