import 'package:equatable/equatable.dart';
import 'package:turla_core/turla_core.dart';

/// Bitirme talebinin son durumu (`completion_status`).
enum CompletionRequestStatus {
  pending('pending'),
  approved('approved'),
  rejected('rejected');

  const CompletionRequestStatus(this.value);

  final String value;

  static CompletionRequestStatus? fromValue(String? value) =>
      CompletionRequestStatus.values.where((status) => status.value == value).firstOrNull;
}

/// Rehberin atandığı bir kalkış (tarih) ve katılım sayıları.
class GuideDeparture extends Equatable {
  const GuideDeparture({
    required this.id,
    required this.tourId,
    required this.tourTitle,
    required this.companyName,
    required this.departureAt,
    required this.status,
    required this.capacity,
    required this.ticketCount,
    required this.checkedInCount,
    this.busPlate,
    this.driverName,
    this.driverPhone,
    this.lastRequestStatus,
  });

  final String id;
  final String tourId;
  final String tourTitle;
  final String companyName;
  final DateTime departureAt;
  final DepartureStatus status;
  final int capacity;
  final String? busPlate;
  final String? driverName;
  final String? driverPhone;

  /// İptal edilmemiş bilet sayısı.
  final int ticketCount;

  /// QR okutulan veya elle "Geldi" işaretlenen yolcu sayısı.
  final int checkedInCount;
  final CompletionRequestStatus? lastRequestStatus;

  int get notArrivedCount => ticketCount - checkedInCount;

  /// Okutma ve elle işaretleme sadece planlanmış tarihte yapılabilir.
  bool get isActive => status == DepartureStatus.scheduled;

  bool get isAwaitingApproval => status == DepartureStatus.finishRequested;

  bool get isCompleted => status == DepartureStatus.completed;

  /// Firma son bitirme talebini reddetti, tarih yeniden açıldı.
  bool get wasRejected =>
      status == DepartureStatus.scheduled && lastRequestStatus == CompletionRequestStatus.rejected;

  /// "Turu bitir" kalkış saatinden sonra istenebilir (asıl kontrol sunucuda).
  bool canRequestCompletionAt(DateTime now) => isActive && !departureAt.isAfter(now);

  GuideDeparture copyWith({
    DepartureStatus? status,
    int? ticketCount,
    int? checkedInCount,
    CompletionRequestStatus? lastRequestStatus,
  }) => GuideDeparture(
    id: id,
    tourId: tourId,
    tourTitle: tourTitle,
    companyName: companyName,
    departureAt: departureAt,
    status: status ?? this.status,
    capacity: capacity,
    busPlate: busPlate,
    driverName: driverName,
    driverPhone: driverPhone,
    ticketCount: ticketCount ?? this.ticketCount,
    checkedInCount: checkedInCount ?? this.checkedInCount,
    lastRequestStatus: lastRequestStatus ?? this.lastRequestStatus,
  );

  @override
  List<Object?> get props => [
    id,
    tourId,
    tourTitle,
    companyName,
    departureAt,
    status,
    capacity,
    busPlate,
    driverName,
    driverPhone,
    ticketCount,
    checkedInCount,
    lastRequestStatus,
  ];
}
