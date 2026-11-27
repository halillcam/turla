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
  // Giriş alanının yatay iç boşluğu (tasarımda 14).
  static const double inputHorizontal = 14;
}

/// Hazır `EdgeInsets` değerleri.
abstract final class AppPaddings {
  static const EdgeInsets allXs = EdgeInsets.all(AppSpacing.xs);
  static const EdgeInsets allSm = EdgeInsets.all(AppSpacing.sm);
  static const EdgeInsets allMd = EdgeInsets.all(AppSpacing.md);
  static const EdgeInsets allLg = EdgeInsets.all(AppSpacing.lg);
  static const EdgeInsets allXl = EdgeInsets.all(AppSpacing.xl);

  static const EdgeInsets horizontalXs = EdgeInsets.symmetric(horizontal: AppSpacing.xs);
  static const EdgeInsets horizontalSm = EdgeInsets.symmetric(horizontal: AppSpacing.sm);
  static const EdgeInsets horizontalLg = EdgeInsets.symmetric(horizontal: AppSpacing.lg);
  static const EdgeInsets horizontalXl = EdgeInsets.symmetric(horizontal: AppSpacing.xl);

  static const EdgeInsets verticalXs = EdgeInsets.symmetric(vertical: AppSpacing.xs);
  static const EdgeInsets verticalSm = EdgeInsets.symmetric(vertical: AppSpacing.sm);
  static const EdgeInsets verticalMd = EdgeInsets.symmetric(vertical: AppSpacing.md);
  static const EdgeInsets verticalLg = EdgeInsets.symmetric(vertical: AppSpacing.lg);

  /// Ekran kenar boşluğu.
  static const EdgeInsets screen = EdgeInsets.symmetric(
    horizontal: AppSpacing.lg,
    vertical: AppSpacing.lg,
  );

  /// Tur kartı içi boşluk.
  static const EdgeInsets tourCard = EdgeInsets.all(AppSpacing.inputHorizontal);

  /// Bölüm başlığı: solda sayfa kenarı, sağda düğmenin kendi boşluğu yeter.
  static const EdgeInsets sectionHeader = EdgeInsets.only(
    left: AppSpacing.lg,
    right: AppSpacing.xs,
  );

  /// Liste ekranının üst başlığı (şehir + arama).
  static const EdgeInsets listHeader = EdgeInsets.fromLTRB(
    AppSpacing.lg,
    AppSpacing.lg,
    AppSpacing.lg,
    AppSpacing.md,
  );

  /// Açılış ekranı.
  static const EdgeInsets splash = EdgeInsets.symmetric(
    horizontal: AppSpacing.lg,
    vertical: AppSpacing.xxxl,
  );

  /// Başlığın altındaki liste gövdesi (üstte boşluk yok).
  static const EdgeInsets listBody = EdgeInsets.fromLTRB(
    AppSpacing.lg,
    0,
    AppSpacing.lg,
    AppSpacing.lg,
  );

  /// Kenarlıklı liste kartındaki satır.
  static const EdgeInsets listRow = EdgeInsets.symmetric(
    horizontal: AppSpacing.lg,
    vertical: AppSpacing.md,
  );

  /// İçerik bölümü başlığı ("Tur hakkında"): üstte bölüm arası, altta başlık-metin arası.
  static const EdgeInsets sectionTitle = EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.sm);

  /// Açılır kartın başlık satırı.
  static const EdgeInsets expansionTile = EdgeInsets.symmetric(horizontal: AppSpacing.lg);

  /// Açılır kartın içeriği.
  static const EdgeInsets expansionChildren = EdgeInsets.fromLTRB(
    AppSpacing.lg,
    0,
    AppSpacing.lg,
    AppSpacing.lg,
  );

  /// Madde işaretli satır ve noktasının metinle hizası.
  static const EdgeInsets bulletRow = EdgeInsets.only(top: 6);
  static const EdgeInsets bulletDot = EdgeInsets.only(top: AppSpacing.sm);

  /// Detay ekranı gövdesi (kapak görselinin altı).
  static const EdgeInsets detailBody = EdgeInsets.fromLTRB(
    AppSpacing.lg,
    20,
    AppSpacing.lg,
    AppSpacing.xl,
  );

  /// Alt yapışık eylem çubuğu.
  static const EdgeInsets bottomBar = EdgeInsets.symmetric(
    horizontal: AppSpacing.lg,
    vertical: AppSpacing.md,
  );

  /// Basılı bilet kartının üst (tur) ve alt (QR) yarısı.
  static const EdgeInsets ticketStubTop = EdgeInsets.all(20);
  static const EdgeInsets ticketStubBottom = EdgeInsets.all(AppSpacing.xl);
  static const EdgeInsets ticketSection = EdgeInsets.fromLTRB(20, 0, 20, AppSpacing.lg);

  /// Sonuç ekranı (bilet alındı vb.).
  static const EdgeInsets successPage = EdgeInsets.symmetric(
    horizontal: AppSpacing.lg,
    vertical: AppSpacing.xxl,
  );

  /// Sohbet: mesaj arası ve balon içi.
  static const EdgeInsets chatMessage = EdgeInsets.symmetric(vertical: AppSpacing.sm);
  static const EdgeInsets chatBubble = EdgeInsets.symmetric(
    horizontal: AppSpacing.inputHorizontal,
    vertical: 10,
  );

  /// Mesaj yazma çubuğu.
  static const EdgeInsets composer = EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 10);

  /// Plaka etiketi içi.
  static const EdgeInsets plateChip = EdgeInsets.symmetric(
    horizontal: AppSpacing.sm,
    vertical: AppSpacing.xxs,
  );

  /// Rehber ana ekranı başlığı (liste içinde; yanlarda liste boşluğu zaten var).
  static const EdgeInsets guideHeader = EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.lg);

  /// Hap süzgeç içi.
  static const EdgeInsets pill = EdgeInsets.symmetric(horizontal: AppSpacing.inputHorizontal);

  /// Katılımcı satırı (sağda arama düğmesinin kendi boşluğu var).
  static const EdgeInsets participantRow = EdgeInsets.fromLTRB(
    AppSpacing.lg,
    AppSpacing.xs,
    AppSpacing.xs,
    AppSpacing.xs,
  );

  /// Okunmamış noktasının başlıkla hizası.
  static const EdgeInsets unreadDot = EdgeInsets.only(top: 6);

  /// Liste ekranının üstündeki bilgi bandı.
  static const EdgeInsets bannerTop = EdgeInsets.fromLTRB(
    AppSpacing.lg,
    AppSpacing.md,
    AppSpacing.lg,
    0,
  );

  /// Web paneli: düğme ve giriş alanı içi (yükseklik 40).
  static const EdgeInsets panelButton = EdgeInsets.symmetric(horizontal: AppSpacing.lg);
  static const EdgeInsets panelInput = EdgeInsets.symmetric(
    horizontal: AppSpacing.md,
    vertical: 10,
  );

  /// Web paneli: sayfa içeriği, sol menü, tablo hücresi, bağlam bandı.
  static const EdgeInsets panelPage = EdgeInsets.all(AppSpacing.xxl);
  static const EdgeInsets panelSidebar = EdgeInsets.all(AppSpacing.lg);
  static const EdgeInsets panelNavItem = EdgeInsets.symmetric(horizontal: AppSpacing.md);
  static const EdgeInsets panelCompanyBox = EdgeInsets.symmetric(
    horizontal: AppSpacing.md,
    vertical: AppSpacing.sm,
  );
  static const EdgeInsets navItemGap = EdgeInsets.only(bottom: AppSpacing.xs);
  static const EdgeInsets panelBanner = EdgeInsets.symmetric(
    horizontal: AppSpacing.xxl,
    vertical: AppSpacing.sm,
  );

  /// Kart içi boşluk.
  static const EdgeInsets card = EdgeInsets.all(AppSpacing.lg);

  /// Giriş alanı içi boşluk (yükseklik 48).
  static const EdgeInsets input = EdgeInsets.symmetric(
    horizontal: AppSpacing.inputHorizontal,
    vertical: AppSpacing.md,
  );

  /// Metin butonu içi boşluk.
  static const EdgeInsets textButton = EdgeInsets.symmetric(
    horizontal: AppSpacing.md,
    vertical: AppSpacing.sm,
  );

  /// Seçim çipi içi boşluk.
  static const EdgeInsets chip = EdgeInsets.symmetric(
    horizontal: AppSpacing.sm,
    vertical: AppSpacing.xs,
  );

  /// Durum rozeti (hap) içi boşluk.
  static const EdgeInsets badge = EdgeInsets.symmetric(horizontal: 10, vertical: AppSpacing.xxs);

  /// Bilgi bandı içi boşluk.
  static const EdgeInsets banner = EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10);

  /// Buton içi boşluk.
  static const EdgeInsets button = EdgeInsets.symmetric(
    horizontal: AppSpacing.xl,
    vertical: AppSpacing.md,
  );
}

/// Hazır `EdgeInsets` margin değerleri.
abstract final class AppMargins {
  static const EdgeInsets cardList = EdgeInsets.only(bottom: AppSpacing.md);
  // Seçim kartı / program günü arası (tasarımda 10).
  static const EdgeInsets listItem = EdgeInsets.only(bottom: 10);
  static const EdgeInsets section = EdgeInsets.only(bottom: AppSpacing.xl);
  static const EdgeInsets none = EdgeInsets.zero;
}
