import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:turla_core/turla_core.dart';

import '../../../../app/router/app_routes.dart';

/// Giriş/kayıt başarılı olduktan sonra ekranı kapatır.
///
/// Giriş ekranı başka bir sayfanın üstüne açıldığı (push) için oturum açılınca
/// kendiliğinden kapanmaz; burada açıkça kapatılır.
/// - Tur sorumlusu kendi ekranına gider.
/// - Müşteri geldiği sayfaya döner (ör. tur detayı); geri dönülecek sayfa
///   yoksa tur listesine gider.
abstract final class AuthNavigation {
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
