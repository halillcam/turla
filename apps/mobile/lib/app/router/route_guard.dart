import '../../features/auth/presentation/bloc/session_bloc.dart';
import '../../features/city_choice/presentation/cubit/selected_city_cubit.dart';
import 'app_routes.dart';

/// Hangi ekranın açılabileceğine karar verir. Yönlendirme gerekmiyorsa null döner.
///
/// Kurallar:
/// - Oturum veya seçili il henüz yüklenmediyse açılış ekranı gösterilir.
/// - Tur sorumlusu sadece kendi ekranını görür.
/// - Giriş yapmış kullanıcı giriş/kayıt ekranına dönmez.
/// - İl seçilmemişse (giriş ekranları hariç) önce şehir seçimi açılır.
abstract final class RouteGuard {
  static String? redirect({
    required String location,
    required SessionState session,
    required SelectedCityState city,
  }) {
    final isReady = session.status != SessionStatus.unknown && !city.isLoading;
    if (!isReady) return location == AppRoutes.splash ? null : AppRoutes.splash;

    if (session.isGuide) {
      return location == AppRoutes.guideHome ? null : AppRoutes.guideHome;
    }
    if (location == AppRoutes.guideHome) return AppRoutes.tours;

    final isAuthRoute = AppRoutes.authRoutes.contains(location);
    if (session.isSignedIn && isAuthRoute) return AppRoutes.tours;

    if (!city.hasCity) {
      if (isAuthRoute || location == AppRoutes.citySelection) return null;
      return AppRoutes.citySelection;
    }

    if (location == AppRoutes.splash) return AppRoutes.tours;
    return null;
  }
}
