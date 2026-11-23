import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/bloc/session_bloc.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/city_choice/presentation/cubit/selected_city_cubit.dart';
import '../../features/city_choice/presentation/screens/city_choice_screen.dart';
import '../../features/guide/presentation/screens/guide_home_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/tours/presentation/screens/tour_detail_screen.dart';
import '../../features/tours/presentation/screens/tour_list_screen.dart';
import '../shell/main_shell.dart';
import '../shell/splash_screen.dart';
import 'app_routes.dart';
import 'route_guard.dart';
import 'stream_refresh_listenable.dart';

/// Uygulamanın tüm ekranları ve yönlendirme kuralları.
class AppRouter {
  AppRouter({required SessionBloc sessionBloc, required SelectedCityCubit selectedCityCubit})
    : _refresh = StreamRefreshListenable([sessionBloc.stream, selectedCityCubit.stream]) {
    router = GoRouter(
      initialLocation: AppRoutes.splash,
      refreshListenable: _refresh,
      redirect: (context, state) => RouteGuard.redirect(
        location: state.matchedLocation,
        session: sessionBloc.state,
        city: selectedCityCubit.state,
      ),
      routes: [
        GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashScreen()),
        GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginScreen()),
        GoRoute(path: AppRoutes.register, builder: (_, _) => const RegisterScreen()),
        GoRoute(path: AppRoutes.citySelection, builder: (_, _) => const CityChoiceScreen()),
        GoRoute(path: AppRoutes.guideHome, builder: (_, _) => const GuideHomeScreen()),
        StatefulShellRoute.indexedStack(
          builder: (_, _, navigationShell) => MainShell(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.tours,
                  builder: (_, _) => const TourListScreen(),
                  routes: [
                    GoRoute(
                      path: ':${AppRoutes.tourDetailParam}',
                      builder: (_, state) => TourDetailScreen(
                        tourId: state.pathParameters[AppRoutes.tourDetailParam]!,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [GoRoute(path: AppRoutes.profile, builder: (_, _) => const ProfileScreen())],
            ),
          ],
        ),
      ],
    );
  }

  final StreamRefreshListenable _refresh;
  late final GoRouter router;

  void dispose() {
    router.dispose();
    _refresh.dispose();
  }
}
