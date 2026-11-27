import 'package:turla_core/turla_core.dart';

/// Profil ekranında gösterilen metinler.
extension ProfileDisplay on UserProfile {
  /// Ad ve soyadın baş harfleri ("Ayşe Yılmaz" → "AY"); tek kelimeyse tek harf.
  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    final first = parts.first.substring(0, 1);
    final last = parts.length > 1 ? parts.last.substring(0, 1) : '';
    return '$first$last'.turkishUpper;
  }
}
