import '../constants/core_strings.dart';

/// Veritabanındaki `ticket_status` tipinin karşılığı.
enum TicketStatus {
  reserved('reserved', CoreStrings.ticketReserved),
  paid('paid', CoreStrings.ticketPaid),
  checkedIn('checked_in', CoreStrings.ticketCheckedIn),
  cancelled('cancelled', CoreStrings.ticketCancelled),
  completed('completed', CoreStrings.ticketCompleted),
  noShow('no_show', CoreStrings.ticketNoShow);

  const TicketStatus(this.value, this.label);

  final String value;
  final String label;

  static TicketStatus fromValue(String value) => TicketStatus.values.firstWhere(
    (status) => status.value == value,
    orElse: () => TicketStatus.reserved,
  );

  /// Henüz kullanılmamış, geçerli bilet mi?
  bool get isUpcoming => this == TicketStatus.reserved || this == TicketStatus.paid;
}
