import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/ticket.dart';
import '../../domain/entities/ticket_failure.dart';
import '../../domain/repositories/ticket_repository.dart';

part 'ticket_detail_state.dart';

/// Bilet detayı cihazdaki kayıttan açılır (internetsiz QR). Sadece iptal
/// sunucuya gider.
class TicketDetailCubit extends Cubit<TicketDetailState> {
  TicketDetailCubit(this._ticketRepository, {DateTime Function()? clock})
    : _now = clock ?? DateTime.now,
      super(const TicketDetailState());

  final TicketRepository _ticketRepository;
  final DateTime Function() _now;

  Future<void> load(String ticketId) async {
    final tickets = await _ticketRepository.getCachedTickets();
    if (isClosed) return;
    final ticket = tickets.where((ticket) => ticket.id == ticketId).firstOrNull;
    emit(
      ticket == null
          ? const TicketDetailState(status: TicketDetailStatus.notFound)
          : _ready(ticket),
    );
  }

  Future<void> cancel() async {
    final ticket = state.ticket;
    if (ticket == null || state.cancelStatus == CancelStatus.inProgress) return;
    emit(state.copyWith(cancelStatus: CancelStatus.inProgress));
    try {
      final updated = await _ticketRepository.cancelTicket(ticket);
      if (isClosed) return;
      emit(_ready(updated, cancelStatus: CancelStatus.success));
    } on TicketFailure catch (failure) {
      if (isClosed) return;
      emit(_ready(ticket, cancelStatus: CancelStatus.failure, failure: failure.reason));
    }
  }

  TicketDetailState _ready(
    Ticket ticket, {
    CancelStatus cancelStatus = CancelStatus.idle,
    TicketFailureReason? failure,
  }) => TicketDetailState(
    status: TicketDetailStatus.ready,
    ticket: ticket,
    canCancel: ticket.canCancelAt(_now()),
    cancelStatus: cancelStatus,
    failure: failure,
  );
}
