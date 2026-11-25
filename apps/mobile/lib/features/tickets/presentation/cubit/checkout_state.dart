part of 'checkout_cubit.dart';

enum CheckoutStatus { idle, submitting, success, failure }

final class CheckoutState extends Equatable {
  const CheckoutState({this.status = CheckoutStatus.idle, this.ticket, this.failure});

  final CheckoutStatus status;

  /// Satın alma başarılıysa yeni bilet.
  final Ticket? ticket;
  final TicketFailureReason? failure;

  @override
  List<Object?> get props => [status, ticket, failure];
}
