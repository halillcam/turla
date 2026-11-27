import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:turla_core/turla_core.dart';

import '../../domain/entities/app_notification.dart';
import '../models/notification_model.dart';

/// Bildirim kutusunun sunucu tarafı (RLS: kullanıcı sadece kendininkini görür).
abstract interface class NotificationRemoteDataSource {
  String? get currentUserId;

  Future<List<AppNotification>> fetch({required int limit});

  Future<void> markRead(String id);

  Future<void> markAllRead();
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  const NotificationRemoteDataSourceImpl(this._client);

  static const String _table = 'notifications';

  final SupabaseClient _client;

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  Future<List<AppNotification>> fetch({required int limit}) async {
    final rows = await _client
        .from(_table)
        .select(NotificationModel.columns)
        .order('created_at', ascending: false)
        .limit(limit);
    return rows.map(NotificationModel.fromRow).toList();
  }

  @override
  Future<void> markRead(String id) => _client.from(_table).update({'is_read': true}).eq('id', id);

  @override
  Future<void> markAllRead() => _client.from(_table).update({'is_read': true}).eq('is_read', false);
}

/// Bildirim kutusunu kullanıcı bazında cihazda saklar.
abstract interface class NotificationLocalDataSource {
  Future<List<AppNotification>?> read(String userId);

  Future<void> write(String userId, List<AppNotification> notifications);
}

class NotificationLocalDataSourceImpl implements NotificationLocalDataSource {
  NotificationLocalDataSourceImpl({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const String _versionKey = 'version';
  static const String _itemsKey = 'items';

  final SharedPreferencesAsync _preferences;

  String _key(String userId) => '${StorageKeys.notificationsByUserPrefix}$userId';

  @override
  Future<List<AppNotification>?> read(String userId) async {
    final raw = await _preferences.getString(_key(userId));
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      if (json[_versionKey] != CacheVersions.notifications) return null;
      return (json[_itemsKey] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(NotificationModel.fromRow)
          .toList();
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  @override
  Future<void> write(String userId, List<AppNotification> notifications) => _preferences.setString(
    _key(userId),
    jsonEncode({
      _versionKey: CacheVersions.notifications,
      _itemsKey: notifications.map(NotificationModel.toRow).toList(),
    }),
  );
}
