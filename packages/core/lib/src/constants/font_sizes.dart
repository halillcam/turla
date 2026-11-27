/// Yazı boyutları (Stitch tipografi ölçeği).
abstract final class AppFontSizes {
  static const double labelSmall = 12;
  static const double caption = 13;
  static const double body = 15;
  static const double bodyLarge = 16;
  static const double titleMedium = 17;
  static const double title = 18;
  static const double headline = 22;
  static const double headlineLarge = 26;
  static const double display = 28;
  static const double displayLarge = 40;

  // Web paneli (daha sıkı ölçek)
  static const double panelBody = 14;
  static const double panelCardTitle = 16;
  static const double panelWordmark = 20;
  static const double panelPageTitle = 24;
}

/// Satır yükseklikleri (yazı boyutuna oran olarak; Flutter `height`).
abstract final class AppLineHeights {
  static const double labelSmall = 16 / 12;
  static const double caption = 18 / 13;
  static const double body = 22 / 15;
  static const double bodyLarge = 24 / 16;
  static const double label = 20 / 15;
  static const double titleMedium = 22 / 17;
  static const double title = 24 / 18;
  static const double headline = 28 / 22;
  static const double headlineLarge = 32 / 26;
  static const double display = 34 / 28;
  static const double displayLarge = 46 / 40;
  static const double panelBody = 20 / 14;
  static const double panelCardTitle = 24 / 16;
  static const double panelWordmark = 28 / 20;
  static const double panelPageTitle = 32 / 24;
  static const double panelSectionTitle = 26 / 18;
}

/// Harf aralıkları.
abstract final class AppLetterSpacings {
  static const double displayLarge = -0.5;
  static const double display = -0.4;
  static const double headlineLarge = -0.3;
  static const double headline = -0.2;
  static const double title = -0.1;
  static const double label = 0.1;
  static const double labelSmall = 0.2;
  static const double mono = 0.3;
  static const double eyebrow = 0.8;
  static const double panelPageTitle = -0.25;
}
