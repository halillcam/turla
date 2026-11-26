import 'dart:async';

import 'package:turla_core/turla_core.dart';

import '../../domain/entities/active_tour.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/entities/chat_message.dart';
import '../models/live_tour_models.dart';

/// Aktif tur, sohbet ve duyuruların sunucu tarafı. Ham hata fırlatır.
abstract interface class LiveTourRemoteDataSource {
  String? get currentUserId;

  Future<ActiveTour> fetchActiveTour(String departureId);

  Future<List<ChatMessage>> fetchMessages(
    String departureId, {
    DateTime? before,
    required int limit,
  });

  Future<ChatMessage> sendMessage(String departureId, String body);

  Future<void> deleteMessage(String messageId);

  /// Realtime: bu tarihe eklenen mesajlar. Akış dinlenmeyi bırakınca kanal kapanır.
  Stream<ChatMessage> watchMessages(String departureId);

  Future<List<Announcement>> fetchAnnouncements(String departureId);

  Future<Announcement> sendAnnouncement(String departureId, String body);
}

class LiveTourRemoteDataSourceImpl implements LiveTourRemoteDataSource {
  const LiveTourRemoteDataSourceImpl(this._client);

  static const String _messages = 'messages';
  static const String _announcements = 'announcements';

  final SupabaseClient _client;

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  Future<ActiveTour> fetchActiveTour(String departureId) async {
    final json = await _client.rpc<Map<String, dynamic>>(
      'participant_departure_info',
      params: {'p_departure_id': departureId},
    );
    return ActiveTourModel.fromJson(json);
  }

  @override
  Future<List<ChatMessage>> fetchMessages(
    String departureId, {
    DateTime? before,
    required int limit,
  }) async {
    var query = _client
        .from(_messages)
        .select(ChatMessageModel.columns)
        .eq('departure_id', departureId);
    if (before != null) query = query.lt('created_at', before.toUtc().toIso8601String());
    final rows = await query.order('created_at', ascending: false).limit(limit);
    return rows.map(ChatMessageModel.fromRow).toList();
  }

  @override
  Future<ChatMessage> sendMessage(String departureId, String body) async {
    final row = await _client
        .from(_messages)
        .insert({'departure_id': departureId, 'body': body})
        .select(ChatMessageModel.columns)
        .single();
    return ChatMessageModel.fromRow(row);
  }

  @override
  Future<void> deleteMessage(String messageId) =>
      _client.from(_messages).delete().eq('id', messageId);

  @override
  Stream<ChatMessage> watchMessages(String departureId) {
    RealtimeChannel? channel;
    late final StreamController<ChatMessage> controller;
    controller = StreamController<ChatMessage>(
      onListen: () {
        channel = _client
            .channel('chat:$departureId')
            .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: _messages,
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'departure_id',
                value: departureId,
              ),
              callback: (payload) {
                if (!controller.isClosed) {
                  controller.add(ChatMessageModel.fromRow(payload.newRecord));
                }
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

  @override
  Future<List<Announcement>> fetchAnnouncements(String departureId) async {
    final rows = await _client
        .from(_announcements)
        .select(AnnouncementModel.columns)
        .eq('departure_id', departureId)
        .order('created_at', ascending: false);
    return rows.map(AnnouncementModel.fromRow).toList();
  }

  @override
  Future<Announcement> sendAnnouncement(String departureId, String body) async {
    final row = await _client
        .from(_announcements)
        .insert({'departure_id': departureId, 'body': body})
        .select(AnnouncementModel.columns)
        .single();
    return AnnouncementModel.fromRow(row);
  }
}
