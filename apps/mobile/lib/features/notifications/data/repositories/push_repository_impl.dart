import 'dart:async';

import '../../../../core/session/session_cleanup.dart';
import '../../domain/repositories/push_repository.dart';
import '../datasources/device_token_remote_data_source.dart';
import '../datasources/push_messaging_data_source.dart';

/// Cihaz token'ını hesaba bağlar; çıkışta siler. Push hataları uygulamayı bozmaz
/// (sessizce yutulur): uygulama içi bildirim kutusu yine çalışır.
class PushRepositoryImpl implements PushRepository, SessionCleanup {
  PushRepositoryImpl({
    required PushMessagingDataSource messagingDataSource,
    required DeviceTokenRemoteDataSource tokenDataSource,
  }) : _messaging = messagingDataSource,
       _tokens = tokenDataSource;

  static const String _platform = 'android';

  final PushMessagingDataSource _messaging;
  final DeviceTokenRemoteDataSource _tokens;
  StreamSubscription<String>? _tokenSubscription;

  @override
  Future<bool> registerDevice() async {
    if (!_messaging.isAvailable || !_tokens.isSignedIn) return false;
    try {
      final granted = await _messaging.requestPermission();
      // Token ilk kayıtta ve her yenilemede gelir; her seferinde hesaba yazılır.
      await _tokenSubscription?.cancel();
      _tokenSubscription = _messaging.tokens.listen(_register);
      await _messaging.register();
      return granted;
    } on Object {
      return false;
    }
  }

  @override
  Future<void> unregisterDevice() async {
    await _tokenSubscription?.cancel();
    _tokenSubscription = null;
    if (!_messaging.isAvailable) return;
    try {
      final token = _messaging.currentToken;
      if (token != null && _tokens.isSignedIn) await _tokens.remove(token);
      await _messaging.unregister();
    } on Object {
      // İnternet yoksa token sunucuda kalır; bir sonraki girişte yeni hesaba geçer.
    }
  }

  @override
  Future<void> beforeSignOut(String userId) => unregisterDevice();

  @override
  Future<void> afterSignOut(String userId) async {}

  @override
  Future<bool> hasPermission() async {
    try {
      return await _messaging.hasPermission();
    } on Object {
      return false;
    }
  }

  @override
  Stream<String?> get openedNotifications {
    late final StreamController<String?> controller;
    StreamSubscription<PushMessage>? subscription;
    controller = StreamController<String?>(
      onListen: () {
        unawaited(
          _messaging.initialMessage().then((message) {
            if (message != null && !controller.isClosed) controller.add(message.departureId);
          }, onError: (_) {}),
        );
        subscription = _messaging.opened.listen(
          (message) => controller.add(message.departureId),
          onError: (_) {},
        );
      },
      onCancel: () => subscription?.cancel(),
    );
    return controller.stream;
  }

  @override
  Stream<PushMessage> get foregroundMessages => _messaging.foreground;

  Future<void> _register(String token) async {
    if (!_tokens.isSignedIn) return;
    try {
      await _tokens.register(token, _platform);
    } on Object {
      // Bir sonraki açılışta yeniden denenir.
    }
  }
}
