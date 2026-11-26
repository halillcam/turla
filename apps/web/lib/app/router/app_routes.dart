import '../../features/auth/domain/panel_session.dart';

/// Panel adresleri.
///
/// `/companies...`  : sadece super admin (firma yönetimi)
/// `/c/<firma>/...` : firma alanı; şirket admini sadece kendi firmasına girer,
///                    super admin her firmaya girebilir.
abstract final class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String companies = '/companies';

  /// Super admin: firmalara duyuru ve tüm geri bildirimler.
  static const String announcements = '/announcements';
  static const String feedback = '/feedback';

  /// Açılış / giriş ekranına taşınan, asıl gidilmek istenen adres.
  static const String fromParam = 'from';

  static const String companyIdParam = 'companyId';
  static const String tourIdParam = 'tourId';
  static const String newTourSegment = 'new';

  // GoRouter kalıpları
  static const String companyDetailPattern = '$companies/:$companyIdParam';
  static const String companyAreaPattern = '/c/:$companyIdParam';
  static const String toursPattern = '$companyAreaPattern/tours';
  static const String newTourPattern = '$toursPattern/$newTourSegment';
  static const String tourPattern = '$toursPattern/:$tourIdParam';
  static const String staffPattern = '$companyAreaPattern/staff';
  static const String completionsPattern = '$companyAreaPattern/completions';
  static const String companyAnnouncementsPattern = '$companyAreaPattern/announcements';
  static const String companyFeedbackPattern = '$companyAreaPattern/feedback';

  static String companyDetail(String companyId) => '$companies/$companyId';
  static String tours(String companyId) => '/c/$companyId/tours';
  static String newTour(String companyId) => '${tours(companyId)}/$newTourSegment';
  static String tour(String companyId, String tourId) => '${tours(companyId)}/$tourId';
  static String staff(String companyId) => '/c/$companyId/staff';
  static String completions(String companyId) => '/c/$companyId/completions';
  static String companyAnnouncements(String companyId) => '/c/$companyId/announcements';
  static String companyFeedback(String companyId) => '/c/$companyId/feedback';

  /// Sadece super admin'in açabildiği yollar.
  static bool isSuperAdminOnly(String path) =>
      path.startsWith(companies) || path.startsWith(announcements) || path.startsWith(feedback);

  /// `/login?from=/c/x/tours` gibi; [from] yoksa ya da ana sayfaysa sade yol.
  static String withFrom(String path, String? from) =>
      from == null || from == splash || from == login
      ? path
      : Uri(path: path, queryParameters: {fromParam: from}).toString();

  static final RegExp _companyArea = RegExp(r'^/c/([^/]+)');

  /// Adres bir firma alanındaysa firma kimliği.
  static String? companyIdOf(String location) => _companyArea.firstMatch(location)?.group(1);

  /// Girişten sonra açılan ekran.
  static String homeFor(PanelSession session) {
    final companyId = session.ownCompanyId;
    return companyId == null ? companies : tours(companyId);
  }
}
