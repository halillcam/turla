/// Bilet işlemlerinin hata türleri. Sunucu kodları (`raise exception '<kod>'`)
/// repository'de bu değerlere çevrilir.
enum TicketFailureReason {
  network,
  notSignedIn,
  onlyCustomersCanBook,
  departureNotFound,
  tourNotAvailable,
  departureNotBookable,
  alreadyHasTicket,
  noSeatsLeft,
  ticketNotFound,
  notAllowed,
  ticketNotCancellable,
  cancellationWindowClosed,
  unknown,
}

class TicketFailure implements Exception {
  const TicketFailure(this.reason, [this.cause]);

  final TicketFailureReason reason;
  final Object? cause;

  @override
  String toString() => 'TicketFailure($reason, $cause)';
}
