import 'package:equatable/equatable.dart';
import 'package:turla_core/turla_core.dart';

/// Turun bir tarihi (`tour_departures`). Kontenjan, rehber ve durum tarih bazındadır.
class Departure extends Equatable {
  const Departure({
    required this.id,
    required this.tourId,
    required this.departureAt,
    required this.capacity,
    required this.seatsLeft,
    required this.status,
    this.guideId,
    this.busPlate,
    this.driverName,
    this.driverPhone,
  });

  final String id;
  final String tourId;
  final DateTime departureAt;
  final int capacity;
  final int seatsLeft;
  final DepartureStatus status;
  final String? guideId;
  final String? busPlate;
  final String? driverName;
  final String? driverPhone;

  int get soldSeats => capacity - seatsLeft;

  /// Tamamlanan veya iptal edilen tarih düzenlenmez.
  bool get isEditable =>
      status == DepartureStatus.scheduled || status == DepartureStatus.finishRequested;

  /// Panelden iptal edilebilir mi: planlanmış ve henüz başlamamış (asıl kontrol sunucuda).
  bool canBeCancelledAt(DateTime now) =>
      status == DepartureStatus.scheduled && departureAt.isAfter(now);

  /// Sunucuda iptal edildikten sonraki hali: tüm koltuklar boş.
  Departure cancelled() => Departure(
    id: id,
    tourId: tourId,
    departureAt: departureAt,
    capacity: capacity,
    seatsLeft: capacity,
    status: DepartureStatus.cancelled,
    guideId: guideId,
    busPlate: busPlate,
    driverName: driverName,
    driverPhone: driverPhone,
  );

  /// Bilet satışı / iptali sonrası boş koltuk sayısı (sunucudaki seats_left ile aynı kural).
  Departure withSoldSeats(int soldSeats) => Departure(
    id: id,
    tourId: tourId,
    departureAt: departureAt,
    capacity: capacity,
    seatsLeft: capacity - soldSeats,
    status: status,
    guideId: guideId,
    busPlate: busPlate,
    driverName: driverName,
    driverPhone: driverPhone,
  );

  DepartureDraft toDraft() => DepartureDraft(
    departureAt: departureAt,
    capacity: capacity,
    guideId: guideId,
    busPlate: busPlate,
    driverName: driverName,
    driverPhone: driverPhone,
  );

  @override
  List<Object?> get props => [
    id,
    tourId,
    departureAt,
    capacity,
    seatsLeft,
    status,
    guideId,
    busPlate,
    driverName,
    driverPhone,
  ];
}

/// Tarih ekleme / düzenleme formunun verisi. Koltuk sayısı ve durum sunucuda
/// yönetilir; buradan gönderilmez.
class DepartureDraft extends Equatable {
  const DepartureDraft({
    required this.departureAt,
    required this.capacity,
    this.guideId,
    this.busPlate,
    this.driverName,
    this.driverPhone,
  });

  final DateTime departureAt;
  final int capacity;
  final String? guideId;
  final String? busPlate;
  final String? driverName;
  final String? driverPhone;

  @override
  List<Object?> get props => [departureAt, capacity, guideId, busPlate, driverName, driverPhone];
}

/// Tarih iptalinin sonucu: kaç bilet iptal edildi ve toplam iade.
class DepartureCancellation extends Equatable {
  const DepartureCancellation({required this.cancelledTickets, required this.refundedTotal});

  final int cancelledTickets;
  final double refundedTotal;

  @override
  List<Object?> get props => [cancelledTickets, refundedTotal];
}
