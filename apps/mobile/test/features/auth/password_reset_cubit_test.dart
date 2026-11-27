import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:turla_core/turla_core.dart';
import 'package:turla_mobile/features/auth/presentation/cubit/password_reset_cubit.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repository;

  setUp(() => repository = _MockAuthRepository());

  blocTest<ForgotPasswordCubit, PasswordResetState>(
    'bağlantı gönderilir',
    setUp: () => when(() => repository.sendPasswordReset(any())).thenAnswer((_) async {}),
    build: () => ForgotPasswordCubit(repository),
    act: (cubit) => cubit.send('ayse@ornek.com'),
    expect: () => const [PasswordResetState(isSubmitting: true), PasswordResetState(isDone: true)],
    verify: (_) => verify(() => repository.sendPasswordReset('ayse@ornek.com')).called(1),
  );

  blocTest<ForgotPasswordCubit, PasswordResetState>(
    'çok sık istenirse hata döner',
    setUp: () => when(
      () => repository.sendPasswordReset(any()),
    ).thenThrow(const AuthFailure(AuthFailureReason.rateLimited)),
    build: () => ForgotPasswordCubit(repository),
    act: (cubit) => cubit.send('ayse@ornek.com'),
    expect: () => const [
      PasswordResetState(isSubmitting: true),
      PasswordResetState(failure: AuthFailureReason.rateLimited),
    ],
  );

  blocTest<ResetPasswordCubit, PasswordResetState>(
    'yeni şifre kaydedilir',
    setUp: () => when(() => repository.updatePassword(any())).thenAnswer((_) async {}),
    build: () => ResetPasswordCubit(repository),
    act: (cubit) => cubit.save('yeni-sifre-123'),
    expect: () => const [PasswordResetState(isSubmitting: true), PasswordResetState(isDone: true)],
  );

  blocTest<ResetPasswordCubit, PasswordResetState>(
    'eski şifreyle aynıysa hata döner',
    setUp: () => when(
      () => repository.updatePassword(any()),
    ).thenThrow(const AuthFailure(AuthFailureReason.samePassword)),
    build: () => ResetPasswordCubit(repository),
    act: (cubit) => cubit.save('ayni-sifre'),
    expect: () => const [
      PasswordResetState(isSubmitting: true),
      PasswordResetState(failure: AuthFailureReason.samePassword),
    ],
  );
}
