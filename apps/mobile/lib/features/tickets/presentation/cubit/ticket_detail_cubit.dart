import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/ticket.dart';
import '../../domain/entities/ticket_failure.dart';
import '../../domain/repositories/ticket_repository.dart';

part 'ticket_detail_state.dart';

/// Bilet detayı cihazdaki kayıttan açılır (internetsiz QR). İptal sunucuya gider.
/// Geçerli bilette ekran açıkken biletin durumu canlı dinlenir: tur sorumlusu QR'ı
/// okutunca "Tura katıldı" hemen görünür; ekran kapanınca abonelik biter.
class TicketDetailCubit extends Cubit<TicketDetailState> {
  TicketDetailCubit(this._ticketRepository, {DateTime Function()? clock})
    : _now = clock ?? DateTime.now,
      super(const TicketDetailState());

  final TicketRepository _ticketRepository;
  final DateTime Function() _now;
  StreamSubscription<Ticket>? _liveSubscription;

  Future<void> load(String ticketId) async {
    final tickets = await _ticketRepository.getCachedTickets();
    if (isClosed) return;
    final ticket = tickets.where((ticket) => ticket.id == ticketId).firstOrNull;
    emit(
      ticket == null
          ? const TicketDetailState(status: TicketDetailStatus.notFound)
          : _ready(ticket),
    );
    if (ticket != null && ticket.isActive) _watch(ticket);
  }

  void _watch(Ticket ticket) {
    unawaited(_liveSubscription?.cancel());
    _liveSubscription = _ticketRepository.watchTicket(ticket).listen((updated) {
      if (isClosed) return;
      emit(_ready(updated, cancelStatus: state.cancelStatus));
    }, onError: (_) {});
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

  @override
  Future<void> close() async {
    await _liveSubscription?.cancel();
    return super.close();
  }
}
