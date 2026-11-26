import 'dart:async';

import 'package:http/http.dart' show ClientException;
import 'package:turla_core/turla_core.dart';

import '../../domain/entities/app_notification.dart';
import '../../domain/entities/notification_failure.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_data_sources.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl({
    required NotificationRemoteDataSource remoteDataSource,
    required NotificationLocalDataSource localDataSource,
  }) : _remote = remoteDataSource,
       _local = localDataSource;

  final NotificationRemoteDataSource _remote;
  final NotificationLocalDataSource _local;
  final StreamController<List<AppNotification>> _changes = StreamController.broadcast();

  @override
  Stream<List<AppNotification>> get changes => _changes.stream;

  @override
  Future<List<AppNotification>?> getCached() async {
    final userId = _remote.currentUserId;
    if (userId == null) return null;
    return _readSafely(userId);
  }

  @override
  Future<List<AppNotification>> refresh() async {
    final userId = _requireUser();
    final list = await _guard(() => _remote.fetch(limit: NotificationRepository.pageSize));
    await _save(userId, list);
    return list;
  }

  @override
  Future<void> markRead(AppNotification notification) async {
    if (notification.isRead) return;
    final userId = _requireUser();
    await _guard(() => _remote.markRead(notification.id));
    final cached = await _readSafely(userId) ?? const [];
    await _save(userId, [
      for (final item in cached) item.id == notification.id ? item.markedRead() : item,
    ]);
  }

  @override
  Future<void> markAllRead() async {
    final userId = _requireUser();
    await _guard(_remote.markAllRead);
    final cached = await _readSafely(userId) ?? const [];
    await _save(userId, [for (final item in cached) item.markedRead()]);
  }

  String _requireUser() {
    final userId = _remote.currentUserId;
    if (userId == null) throw const NotificationFailure(NotificationFailureReason.notSignedIn);
    return userId;
  }

  Future<void> _save(String userId, List<AppNotification> list) async {
    try {
      await _local.write(userId, list);
    } on Object {
      // Cihaza yazılamaması işlemi bozmaz.
    }
    _changes.add(list);
  }

  Future<List<AppNotification>?> _readSafely(String userId) async {
    try {
      return await _local.read(userId);
    } on Object {
      return null;
    }
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action().timeout(AppDurations.requestTimeout);
    } on PostgrestException catch (error) {
      throw NotificationFailure(NotificationFailureReason.unknown, error);
    } on ClientException catch (error) {
      throw NotificationFailure(NotificationFailureReason.network, error);
    } on TimeoutException catch (error) {
      throw NotificationFailure(NotificationFailureReason.network, error);
    } on AuthException catch (error) {
      throw NotificationFailure(
        error is AuthRetryableFetchException
            ? NotificationFailureReason.network
            : NotificationFailureReason.notSignedIn,
        error,
      );
    }
  }
}
