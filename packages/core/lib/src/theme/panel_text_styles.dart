import 'package:flutter/painting.dart';

import '../constants/colors.dart';
import '../constants/font_sizes.dart';
import 'app_fonts.dart';
import 'app_text_styles.dart';

/// Web panelinin yazı stilleri (Stitch "Turla Web" ölçeği: 14 px metin, Fraunces başlık).
abstract final class PanelTextStyles {
  /// Sol menü üstündeki "Turla Panel" yazı-logosu.
  static const TextStyle wordmark = TextStyle(
    fontFamily: AppFonts.display,
    fontSize: AppFontSizes.panelWordmark,
    height: AppLineHeights.panelWordmark,
    letterSpacing: AppLetterSpacings.headline,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );

  /// Sayfa başlığı ("Firmalar", "Turlar").
  static const TextStyle pageTitle = TextStyle(
    fontFamily: AppFonts.display,
    fontSize: AppFontSizes.panelPageTitle,
    height: AppLineHeights.panelPageTitle,
    letterSpacing: AppLetterSpacings.panelPageTitle,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  /// Bölüm başlığı (kart/pencere içinde).
  static const TextStyle sectionTitle = TextStyle(
    fontFamily: AppFonts.sans,
    fontSize: AppFontSizes.title,
    height: AppLineHeights.panelSectionTitle,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle cardTitle = TextStyle(
    fontFamily: AppFonts.sans,
    fontSize: AppFontSizes.panelCardTitle,
    height: AppLineHeights.panelCardTitle,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontFamily: AppFonts.sans,
    fontSize: AppFontSizes.panelBody,
    height: AppLineHeights.panelBody,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  /// Tablo ilk sütunu, menü seçili satırı, metin düğmeleri.
  static const TextStyle bodyStrong = TextStyle(
    fontFamily: AppFonts.sans,
    fontSize: AppFontSizes.panelBody,
    height: AppLineHeights.panelBody,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelMedium = AppTextStyles.labelMedium;
  static const TextStyle labelSmall = AppTextStyles.labelSmall;

  /// Panelde mono (REH-/MUS- kimliği, plaka).
  static const TextStyle mono = TextStyle(
    fontFamily: AppFonts.mono,
    fontSize: AppFontSizes.panelBody,
    height: AppLineHeights.panelBody,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  /// Yeni açılan hesabın şifresi gibi öne çıkan mono değer.
  static const TextStyle monoLarge = TextStyle(
    fontFamily: AppFonts.mono,
    fontSize: AppFontSizes.title,
    height: AppLineHeights.title,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );
}
