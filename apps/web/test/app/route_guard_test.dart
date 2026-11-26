import 'package:flutter_test/flutter_test.dart';
import 'package:turla_web/app/router/app_routes.dart';
import 'package:turla_web/app/router/route_guard.dart';
import 'package:turla_web/features/auth/presentation/bloc/session_bloc.dart';

import '../helpers/fixtures.dart';

void main() {
  /// [address] tarayıcıdaki adres (ör. `/login?from=/c/x/tours`).
  String? go(String address, SessionState session) {
    final uri = Uri.parse(address);
    return RouteGuard.redirect(location: uri.path, uri: uri, session: session);
  }

  String from(String path, String target) => AppRoutes.withFrom(path, target);

  group('oturum yokken', () {
    test('kontrol bitmeden açılış ekranı, gidilecek adres korunur', () {
      expect(
        go(AppRoutes.tours(companyA), const SessionState.unknown()),
        from(AppRoutes.splash, AppRoutes.tours(companyA)),
      );
      expect(go(AppRoutes.splash, const SessionState.unknown()), isNull);
    });

    test('misafir girişe gider, gidilecek adres taşınır', () {
      expect(
        go(AppRoutes.companies, const SessionState.guest()),
        from(AppRoutes.login, AppRoutes.companies),
      );
      expect(go(AppRoutes.login, const SessionState.guest()), isNull);
      // Açılış ekranındaki "from" girişe aktarılır.
      expect(
        go(from(AppRoutes.splash, AppRoutes.staff(companyA)), const SessionState.guest()),
        from(AppRoutes.login, AppRoutes.staff(companyA)),
      );
    });
  });

  group('super admin', () {
    final session = SessionState.signedIn(superAdminSession());

    test('firmalara duyuru ve tüm geri bildirimler sayfasını açar', () {
      expect(go(AppRoutes.announcements, session), isNull);
      expect(go(AppRoutes.feedback, session), isNull);
    });

    test('girişten firmalar listesine gider', () {
      expect(go(AppRoutes.login, session), AppRoutes.companies);
      expect(go(AppRoutes.splash, session), AppRoutes.companies);
    });

    test('sayfa yenilenince bulunduğu adrese döner', () {
      final tour = AppRoutes.tour(companyB, 't1');
      expect(go(from(AppRoutes.splash, tour), session), tour);
      expect(go(from(AppRoutes.login, tour), session), tour);
    });

    test('her firmanın alanına girebilir', () {
      expect(go(AppRoutes.tours(companyA), session), isNull);
      expect(go(AppRoutes.completions(companyB), session), isNull);
      expect(go(AppRoutes.companyDetail(companyB), session), isNull);
    });

    test('dış adres "from" ile açılmaz', () {
      expect(go('${AppRoutes.login}?from=https://kotu.site', session), AppRoutes.companies);
    });
  });

  group('şirket admini', () {
    final session = SessionState.signedIn(adminSession());
    final home = AppRoutes.tours(companyA);

    test('girişten kendi turlarına gider', () {
      expect(go(AppRoutes.login, session), home);
    });

    test('yenilemede kendi firmasındaki adrese döner, başka firmaya dönmez', () {
      expect(
        go(from(AppRoutes.splash, AppRoutes.staff(companyA)), session),
        AppRoutes.staff(companyA),
      );
      expect(go(from(AppRoutes.splash, AppRoutes.staff(companyB)), session), home);
      expect(go(from(AppRoutes.login, AppRoutes.companies), session), home);
    });

    test('kendi firmasının ekranlarına girer', () {
      expect(go(AppRoutes.staff(companyA), session), isNull);
      expect(go(AppRoutes.tour(companyA, 't1'), session), isNull);
      expect(go(AppRoutes.newTour(companyA), session), isNull);
    });

    test('firma yönetimine ve başka firmaya giremez', () {
      expect(go(AppRoutes.companies, session), home);
      expect(go(AppRoutes.companyDetail(companyA), session), home);
      expect(go(AppRoutes.tours(companyB), session), home);
      expect(go(AppRoutes.completions(companyB), session), home);
    });

    test('firma duyuru/geri bildirim yönetimine giremez, kendi firma sayfalarına girer', () {
      expect(go(AppRoutes.announcements, session), home);
      expect(go(AppRoutes.feedback, session), home);
      expect(go(AppRoutes.companyAnnouncements(companyA), session), isNull);
      expect(go(AppRoutes.companyFeedback(companyA), session), isNull);
      expect(go(AppRoutes.companyFeedback(companyB), session), home);
    });
  });

  test('adresten firma kimliği okunur', () {
    expect(AppRoutes.companyIdOf('/c/abc/tours/xyz'), 'abc');
    expect(AppRoutes.companyIdOf(AppRoutes.companies), isNull);
  });
}
