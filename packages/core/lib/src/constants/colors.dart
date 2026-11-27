import 'package:flutter/painting.dart';

/// Uygulamanın tüm renkleri (Stitch tasarım sistemi). Widget'larda doğrudan
/// `Color(0x...)` ya da `Colors.xxx` yazılmaz.
///
/// Dil: sıcak kâğıt zemin, çam yeşili ana renk, terracotta sadece küçük vurgu.
/// Mor, gradyan ve parlak renk yok.
abstract final class AppColors {
  // Marka
  static const Color primary = Color(0xFF1F5E4E);
  static const Color primaryPressed = Color(0xFF174A3D);
  static const Color primaryTint = Color(0xFFDCEAE3);
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// Terracotta: sadece küçük vurgu (rozet noktası, ince çizgi). Büyük alanlarda kullanılmaz.
  static const Color accent = Color(0xFFC1603E);

  // Zemin ve yüzey
  static const Color background = Color(0xFFF6F2EA);
  static const Color surface = Color(0xFFFFFDF9);
  static const Color surfaceMuted = Color(0xFFEFE8DC);
  static const Color border = Color(0xFFE2D8C8);

  // Metin
  static const Color textPrimary = Color(0xFF1E2422);
  static const Color textSecondary = Color(0xFF5B625E);

  /// Sadece ipucu/yer tutucu ve pasif öğe; okunması gereken metinde kullanılmaz.
  static const Color textMuted = Color(0xFF8D928C);

  // Durum
  static const Color success = Color(0xFF2F7D4F);
  static const Color successTint = Color(0xFFE3F1E7);
  static const Color onSuccessTint = Color(0xFF2E794D);
  static const Color warning = Color(0xFFB7791F);
  static const Color warningTint = Color(0xFFF6EBD6);
  static const Color onWarningTint = Color(0xFF7C5012);
  static const Color error = Color(0xFFB23A35);
  static const Color errorTint = Color(0xFFF4DEDB);
  static const Color onErrorTint = Color(0xFFB23A35);

  /// Bilgi bandı: ayrı bir mavi yok, ana rengin açık tonu kullanılır.
  static const Color info = primary;
  static const Color infoTint = primaryTint;

  // Katılımcı durumu (rehber ekranı: geldi / gelmedi)
  static const Color arrived = success;
  static const Color notArrived = error;

  // Kamera üstünde örtü ve kamera ekranının zemini.
  static const Color scrim = Color(0x8A000000);
  static const Color cameraBackground = Color(0xFF111614);
  static const Color onCamera = Color(0xFFFFFFFF);

  // Seçili olmayan, saydam yüzey.
  static const Color transparent = Color(0x00000000);
}
