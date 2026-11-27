/// Bileşen boyutları (ikon, buton, görsel vb.).
abstract final class AppSizes {
  // İkon
  static const double iconXs = 14;
  static const double iconSm = 16;
  static const double iconBanner = 18;
  static const double iconMd = 20;
  static const double iconLg = 24;
  static const double iconXl = 32;
  static const double iconPlaceholder = 36;

  // Buton / form alanı
  static const double buttonHeight = 48;
  static const double inputHeight = 48;
  // Dokunma hedefi en az 48 dp (erişilebilirlik).
  static const double minTapTarget = 48;
  // Alt menü
  static const double navigationBarHeight = 72;
  static const double navigationIcon = 22;

  // Görsel
  static const double tourCardImageHeight = 160;
  // Bölge satırındaki yatay kayan tur kartı (sonraki kart sağdan görünsün diye ekrandan dar).
  static const double tourCarouselCardWidth = 260;
  // Tur kartı görsel oranı (genişlik / yükseklik).
  static const double tourCardImageAspect = 16 / 10;
  static const double tourDetailImageHeight = 260;
  // Madde işareti noktası.
  static const double bulletDot = 5;
  // Listedeki küçük kare görsel (bilet satırı).
  static const double thumbnail = 64;
  // Duyuru kartının solundaki ince vurgu şeridi.
  static const double accentStripe = 3;
  // İki sütunlu bilgi listesinde etiket sütunu.
  static const double detailLabelWidth = 110;
  // Üst çubuktaki yuvarlak geri düğmesi.
  static const double roundBackButton = 40;
  // Sekme seçicinin satır yüksekliği (dokunma hedefi: dış boşlukla 48).
  static const double segmentHeight = 40;
  // Hap biçimli süzgeç düğmesi.
  static const double pillHeight = 40;
  // Katılımcı durum noktası.
  static const double statusDot = 10;
  static const double avatarSm = 32;
  static const double avatarMd = 48;
  static const double qrCode = 220;
  // Okutma sonucu ekranındaki büyük durum ikonu.
  static const double statusIconLarge = 96;
  // Sonuç ekranı başındaki tonlu daire ve içindeki ikonun oranı.
  static const double statusCircle = 56;
  static const double statusCircleIconRatio = 0.54;
  // Bilet kartındaki delikli kesim çizgisi.
  static const double ticketNotchHeight = 28;
  static const double dashLength = 4;
  // QR okutma çerçevesi.
  static const double scanWindow = 240;
  static const double scanWindowBorder = 2;

  // Sohbet balonu en fazla bu genişlikte (uzun mesaj satıra kırılır).
  static const double chatBubbleMaxWidth = 300;
  // Okunmamış bildirim rozeti.
  static const double badgeSize = 18;

  // Kenarlık
  static const double borderWidth = 1;
  static const double focusBorderWidth = 2;
  // Açılır menü gölgesi (tasarımda gölge çok hafif).
  static const double menuElevation = 1;

  // Web panel yerleşimi
  static const double sidebarWidth = 260;
  // Panelde düğme/giriş alanı ve menü satırı yüksekliği.
  static const double panelControlHeight = 40;
  static const double panelRowHeight = 48;
  static const double panelSignOutHeight = 36;
  static const double panelThumbWidth = 48;
  static const double panelThumbHeight = 36;
  static const double panelMaxContentWidth = 1200;
  static const double loginFormMaxWidth = 420;
  static const double dialogWidth = 480;
  static const double wideDialogWidth = 820;
  static const double wideDialogHeight = 560;
  static const double panelImagePreviewWidth = 320;
  static const double panelImagePreviewHeight = 180;
  static const double progressStroke = 2;
  // Açılış ekranındaki ince yükleme çubuğu.
  static const double splashProgressWidth = 128;
  static const double splashProgressHeight = 4;
  // İl listesindeki plaka kutusu.
  static const double plateBoxWidth = 32;
  static const double plateBoxHeight = 28;
  static const double dropdownMenuMaxHeight = 320;
  static const double tableHeadingHeight = 44;
  static const double tableRowHeight = 52;
  static const double tableRowMaxHeight = 72;

  // Görsel yükleme: en uzun kenar bu değere küçültülür (piksel).
  static const int uploadImageMaxDimension = 1280;
  // Görsel yükleme: JPEG kalitesi (0-100).
  static const int uploadImageQuality = 80;

  // Görsel önbelleği: cihazda tutulacak en fazla görsel sayısı.
  static const int imageCacheMaxObjects = 100;
}
