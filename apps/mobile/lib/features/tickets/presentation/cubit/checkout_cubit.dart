import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/ticket.dart';
import '../../domain/entities/ticket_failure.dart';
import '../../domain/repositories/ticket_repository.dart';

part 'checkout_state.dart';

/// Demo ödeme ekranı: bileti `book_ticket` ile alır. Kontenjan, tarih ve
/// rol kontrolleri sunucudadır.
class CheckoutCubit extends Cubit<CheckoutState> {
  CheckoutCubit(this._ticketRepository) : super(const CheckoutState());

  final TicketRepository _ticketRepository;

  Future<void> purchase({required String departureId, required String passengerName}) async {
    if (state.status == CheckoutStatus.submitting || state.status == CheckoutStatus.success) {
      return;
    }
    emit(const CheckoutState(status: CheckoutStatus.submitting));
    try {
      final ticket = await _ticketRepository.bookTicket(
        departureId: departureId,
        passengerName: passengerName,
      );
      if (isClosed) return;
      emit(CheckoutState(status: CheckoutStatus.success, ticket: ticket));
    } on TicketFailure catch (failure) {
      if (isClosed) return;
      emit(CheckoutState(status: CheckoutStatus.failure, failure: failure.reason));
    }
  }
}
