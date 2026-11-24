import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:turla_web/app/router/app_routes.dart';
import 'package:turla_web/app/router/route_guard.dart';
import 'package:turla_web/features/auth/presentation/bloc/session_bloc.dart';

import '../helpers/fixtures.dart';

/// Sayfa yenileme senaryosu gerçek GoRouter ile: oturum kontrol edilirken
/// açılış ekranı gösterilir, sonra kullanıcı istediği adrese döner.
void main() {
  testWidgets('yenilemede oturum gelince istenen adrese dönülür', (tester) async {
    final session = ValueNotifier<SessionState>(const SessionState.unknown());
    final target = AppRoutes.staff(companyA);
    Widget page(String name) => Scaffold(body: Text(name));

    final router = GoRouter(
      initialLocation: target,
      refreshListenable: session,
      redirect: (_, state) => RouteGuard.redirect(
        location: state.matchedLocation,
        uri: state.uri,
        session: session.value,
      ),
      routes: [
        GoRoute(path: AppRoutes.splash, builder: (_, _) => page('splash')),
        GoRoute(path: AppRoutes.login, builder: (_, _) => page('login')),
        GoRoute(path: AppRoutes.companies, builder: (_, _) => page('companies')),
        GoRoute(path: AppRoutes.staffPattern, builder: (_, _) => page('staff')),
        GoRoute(path: AppRoutes.toursPattern, builder: (_, _) => page('tours')),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.text('splash'), findsOneWidget);

    session.value = SessionState.signedIn(superAdminSession());
    await tester.pumpAndSettle();

    expect(router.routerDelegate.currentConfiguration.uri.toString(), target);
    expect(find.text('staff'), findsOneWidget);
  });
}
