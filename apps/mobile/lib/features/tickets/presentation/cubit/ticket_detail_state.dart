part of 'ticket_detail_cubit.dart';

enum TicketDetailStatus { loading, ready, notFound }

enum CancelStatus { idle, inProgress, success, failure }

final class TicketDetailState extends Equatable {
  const TicketDetailState({
    this.status = TicketDetailStatus.loading,
    this.ticket,
    this.canCancel = false,
    this.cancelStatus = CancelStatus.idle,
    this.failure,
  });

  final TicketDetailStatus status;
  final Ticket? ticket;

  /// İptal düğmesi gösterilsin mi (kalkışa 1 saatten fazla var ve bilet geçerli).
  final bool canCancel;
  final CancelStatus cancelStatus;
  final TicketFailureReason? failure;

  TicketDetailState copyWith({CancelStatus? cancelStatus}) => TicketDetailState(
    status: status,
    ticket: ticket,
    canCancel: canCancel,
    cancelStatus: cancelStatus ?? this.cancelStatus,
    failure: failure,
  );

  @override
  List<Object?> get props => [status, ticket, canCancel, cancelStatus, failure];
}
