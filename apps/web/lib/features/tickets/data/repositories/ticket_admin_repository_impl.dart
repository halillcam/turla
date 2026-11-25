import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/panel_guard.dart';
import '../../domain/entities/participant_ticket.dart';
import '../../domain/repositories/ticket_admin_repository.dart';
import '../models/participant_ticket_model.dart';

class TicketAdminRepositoryImpl implements TicketAdminRepository {
  const TicketAdminRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<ParticipantTicket>> listDepartureTickets(String departureId) => guardPanel(() async {
    final rows = await _client
        .from(ParticipantTicketModel.table)
        .select(ParticipantTicketModel.columns)
        .eq('departure_id', departureId)
        .order('created_at');
    return rows.map(ParticipantTicketModel.fromRow).toList();
  });

  @override
  Future<ParticipantTicket> cancelTicket(String ticketId) => guardPanel(() async {
    final row = await _client.rpc<Map<String, dynamic>>(
      'cancel_ticket',
      params: {'p_ticket_id': ticketId},
    );
    return ParticipantTicketModel.fromRow(row);
  });

  @override
  Future<ParticipantTicket> issueTicket({
    required String departureId,
    required String customerId,
    String? passengerName,
  }) => guardPanel(() async {
    final name = passengerName?.trim();
    final row = await _client.rpc<Map<String, dynamic>>(
      'admin_issue_ticket',
      params: {
        'p_departure_id': departureId,
        'p_customer_id': customerId,
        if (name != null && name.isNotEmpty) 'p_passenger_name': name,
      },
    );
    return ParticipantTicketModel.fromRow(row);
  });
}
