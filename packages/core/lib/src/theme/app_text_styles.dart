import 'package:flutter/painting.dart';

import '../constants/colors.dart';
import '../constants/font_sizes.dart';
import 'app_fonts.dart';

/// Yazı stilleri (Stitch tipografi belirteçleri). Tema bunlardan kurulur; ekranlar
/// çoğunlukla `Theme.of(context).textTheme` kullanır, temada karşılığı olmayan
/// stiller (bölüm başlığı, mono, fiyat) buradan alınır.
abstract final class AppTextStyles {
  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  // Fraunces başlıklar
  static const TextStyle displayLarge = TextStyle(
    fontFamily: AppFonts.display,
    fontSize: AppFontSizes.displayLarge,
    height: AppLineHeights.displayLarge,
    letterSpacing: AppLetterSpacings.displayLarge,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const TextStyle display = TextStyle(
    fontFamily: AppFonts.display,
    fontSize: AppFontSizes.display,
    height: AppLineHeights.display,
    letterSpacing: AppLetterSpacings.display,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: AppFonts.display,
    fontSize: AppFontSizes.headlineLarge,
    height: AppLineHeights.headlineLarge,
    letterSpacing: AppLetterSpacings.headlineLarge,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const TextStyle headline = TextStyle(
    fontFamily: AppFonts.display,
    fontSize: AppFontSizes.headline,
    height: AppLineHeights.headline,
    letterSpacing: AppLetterSpacings.headline,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const TextStyle titleLarge = TextStyle(
    fontFamily: AppFonts.display,
    fontSize: AppFontSizes.title,
    height: AppLineHeights.title,
    letterSpacing: AppLetterSpacings.title,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const TextStyle titleMedium = TextStyle(
    fontFamily: AppFonts.display,
    fontSize: AppFontSizes.titleMedium,
    height: AppLineHeights.titleMedium,
    letterSpacing: AppLetterSpacings.title,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // IBM Plex Sans metin
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: AppFonts.sans,
    fontSize: AppFontSizes.bodyLarge,
    height: AppLineHeights.bodyLarge,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );
  static const TextStyle body = TextStyle(
    fontFamily: AppFonts.sans,
    fontSize: AppFontSizes.body,
    height: AppLineHeights.body,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );
  static const TextStyle bodySmall = TextStyle(
    fontFamily: AppFonts.sans,
    fontSize: AppFontSizes.caption,
    height: AppLineHeights.caption,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  // Etiketler
  static const TextStyle labelLarge = TextStyle(
    fontFamily: AppFonts.sans,
    fontSize: AppFontSizes.body,
    height: AppLineHeights.label,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const TextStyle labelMedium = TextStyle(
    fontFamily: AppFonts.sans,
    fontSize: AppFontSizes.caption,
    height: AppLineHeights.caption,
    letterSpacing: AppLetterSpacings.label,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );
  static const TextStyle labelSmall = TextStyle(
    fontFamily: AppFonts.sans,
    fontSize: AppFontSizes.labelSmall,
    height: AppLineHeights.labelSmall,
    letterSpacing: AppLetterSpacings.labelSmall,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  /// Bölüm başlığı: küçük, büyük harf, ana renk (ör. "DOĞU KARADENİZ").
  /// Metin büyük harfe `toUpperCase` ile değil, Türkçe kurala uygun `display` katmanında çevrilir.
  static const TextStyle eyebrow = TextStyle(
    fontFamily: AppFonts.sans,
    fontSize: AppFontSizes.labelSmall,
    height: AppLineHeights.labelSmall,
    letterSpacing: AppLetterSpacings.eyebrow,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );

  /// Plaka, REH-/MUS- kimliği, bilet kodu.
  static const TextStyle mono = TextStyle(
    fontFamily: AppFonts.mono,
    fontSize: AppFontSizes.caption,
    height: AppLineHeights.caption,
    letterSpacing: AppLetterSpacings.mono,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  /// Fiyat: Fraunces, ana renk, eşit genişlikli rakam.
  static const TextStyle price = TextStyle(
    fontFamily: AppFonts.display,
    fontSize: AppFontSizes.title,
    height: AppLineHeights.title,
    letterSpacing: AppLetterSpacings.title,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
    fontFeatures: _tabular,
  );

  /// Saat/sayı gibi hizalı rakam isteyen metinler için.
  static const List<FontFeature> tabularFigures = _tabular;
}
