import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../core/bloc/load_status.dart';
import '../../../../core/errors/panel_failure.dart';
import '../../../staff/domain/entities/staff_member.dart';
import '../../../staff/domain/repositories/account_repository.dart';
import '../../../tours/domain/entities/departure.dart';
import '../../domain/entities/participant_ticket.dart';
import '../../domain/repositories/ticket_admin_repository.dart';

/// Bir tarihin katılımcı / bilet listesi: yönetici iptali ve panelden bilet kesme.
/// İşlemlerden sonra liste yeniden çekilmez, yerelde güncellenir.
class ParticipantsCubit extends Cubit<ParticipantsState> {
  ParticipantsCubit({
    required this.companyId,
    required this.departure,
    required TicketAdminRepository ticketRepository,
    required AccountRepository accountRepository,
  }) : _tickets = ticketRepository,
       _accounts = accountRepository,
       super(const ParticipantsState());

  final String companyId;
  final Departure departure;
  final TicketAdminRepository _tickets;
  final AccountRepository _accounts;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));
    try {
      final results = await Future.wait([
        _tickets.listDepartureTickets(departure.id),
        // Bilet kesilebilecek müşteriler: firmanın panelden açtığı aktif müşteri hesapları.
        _accounts.listMembers(companyId, roles: const [UserRole.customer], activeOnly: true),
      ]);
      emit(
        ParticipantsState(
          status: LoadStatus.ready,
          tickets: results[0] as List<ParticipantTicket>,
          customers: results[1] as List<StaffMember>,
        ),
      );
    } on PanelFailure catch (failure) {
      emit(state.copyWith(status: LoadStatus.failure, loadFailure: failure.reason));
    }
  }

  Future<ActionResult<ParticipantTicket>> cancel(String ticketId) => _busy(() async {
    final updated = await _tickets.cancelTicket(ticketId);
    emit(
      state.copyWith(
        tickets: [for (final ticket in state.tickets) ticket.id == updated.id ? updated : ticket],
      ),
    );
    return updated;
  });

  Future<ActionResult<ParticipantTicket>> issue({
    required String customerId,
    String? passengerName,
  }) => _busy(() async {
    final created = await _tickets.issueTicket(
      departureId: departure.id,
      customerId: customerId,
      passengerName: passengerName,
    );
    emit(state.copyWith(tickets: [...state.tickets, created]));
    return created;
  });

  Future<ActionResult<T>> _busy<T>(Future<T> Function() action) async {
    emit(state.copyWith(isBusy: true));
    final result = await runAction(action);
    emit(state.copyWith(isBusy: false));
    return result;
  }
}

final class ParticipantsState extends Equatable {
  const ParticipantsState({
    this.status = LoadStatus.initial,
    this.tickets = const [],
    this.customers = const [],
    this.loadFailure,
    this.isBusy = false,
  });

  final LoadStatus status;
  final List<ParticipantTicket> tickets;

  /// Bilet kesilebilecek aktif müşteriler.
  final List<StaffMember> customers;
  final PanelFailureReason? loadFailure;
  final bool isBusy;

  /// Koltuk tutan bilet sayısı (tarih listesindeki "satılan" sütunu bununla güncellenir).
  int get soldSeats => tickets.where((ticket) => ticket.holdsSeat).length;

  /// Önce geçerli biletler, sonra iptaller; her grup alış sırasına göre.
  List<ParticipantTicket> get sortedTickets => [
    ...tickets.where((ticket) => ticket.holdsSeat),
    ...tickets.where((ticket) => !ticket.holdsSeat),
  ];

  ParticipantsState copyWith({
    LoadStatus? status,
    List<ParticipantTicket>? tickets,
    PanelFailureReason? loadFailure,
    bool? isBusy,
  }) => ParticipantsState(
    status: status ?? this.status,
    tickets: tickets ?? this.tickets,
    customers: customers,
    loadFailure: loadFailure ?? this.loadFailure,
    isBusy: isBusy ?? this.isBusy,
  );

  @override
  List<Object?> get props => [status, tickets, customers, loadFailure, isBusy];
}
