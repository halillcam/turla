import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/app_notification.dart';
import '../../domain/entities/notification_failure.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/repositories/push_repository.dart';

part 'notification_center_state.dart';

/// Uygulama boyu yaşar: okunmamış rozeti, push kaydı, push'a dokununca açılacak
/// tur ve uygulama açıkken gelen bildirim. Sadece müşteri oturumunda çalışır.
class NotificationCenterCubit extends Cubit<NotificationCenterState> {
  NotificationCenterCubit({
    required NotificationRepository notificationRepository,
    required PushRepository pushRepository,
  }) : _notifications = notificationRepository,
       _push = pushRepository,
       super(const NotificationCenterState()) {
    _changesSubscription = _notifications.changes.listen(_onListChanged);
  }

  final NotificationRepository _notifications;
  final PushRepository _push;
  StreamSubscription<List<AppNotification>>? _changesSubscription;
  StreamSubscription<String?>? _openedSubscription;
  StreamSubscription<({String title, String body, String? departureId})>? _foregroundSubscription;

  /// Oturum değişince çağrılır. Müşteri girişinde push kaydı + rozet yenilemesi
  /// yapılır; çıkışta her şey sıfırlanır.
  Future<void> sessionChanged({required bool isCustomer}) async {
    if (!isCustomer) {
      await _stopListening();
      if (!isClosed) emit(const NotificationCenterState());
      return;
    }
    if (state.isActive) return;
    emit(state.copyWith(isActive: true));
    _openedSubscription = _push.openedNotifications.listen(_onOpened);
    _foregroundSubscription = _push.foregroundMessages.listen(_onForeground);
    final cached = await _notifications.getCached();
    if (cached != null) _onListChanged(cached);
    await refresh();
    // Uyarı telefonun izin durumuna bakar; push kaydı ağ yüzünden başarısız olsa da
    // izin verilmişse "izin kapalı" denmez.
    await _push.registerDevice();
    final granted = await _push.hasPermission();
    if (!isClosed) emit(state.copyWith(pushPermissionGranted: granted));
  }

  /// Sunucudan sessizce yeniler (hata rozeti bozmaz).
  Future<void> refresh() async {
    if (!state.isActive) return;
    try {
      await _notifications.refresh();
    } on NotificationFailure {
      // İnternet yok: cihazdaki sayı kalır.
    }
  }

  void _onListChanged(List<AppNotification> list) {
    if (isClosed || !state.isActive) return;
    emit(state.copyWith(unreadCount: list.where((item) => !item.isRead).length));
  }

  void _onOpened(String? departureId) {
    if (isClosed) return;
    emit(state.copyWith(openRequest: OpenRequest(departureId, state.eventSeq + 1)));
    unawaited(refresh());
  }

  void _onForeground(({String title, String body, String? departureId}) message) {
    if (isClosed) return;
    emit(
      state.copyWith(
        foreground: ForegroundNotice(
          title: message.title,
          body: message.body,
          departureId: message.departureId,
          seq: state.eventSeq + 1,
        ),
      ),
    );
    unawaited(refresh());
  }

  Future<void> _stopListening() async {
    await _openedSubscription?.cancel();
    await _foregroundSubscription?.cancel();
    _openedSubscription = null;
    _foregroundSubscription = null;
  }

  @override
  Future<void> close() async {
    await _changesSubscription?.cancel();
    await _stopListening();
    return super.close();
  }
}
