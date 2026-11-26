import '../../features/auth/domain/panel_session.dart';
import '../../features/auth/presentation/bloc/session_bloc.dart';
import 'app_routes.dart';

/// Hangi adresin açılabileceğine karar verir. Yönlendirme gerekmiyorsa null.
///
/// Kurallar:
/// - Oturum kontrol edilmeden açılış ekranı gösterilir.
/// - Giriş yapılmamışsa sadece giriş ekranı açılır.
/// - Giriş yapmış kullanıcı giriş / açılış ekranında kalmaz: gitmek istediği
///   adrese (sayfa yenileme veya bağlantı) yetkisi varsa oraya, yoksa ana ekranına gider.
/// - Şirket admini firma yönetimine (`/companies`) ve başka firmaya giremez.
///
/// Gidilmek istenen adres açılış / giriş ekranına `from` parametresiyle taşınır.
/// Bu sadece arayüz kuralıdır; asıl yetki sunucuda (RLS ve fonksiyonlar).
abstract final class RouteGuard {
  /// [location]: eşleşen yol (ör. `/c/x/tours`), [uri]: sorgu parametreleriyle tam adres.
  static String? redirect({
    required String location,
    required Uri uri,
    required SessionState session,
  }) {
    final isEntry = location == AppRoutes.splash || location == AppRoutes.login;
    final from = isEntry ? uri.queryParameters[AppRoutes.fromParam] : uri.toString();

    switch (session.status) {
      case SessionStatus.unknown:
        return location == AppRoutes.splash ? null : AppRoutes.withFrom(AppRoutes.splash, from);
      case SessionStatus.guest:
        return location == AppRoutes.login ? null : AppRoutes.withFrom(AppRoutes.login, from);
      case SessionStatus.signedIn:
        break;
    }

    final panelSession = session.session!;
    final home = AppRoutes.homeFor(panelSession);
    if (isEntry) {
      final target = from;
      if (target == null || !target.startsWith('/')) return home;
      final targetPath = Uri.parse(target).path;
      final isEntryTarget = targetPath == AppRoutes.splash || targetPath == AppRoutes.login;
      return !isEntryTarget && canOpen(targetPath, panelSession) ? target : home;
    }
    return canOpen(location, panelSession) ? null : home;
  }

  /// Oturumdaki kullanıcı bu yolu açabilir mi?
  static bool canOpen(String path, PanelSession session) {
    if (session.isSuperAdmin) return true;
    if (AppRoutes.isSuperAdminOnly(path)) return false;
    final companyId = AppRoutes.companyIdOf(path);
    return companyId == null || companyId == session.ownCompanyId;
  }
}
