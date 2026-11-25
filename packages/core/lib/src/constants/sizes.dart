/// Bileşen boyutları (ikon, buton, görsel vb.).
abstract final class AppSizes {
  // İkon
  static const double iconSm = 16;
  static const double iconMd = 20;
  static const double iconLg = 24;
  static const double iconXl = 32;

  // Buton / form alanı
  static const double buttonHeight = 48;
  static const double inputHeight = 48;

  // Görsel
  static const double tourCardImageHeight = 160;
  static const double tourDetailImageHeight = 240;
  static const double avatarSm = 32;
  static const double avatarMd = 48;
  static const double qrCode = 220;

  // Kenarlık
  static const double borderWidth = 1;

  // Web panel yerleşimi
  static const double sidebarWidth = 260;
  static const double panelMaxContentWidth = 1200;
  static const double loginFormMaxWidth = 420;
  static const double dialogWidth = 480;
  static const double wideDialogWidth = 820;
  static const double wideDialogHeight = 560;
  static const double panelImagePreviewWidth = 320;
  static const double panelImagePreviewHeight = 180;
  static const double progressStroke = 2;
  static const double dropdownMenuMaxHeight = 320;

  // Görsel yükleme: en uzun kenar bu değere küçültülür (piksel).
  static const int uploadImageMaxDimension = 1280;
  // Görsel yükleme: JPEG kalitesi (0-100).
  static const int uploadImageQuality = 80;

  // Görsel önbelleği: cihazda tutulacak en fazla görsel sayısı.
  static const int imageCacheMaxObjects = 100;
}
