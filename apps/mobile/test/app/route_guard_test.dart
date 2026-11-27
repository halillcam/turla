import 'package:flutter_test/flutter_test.dart';
import 'package:turla_core/turla_core.dart';
import 'package:turla_mobile/app/router/app_routes.dart';
import 'package:turla_mobile/app/router/route_guard.dart';
import 'package:turla_mobile/features/auth/presentation/bloc/session_bloc.dart';
import 'package:turla_mobile/features/city_choice/presentation/cubit/selected_city_cubit.dart';

import '../helpers/fixtures.dart';

void main() {
  const guest = SessionState.guest();
  final customer = SessionState.signedIn(profileWith(UserRole.customer));
  final guide = SessionState.signedIn(profileWith(UserRole.guide));
  const noCity = SelectedCityState.ready();
  const withCity = SelectedCityState.ready(cityId: 46, city: maras);

  String? redirect(String location, SessionState session, SelectedCityState city) =>
      RouteGuard.redirect(location: location, session: session, city: city);

  test('oturum veya il yüklenmeden açılış ekranında beklenir', () {
    expect(redirect(AppRoutes.tours, const SessionState.unknown(), withCity), AppRoutes.splash);
    expect(redirect(AppRoutes.tours, guest, const SelectedCityState.loading()), AppRoutes.splash);
    expect(redirect(AppRoutes.splash, const SessionState.unknown(), withCity), isNull);
  });

  test('il seçilmemiş misafir önce şehir seçimine gider', () {
    expect(redirect(AppRoutes.splash, guest, noCity), AppRoutes.citySelection);
    expect(redirect(AppRoutes.tours, guest, noCity), AppRoutes.citySelection);
    expect(redirect(AppRoutes.citySelection, guest, noCity), isNull);
  });

  test('il seçilmemişken de giriş ve kayıt ekranları açılabilir', () {
    expect(redirect(AppRoutes.login, guest, noCity), isNull);
    expect(redirect(AppRoutes.register, guest, noCity), isNull);
  });

  test('il seçiliyse açılıştan tur listesine geçilir', () {
    expect(redirect(AppRoutes.splash, guest, withCity), AppRoutes.tours);
    expect(redirect(AppRoutes.tours, guest, withCity), isNull);
  });

  test('giriş yapmış kullanıcı giriş/kayıt ekranında kalmaz', () {
    expect(redirect(AppRoutes.login, customer, withCity), AppRoutes.tours);
    expect(redirect(AppRoutes.register, customer, withCity), AppRoutes.tours);
  });

  test('tur sorumlusu sadece kendi ekranını görür, il seçimi istenmez', () {
    expect(redirect(AppRoutes.tours, guide, noCity), AppRoutes.guideHome);
    expect(redirect(AppRoutes.login, guide, withCity), AppRoutes.guideHome);
    expect(redirect(AppRoutes.guideHome, guide, noCity), isNull);
    expect(redirect(AppRoutes.guideDepartureOf('d1'), guide, noCity), isNull);
    expect(redirect(AppRoutes.guideScanOf('d1'), guide, withCity), isNull);
    expect(redirect('/guidex', guide, withCity), AppRoutes.guideHome);
  });

  test('müşteri rehber ekranına giremez', () {
    expect(redirect(AppRoutes.guideHome, customer, withCity), AppRoutes.tours);
    expect(redirect(AppRoutes.guideScanOf('d1'), customer, withCity), AppRoutes.tours);
  });

  test('şifremi unuttum ekranı il seçilmeden açılır; yeni şifre ekranı sadece oturumla', () {
    expect(redirect(AppRoutes.forgotPassword, guest, noCity), isNull);
    expect(redirect(AppRoutes.forgotPassword, customer, withCity), AppRoutes.tours);
    expect(redirect(AppRoutes.resetPassword, customer, noCity), isNull);
    expect(redirect(AppRoutes.resetPassword, guest, withCity), AppRoutes.login);
  });
}
