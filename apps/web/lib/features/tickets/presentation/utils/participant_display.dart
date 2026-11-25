import '../../../../core/constants/strings.dart';
import '../../../../core/utils/formatters.dart';
import '../../../staff/domain/entities/staff_member.dart';
import '../../domain/entities/participant_ticket.dart';

extension ParticipantTicketDisplay on ParticipantTicket {
  String get sourceLabel => isFromPanel ? AppStrings.ticketSourcePanel : AppStrings.ticketSourceApp;

  String get priceLabel => Formatters.price(pricePaid);

  String get purchasedAtLabel => Formatters.dateTime(createdAt);

  String get phoneLabel => passengerPhone ?? AppStrings.empty;

  /// "Tura katıldı (elle)" — rehber QR yerine listeden işaretlediyse.
  String get statusLabel =>
      isManualCheckIn ? '${status.label} ${AppStrings.manualCheckInSuffix}' : status.label;
}

extension CustomerOptionDisplay on StaffMember {
  /// Seçim listesinde: "Ayşe Kaya (MUS-1234)"
  String get optionLabel => loginId == null ? fullName : '$fullName ($loginId)';
}
