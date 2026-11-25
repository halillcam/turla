import 'package:url_launcher/url_launcher.dart';

/// Telefon uygulamasını numarayla açar (arama kullanıcı onayıyla başlar).
abstract final class PhoneLauncher {
  static Future<bool> call(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.isEmpty) return Future.value(false);
    return launchUrl(Uri(scheme: 'tel', path: digits));
  }
}
