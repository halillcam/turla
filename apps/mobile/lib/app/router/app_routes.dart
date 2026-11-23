/// Uygulama içi rota adresleri.
abstract final class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String citySelection = '/city';
  static const String tours = '/tours';
  static const String tourDetailParam = 'tourId';
  static const String tourDetail = '/tours/:$tourDetailParam';
  static const String profile = '/profile';
  static const String guideHome = '/guide';

  static String tourDetailOf(String tourId) => '$tours/$tourId';

  /// Misafirin girebildiği giriş ekranları.
  static const Set<String> authRoutes = {login, register};
}
