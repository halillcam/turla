/// Uygulama içi rota adresleri.
abstract final class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String citySelection = '/city';
  static const String tours = '/tours';
  static const String tourDetailParam = 'tourId';
  static const String tourDetail = '/tours/:$tourDetailParam';
  static const String checkout = '/checkout';
  static const String myTickets = '/my-tickets';
  static const String ticketDetailParam = 'ticketId';
  static const String profile = '/profile';
  static const String guideHome = '/guide';

  static String tourDetailOf(String tourId) => '$tours/$tourId';

  static String ticketDetailOf(String ticketId) => '$myTickets/$ticketId';

  /// Misafirin girebildiği giriş ekranları.
  static const Set<String> authRoutes = {login, register};
}
