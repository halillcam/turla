import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/strings.dart';
import '../../core/widgets/status_view.dart';
import '../../features/announcements/presentation/screens/company_announcements_screen.dart';
import '../../features/auth/presentation/bloc/session_bloc.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/companies/presentation/screens/companies_screen.dart';
import '../../features/companies/presentation/screens/company_detail_screen.dart';
import '../../features/completions/presentation/screens/completions_screen.dart';
import '../../features/feedback/presentation/screens/feedback_screen.dart';
import '../../features/staff/presentation/screens/staff_screen.dart';
import '../../features/tours/presentation/screens/tour_editor_screen.dart';
import '../../features/tours/presentation/screens/tours_screen.dart';
import '../shell/panel_shell.dart';
import '../shell/splash_screen.dart';
import 'app_routes.dart';
import 'route_guard.dart';
import 'stream_refresh_listenable.dart';

/// Panelin tüm ekranları ve yönlendirme kuralları.
class AppRouter {
  AppRouter({required SessionBloc sessionBloc})
    : _refresh = StreamRefreshListenable([sessionBloc.stream]) {
    router = GoRouter(
      initialLocation: AppRoutes.splash,
      refreshListenable: _refresh,
      redirect: (context, state) => RouteGuard.redirect(
        location: state.matchedLocation,
        uri: state.uri,
        session: sessionBloc.state,
      ),
      errorBuilder: (_, _) =>
          const Scaffold(body: StatusView.message(message: AppStrings.errorNotFound)),
      routes: [
        GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashScreen()),
        GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginScreen()),
        ShellRoute(
          builder: (_, state, child) => PanelShell(location: state.uri.path, child: child),
          routes: [
            GoRoute(path: AppRoutes.companies, builder: (_, _) => const CompaniesScreen()),
            GoRoute(
              path: AppRoutes.announcements,
              builder: (_, _) => const CompanyAnnouncementsScreen(),
            ),
            GoRoute(path: AppRoutes.feedback, builder: (_, _) => const FeedbackScreen()),
            GoRoute(
              path: AppRoutes.companyDetailPattern,
              builder: (_, state) => CompanyDetailScreen(companyId: _companyId(state)),
            ),
            GoRoute(
              path: AppRoutes.toursPattern,
              builder: (_, state) => ToursScreen(companyId: _companyId(state)),
            ),
            // "new" kalıbı ":tourId"den önce gelmeli.
            GoRoute(
              path: AppRoutes.newTourPattern,
              builder: (_, state) => TourEditorScreen(companyId: _companyId(state)),
            ),
            GoRoute(
              path: AppRoutes.tourPattern,
              builder: (_, state) => TourEditorScreen(
                key: ValueKey(state.pathParameters[AppRoutes.tourIdParam]),
                companyId: _companyId(state),
                tourId: state.pathParameters[AppRoutes.tourIdParam],
              ),
            ),
            GoRoute(
              path: AppRoutes.staffPattern,
              builder: (_, state) => StaffScreen(companyId: _companyId(state)),
            ),
            GoRoute(
              path: AppRoutes.completionsPattern,
              builder: (_, state) => CompletionsScreen(companyId: _companyId(state)),
            ),
            GoRoute(
              path: AppRoutes.companyAnnouncementsPattern,
              builder: (_, state) => CompanyAnnouncementsScreen(companyId: _companyId(state)),
            ),
            GoRoute(
              path: AppRoutes.companyFeedbackPattern,
              // Geri bildirimi firma admini gönderir; super admin firma alanında sadece okur.
              builder: (_, state) => FeedbackScreen(
                companyId: _companyId(state),
                canSend: !(sessionBloc.state.session?.isSuperAdmin ?? true),
              ),
            ),
          ],
        ),
      ],
    );
  }

  final StreamRefreshListenable _refresh;
  late final GoRouter router;

  static String _companyId(GoRouterState state) => state.pathParameters[AppRoutes.companyIdParam]!;

  void dispose() {
    router.dispose();
    _refresh.dispose();
  }
}
