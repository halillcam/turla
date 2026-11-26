import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:turla_core/turla_core.dart';
import 'package:turla_mobile/core/session/session_cleanup.dart';
import 'package:turla_mobile/features/auth/presentation/bloc/session_bloc.dart';

import '../../helpers/fixtures.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository auth;
  late StreamController<void> authChanges;

  setUp(() {
    auth = _MockAuthRepository();
    authChanges = StreamController<void>.broadcast();
    when(() => auth.authStateChanges).thenAnswer((_) => authChanges.stream);
    when(() => auth.signOut()).thenAnswer((_) async {});
  });

  tearDown(() => authChanges.close());

  blocTest<SessionBloc, SessionState>(
    'oturum yoksa misafir olur',
    build: () {
      when(() => auth.currentProfile()).thenAnswer((_) async => null);
      return SessionBloc(auth);
    },
    act: (bloc) => bloc.add(const SessionStarted()),
    expect: () => [const SessionState.guest()],
  );

  blocTest<SessionBloc, SessionState>(
    'müşteri oturumu açık kalır',
    build: () {
      when(() => auth.currentProfile()).thenAnswer((_) async => profileWith(UserRole.customer));
      return SessionBloc(auth);
    },
    act: (bloc) => bloc.add(const SessionStarted()),
    expect: () => [SessionState.signedIn(profileWith(UserRole.customer))],
  );

  blocTest<SessionBloc, SessionState>(
    'admin hesabıyla açılan oturum kapatılır ve kullanıcıya nedeni bildirilir',
    build: () {
      when(() => auth.currentProfile()).thenAnswer((_) async => profileWith(UserRole.admin));
      return SessionBloc(auth);
    },
    act: (bloc) => bloc.add(const SessionStarted()),
    expect: () => [const SessionState.guest(notice: AuthFailureReason.roleNotAllowed)],
    verify: (_) => verify(() => auth.signOut()).called(1),
  );

  blocTest<SessionBloc, SessionState>(
    'giriş yapılınca (auth olayı) profil yeniden yüklenir',
    build: () {
      var calls = 0;
      when(
        () => auth.currentProfile(),
      ).thenAnswer((_) async => calls++ == 0 ? null : profileWith(UserRole.customer));
      return SessionBloc(auth);
    },
    act: (bloc) async {
      bloc.add(const SessionStarted());
      await Future<void>.delayed(Duration.zero);
      authChanges.add(null);
    },
    wait: const Duration(milliseconds: 10),
    expect: () => [
      const SessionState.guest(),
      SessionState.signedIn(profileWith(UserRole.customer)),
    ],
  );

  blocTest<SessionBloc, SessionState>(
    'çıkış yapılınca misafir olur',
    build: () => SessionBloc(auth),
    seed: () => SessionState.signedIn(profileWith(UserRole.customer)),
    act: (bloc) => bloc.add(const SessionSignOutRequested()),
    expect: () => [const SessionState.guest()],
  );

  test('çıkışta temizlik sırası: önce push token (oturum açıkken), sonra önbellek', () async {
    final calls = <String>[];
    when(() => auth.signOut()).thenAnswer((_) async => calls.add('signOut'));
    final bloc = SessionBloc(auth, cleanups: [_RecordingCleanup('push', calls)]);
    bloc.emit(SessionState.signedIn(profileWith(UserRole.customer)));
    bloc.add(const SessionSignOutRequested());
    await bloc.stream.firstWhere((state) => state.status == SessionStatus.guest);
    final userId = profileWith(UserRole.customer).id;
    expect(calls, ['push.before:$userId', 'signOut', 'push.after:$userId']);
    await bloc.close();
  });

  test('temizlik hatası çıkışı engellemez', () async {
    final bloc = SessionBloc(auth, cleanups: [_FailingCleanup()]);
    bloc.emit(SessionState.signedIn(profileWith(UserRole.customer)));
    bloc.add(const SessionSignOutRequested());
    await bloc.stream.firstWhere((state) => state.status == SessionStatus.guest);
    verify(() => auth.signOut()).called(1);
    await bloc.close();
  });
}

class _RecordingCleanup implements SessionCleanup {
  _RecordingCleanup(this.name, this.calls);

  final String name;
  final List<String> calls;

  @override
  Future<void> beforeSignOut(String userId) async => calls.add('$name.before:$userId');

  @override
  Future<void> afterSignOut(String userId) async => calls.add('$name.after:$userId');
}

class _FailingCleanup implements SessionCleanup {
  @override
  Future<void> beforeSignOut(String userId) => Future.error(StateError('ağ yok'));

  @override
  Future<void> afterSignOut(String userId) => Future.error(StateError('disk'));
}
