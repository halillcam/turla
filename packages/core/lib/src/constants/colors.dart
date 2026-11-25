import 'package:flutter/painting.dart';

/// Uygulamanın tüm renkleri. Widget'larda doğrudan `Color(0x...)` yazılmaz.
abstract final class AppColors {
  // Marka
  static const Color primary = Color(0xFF0E7C86);
  static const Color primaryDark = Color(0xFF0A5C63);
  static const Color primaryLight = Color(0xFFD7F0F2);
  static const Color secondary = Color(0xFFF59E0B);

  // Zemin ve yüzey
  static const Color background = Color(0xFFF6F7F9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFEEF1F4);
  static const Color border = Color(0xFFDDE2E8);

  // Metin
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Durum
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF2563EB);

  // Katılımcı durumu (rehber ekranı: geldi / gelmedi)
  static const Color arrived = success;
  static const Color notArrived = error;

  // Kamera üstünde "kontrol ediliyor" örtüsü.
  static const Color scrim = Color(0x8A000000);
}
