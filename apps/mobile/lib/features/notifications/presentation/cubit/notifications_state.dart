part of 'notifications_cubit.dart';

enum NotificationsStatus { loading, ready, failure }

final class NotificationsState extends Equatable {
  const NotificationsState({
    this.status = NotificationsStatus.loading,
    this.notifications = const [],
    this.isStale = false,
    this.failure,
  });

  final NotificationsStatus status;
  final List<AppNotification> notifications;

  /// İnternet yok, cihazdaki liste gösteriliyor.
  final bool isStale;
  final NotificationFailureReason? failure;

  bool get hasUnread => notifications.any((item) => !item.isRead);

  NotificationsState copyWith({
    NotificationsStatus? status,
    List<AppNotification>? notifications,
    bool? isStale,
    NotificationFailureReason? failure,
  }) => NotificationsState(
    status: status ?? this.status,
    notifications: notifications ?? this.notifications,
    isStale: isStale ?? this.isStale,
    failure: failure ?? this.failure,
  );

  @override
  List<Object?> get props => [status, notifications, isStale, failure];
}
