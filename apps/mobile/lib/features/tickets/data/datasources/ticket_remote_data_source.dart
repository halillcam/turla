import 'dart:async';

import 'package:turla_core/turla_core.dart';

import '../../domain/entities/ticket.dart';
import '../models/ticket_model.dart';

/// Biletlerin sunucu tarafı. Yazma işlemleri sadece RPC ile yapılır
/// (tabloya istemciden yazılamaz).
abstract interface class TicketRemoteDataSource {
  /// Oturumdaki kullanıcı; giriş yapılmamışsa null.
  String? get currentUserId;

  Future<List<Ticket>> fetchMyTickets(String userId);

  Future<Ticket> fetchTicket(String ticketId);

  /// `book_ticket` çağırır, yeni biletin id'sini döndürür.
  Future<String> bookTicket({
    required String departureId,
    required String passengerName,
    required String passengerPhone,
  });

  /// `cancel_ticket` çağırır, iptal zamanını döndürür.
  Future<DateTime> cancelTicket(String ticketId);

  /// Realtime: biletin satırı değişince (durum, okutma zamanı). Dinleme bitince kanal kapanır.
  Stream<TicketLiveChange> watchTicket(String ticketId);
}

/// Bilet satırındaki canlı değişiklik.
typedef TicketLiveChange = ({TicketStatus status, DateTime? scannedAt, DateTime? cancelledAt});

class TicketRemoteDataSourceImpl implements TicketRemoteDataSource {
  const TicketRemoteDataSourceImpl(this._client);

  static const String _table = 'tickets';

  final SupabaseClient _client;

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  Future<List<Ticket>> fetchMyTickets(String userId) async {
    final rows = await _client
        .from(_table)
        .select(TicketModel.columns)
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return rows.map(TicketModel.fromRow).toList();
  }

  @override
  Future<Ticket> fetchTicket(String ticketId) async {
    final row = await _client.from(_table).select(TicketModel.columns).eq('id', ticketId).single();
    return TicketModel.fromRow(row);
  }

  @override
  Future<String> bookTicket({
    required String departureId,
    required String passengerName,
    required String passengerPhone,
  }) async {
    final row = await _client.rpc<Map<String, dynamic>>(
      'book_ticket',
      params: {
        'p_departure_id': departureId,
        'p_passenger_name': passengerName,
        'p_passenger_phone': passengerPhone,
      },
    );
    return row['id'] as String;
  }

  @override
  Future<DateTime> cancelTicket(String ticketId) async {
    final row = await _client.rpc<Map<String, dynamic>>(
      'cancel_ticket',
      params: {'p_ticket_id': ticketId},
    );
    return DateTime.parse(row['cancelled_at'] as String);
  }

  @override
  Stream<TicketLiveChange> watchTicket(String ticketId) {
    RealtimeChannel? channel;
    late final StreamController<TicketLiveChange> controller;
    controller = StreamController<TicketLiveChange>(
      onListen: () {
        channel = _client
            .channel('ticket:$ticketId')
            .onPostgresChanges(
              event: PostgresChangeEvent.update,
              schema: 'public',
              table: _table,
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'id',
                value: ticketId,
              ),
              callback: (payload) {
                if (!controller.isClosed) controller.add(_liveChange(payload.newRecord));
              },
            )
            .subscribe();
      },
      onCancel: () async {
        final open = channel;
        channel = null;
        if (open != null) await _client.removeChannel(open);
      },
    );
    return controller.stream;
  }

  static TicketLiveChange _liveChange(Map<String, dynamic> row) {
    final scannedAt = row['scanned_at'] as String?;
    final cancelledAt = row['cancelled_at'] as String?;
    return (
      status: TicketStatus.fromValue(row['status'] as String),
      scannedAt: scannedAt == null ? null : DateTime.parse(scannedAt),
      cancelledAt: cancelledAt == null ? null : DateTime.parse(cancelledAt),
    );
  }
}
