import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../app/router/app_routes.dart';

/// Giriş ekranını açar ve giriş/kayıt başarılı olduktan sonra kapatır.
///
/// Giriş ekranı başka bir sayfanın üstüne açıldığı (push) için oturum açılınca
/// kendiliğinden kapanmaz; burada açıkça kapatılır.
/// - Tur sorumlusu kendi ekranına gider.
/// - Müşteri geldiği sayfaya döner (ör. tur detayı); geri dönülecek sayfa
///   yoksa tur listesine gider.
abstract final class AuthNavigation {
  /// Giriş ekranını açar; ekran kapanınca biter. Giriş ekranı zaten en üstteyse (ör. düğmeye
  /// iki kez basıldı) ikinci bir giriş ekranı açılmaz: üst üste iki giriş ekranı olursa
  /// alttaki giriş sonrası ekranda kalıyordu.
  static Future<void> openLogin(BuildContext context) async {
    final router = GoRouter.of(context);
    // Aynı karede gelen iki dokunuşta adres henüz değişmemiş olur; bu yüzden açılış
    // yönlendirici başına bir bayrakla da izlenir (ekran kapanınca kalkar).
    if (_loginOpening[router] == true ||
        router.routerDelegate.currentConfiguration.uri.path == AppRoutes.login) {
      return;
    }
    _loginOpening[router] = true;
    try {
      await router.push(AppRoutes.login);
    } finally {
      _loginOpening[router] = null;
    }
  }

  static final Expando<bool> _loginOpening = Expando<bool>();

  static void afterSignIn(BuildContext context, UserRole role) {
    if (role == UserRole.guide) {
      context.go(AppRoutes.guideHome);
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.tours);
    }
  }
}
