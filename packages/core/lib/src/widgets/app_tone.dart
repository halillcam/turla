import 'package:flutter/painting.dart';

import '../constants/colors.dart';

/// Durum tonu: rozet ve bilgi bantlarının renk çifti (açık zemin + koyu metin).
enum AppTone {
  neutral(AppColors.surfaceMuted, AppColors.textSecondary, AppColors.textSecondary),
  primary(AppColors.primaryTint, AppColors.primary, AppColors.primary),
  success(AppColors.successTint, AppColors.onSuccessTint, AppColors.success),
  warning(AppColors.warningTint, AppColors.onWarningTint, AppColors.warning),
  error(AppColors.errorTint, AppColors.onErrorTint, AppColors.error);

  const AppTone(this.background, this.foreground, this.strong);

  /// Açık zemin rengi.
  final Color background;

  /// Zemin üstündeki metin/ikon rengi (AA kontrastlı).
  final Color foreground;

  /// Tek başına kullanılan güçlü renk (nokta, ince çizgi, ikon).
  final Color strong;
}
