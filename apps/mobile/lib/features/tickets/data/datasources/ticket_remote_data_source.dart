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
  Future<String> bookTicket({required String departureId, required String passengerName});

  /// `cancel_ticket` çağırır, iptal zamanını döndürür.
  Future<DateTime> cancelTicket(String ticketId);
}

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
  Future<String> bookTicket({required String departureId, required String passengerName}) async {
    final row = await _client.rpc<Map<String, dynamic>>(
      'book_ticket',
      params: {'p_departure_id': departureId, 'p_passenger_name': passengerName},
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
}
