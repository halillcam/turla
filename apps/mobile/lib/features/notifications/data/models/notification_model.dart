import '../../domain/entities/app_notification.dart';

/// Supabase satırı ↔ [AppNotification]. Cihazdaki önbellek de aynı biçimi kullanır.
abstract final class NotificationModel {
  static const String columns = 'id, title, body, departure_id, is_read, created_at';

  static AppNotification fromRow(Map<String, dynamic> row) => AppNotification(
    id: row['id'] as String,
    title: row['title'] as String,
    body: row['body'] as String,
    departureId: row['departure_id'] as String?,
    isRead: row['is_read'] as bool? ?? false,
    createdAt: DateTime.parse(row['created_at'] as String),
  );

  static Map<String, dynamic> toRow(AppNotification notification) => {
    'id': notification.id,
    'title': notification.title,
    'body': notification.body,
    'departure_id': notification.departureId,
    'is_read': notification.isRead,
    'created_at': notification.createdAt.toUtc().toIso8601String(),
  };
}
