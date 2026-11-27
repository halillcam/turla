import '../../features/auth/presentation/bloc/session_bloc.dart';
import '../../features/city_choice/presentation/cubit/selected_city_cubit.dart';
import 'app_routes.dart';

/// Hangi ekranın açılabileceğine karar verir. Yönlendirme gerekmiyorsa null döner.
///
/// Kurallar:
/// - Oturum veya seçili il henüz yüklenmediyse açılış ekranı gösterilir.
/// - Tur sorumlusu sadece kendi ekranını görür.
/// - Yeni şifre ekranı sadece oturum varken (sıfırlama bağlantısı) açılır.
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

    // Yeni şifre ekranı sadece sıfırlama bağlantısıyla açılan oturumda anlamlı; il seçimi beklenmez.
    if (location == AppRoutes.resetPassword) {
      return session.isSignedIn ? null : AppRoutes.login;
    }

    if (session.isGuide) {
      return AppRoutes.isGuideRoute(location) ? null : AppRoutes.guideHome;
    }
    if (AppRoutes.isGuideRoute(location)) return AppRoutes.tours;

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
