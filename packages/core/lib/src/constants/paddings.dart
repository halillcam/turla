import 'package:flutter/painting.dart';

/// Boşluk ölçüleri (padding / margin / aralık). 4'ün katları kullanılır.
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

/// Hazır `EdgeInsets` değerleri.
abstract final class AppPaddings {
  static const EdgeInsets allXs = EdgeInsets.all(AppSpacing.xs);
  static const EdgeInsets allSm = EdgeInsets.all(AppSpacing.sm);
  static const EdgeInsets allMd = EdgeInsets.all(AppSpacing.md);
  static const EdgeInsets allLg = EdgeInsets.all(AppSpacing.lg);
  static const EdgeInsets allXl = EdgeInsets.all(AppSpacing.xl);

  static const EdgeInsets horizontalSm = EdgeInsets.symmetric(horizontal: AppSpacing.sm);
  static const EdgeInsets horizontalLg = EdgeInsets.symmetric(horizontal: AppSpacing.lg);
  static const EdgeInsets horizontalXl = EdgeInsets.symmetric(horizontal: AppSpacing.xl);

  static const EdgeInsets verticalXs = EdgeInsets.symmetric(vertical: AppSpacing.xs);
  static const EdgeInsets verticalSm = EdgeInsets.symmetric(vertical: AppSpacing.sm);
  static const EdgeInsets verticalLg = EdgeInsets.symmetric(vertical: AppSpacing.lg);

  /// Ekran kenar boşluğu.
  static const EdgeInsets screen = EdgeInsets.symmetric(
    horizontal: AppSpacing.lg,
    vertical: AppSpacing.lg,
  );

  /// Kart içi boşluk.
  static const EdgeInsets card = EdgeInsets.all(AppSpacing.lg);

  /// Buton içi boşluk.
  static const EdgeInsets button = EdgeInsets.symmetric(
    horizontal: AppSpacing.xl,
    vertical: AppSpacing.md,
  );
}

/// Hazır `EdgeInsets` margin değerleri.
abstract final class AppMargins {
  static const EdgeInsets cardList = EdgeInsets.only(bottom: AppSpacing.md);
  static const EdgeInsets section = EdgeInsets.only(bottom: AppSpacing.xl);
  static const EdgeInsets none = EdgeInsets.zero;
}
