import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/app_notification.dart';
import '../../domain/entities/notification_failure.dart';
import '../../domain/repositories/notification_repository.dart';

part 'notifications_state.dart';

/// Bildirim kutusu ekranı: önce cihazdaki liste, sonra sunucudan yenileme.
/// Okundu işaretleri cihazdaki listeye yazılır, liste yeniden çekilmez.
class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit(this._repository) : super(const NotificationsState()) {
    _subscription = _repository.changes.listen((list) {
      if (!isClosed) emit(state.copyWith(notifications: list));
    });
  }

  final NotificationRepository _repository;
  StreamSubscription<List<AppNotification>>? _subscription;

  Future<void> load() async {
    final cached = await _repository.getCached();
    if (isClosed) return;
    if (cached != null) {
      emit(state.copyWith(status: NotificationsStatus.ready, notifications: cached));
    }
    await refresh();
  }

  Future<void> refresh() async {
    try {
      final list = await _repository.refresh();
      if (isClosed) return;
      emit(NotificationsState(status: NotificationsStatus.ready, notifications: list));
    } on NotificationFailure catch (failure) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: state.notifications.isEmpty
              ? NotificationsStatus.failure
              : NotificationsStatus.ready,
          isStale: true,
          failure: failure.reason,
        ),
      );
    }
  }

  Future<void> markRead(AppNotification notification) async {
    try {
      await _repository.markRead(notification);
    } on NotificationFailure catch (failure) {
      if (!isClosed) emit(state.copyWith(failure: failure.reason));
    }
  }

  Future<void> markAllRead() async {
    try {
      await _repository.markAllRead();
    } on NotificationFailure catch (failure) {
      if (!isClosed) emit(state.copyWith(failure: failure.reason));
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
