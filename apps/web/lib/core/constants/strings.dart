/// Web paneline özel sabit metinler.
/// Ortak metinler `turla_core` paketindeki `CoreStrings` içindedir.
abstract final class AppStrings {
  static const String panelTitle = 'Turla Panel';

  // Genel
  static const String retry = 'Tekrar dene';
  static const String save = 'Kaydet';
  static const String cancel = 'Vazgeç';
  static const String create = 'Oluştur';
  static const String edit = 'Düzenle';
  static const String delete = 'Sil';
  static const String close = 'Kapat';
  static const String confirm = 'Onayla';
  static const String add = 'Ekle';
  static const String active = 'Aktif';
  static const String passive = 'Pasif';
  static const String makeActive = 'Aktif yap';
  static const String makePassive = 'Pasif yap';
  static const String empty = '—';
  static const String saved = 'Kaydedildi.';
  static const String deleted = 'Silindi.';
  static const String signOut = 'Çıkış yap';
  static const String deleteConfirmTitle = 'Silinsin mi?';
  static const String deleteConfirmMessage = 'Bu işlem geri alınamaz.';

  // Form doğrulama
  static const String fieldRequired = 'Bu alan zorunlu.';
  static const String invalidEmail = 'Geçerli bir e-posta adresi girin.';
  static const String passwordTooShort = 'Şifre en az 8 karakter olmalı.';
  static const String nameTooShort = 'En az 3 karakter girin.';
  static const String titleTooShort = 'Başlık en az 3 karakter olmalı.';
  static const String invalidNumber = 'Geçerli bir sayı girin.';
  static const String invalidPrice = 'Geçerli bir fiyat girin (ör. 750 veya 750,50).';
  static const String capacityMustBePositive = 'Kontenjan en az 1 olmalı.';
  static const String phoneTooLong = 'Telefon en fazla 20 karakter olabilir.';

  // Giriş
  static const String loginTitle = 'Panele giriş';
  static const String loginSubtitle = 'Şirket yöneticisi veya super admin hesabınızla giriş yapın.';
  static const String emailLabel = 'E-posta';
  static const String passwordLabel = 'Şifre';
  static const String loginButton = 'Giriş yap';

  // Giriş hataları
  static const String errorInvalidCredentials = 'E-posta veya şifre hatalı.';
  static const String errorEmailNotConfirmed = 'E-posta adresi henüz doğrulanmamış.';
  static const String errorRateLimited = 'Çok fazla deneme yapıldı. Biraz sonra tekrar deneyin.';
  static const String errorAccountDisabled = 'Bu hesap kullanıma kapatılmış.';
  static const String errorProfileMissing = 'Hesap bilgileri bulunamadı.';
  static const String errorRoleNotAllowed =
      'Bu hesap panele giremez. Müşteri ve tur sorumlusu hesapları mobil uygulamayı kullanır.';
  static const String errorCompanyInactive =
      'Firmanız pasif durumda. Panel kullanımı için Turla ile iletişime geçin.';

  // Panel hataları
  static const String errorNotAllowed = 'Bu işlem için yetkiniz yok.';
  static const String errorNotFound = 'Kayıt bulunamadı.';
  static const String errorHasTickets =
      'Bu kayda bağlı satılmış bilet var; silinemez. Bunun yerine pasif yapabilirsiniz.';
  static const String errorCapacityBelowSold =
      'Kontenjan satılan bilet sayısının altına düşürülemez.';
  static const String errorInvalidGuide = 'Seçilen tur sorumlusu bu firmada aktif değil.';
  static const String errorAlreadyReviewed = 'Bu talep zaten sonuçlandırılmış.';
  static const String errorEmailExists = 'Bu e-posta ile zaten bir hesap var.';
  static const String errorWeakPassword = 'Şifre çok zayıf. En az 8 karakterli bir şifre seçin.';
  static const String errorInvalidInput = 'Girilen bilgiler geçersiz. Alanları kontrol edin.';
  static const String errorCannotChangeSelf = 'Kendi hesabınızın durumunu değiştiremezsiniz.';
  static const String errorInvalidImage = 'Görsel okunamadı. JPEG, PNG veya WebP bir dosya seçin.';
  static const String errorInvalidCustomer =
      'Bilet sadece firmanın panelden eklediği aktif müşterilere kesilebilir.';
  static const String errorAlreadyHasTicket =
      'Bu müşterinin bu tarih için zaten geçerli bir bileti var.';
  static const String errorNoSeatsLeft = 'Bu tarihte boş koltuk kalmadı.';
  static const String errorDepartureNotBookable =
      'Bu tarihe bilet kesilemez (kalkış saati geçti veya tarih kapandı).';
  static const String errorNotResettable =
      'Bu hesabın şifresi panelden sıfırlanamaz (sadece REH-/MUS- giriş kimlikli hesaplar).';
  static const String errorTicketNotCancellable =
      'Bu bilet iptal edilemez (kullanıldı, tur tamamlandı veya zaten iptal edildi).';

  // Menü
  static const String navCompanies = 'Firmalar';
  static const String navTours = 'Turlar';
  static const String navStaff = 'Personel ve müşteriler';
  static const String navCompletions = 'Tur bitirme talepleri';
  static const String backToCompanies = 'Tüm firmalar';

  // Firmalar (super admin)
  static const String companiesTitle = 'Firmalar';
  static const String newCompany = 'Yeni firma';
  static const String editCompany = 'Firmayı düzenle';
  static const String companyName = 'Firma adı';
  static const String companyCity = 'İl';
  static const String companyPhone = 'Telefon';
  static const String companiesEmpty = 'Henüz firma yok.';
  static const String manageCompany = 'Firmayı yönet';
  static const String companyAdmins = 'Firma yöneticileri';
  static const String companyAdminsEmpty = 'Bu firmanın yöneticisi yok.';
  static const String newAdmin = 'Yönetici hesabı aç';
  static const String companyInactiveBanner =
      'Bu firma pasif: turları müşterilere görünmez ve yöneticisi panele giremez.';

  // Hesap açma
  static const String fullNameLabel = 'Ad soyad';
  static const String phoneLabel = 'Telefon (isteğe bağlı)';
  static const String temporaryPasswordLabel = 'Geçici şifre';
  static const String temporaryPasswordHelper = 'En az 8 karakter. Hesap sahibine siz iletirsiniz.';
  static const String accountCreatedTitle = 'Hesap açıldı';
  static const String accountCreatedLoginId = 'Giriş kimliği';
  static const String accountCreatedEmail = 'Giriş e-postası';
  static const String accountCreatedHint =
      'Bu bilgileri ve belirlediğiniz geçici şifreyi hesap sahibine iletin. '
      'Şifre burada tekrar gösterilmez.';

  // Personel
  static const String staffTitle = 'Personel ve müşteriler';
  static const String guidesTab = 'Tur sorumluları';
  static const String customersTab = 'Dışarıdan eklenen müşteriler';
  static const String newGuide = 'Tur sorumlusu ekle';
  static const String newCustomer = 'Müşteri ekle';
  static const String guidesEmpty = 'Henüz tur sorumlusu yok.';
  static const String customersEmpty = 'Henüz dışarıdan eklenen müşteri yok.';
  static const String loginIdColumn = 'Giriş kimliği';
  static const String statusColumn = 'Durum';
  static const String nameColumn = 'Ad soyad';
  static const String phoneColumn = 'Telefon';
  static const String resetPassword = 'Şifre sıfırla';
  static const String resetPasswordTitle = 'Şifre sıfırlansın mı?';
  static const String resetPasswordMessage =
      'Hesaba yeni bir geçici şifre verilir; eski şifre hemen geçersiz olur. '
      'Yeni şifreyi hesap sahibine siz iletirsiniz.';
  static const String resetPasswordConfirm = 'Sıfırla';
  static const String passwordResetTitle = 'Yeni geçici şifre';
  static const String passwordResetHint =
      'Bu şifreyi hesap sahibine iletin. Pencere kapanınca tekrar gösterilmez.';
  static const String newPasswordLabel = 'Yeni şifre';

  // Turlar
  static const String toursTitle = 'Turlar';
  static const String newTour = 'Yeni tur';
  static const String toursEmpty = 'Henüz tur yok. "Yeni tur" ile ekleyin.';
  static const String tourTitle = 'Tur adı';
  static const String tourDescription = 'Açıklama';
  static const String tourExtraDetail = 'Ek bilgi (dahil olanlar, notlar)';
  static const String tourPrice = 'Fiyat (₺)';
  static const String tourCity = 'Kalkış ili';
  static const String tourRegion = 'Bölge';
  static const String tourActive = 'Satışta (müşterilere görünür)';
  static const String tourImage = 'Kapak görseli';
  static const String uploadImage = 'Görsel yükle';
  static const String replaceImage = 'Görseli değiştir';
  static const String noImage = 'Görsel yok';
  static const String imageUploaded = 'Görsel yüklendi.';
  static const String tourInfoTab = 'Bilgiler';
  static const String tourProgramTab = 'Program';
  static const String tourDeparturesTab = 'Tarihler';
  static const String saveTourFirst = 'Program ve tarih eklemek için önce turu kaydedin.';
  static const String departuresColumn = 'Tarih sayısı';
  static const String priceColumn = 'Fiyat';

  // Program
  static const String programEmpty = 'Program henüz eklenmedi.';
  static const String addDay = 'Gün ekle';
  static const String dayLabel = 'Gün';
  static const String dayTitle = 'Gün başlığı';
  static const String dayActivities = 'Etkinlikler (her satıra bir tane)';
  static const String moveUp = 'Yukarı taşı';
  static const String moveDown = 'Aşağı taşı';
  static const String removeDay = 'Günü kaldır';
  static const String saveProgram = 'Programı kaydet';
  static const String programUnsaved = 'Kaydedilmemiş değişiklikler var.';

  // Tarihler
  static const String departuresEmpty = 'Henüz tarih yok.';
  static const String newDeparture = 'Tarih ekle';
  static const String editDeparture = 'Tarihi düzenle';
  static const String departureDate = 'Kalkış tarihi';
  static const String departureTime = 'Kalkış saati';
  static const String departureCapacity = 'Kontenjan';
  static const String departureGuide = 'Tur sorumlusu';
  static const String noGuide = 'Atanmadı';
  static const String busPlate = 'Araç plakası';
  static const String driverName = 'Şoför adı';
  static const String driverPhone = 'Şoför telefonu';
  static const String seatsColumn = 'Dolu / kontenjan';
  static const String departureLocked = 'Bu tarih kapandı; düzenlenemez.';

  // Katılımcılar ve biletler (tarih bazında)
  static const String participants = 'Katılımcılar';
  static const String participantsTitle = 'Katılımcılar ve biletler';
  static const String participantsEmpty = 'Bu tarihe henüz bilet satılmadı.';
  static const String soldSeatsLabel = 'Satılan koltuk';
  static const String passengerColumn = 'Yolcu';
  static const String ticketSourceColumn = 'Kaynak';
  static const String pricePaidColumn = 'Ödenen';
  static const String purchasedAtColumn = 'Alış';
  static const String ticketSourceApp = 'Uygulama';
  static const String ticketSourcePanel = 'Panel';
  static const String manualCheckInSuffix = '(elle)';
  static const String issueTicket = 'Bilet kes';
  static const String issueTicketTitle = 'Müşteriye bilet kes';
  static const String issueTicketHint =
      'Panelden eklenen (MUS-) müşterilere kesilir. Ödeme "elden / havale" olarak kaydedilir.';
  static const String issueTicketCustomer = 'Müşteri';
  static const String issueTicketPassenger = 'Yolcu adı (boşsa müşterinin adı)';
  static const String issueTicketNoCustomers =
      'Aktif müşteri yok. Önce "Personel ve müşteriler" sayfasından müşteri hesabı açın.';
  static const String issueTicketClosed = 'Bu tarih kapandı; bilet kesilemez.';
  static const String ticketIssued = 'Bilet kesildi.';
  static const String cancelTicket = 'Bileti iptal et';
  static const String cancelTicketTitle = 'Bilet iptal edilsin mi?';
  static const String cancelTicketMessage =
      'Koltuk geri açılır, ödeme varsa tamamı iade olarak kaydedilir. Yönetici iptali 1 saat '
      'kuralından muaftır.';
  static const String ticketCancelled = 'Bilet iptal edildi.';

  // Tur bitirme talepleri
  static const String completionsTitle = 'Tur bitirme talepleri';
  static const String completionsEmpty = 'Bekleyen veya geçmiş talep yok.';
  static const String completionPending = 'Bekliyor';
  static const String completionApproved = 'Onaylandı';
  static const String completionRejected = 'Reddedildi';
  static const String approve = 'Onayla';
  static const String reject = 'Reddet';
  static const String approveConfirmTitle = 'Tur bitirilsin mi?';
  static const String approveConfirmMessage =
      'Sadece bu tarih kapanır. QR okutulan yolcular "Tamamlandı", okutulmayanlar '
      '"Gelmedi" olarak işaretlenir.';
  static const String rejectConfirmTitle = 'Talep reddedilsin mi?';
  static const String rejectConfirmMessage = 'Tarih yeniden aktif olur; rehber turu sürdürür.';
  static const String requestedBy = 'Talep eden';
  static const String requestedAt = 'Talep zamanı';

  // Ortak
  static const String send = 'Gönder';
  static const String publish = 'Yayınla';
  static const String messageTitleLabel = 'Başlık';
  static const String messageBodyLabel = 'Metin';

  // Tur sohbeti (firma denetimi)
  static const String chatButton = 'Sohbet';
  static const String chatTitle = 'Tur sohbeti';
  static const String chatEmpty = 'Bu tarihte henüz mesaj yok.';
  static const String chatInputHint = 'Firma olarak mesaj yaz';
  static const String chatLoadOlder = 'Önceki mesajlar';
  static const String chatReadOnlyPanel =
      'Tarih açık değil: yeni mesaj yazılamaz. Tur bitince sohbet yolculardan ve rehberden '
      'gizlenir; kayıtlar burada görünmeye devam eder.';
  static const String chatDeleteTitle = 'Mesaj silinsin mi?';
  static const String chatGuideTag = 'Tur sorumlusu';
  static const String chatCompanyTag = 'Firma';

  // Firma duyuruları (super admin → firmalar)
  static const String navAnnouncements = 'Duyurular';
  static const String announcementsTitle = 'Duyurular';
  static const String announcementsEmpty = 'Henüz duyuru yok.';
  static const String publishAnnouncement = 'Duyuru yayınla';
  static const String announcementTarget = 'Kime';
  static const String allCompanies = 'Tüm firmalar';
  static const String announcementPublished = 'Duyuru yayınlandı.';
  static const String deleteAnnouncementTitle = 'Duyuru silinsin mi?';

  // Geri bildirim (firma → super admin)
  static const String navFeedback = 'Geri bildirim';
  static const String feedbackTitle = 'Geri bildirimler';
  static const String feedbackEmpty = 'Henüz geri bildirim yok.';
  static const String sendFeedback = 'Geri bildirim gönder';
  static const String feedbackSent = 'Geri bildirimin iletildi.';
  static const String feedbackOpen = 'Açık';
  static const String feedbackInProgress = 'İnceleniyor';
  static const String feedbackResolved = 'Çözüldü';

  // Hata
  static const String errorChatRateLimited = 'Çok hızlı gönderiyorsun; biraz bekleyip tekrar dene.';
}
