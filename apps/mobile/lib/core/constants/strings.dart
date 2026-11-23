/// Mobil uygulamaya özel sabit metinler.
/// Ortak metinler `turla_core` paketindeki `CoreStrings` içindedir.
abstract final class AppStrings {
  // Genel
  static const String retry = 'Tekrar dene';
  static const String loading = 'Yükleniyor...';
  static const String back = 'Geri';
  static const String change = 'Değiştir';

  // Alt menü
  static const String navTours = 'Turlar';
  static const String navProfile = 'Profil';

  // Giriş
  static const String loginTitle = 'Giriş yap';
  static const String loginSubtitle =
      'Müşteriysen e-postanla, tur sorumlusuysan firmanın verdiği kimlikle giriş yap.';
  static const String identityLabel = 'E-posta veya giriş kimliği';
  static const String identityHint = 'ornek@mail.com veya REH-1234';
  static const String passwordLabel = 'Şifre';
  static const String loginButton = 'Giriş yap';
  static const String noAccount = 'Hesabın yok mu?';
  static const String goToRegister = 'Kayıt ol';
  static const String continueAsGuest = 'Giriş yapmadan devam et';

  // Kayıt
  static const String registerTitle = 'Kayıt ol';
  static const String registerSubtitle = 'Bilet alabilmek için bir hesap oluştur.';
  static const String fullNameLabel = 'Ad soyad';
  static const String emailLabel = 'E-posta';
  static const String passwordConfirmLabel = 'Şifre (tekrar)';
  static const String registerButton = 'Hesap oluştur';
  static const String haveAccount = 'Zaten hesabın var mı?';
  static const String goToLogin = 'Giriş yap';
  static const String confirmationSentTitle = 'E-postanı kontrol et';
  static const String confirmationSentMessage =
      'Hesabını doğrulamak için e-posta adresine bir bağlantı gönderdik. '
      'Doğruladıktan sonra giriş yapabilirsin.';

  // Form doğrulama
  static const String fieldRequired = 'Bu alan zorunlu.';
  static const String invalidEmail = 'Geçerli bir e-posta adresi gir.';
  static const String passwordTooShort = 'Şifre en az 8 karakter olmalı.';
  static const String passwordsDoNotMatch = 'Şifreler aynı değil.';
  static const String fullNameTooShort = 'Ad soyad en az 3 karakter olmalı.';

  // Giriş hataları
  static const String errorInvalidCredentials = 'E-posta/kimlik veya şifre hatalı.';
  static const String errorEmailNotConfirmed =
      'E-posta adresin henüz doğrulanmamış. Gelen kutunu kontrol et.';
  static const String errorUserAlreadyExists = 'Bu e-posta ile zaten bir hesap var.';
  static const String errorWeakPassword = 'Şifre çok zayıf. Daha uzun bir şifre seç.';
  static const String errorRateLimited = 'Çok fazla deneme yapıldı. Biraz sonra tekrar dene.';
  static const String errorAccountDisabled = 'Bu hesap kullanıma kapatılmış.';
  static const String errorProfileMissing = 'Hesap bilgileri bulunamadı. Destek ile iletişime geç.';
  static const String errorRoleNotAllowed =
      'Bu hesap web panelinde kullanılır. Mobil uygulamaya müşteri veya tur sorumlusu '
      'hesabıyla giriş yapabilirsin.';

  // Şehir seçimi
  static const String cityChoiceTitle = 'Şehrini seç';
  static const String cityChoiceSubtitle = 'Bu şehirden kalkan turları göstereceğiz.';
  static const String citySearchHint = 'Şehir ara';
  static const String cityNotFound = 'Bu isimde bir şehir bulunamadı.';
  static const String citiesLoadError = 'Şehirler yüklenemedi. İnternet bağlantını kontrol et.';

  // Tur listesi
  static const String tourSearchHint = 'Tur ara';
  static const String departingFrom = 'Kalkış şehri';
  static const String noToursInCity = 'Bu şehirden kalkan aktif tur bulunmuyor.';
  static const String noToursMatch = 'Aramana uygun tur bulunamadı.';
  static const String toursLoadError = 'Turlar yüklenemedi. İnternet bağlantını kontrol et.';
  static const String showingCachedTours =
      'İnternet bağlantısı yok. Son kaydedilen turlar gösteriliyor.';
  static const String nextDeparture = 'İlk kalkış';
  static const String departureCountSuffix = 'tarih';
  static const String soldOut = 'Dolu';
  static const String seatsLeftSuffix = 'koltuk kaldı';

  // Tur detayı
  static const String tourDetailLoadError = 'Tur bilgileri yüklenemedi.';
  static const String tourNotFound = 'Bu tur artık yayında değil.';
  static const String organizer = 'Düzenleyen';
  static const String aboutTour = 'Tur hakkında';
  static const String extraDetails = 'Ek bilgiler';
  static const String program = 'Tur programı';
  static const String dayPrefix = 'Gün';
  static const String departures = 'Kalkış tarihleri';
  static const String noUpcomingDepartures = 'Yaklaşan kalkış tarihi yok.';
  static const String pricePerPerson = 'Kişi başı';
  static const String buyTicket = 'Bilet al';
  static const String loginToBuy = 'Bilet almak için giriş yap';
  static const String purchaseComingSoon = 'Bilet satın alma bir sonraki sürümde açılacak.';

  // Profil
  static const String profileTitle = 'Profil';
  static const String guestProfileTitle = 'Henüz giriş yapmadın';
  static const String guestProfileMessage =
      'Turlara giriş yapmadan göz atabilirsin. Bilet almak için giriş yap veya kayıt ol.';
  static const String selectedCity = 'Seçili şehir';
  static const String noCitySelected = 'Seçilmedi';
  static const String account = 'Hesap';
  static const String signOut = 'Çıkış yap';

  // Rehber
  static const String guideHomeTitle = 'Tur sorumlusu';
  static const String guideWelcomePrefix = 'Hoş geldin,';
  static const String guideComingSoon =
      'Katılımcı listesi, QR okutma ve duyurular bir sonraki sürümde bu ekrana gelecek.';
}
