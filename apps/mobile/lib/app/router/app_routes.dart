import 'package:turla_core/turla_core.dart';

/// Uygulama içi rota adresleri.
abstract final class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String citySelection = '/city';
  static const String tours = '/tours';
  static const String tourDetailParam = 'tourId';
  static const String tourDetail = '/tours/:$tourDetailParam';
  static const String regionParam = 'region';
  static const String regionTours = '/tours/region/:$regionParam';
  static const String checkout = '/checkout';
  static const String myTickets = '/my-tickets';
  static const String ticketDetailParam = 'ticketId';
  static const String profile = '/profile';
  static const String guideHome = '/guide';
  static const String guideDepartureParam = 'departureId';

  static String tourDetailOf(String tourId) => '$tours/$tourId';

  static String regionToursOf(TourRegion region) => '$tours/region/${region.value}';

  static String ticketDetailOf(String ticketId) => '$myTickets/$ticketId';

  static String guideDepartureOf(String departureId) => '$guideHome/departures/$departureId';

  static String guideScanOf(String departureId) => '${guideDepartureOf(departureId)}/scan';

  /// Tur sorumlusunun ekranları bu önekle başlar.
  static bool isGuideRoute(String location) =>
      location == guideHome || location.startsWith('$guideHome/');

  /// Misafirin girebildiği giriş ekranları.
  static const Set<String> authRoutes = {login, register};
}
