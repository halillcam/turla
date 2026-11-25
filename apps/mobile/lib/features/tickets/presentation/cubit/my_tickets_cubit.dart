import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/ticket.dart';
import '../../domain/entities/ticket_failure.dart';
import '../../domain/repositories/ticket_repository.dart';

part 'my_tickets_state.dart';

/// Turlarım: önce cihazdaki biletler gösterilir, ardından sunucudan yenilenir.
/// Alma/iptal sonrası liste repository'nin [TicketRepository.changes] akışıyla
/// güncellenir (yeniden istek atılmaz).
class MyTicketsCubit extends Cubit<MyTicketsState> {
  MyTicketsCubit(this._ticketRepository) : super(const MyTicketsState()) {
    _subscription = _ticketRepository.changes.listen(
      (tickets) => emit(state.copyWith(status: MyTicketsStatus.ready, tickets: tickets)),
    );
  }

  final TicketRepository _ticketRepository;
  late final StreamSubscription<List<Ticket>> _subscription;

  /// Ekran açılınca: cihazdaki liste hemen, ardından sunucudan güncel liste.
  Future<void> load() async {
    final cached = await _ticketRepository.getCachedTickets();
    if (isClosed) return;
    if (cached.isNotEmpty) {
      emit(state.copyWith(status: MyTicketsStatus.ready, tickets: cached));
    }
    await refresh();
  }

  /// Aşağı çekince.
  Future<void> refresh() async {
    emit(state.copyWith(isRefreshing: true));
    try {
      final tickets = await _ticketRepository.refreshTickets();
      if (isClosed) return;
      emit(MyTicketsState(status: MyTicketsStatus.ready, tickets: tickets));
    } on TicketFailure catch (failure) {
      if (isClosed) return;
      final hasData = state.status == MyTicketsStatus.ready;
      emit(
        MyTicketsState(
          status: hasData ? MyTicketsStatus.ready : MyTicketsStatus.failure,
          tickets: state.tickets,
          isStale: hasData,
          failure: failure.reason,
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
