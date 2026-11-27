part of 'notification_center_cubit.dart';

/// Push bildirimine dokunuldu: açılacak tur tarihi (yoksa bildirim kutusu açılır).
final class OpenRequest extends Equatable {
  const OpenRequest(this.departureId, this.seq);

  final String? departureId;
  final int seq;

  @override
  List<Object?> get props => [departureId, seq];
}

/// Uygulama açıkken gelen bildirim (ekranda kısa mesaj olarak gösterilir).
final class ForegroundNotice extends Equatable {
  const ForegroundNotice({
    required this.title,
    required this.body,
    required this.seq,
    this.departureId,
  });

  final String title;
  final String body;
  final String? departureId;
  final int seq;

  @override
  List<Object?> get props => [title, body, departureId, seq];
}

final class NotificationCenterState extends Equatable {
  const NotificationCenterState({
    this.isActive = false,
    this.unreadCount = 0,
    this.pushPermissionGranted = true,
    this.openRequest,
    this.foreground,
  });

  /// Müşteri oturumu açık.
  final bool isActive;
  final int unreadCount;

  /// İzin reddedildiyse bildirim kutusunda uyarı gösterilir.
  final bool pushPermissionGranted;
  final OpenRequest? openRequest;
  final ForegroundNotice? foreground;

  /// Her olayda artan sıra (aynı içerikli iki olay da ayrı yakalansın).
  int get eventSeq => [openRequest?.seq ?? 0, foreground?.seq ?? 0].reduce((a, b) => a > b ? a : b);

  NotificationCenterState copyWith({
    bool? isActive,
    int? unreadCount,
    bool? pushPermissionGranted,
    OpenRequest? openRequest,
    ForegroundNotice? foreground,
  }) => NotificationCenterState(
    isActive: isActive ?? this.isActive,
    unreadCount: unreadCount ?? this.unreadCount,
    pushPermissionGranted: pushPermissionGranted ?? this.pushPermissionGranted,
    openRequest: openRequest ?? this.openRequest,
    foreground: foreground ?? this.foreground,
  );

  @override
  List<Object?> get props => [
    isActive,
    unreadCount,
    pushPermissionGranted,
    openRequest,
    foreground,
  ];
}
