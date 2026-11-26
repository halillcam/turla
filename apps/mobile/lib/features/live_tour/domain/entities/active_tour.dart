import 'package:equatable/equatable.dart';
import 'package:turla_core/turla_core.dart';

import '../../../tours/domain/entities/tour_program_day.dart';
import 'announcement.dart';

/// Müşterinin "Aktif tur" ekranı: tur, tarih, araç, rehber ve son duyuru.
/// Rehberin adı/telefonu sadece bu tarihte geçerli bileti olana döner
/// (`participant_departure_info`).
class ActiveTour extends Equatable {
  const ActiveTour({
    required this.departureId,
    required this.tourTitle,
    required this.departureAt,
    required this.departureStatus,
    required this.ticketStatus,
    required this.companyName,
    required this.chatOpen,
    required this.program,
    this.busPlate,
    this.driverName,
    this.driverPhone,
    this.companyPhone,
    this.guideName,
    this.guidePhone,
    this.lastAnnouncement,
  });

  final String departureId;
  final String tourTitle;
  final DateTime departureAt;
  final DepartureStatus departureStatus;
  final TicketStatus ticketStatus;
  final String? busPlate;
  final String? driverName;
  final String? driverPhone;
  final String companyName;
  final String? companyPhone;
  final String? guideName;
  final String? guidePhone;

  /// Yazma açık mı (tarih planlanmış ve QR okutulmuş).
  final bool chatOpen;
  final List<TourProgramDay> program;
  final Announcement? lastAnnouncement;

  /// Sohbet ve duyurular QR okutulunca açılır (sunucu kuralı).
  bool get isCheckedIn => ticketStatus == TicketStatus.checkedIn;

  bool get hasGuidePhone => (guidePhone ?? '').trim().isNotEmpty;

  @override
  List<Object?> get props => [
    departureId,
    tourTitle,
    departureAt,
    departureStatus,
    ticketStatus,
    busPlate,
    driverName,
    driverPhone,
    companyName,
    companyPhone,
    guideName,
    guidePhone,
    chatOpen,
    program,
    lastAnnouncement,
  ];
}
