import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Push mesajı (başlık, metin, tur tarihi).
typedef PushMessage = ({String title, String body, String? departureId});

/// Firebase Cloud Messaging sarmalayıcısı. Firebase yapılandırılmamışsa
/// ([isAvailable] false) tüm çağrılar etkisizdir.
abstract interface class PushMessagingDataSource {
  bool get isAvailable;

  Future<bool> requestPermission();

  Future<bool> hasPermission();

  /// FCM kaydını başlatır; token [tokens] akışından gelir (yenilenince de).
  Future<void> register();

  /// FCM kaydını siler (bu telefona artık push gelmez).
  Future<void> unregister();

  Stream<String> get tokens;

  /// En son bilinen token (çıkışta sunucudan silmek için).
  String? get currentToken;

  /// Bildirime dokunulunca (uygulama arka planda/kapalıyken) mesaj.
  Stream<PushMessage> get opened;

  /// Uygulama açıkken gelen mesaj (sistem bildirimi göstermez).
  Stream<PushMessage> get foreground;

  /// Uygulama kapalıyken bildirime dokunup açıldıysa o mesaj.
  Future<PushMessage?> initialMessage();
}

class FirebasePushMessagingDataSource implements PushMessagingDataSource {
  FirebasePushMessagingDataSource._(this._available) {
    if (_available) {
      _tokenSubscription = FirebaseMessaging.instance.onRegistered.listen(
        (token) => _currentToken = token,
      );
      FirebaseMessaging.instance.onUnregistered.listen((_) => _currentToken = null);
    }
  }

  /// Firebase'i başlatır; google-services.json yoksa push kapalı döner.
  static Future<FirebasePushMessagingDataSource> initialize() async {
    try {
      await Firebase.initializeApp();
      return FirebasePushMessagingDataSource._(true);
    } on Object {
      return FirebasePushMessagingDataSource._(false);
    }
  }

  final bool _available;
  String? _currentToken;
  // Uygulama boyu yaşar (kayıt olayları kaçmasın).
  // ignore: unused_field
  StreamSubscription<String>? _tokenSubscription;

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  @override
  bool get isAvailable => _available;

  @override
  String? get currentToken => _currentToken;

  @override
  Future<bool> requestPermission() async {
    if (!_available) return false;
    final settings = await _messaging.requestPermission();
    return _granted(settings.authorizationStatus);
  }

  @override
  Future<bool> hasPermission() async {
    if (!_available) return false;
    final settings = await _messaging.getNotificationSettings();
    return _granted(settings.authorizationStatus);
  }

  @override
  Future<void> register() => _available ? _messaging.register() : Future.value();

  @override
  Future<void> unregister() => _available ? _messaging.unregister() : Future.value();

  @override
  Stream<String> get tokens => _available ? _messaging.onRegistered : const Stream.empty();

  @override
  Stream<PushMessage> get opened =>
      _available ? FirebaseMessaging.onMessageOpenedApp.map(_toMessage) : const Stream.empty();

  @override
  Stream<PushMessage> get foreground =>
      _available ? FirebaseMessaging.onMessage.map(_toMessage) : const Stream.empty();

  @override
  Future<PushMessage?> initialMessage() async {
    if (!_available) return null;
    final message = await _messaging.getInitialMessage();
    return message == null ? null : _toMessage(message);
  }

  static bool _granted(AuthorizationStatus status) =>
      status == AuthorizationStatus.authorized || status == AuthorizationStatus.provisional;

  static PushMessage _toMessage(RemoteMessage message) => (
    title: message.notification?.title ?? '',
    body: message.notification?.body ?? '',
    departureId: message.data['departure_id'] as String?,
  );
}
