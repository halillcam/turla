import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:turla_core/turla_core.dart';
import 'package:turla_mobile/app/router/app_routes.dart';
import 'package:turla_mobile/core/constants/strings.dart';
import 'package:turla_mobile/core/di/injection.dart';
import 'package:turla_mobile/features/auth/presentation/cubit/login_cubit.dart';
import 'package:turla_mobile/features/auth/presentation/screens/login_screen.dart';

import '../../helpers/fixtures.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

const _previousPageText = 'Önceki sayfa';
const _guidePageText = 'Rehber sayfası';

/// Giriş ekranı başka bir sayfanın üstüne açılır (uygulamadaki gibi push).
GoRouter _router() => GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, _) => Scaffold(
        body: TextButton(
          onPressed: () => context.push(AppRoutes.login),
          child: const Text(_previousPageText),
        ),
      ),
    ),
    GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginScreen()),
    GoRoute(path: AppRoutes.tours, builder: (_, _) => const Text('Turlar')),
    GoRoute(path: AppRoutes.guideHome, builder: (_, _) => const Text(_guidePageText)),
  ],
);

Future<void> _openLoginAndSubmit(WidgetTester tester, String identity) async {
  await tester.pumpWidget(MaterialApp.router(routerConfig: _router()));
  await tester.tap(find.text(_previousPageText));
  await tester.pumpAndSettle();
  expect(find.byType(LoginScreen), findsOneWidget);

  await tester.enterText(find.byType(TextFormField).at(0), identity);
  await tester.enterText(find.byType(TextFormField).at(1), 'test-sifre');
  await tester.tap(find.widgetWithText(ElevatedButton, AppStrings.loginButton));
  await tester.pumpAndSettle();
}

void main() {
  late _MockAuthRepository auth;

  setUp(() {
    auth = _MockAuthRepository();
    getIt.registerFactory<LoginCubit>(() => LoginCubit(auth));
  });

  tearDown(() => getIt.reset());

  testWidgets('müşteri girişi başarılı olunca giriş ekranı kapanır ve önceki sayfaya dönülür', (
    tester,
  ) async {
    when(
      () => auth.signInWithEmail(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => profileWith(UserRole.customer));

    await _openLoginAndSubmit(tester, 'ali@example.com');

    expect(find.byType(LoginScreen), findsNothing);
    expect(find.text(_previousPageText), findsOneWidget);
  });

  testWidgets('tur sorumlusu girişi başarılı olunca rehber ekranına gidilir', (tester) async {
    when(
      () => auth.signInWithLoginId(
        loginId: any(named: 'loginId'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => profileWith(UserRole.guide));

    await _openLoginAndSubmit(tester, 'REH-1234');

    expect(find.byType(LoginScreen), findsNothing);
    expect(find.text(_guidePageText), findsOneWidget);
  });

  testWidgets('hatalı girişte ekran açık kalır ve hata gösterilir', (tester) async {
    when(
      () => auth.signInWithEmail(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(const AuthFailure(AuthFailureReason.invalidCredentials));

    await _openLoginAndSubmit(tester, 'ali@example.com');

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text(AppStrings.errorInvalidCredentials), findsOneWidget);
  });
}
