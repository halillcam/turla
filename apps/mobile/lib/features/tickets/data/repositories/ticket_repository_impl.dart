import 'dart:async';

import 'package:http/http.dart' show ClientException;
import 'package:turla_core/turla_core.dart';

import '../../domain/entities/ticket.dart';
import '../../domain/entities/ticket_failure.dart';
import '../../domain/repositories/ticket_repository.dart';
import '../datasources/ticket_local_data_source.dart';
import '../datasources/ticket_remote_data_source.dart';

class TicketRepositoryImpl implements TicketRepository {
  TicketRepositoryImpl({
    required TicketRemoteDataSource remoteDataSource,
    required TicketLocalDataSource localDataSource,
  }) : _remote = remoteDataSource,
       _local = localDataSource;

  final TicketRemoteDataSource _remote;
  final TicketLocalDataSource _local;
  final StreamController<List<Ticket>> _changes = StreamController.broadcast();

  @override
  Stream<List<Ticket>> get changes => _changes.stream;

  @override
  Future<List<Ticket>> getCachedTickets() async {
    final userId = _remote.currentUserId;
    if (userId == null) return const [];
    return await _readCacheSafely(userId) ?? const [];
  }

  @override
  Future<List<Ticket>> refreshTickets() async {
    final userId = _requireUser();
    final tickets = await _guard(() => _remote.fetchMyTickets(userId));
    await _save(userId, tickets);
    return tickets;
  }

  @override
  Future<Ticket> bookTicket({required String departureId, required String passengerName}) async {
    final userId = _requireUser();
    final ticket = await _guard(() async {
      final ticketId = await _remote.bookTicket(
        departureId: departureId,
        passengerName: passengerName.trim(),
      );
      return _remote.fetchTicket(ticketId);
    });
    final cached = await _readCacheSafely(userId) ?? const [];
    await _save(userId, [ticket, ...cached.where((other) => other.id != ticket.id)]);
    return ticket;
  }

  @override
  Future<Ticket> cancelTicket(Ticket ticket) async {
    final userId = _requireUser();
    final cancelledAt = await _guard(() => _remote.cancelTicket(ticket.id));
    // İptal sonucu sunucudan yeniden çekilmez: iade tutarı bilet fiyatıdır (tam iade).
    final updated = ticket.cancelled(cancelledAt);
    final cached = await _readCacheSafely(userId) ?? const [];
    await _save(userId, [
      for (final other in cached) other.id == updated.id ? updated : other,
      if (!cached.any((other) => other.id == updated.id)) updated,
    ]);
    return updated;
  }

  String _requireUser() {
    final userId = _remote.currentUserId;
    if (userId == null) throw const TicketFailure(TicketFailureReason.notSignedIn);
    return userId;
  }

  Future<void> _save(String userId, List<Ticket> tickets) async {
    try {
      await _local.write(userId, tickets);
    } on Object {
      // Cihaza yazılamaması işlemi bozmaz; liste bir sonraki yenilemede gelir.
    }
    _changes.add(tickets);
  }

  Future<List<Ticket>?> _readCacheSafely(String userId) async {
    try {
      return await _local.read(userId);
    } on Object {
      return null;
    }
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on TicketFailure {
      rethrow;
    } on PostgrestException catch (error) {
      throw TicketFailure(TicketErrorMapper.fromPostgrest(error.code, error.message), error);
    } on ClientException catch (error) {
      throw TicketFailure(TicketFailureReason.network, error);
    } on TimeoutException catch (error) {
      throw TicketFailure(TicketFailureReason.network, error);
    } on AuthException catch (error) {
      throw TicketFailure(
        error is AuthRetryableFetchException
            ? TicketFailureReason.network
            : TicketFailureReason.notSignedIn,
        error,
      );
    }
  }
}

/// Sunucu hata kodlarının (`raise exception '<kod>'`) eşlemesi.
abstract final class TicketErrorMapper {
  static TicketFailureReason fromPostgrest(String? code, String message) {
    final byMessage = _byCode[message.trim()];
    if (byMessage != null) return byMessage;
    return switch (code) {
      '42501' => TicketFailureReason.notAllowed,
      'PGRST116' => TicketFailureReason.ticketNotFound,
      _ => TicketFailureReason.unknown,
    };
  }

  static const Map<String, TicketFailureReason> _byCode = {
    'only_customers_can_book': TicketFailureReason.onlyCustomersCanBook,
    'departure_not_found': TicketFailureReason.departureNotFound,
    'tour_not_available': TicketFailureReason.tourNotAvailable,
    'departure_not_bookable': TicketFailureReason.departureNotBookable,
    'already_has_ticket': TicketFailureReason.alreadyHasTicket,
    'no_seats_left': TicketFailureReason.noSeatsLeft,
    'ticket_not_found': TicketFailureReason.ticketNotFound,
    'not_allowed': TicketFailureReason.notAllowed,
    'ticket_not_cancellable': TicketFailureReason.ticketNotCancellable,
    'cancellation_window_closed': TicketFailureReason.cancellationWindowClosed,
  };
}
