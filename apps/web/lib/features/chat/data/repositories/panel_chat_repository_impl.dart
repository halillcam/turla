import 'package:turla_core/turla_core.dart';

import '../../../../core/errors/panel_failure.dart';
import '../../../../core/errors/panel_guard.dart';
import '../../domain/entities/panel_chat_message.dart';
import '../../domain/repositories/panel_chat_repository.dart';

class PanelChatRepositoryImpl implements PanelChatRepository {
  const PanelChatRepositoryImpl(this._client);

  static const String _table = 'messages';
  static const String _columns = 'id, sender_id, sender_name, sender_role, body, created_at';

  final SupabaseClient _client;

  @override
  Future<List<PanelChatMessage>> listMessages(String departureId, {DateTime? before}) =>
      guardPanel(() async {
        var query = _client.from(_table).select(_columns).eq('departure_id', departureId);
        if (before != null) query = query.lt('created_at', before.toUtc().toIso8601String());
        final rows = await query
            .order('created_at', ascending: false)
            .limit(PanelChatRepository.pageSize);
        return rows.map(fromRow).toList();
      });

  @override
  Future<PanelChatMessage> send(String departureId, String body) => guardPanel(() async {
    final text = body.trim();
    if (text.isEmpty || text.length > PanelChatMessage.maxLength) {
      throw const PanelFailure(PanelFailureReason.invalidInput);
    }
    final row = await _client
        .from(_table)
        .insert({'departure_id': departureId, 'body': text})
        .select(_columns)
        .single();
    return fromRow(row);
  });

  @override
  Future<void> delete(String messageId) =>
      guardPanel(() => _client.from(_table).delete().eq('id', messageId));

  static PanelChatMessage fromRow(Map<String, dynamic> row) => PanelChatMessage(
    id: row['id'] as String,
    senderId: row['sender_id'] as String,
    senderName: row['sender_name'] as String,
    senderRole: UserRole.fromValue((row['sender_role'] as String?) ?? UserRole.customer.value),
    body: row['body'] as String,
    createdAt: DateTime.parse(row['created_at'] as String),
  );
}
