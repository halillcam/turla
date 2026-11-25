import 'package:equatable/equatable.dart';
import 'package:turla_core/turla_core.dart';

/// Bir tarihe kesilmiş bilet (firma paneli görünümü). QR değeri panele çekilmez.
class ParticipantTicket extends Equatable {
  const ParticipantTicket({
    required this.id,
    required this.departureId,
    required this.userId,
    required this.passengerName,
    required this.status,
    required this.isFromPanel,
    required this.pricePaid,
    required this.createdAt,
    this.cancelledAt,
    this.passengerPhone,
    this.checkedInAt,
    this.isManualCheckIn = false,
  });

  final String id;
  final String departureId;
  final String userId;
  final String passengerName;
  final TicketStatus status;

  /// true: panelden kesildi (ödeme elden/havale); false: uygulamadan alındı (demo ödeme).
  final bool isFromPanel;
  final double pricePaid;
  final DateTime createdAt;
  final DateTime? cancelledAt;
  final String? passengerPhone;

  /// Tur sorumlusunun QR okuttuğu / elle işaretlediği an.
  final DateTime? checkedInAt;

  /// Rehber QR yerine listeden elle "Geldi" dedi.
  final bool isManualCheckIn;

  /// Koltuk tutan bilet (iptal edilenler koltuğu geri bırakır).
  bool get holdsSeat => status != TicketStatus.cancelled;

  /// Yönetici iptali: kullanılmamış, geçerli bilet. Sunucu ayrıca tarih durumunu denetler.
  bool get isCancellable => status.isUpcoming;

  @override
  List<Object?> get props => [
    id,
    departureId,
    userId,
    passengerName,
    status,
    isFromPanel,
    pricePaid,
    createdAt,
    cancelledAt,
    passengerPhone,
    checkedInAt,
    isManualCheckIn,
  ];
}
