import 'package:equatable/equatable.dart';

/// Turun bir kalkış tarihi.
class TourDeparture extends Equatable {
  const TourDeparture({
    required this.id,
    required this.departureAt,
    required this.seatsLeft,
    required this.capacity,
  });

  final String id;
  final DateTime departureAt;
  final int seatsLeft;
  final int capacity;

  bool get isSoldOut => seatsLeft <= 0;

  @override
  List<Object?> get props => [id, departureAt, seatsLeft, capacity];
}
