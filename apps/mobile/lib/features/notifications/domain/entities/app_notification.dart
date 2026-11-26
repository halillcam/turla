import 'package:equatable/equatable.dart';

/// Kullanıcının bildirim kutusundaki bir kayıt (ör. tur sorumlusunun duyurusu).
class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.departureId,
  });

  final String id;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;

  /// Duyurunun ait olduğu tur tarihi (dokununca o turun duyuruları açılır).
  final String? departureId;

  AppNotification markedRead() => AppNotification(
    id: id,
    title: title,
    body: body,
    isRead: true,
    createdAt: createdAt,
    departureId: departureId,
  );

  @override
  List<Object?> get props => [id, title, body, isRead, createdAt, departureId];
}
