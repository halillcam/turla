import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' show ClientException;
import 'package:turla_mobile/features/notifications/data/datasources/device_token_remote_data_source.dart';
import 'package:turla_mobile/features/notifications/data/datasources/notification_data_sources.dart';
import 'package:turla_mobile/features/notifications/data/datasources/push_messaging_data_source.dart';
import 'package:turla_mobile/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:turla_mobile/features/notifications/data/repositories/push_repository_impl.dart';
import 'package:turla_mobile/features/notifications/domain/entities/app_notification.dart';
import 'package:turla_mobile/features/notifications/domain/entities/notification_failure.dart';
import 'package:turla_mobile/features/notifications/presentation/cubit/notification_center_cubit.dart';
import 'package:turla_mobile/features/notifications/presentation/cubit/notifications_cubit.dart';

AppNotification _n(String id, {bool read = false}) => AppNotification(
  id: id,
  title: 'Göksun Turu',
  body: 'Duyuru $id',
  isRead: read,
  createdAt: DateTime.utc(2026, 12, 1, 8),
  departureId: 'dep-1',
);

class _FakeRemote implements NotificationRemoteDataSource {
  @override
  String? currentUserId = 'u1';
  List<AppNotification> server = [_n('1'), _n('2'), _n('3', read: true)];
  Object? error;
  int fetchCalls = 0;
  final List<String> markedRead = [];
  bool markedAll = false;

  @override
  Future<List<AppNotification>> fetch({required int limit}) async {
    fetchCalls++;
    if (error != null) throw error!;
    return server;
  }

  @override
  Future<void> markRead(String id) async => markedRead.add(id);

  @override
  Future<void> markAllRead() async => markedAll = true;
}

class _FakeLocal implements NotificationLocalDataSource {
  final Map<String, List<AppNotification>> store = {};

  @override
  Future<List<AppNotification>?> read(String userId) async => store[userId];

  @override
  Future<void> write(String userId, List<AppNotification> notifications) async =>
      store[userId] = notifications;
}

class _FakeMessaging implements PushMessagingDataSource {
  @override
  bool isAvailable = true;
  bool granted = true;
  bool failRegister = false;
  bool registered = false;
  bool unregistered = false;
  @override
  String? currentToken;
  final StreamController<String> tokenController = StreamController.broadcast();
  final StreamController<PushMessage> openedController = StreamController.broadcast();
  final StreamController<PushMessage> foregroundController = StreamController.broadcast();

  @override
  Future<bool> requestPermission() async => granted;

  @override
  Future<bool> hasPermission() async => granted;

  @override
  Future<void> register() async {
    if (failRegister) throw StateError('FIS unavailable');
    registered = true;
    currentToken = 'token-1';
    tokenController.add('token-1');
  }

  @override
  Future<void> unregister() async => unregistered = true;

  @override
  Stream<String> get tokens => tokenController.stream;

  @override
  Stream<PushMessage> get opened => openedController.stream;

  @override
  Stream<PushMessage> get foreground => foregroundController.stream;

  @override
  Future<PushMessage?> initialMessage() async => null;
}

class _FakeTokens implements DeviceTokenRemoteDataSource {
  @override
  bool isSignedIn = true;
  final List<String> registered = [];
  final List<String> removed = [];

  @override
  Future<void> register(String token, String platform) async => registered.add('$token:$platform');

  @override
  Future<void> remove(String token) async => removed.add(token);
}

Future<void> _flush() => Future<void>.delayed(Duration.zero);

void main() {
  late _FakeRemote remote;
  late _FakeLocal local;
  late NotificationRepositoryImpl repository;

  setUp(() {
    remote = _FakeRemote();
    local = _FakeLocal();
    repository = NotificationRepositoryImpl(remoteDataSource: remote, localDataSource: local);
  });

  group('NotificationRepositoryImpl', () {
    test('yenileme cihaza yazar ve değişikliği yayar', () async {
      final emitted = <List<AppNotification>>[];
      final sub = repository.changes.listen(emitted.add);
      await repository.refresh();
      await _flush();
      expect(local.store['u1'], hasLength(3));
      expect(emitted.single, hasLength(3));
      await sub.cancel();
    });

    test('okundu işareti cihazdaki listeye yazılır, liste yeniden çekilmez', () async {
      await repository.refresh();
      await repository.markRead(_n('1'));
      expect(remote.markedRead, ['1']);
      expect(remote.fetchCalls, 1);
      expect(local.store['u1']!.first.isRead, isTrue);
    });

    test('okunmuş bildirim için istek atılmaz', () async {
      await repository.markRead(_n('3', read: true));
      expect(remote.markedRead, isEmpty);
    });

    test('tümünü okundu yap', () async {
      await repository.refresh();
      await repository.markAllRead();
      expect(remote.markedAll, isTrue);
      expect(local.store['u1']!.every((n) => n.isRead), isTrue);
    });

    test('ağ hatası network, cihazdaki liste kalır', () async {
      local.store['u1'] = [_n('eski')];
      remote.error = ClientException('yok');
      await expectLater(
        repository.refresh(),
        throwsA(
          isA<NotificationFailure>().having(
            (f) => f.reason,
            'r',
            NotificationFailureReason.network,
          ),
        ),
      );
      expect((await repository.getCached())!.single.id, 'eski');
    });
  });

  group('NotificationsCubit', () {
    test('internet yoksa cihazdaki liste eski olarak gösterilir', () async {
      local.store['u1'] = [_n('eski')];
      remote.error = ClientException('yok');
      final cubit = NotificationsCubit(repository);
      await cubit.load();
      expect(cubit.state.status, NotificationsStatus.ready);
      expect(cubit.state.isStale, isTrue);
      expect(cubit.state.notifications.single.id, 'eski');
      await cubit.close();
    });

    test('okundu işaretleyince liste (changes akışından) güncellenir', () async {
      final cubit = NotificationsCubit(repository);
      await cubit.load();
      expect(cubit.state.hasUnread, isTrue);
      await cubit.markAllRead();
      await _flush();
      expect(cubit.state.hasUnread, isFalse);
      await cubit.close();
    });
  });

  group('PushRepositoryImpl', () {
    test('kayıtta izin istenir ve gelen token hesaba yazılır; yenilenen token da', () async {
      final messaging = _FakeMessaging();
      final tokens = _FakeTokens();
      final push = PushRepositoryImpl(messagingDataSource: messaging, tokenDataSource: tokens);
      expect(await push.registerDevice(), isTrue);
      await _flush();
      messaging.tokenController.add('token-2');
      await _flush();
      expect(tokens.registered, ['token-1:android', 'token-2:android']);
    });

    test('çıkışta token sunucudan silinir ve FCM kaydı kaldırılır', () async {
      final messaging = _FakeMessaging();
      final tokens = _FakeTokens();
      final push = PushRepositoryImpl(messagingDataSource: messaging, tokenDataSource: tokens);
      await push.registerDevice();
      await push.beforeSignOut('u1');
      expect(tokens.removed, ['token-1']);
      expect(messaging.unregistered, isTrue);
      messaging.tokenController.add('token-3');
      await _flush();
      expect(tokens.registered, isNot(contains('token-3:android')));
    });

    test('Firebase yoksa hiçbir şey yapılmaz', () async {
      final messaging = _FakeMessaging()..isAvailable = false;
      final tokens = _FakeTokens();
      final push = PushRepositoryImpl(messagingDataSource: messaging, tokenDataSource: tokens);
      expect(await push.registerDevice(), isFalse);
      await push.unregisterDevice();
      expect(messaging.registered, isFalse);
      expect(tokens.removed, isEmpty);
    });
  });

  group('NotificationCenterCubit', () {
    late _FakeMessaging messaging;
    late NotificationCenterCubit cubit;

    setUp(() {
      messaging = _FakeMessaging();
      cubit = NotificationCenterCubit(
        notificationRepository: repository,
        pushRepository: PushRepositoryImpl(
          messagingDataSource: messaging,
          tokenDataSource: _FakeTokens(),
        ),
      );
    });

    tearDown(() => cubit.close());

    test('müşteri girişinde rozet okunmamış sayısını gösterir, push kaydolur', () async {
      await cubit.sessionChanged(isCustomer: true);
      await _flush();
      expect(cubit.state.isActive, isTrue);
      expect(cubit.state.unreadCount, 2);
      expect(messaging.registered, isTrue);
    });

    test('push kaydı ağ yüzünden başarısızsa izin verilmişse uyarı çıkmaz', () async {
      messaging.failRegister = true;
      await cubit.sessionChanged(isCustomer: true);
      expect(cubit.state.pushPermissionGranted, isTrue);
    });

    test('izin reddedilirse durum saklanır', () async {
      messaging.granted = false;
      await cubit.sessionChanged(isCustomer: true);
      expect(cubit.state.pushPermissionGranted, isFalse);
    });

    test('uygulama açıkken push gelince bildirim olayı ve rozet yenilemesi', () async {
      await cubit.sessionChanged(isCustomer: true);
      remote.server = [_n('yeni'), ...remote.server];
      messaging.foregroundController.add((title: 'Göksun', body: 'Mola', departureId: 'dep-1'));
      await _flush();
      await _flush();
      expect(cubit.state.foreground?.body, 'Mola');
      expect(cubit.state.unreadCount, 3);
    });

    test('push dokunuşu açılacak turu bildirir', () async {
      await cubit.sessionChanged(isCustomer: true);
      messaging.openedController.add((title: 'a', body: 'b', departureId: 'dep-9'));
      await _flush();
      expect(cubit.state.openRequest?.departureId, 'dep-9');
    });

    test('çıkışta sıfırlanır ve push olayları dinlenmez', () async {
      await cubit.sessionChanged(isCustomer: true);
      await cubit.sessionChanged(isCustomer: false);
      expect(cubit.state, const NotificationCenterState());
      expect(messaging.openedController.hasListener, isFalse);
    });
  });
}
