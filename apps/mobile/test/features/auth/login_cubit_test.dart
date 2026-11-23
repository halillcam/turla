import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:turla_core/turla_core.dart';
import 'package:turla_mobile/features/auth/presentation/cubit/login_cubit.dart';

import '../../helpers/fixtures.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository auth;

  setUp(() {
    auth = _MockAuthRepository();
    when(() => auth.signOut()).thenAnswer((_) async {});
  });

  blocTest<LoginCubit, LoginState>(
    'e-posta girilirse e-posta ile giriş yapılır',
    build: () {
      when(
        () => auth.signInWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => profileWith(UserRole.customer));
      return LoginCubit(auth);
    },
    act: (cubit) => cubit.submit(identity: 'ali@example.com', password: 'gizli123'),
    expect: () => [const LoginState(isSubmitting: true), const LoginState(isSuccess: true)],
    verify: (_) {
      verify(() => auth.signInWithEmail(email: 'ali@example.com', password: 'gizli123')).called(1);
      verifyNever(
        () => auth.signInWithLoginId(
          loginId: any(named: 'loginId'),
          password: any(named: 'password'),
        ),
      );
    },
  );

  blocTest<LoginCubit, LoginState>(
    'kimlik girilirse (e-posta değil) giriş kimliğiyle giriş yapılır',
    build: () {
      when(
        () => auth.signInWithLoginId(
          loginId: any(named: 'loginId'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => profileWith(UserRole.guide));
      return LoginCubit(auth);
    },
    act: (cubit) => cubit.submit(identity: 'REH-1234', password: 'gizli123'),
    expect: () => [const LoginState(isSubmitting: true), const LoginState(isSuccess: true)],
    verify: (_) =>
        verify(() => auth.signInWithLoginId(loginId: 'REH-1234', password: 'gizli123')).called(1),
  );

  blocTest<LoginCubit, LoginState>(
    'admin hesabıyla giriş reddedilir ve oturum kapatılır',
    build: () {
      when(
        () => auth.signInWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => profileWith(UserRole.admin));
      return LoginCubit(auth);
    },
    act: (cubit) => cubit.submit(identity: 'admin@firma.com', password: 'gizli123'),
    expect: () => [
      const LoginState(isSubmitting: true),
      const LoginState(failure: AuthFailureReason.roleNotAllowed),
    ],
    verify: (_) => verify(() => auth.signOut()).called(1),
  );

  blocTest<LoginCubit, LoginState>(
    'hatalı şifre hatası duruma yansır',
    build: () {
      when(
        () => auth.signInWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const AuthFailure(AuthFailureReason.invalidCredentials));
      return LoginCubit(auth);
    },
    act: (cubit) => cubit.submit(identity: 'ali@example.com', password: 'yanlis'),
    expect: () => [
      const LoginState(isSubmitting: true),
      const LoginState(failure: AuthFailureReason.invalidCredentials),
    ],
  );
}
