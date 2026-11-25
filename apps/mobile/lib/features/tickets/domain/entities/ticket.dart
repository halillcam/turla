import 'package:equatable/equatable.dart';
import 'package:turla_core/turla_core.dart';

/// Müşterinin bileti: tur, tarih, araç ve firma bilgisiyle birlikte.
/// Cihazda saklanır; QR internetsiz açılabilsin diye [qrToken] da tutulur.
class Ticket extends Equatable {
  const Ticket({
    required this.id,
    required this.qrToken,
    required this.status,
    required this.passengerName,
    required this.pricePaid,
    required this.createdAt,
    required this.departureId,
    required this.departureAt,
    required this.departureStatus,
    required this.tourId,
    required this.tourTitle,
    required this.companyName,
    this.cancelledAt,
    this.busPlate,
    this.driverName,
    this.driverPhone,
    this.tourImageUrl,
    this.companyPhone,
    this.refundAmount,
  });

  final String id;
  final String qrToken;
  final TicketStatus status;
  final String passengerName;
  final double pricePaid;
  final DateTime createdAt;
  final DateTime? cancelledAt;
  final String departureId;
  final DateTime departureAt;
  final DepartureStatus departureStatus;
  final String? busPlate;
  final String? driverName;
  final String? driverPhone;
  final String tourId;
  final String tourTitle;
  final String? tourImageUrl;
  final String companyName;
  final String? companyPhone;

  /// İptal edildiyse iade edilen tutar (ücretsiz turda null).
  final double? refundAmount;

  /// Tur henüz bitmedi ve bilet geçerli: "Yaklaşan" listesinde görünür, QR gösterilir.
  bool get isActive =>
      (status.isUpcoming || status == TicketStatus.checkedIn) &&
      (departureStatus == DepartureStatus.scheduled ||
          departureStatus == DepartureStatus.finishRequested);

  /// Müşteri bu saate kadar iptal edebilir. Asıl kontrol sunucudadır (`cancel_ticket`).
  DateTime get cancellationDeadline => departureAt.subtract(AppDurations.cancellationCutoff);

  bool canCancelAt(DateTime now) =>
      status.isUpcoming &&
      departureStatus == DepartureStatus.scheduled &&
      now.isBefore(cancellationDeadline);

  /// Sunucu iptali onayladıktan sonraki hali: koltuk geri eklenir, ödeme varsa tamamı iade edilir.
  Ticket cancelled(DateTime at) => _copyWith(
    status: TicketStatus.cancelled,
    cancelledAt: at,
    refundAmount: pricePaid > 0 ? pricePaid : null,
  );

  Ticket _copyWith({TicketStatus? status, DateTime? cancelledAt, double? refundAmount}) => Ticket(
    id: id,
    qrToken: qrToken,
    status: status ?? this.status,
    passengerName: passengerName,
    pricePaid: pricePaid,
    createdAt: createdAt,
    cancelledAt: cancelledAt ?? this.cancelledAt,
    departureId: departureId,
    departureAt: departureAt,
    departureStatus: departureStatus,
    busPlate: busPlate,
    driverName: driverName,
    driverPhone: driverPhone,
    tourId: tourId,
    tourTitle: tourTitle,
    tourImageUrl: tourImageUrl,
    companyName: companyName,
    companyPhone: companyPhone,
    refundAmount: refundAmount ?? this.refundAmount,
  );

  @override
  List<Object?> get props => [
    id,
    qrToken,
    status,
    passengerName,
    pricePaid,
    createdAt,
    cancelledAt,
    departureId,
    departureAt,
    departureStatus,
    busPlate,
    driverName,
    driverPhone,
    tourId,
    tourTitle,
    tourImageUrl,
    companyName,
    companyPhone,
    refundAmount,
  ];
}
