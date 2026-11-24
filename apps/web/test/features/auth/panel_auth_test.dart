import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:turla_core/turla_core.dart';
import 'package:turla_web/core/errors/panel_failure.dart';
import 'package:turla_web/features/auth/data/panel_auth_repository_impl.dart';
import 'package:turla_web/features/auth/domain/panel_auth_repository.dart';
import 'package:turla_web/features/auth/domain/panel_session.dart';
import 'package:turla_web/features/auth/presentation/bloc/session_bloc.dart';
import 'package:turla_web/features/auth/presentation/cubit/login_cubit.dart';
import 'package:turla_web/features/companies/domain/repositories/company_repository.dart';

import '../../helpers/fixtures.dart';

class _MockAuth extends Mock implements AuthRepository {}

class _MockCompanies extends Mock implements CompanyRepository {}

class _MockPanelAuth extends Mock implements PanelAuthRepository {}

void main() {
  group('PanelAuthRepositoryImpl erişim kontrolü', () {
    late _MockAuth auth;
    late _MockCompanies companies;
    late PanelAuthRepositoryImpl repository;

    setUp(() {
      auth = _MockAuth();
      companies = _MockCompanies();
      repository = PanelAuthRepositoryImpl(
        authRepository: auth,
        companyRepository: companies,
        authStates: const Stream<AuthState>.empty(),
      );
      when(() => auth.signOut()).thenAnswer((_) async {});
    });

    void signInAs(UserProfile profile) => when(
      () => auth.signInWithEmail(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => profile);

    test('super admin girer, firma okunmaz', () async {
      signInAs(profileWith(UserRole.superAdmin));
      final session = await repository.signIn(email: 'a@b.com', password: 'x');
      expect(session.isSuperAdmin, isTrue);
      verifyNever(() => companies.getCompany(any()));
      verifyNever(() => auth.signOut());
    });

    test('aktif firmanın admini girer', () async {
      signInAs(profileWith(UserRole.admin, companyId: companyA));
      when(() => companies.getCompany(companyA)).thenAnswer((_) async => activeCompany);
      final session = await repository.signIn(email: 'a@b.com', password: 'x');
      expect(session.company, activeCompany);
      expect(session.ownCompanyId, companyA);
    });

    for (final role in [UserRole.customer, UserRole.guide]) {
      test('${role.value} reddedilir ve oturum kapatılır', () async {
        signInAs(profileWith(role, companyId: companyA));
        await expectLater(
          repository.signIn(email: 'a@b.com', password: 'x'),
          throwsA(
            isA<PanelAccessDenied>().having((e) => e.denial, 'denial', PanelDenial.roleNotAllowed),
          ),
        );
        verify(() => auth.signOut()).called(1);
      });
    }

    test('pasif (görünmeyen) firmanın admini reddedilir', () async {
      signInAs(profileWith(UserRole.admin, companyId: companyA));
      when(() => companies.getCompany(companyA)).thenAnswer((_) async => null);
      await expectLater(
        repository.signIn(email: 'a@b.com', password: 'x'),
        throwsA(
          isA<PanelAccessDenied>().having((e) => e.denial, 'denial', PanelDenial.companyInactive),
        ),
      );
      verify(() => auth.signOut()).called(1);
    });

    test('firma okunurken ağ hatası → AuthFailure(network), oturum açık kalır', () async {
      signInAs(profileWith(UserRole.admin, companyId: companyA));
      when(
        () => companies.getCompany(companyA),
      ).thenThrow(const PanelFailure(PanelFailureReason.network));
      await expectLater(
        repository.signIn(email: 'a@b.com', password: 'x'),
        throwsA(isA<AuthFailure>().having((e) => e.reason, 'reason', AuthFailureReason.network)),
      );
      verifyNever(() => auth.signOut());
    });

    test('oturum yoksa currentSession null', () async {
      when(() => auth.currentProfile()).thenAnswer((_) async => null);
      expect(await repository.currentSession(), isNull);
    });
  });

  group('SessionBloc', () {
    late _MockPanelAuth panelAuth;
    late StreamController<void> signedOut;

    setUp(() {
      panelAuth = _MockPanelAuth();
      signedOut = StreamController<void>.broadcast();
      when(() => panelAuth.signedOut).thenAnswer((_) => signedOut.stream);
      when(() => panelAuth.signOut()).thenAnswer((_) async {});
    });

    tearDown(() => signedOut.close());

    blocTest<SessionBloc, SessionState>(
      'açılışta oturum varsa signedIn',
      build: () {
        when(() => panelAuth.currentSession()).thenAnswer((_) async => adminSession());
        return SessionBloc(panelAuth);
      },
      act: (bloc) => bloc.add(const SessionStarted()),
      expect: () => [SessionState.signedIn(adminSession())],
    );

    blocTest<SessionBloc, SessionState>(
      'açılışta reddedilen oturum nedeniyle misafir olur',
      build: () {
        when(
          () => panelAuth.currentSession(),
        ).thenThrow(const PanelAccessDenied(PanelDenial.companyInactive));
        return SessionBloc(panelAuth);
      },
      act: (bloc) => bloc.add(const SessionStarted()),
      expect: () => [const SessionState.guest(denial: PanelDenial.companyInactive)],
    );

    blocTest<SessionBloc, SessionState>(
      'oturum dışarıdan kapanınca misafir olur',
      build: () {
        when(() => panelAuth.currentSession()).thenAnswer((_) async => adminSession());
        return SessionBloc(panelAuth);
      },
      act: (bloc) async {
        bloc.add(const SessionStarted());
        await Future<void>.delayed(Duration.zero);
        signedOut.add(null);
      },
      expect: () => [SessionState.signedIn(adminSession()), const SessionState.guest()],
    );
  });

  group('LoginCubit', () {
    late _MockPanelAuth panelAuth;

    setUp(() => panelAuth = _MockPanelAuth());

    blocTest<LoginCubit, LoginState>(
      'başarılı giriş oturumu döndürür',
      build: () {
        when(
          () => panelAuth.signIn(email: 'a@b.com', password: 'gizli123'),
        ).thenAnswer((_) async => superAdminSession());
        return LoginCubit(panelAuth);
      },
      act: (cubit) => cubit.submit(email: 'a@b.com', password: 'gizli123'),
      expect: () => [
        const LoginState(isSubmitting: true),
        LoginState(session: superAdminSession()),
      ],
    );

    blocTest<LoginCubit, LoginState>(
      'müşteri hesabı reddedilir',
      build: () {
        when(
          () => panelAuth.signIn(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(const PanelAccessDenied(PanelDenial.roleNotAllowed));
        return LoginCubit(panelAuth);
      },
      act: (cubit) => cubit.submit(email: 'a@b.com', password: 'x'),
      expect: () => [
        const LoginState(isSubmitting: true),
        const LoginState(denial: PanelDenial.roleNotAllowed),
      ],
    );

    blocTest<LoginCubit, LoginState>(
      'hatalı şifre',
      build: () {
        when(
          () => panelAuth.signIn(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(const AuthFailure(AuthFailureReason.invalidCredentials));
        return LoginCubit(panelAuth);
      },
      act: (cubit) => cubit.submit(email: 'a@b.com', password: 'x'),
      expect: () => [
        const LoginState(isSubmitting: true),
        const LoginState(failure: AuthFailureReason.invalidCredentials),
      ],
    );
  });
}
