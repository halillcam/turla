# Turla — Teknik Doküman

> Bu doküman, okuyanların rahat okuyabilmesi için yapay zekâ (Claude) yardımıyla düzenlenmiştir. İçerik, projenin kodundan ve veritabanından derlenmiştir.

| | |
|---|---|
| **Ürün** | Turla: butik tur firmaları için tur satışı ve tur günü takibi |
| **Parçalar** | Mobil uygulama (Android/iOS), web yönetim paneli, Supabase sunucusu |
| **Durum** | MVP aşamasında. Faz 0–4 bitti, sırada Faz 5 (tur sohbeti, duyurular, bildirimler) var |
| **Dil** | Uygulamanın tamamı Türkçe |
| **Son güncelleme** | Kasım 2026 |

---

## İçindekiler

1. [Amaç ve kapsam](#1-amaç-ve-kapsam)
2. [Kotayı korumak için yaptıklarımız](#2-kotayı-korumak-için-yaptıklarımız)
3. [Sisteme genel bakış](#3-sisteme-genel-bakış)
4. [Roller ve yetkiler](#4-roller-ve-yetkiler)
5. [Temel iş akışları](#5-temel-iş-akışları)
6. [Kullanılan teknolojiler](#6-kullanılan-teknolojiler)
7. [Proje yapısı](#7-proje-yapısı)
8. [Mimari ve kod kuralları](#8-mimari-ve-kod-kuralları)
9. [Mobil uygulama](#9-mobil-uygulama)
10. [Web paneli](#10-web-paneli)
11. [Ortak paket (turla_core)](#11-ortak-paket-turla_core)
12. [Veritabanı](#12-veritabanı)
13. [Sunucudaki iş kuralı fonksiyonları](#13-sunucudaki-iş-kuralı-fonksiyonları)
14. [Güvenlik](#14-güvenlik)
15. [Dosya depolama](#15-dosya-depolama)
16. [Hesap açma fonksiyonu (create-account)](#16-hesap-açma-fonksiyonu-create-account)
17. [Hata kodları](#17-hata-kodları)
18. [Testler](#18-testler)
19. [Veritabanı değişiklik listesi (migration)](#19-veritabanı-değişiklik-listesi-migration)
20. [Alınan kararlar](#20-alınan-kararlar)
21. [Yol haritası ve eksikler](#21-yol-haritası-ve-eksikler)

---

## 1. Amaç ve kapsam

### 1.1 Hangi sorunu çözüyor?

Küçük tur firmaları satışlarını genelde telefonla, mesajlaşma uygulamalarıyla ve elle tutulan listelerle yapıyor. Bu yüzden:

- Kaç koltuğun dolduğu anlık bilinmiyor, aynı koltuk iki kişiye satılabiliyor.
- Kimin ödediği, kimin iptal ettiği ve kime para iade edileceği karışıyor.
- Tur günü otobüse kimin bindiği kâğıt listeyle kontrol ediliyor.
- Son dakika bilgisi yolculara tek tek mesajla gönderiliyor.

### 1.2 Turla ne yapıyor?

Bütün bu işleri tek sistemde topluyor:

- **Müşteri** turu telefonundan bulur, tarih seçer ve bilet alır. Bileti tek kullanımlık bir QR koddur.
- **Firma** turlarını, tarihlerini, koltuk sayısını ve çalışanlarını web panelinden yönetir.
- **Tur sorumlusu** tur günü yolcuların QR kodunu okutur, duyuru gönderir ve turu bitirir.
- Para ve koltukla ilgili bütün kararlar telefonda değil, sunucuda verilir.

### 1.3 MVP'de bilerek sade bırakılanlar

- Gerçek ödeme yok. Ödeme adımı **demo** olarak çalışır, karttan para çekilmez.
- Koltuk seçimi yok. Bilet tarih için satılır.
- Ekranlar işlevsel ama sade. Asıl tasarım ayrı bir aşamada yapılacak.

---

## 2. Kotayı korumak için yaptıklarımız

Proje Supabase'in **ücretsiz planında** çalışıyor. Ücretsiz planda veritabanı boyutu, dosya alanı ve aylık veri çıkışı sınırlı. Bu yüzden uygulama baştan "sunucuya gereksiz istek atmayacak" şekilde yazıldı.

### 2.1 Neyi nerede tutuyoruz?

| Ne | Nerede | Ne sıklıkla sunucuya gidilir |
|---|---|---|
| 81 il listesi | Telefonda, kalıcı | Sadece ilk açılışta bir kez |
| Seçilen şehir | Telefonda, kalıcı | Hiç (giriş yapılmışsa profile de yazılır) |
| Bir şehrin tur listesi | Telefonda, 20 dakika | 20 dakikada en fazla bir kez, ya da kullanıcı aşağı çekip yenilerse |
| Tur görselleri | Telefonun disk önbelleğinde | Her görsel bir kez; en fazla 100 görsel, 7 gün sonra silinir |
| Kullanıcının biletleri | Telefonda, kalıcı | Turlarım açılınca ve aşağı çekince |
| Bir bölgenin tüm turları ("Tümünü gör") | Aynı tur listesi önbelleği | Ek istek yok |
| Tur sorumlusunun tarihleri | Telefonda, son çekilen hali | Ana ekran açılınca ve aşağı çekince (tek istek) |
| Bir tarihin katılımcıları | Telefonda, son çekilen hali | Tarih ekranı açılınca ve aşağı çekince |
| Tur detayındaki boş koltuk | Tutulmaz | Her açılışta (güncel olması şart) |

### 2.2 Uygulanan kurallar

- **Arama telefonda yapılıyor.** Tur ya da şehir ararken her harfte sunucuya istek gitmez; zaten indirilmiş liste telefonda süzülür.
- **İşlemden sonra liste tekrar indirilmiyor.** Bilet iptal edilince bilet telefonda güncellenir. QR okutulunca ya da yolcu elle işaretlenince katılımcı listesi ve sayılar telefonda güncellenir. Panelde hesap açınca ya da bir kaydı düzenleyince liste baştan çekilmez, sadece değişen satır güncellenir.
- **İnternet yoksa uygulama çalışmaya devam ediyor.** Son kaydedilen tur listesi bir uyarıyla gösterilir. Bilet ve QR kod internetsiz açılır; tur günü otobüste internet olmasa da yolcu QR'ını gösterebilir.
- **Görseller küçültülerek yükleniyor.** Panelden yüklenen tur görselinin en uzun kenarı 1280 piksele indirilir ve sıkıştırılır. Bu hem dosya alanını hem de veri çıkışını korur.
- **Panelde sekmeler canlı tutuluyor.** Tur düzenleyicide sekme değiştirince veri tekrar indirilmez.
- **Veri biçimi değişirse önbellek kendini yeniliyor.** Her önbelleğin bir sürüm numarası var. Örneğin Karadeniz bölgesi ikiye ayrılınca tur önbelleğinin sürümü artırıldı ve telefonlardaki eski listeler kendiliğinden atıldı.

Örnek: 81 ilin tamamı sadece yaklaşık 2,4 KB tutuyor.

---

## 3. Sisteme genel bakış

```
┌──────────────────────┐        ┌──────────────────────┐
│   Mobil uygulama     │        │     Web paneli       │
│  (Flutter, Android)  │        │   (Flutter Web)      │
│                      │        │                      │
│ misafir · müşteri ·  │        │ firma yöneticisi ·   │
│ tur sorumlusu        │        │ sistem yöneticisi    │
└──────────┬───────────┘        └──────────┬───────────┘
           │        HTTPS ile Supabase'e    │
           ▼                               ▼
┌──────────────────────────────────────────────────────┐
│                      Supabase                        │
│                                                      │
│  Auth ── kullanıcılar ve oturumlar                   │
│  Veritabanı (PostgreSQL) ── tablolar ve kurallar     │
│  Fonksiyonlar ── bilet alma, iptal, QR okutma        │
│  Storage ── tur görselleri                           │
│  Edge Function ── hesap açma                         │
└──────────────────────────────────────────────────────┘
```

**Temel fikir:** Uygulamalar sadece veriyi gösterir ve isteği gönderir. "Bu bilet satılabilir mi?", "Bu iptal kabul edilir mi?", "Bu kişi bu veriyi görebilir mi?" gibi kararları veritabanı verir. Böylece uygulamada bir hata olsa ya da biri isteği değiştirmeye çalışsa bile kurallar atlanamaz.

---

## 4. Roller ve yetkiler

Kullanıcının rolü hesap açılırken sunucuda belirlenir; kullanıcı kendi rolünü değiştiremez (bkz. [14.3](#143-rol-nasıl-belirleniyor)).

| Rol | Veritabanındaki adı | Nerede kullanır | Neler yapabilir |
|---|---|---|---|
| Misafir | — (giriş yok) | Mobil | Şehir seçer, turları ve detaylarını görür. Bilet alamaz. |
| Müşteri | `customer` | Mobil | Bilet alır, biletlerini ve QR kodunu görür, iptal eder. QR'ı okutulunca tur sohbetine katılır. |
| Tur sorumlusu | `guide` | Mobil | Atandığı tarihin yolcularını görür, QR okutur, duyuru gönderir, turu bitirme talebi açar. |
| Firma yöneticisi | `admin` | Web | Kendi firmasının turlarını, tarihlerini, çalışanlarını ve biletlerini yönetir; turu bitirme taleplerini onaylar. |
| Sistem yöneticisi | `super_admin` | Web | Firma açar, kapatır ve her firmayı yönetebilir. |

**Ek kurallar:**

- Mobil uygulamaya sadece müşteri ve tur sorumlusu girebilir. Yönetici hesabıyla giriş yapılırsa oturum kapatılır ve nedeni gösterilir.
- Web paneline sadece firma yöneticisi ve sistem yöneticisi girebilir. Firması pasife alınmış yönetici panele giremez.
- Tur sorumlusu ve "dışarıdan eklenen müşteri" hesapları panelden açılır. Bu hesaplar e-posta yerine **giriş kimliği** ile girer (`REH-4821`, `MUS-1093` gibi).

---

## 5. Temel iş akışları

### 5.1 Müşteri tur bulur ve bilet alır

1. Uygulama ilk açılışta şehir seçtirir.
2. O şehirden kalkan turlar bölgelere göre listelenir.
3. Müşteri bir tura girer; program, kalkış tarihleri ve boş koltuklar görünür.
4. Bir tarih seçer. Dolu tarihler seçilemez.
5. Giriş yapmamışsa giriş ekranı açılır; giriş yapınca aynı tura geri döner.
6. Ödeme ekranında özet ve "Demo: gerçek tahsilat yapılmaz" notu görünür. Müşteri adını ve **telefonunu** yazar (profilde telefon varsa dolu gelir). Telefon bilete kopyalanır; tur günü tur sorumlusu gerekirse yolcuyu arar.
7. "Ödemeyi onayla"ya basınca sunucudaki `book_ticket` fonksiyonu çalışır.
8. Sunucu tek seferde şunları yapar: koltuğu bir azaltır, bileti ve QR kodu oluşturur, demo ödeme kaydını yazar. Profilde telefon yoksa yazılan telefonu oraya da kaydeder.
9. Başarı ekranında QR gösterilir. Bilet **Turlarım** sekmesine eklenir ve telefonda saklanır.

Kurallar: Müşteri her seferinde sadece kendine bir bilet alır. Aynı tarihe ikinci bilet alamaz.

### 5.2 Müşteri biletini iptal eder

1. Turlarım → bilet detayı → "Bileti iptal et".
2. Onay penceresinde iade edilecek tutar görünür.
3. Sunucudaki `cancel_ticket` fonksiyonu:
   - biletin bu kişiye ait olduğunu kontrol eder,
   - kalkışa **1 saatten az** kaldıysa iptali reddeder,
   - bileti iptal eder ve koltuğu geri ekler,
   - ödenen tutarın **tamamını** iade olarak kaydeder.
4. Bilet "Geçmiş" listesine geçer.

Firma yöneticisi panelden iptal ederse 1 saat kuralı uygulanmaz.

### 5.3 Tur günü QR okutma

1. Tur sorumlusu giriş kimliğiyle (`REH-xxxx`) girer. Ana ekranda kendisine atanmış tarihler görünür: önce **bugünküler**, sonra yaklaşanlar, sonra son günlerde tamamlananlar. Her kartta geldi / gelmedi / toplam sayıları vardır.
2. Bir tarihe girince katılımcı listesi açılır: yeşil "Geldi · 08:12", kırmızı "Gelmedi". Liste Tümü / Geldi / Gelmedi diye süzülür ve isimle aranır (arama telefonda yapılır, sunucuya istek atılmaz).
3. "QR okut" ile kamera açılır, yolcunun bilet QR kodu okutulur. Sunucudaki `scan_ticket` fonksiyonu:
   - okutan kişinin o tarihin sorumlusu (ya da firma yöneticisi) olduğunu kontrol eder,
   - biletin bu tarihe ait, ödenmiş ve daha önce okutulmamış olduğuna bakar,
   - bileti "tura katıldı" yapar, saatini ve "QR ile" bilgisini yazar.
4. Sonuç ekranında yolcunun adı ya da sorun görünür: daha önce okutuldu, başka bir tarihin bileti, bilet bulunamadı, iptal edilmiş, ödenmemiş. "Sıradaki yolcu" ile kameraya dönülür.
5. Kamera aynı kodu saniyede birkaç kez yakalar; aynı kod 3 saniye içinde tekrar gelirse ve sonuç ekrandayken yeni kod gelirse yok sayılır.
6. Kamera izni verilmezse ya da kamera bozuksa açıklama çıkar; **"Kodu elle gir"** ile biletteki kod yazılabilir.
7. Yolcunun telefonu kapalı ya da kırıksa tur sorumlusu listede isme dokunur ve onaylayarak **elle "Geldi"** işaretler (`check_in_manually`). Kayıtta "elle" olarak görünür.
8. Telefonu olan yolcu listeden aranabilir; şoför de tarih ekranından aranabilir.
9. Müşterinin biletinde QR yerine **"QR kodun okutuldu · saat"** görünür, durum "Tura katıldı" olur (Turlarım açılınca ya da aşağı çekince güncellenir).

Bir QR kod sadece bir kez kullanılabilir. **Okutma internet ister:** bağlantı yoksa "İnternet bağlantısı yok" uyarısı çıkar; liste son kaydedilen haliyle görünmeye devam eder.

### 5.4 Turu bitirme

1. Tur sorumlusu kalkış saati geçtikten sonra tarih ekranında "Turu bitir" der ve onaylar (`request_departure_completion`). Düğme kalkış saatinden önce görünmez; sunucu da reddeder.
2. O tarih "bitiş onayı bekliyor" durumuna geçer. Tur sorumlusunun ekranında "Firma onayı bekleniyor" bandı çıkar; bu sırada okutma ve elle işaretleme kapanır.
3. Firma yöneticisi panelden talebi onaylar ya da reddeder:
   - **Onaylarsa** sadece o tarih kapanır. QR'ı okutulanlar "tamamlandı", okutulmayanlar "gelmedi" olarak işaretlenir.
   - **Reddederse** tarih tekrar aktif olur; tur sorumlusunun ekranında "Firma talebi reddetti" bandı görünür.
4. Aynı turun diğer tarihleri bundan etkilenmez.

### 5.5 Panelden firma ve hesap açma

- Sistem yöneticisi firma oluşturur ve firmaya bir yönetici hesabı açar (e-posta ve geçici şifre ile).
- Firma yöneticisi tur sorumlusu (`REH-xxxx`) ve dışarıdan müşteri (`MUS-xxxx`) hesapları açar.
- Geçici şifreyi yönetici hesap sahibine kendisi iletir. Şifre panelde bir daha gösterilmez.
- Tur sorumlusu ya da `MUS-` müşterisi şifresini unutursa yönetici "Personel ve müşteriler" sayfasında **"Şifre sıfırla"** der. Sunucu 10 karakterlik yeni bir geçici şifre üretir (karışan 0/O, 1/l/I harfleri yok) ve panel bunu bir kez gösterir; eski şifre hemen geçersiz olur.

### 5.6 Telefonla ya da ofisten satılan bilet

1. Firma yöneticisi müşteri için bir `MUS-xxxx` hesabı açar.
2. İlgili tarihin katılımcılar penceresinde "Bilet kes" ile müşteriyi seçer.
3. Sunucudaki `admin_issue_ticket` fonksiyonu bileti "panelden kesildi, ödeme elden alındı" olarak kaydeder. Müşterinin profilindeki telefon bilete kopyalanır.
4. Müşteri giriş kimliğiyle mobil uygulamaya girip biletini ve QR kodunu görür.

---

## 6. Kullanılan teknolojiler

| Alan | Ne kullanıldı | Neden |
|---|---|---|
| Mobil uygulama | Flutter 3.44, Dart 3.12 | Tek kodla Android ve iOS |
| Web paneli | Flutter Web | Mobille aynı dil, ortak kod paylaşımı |
| Ekran durumu yönetimi | flutter_bloc (Bloc/Cubit) | Ekranın ne göstereceği tek yerde, kolay test |
| Bağımlılık yönetimi | get_it | Sınıflara ihtiyaç duydukları nesneler dışarıdan verilir; testte sahte nesne kullanılabilir |
| Sayfa geçişleri | go_router | Rotalar ve yönlendirme kuralları tek yerde |
| Sunucu | Supabase (PostgreSQL 17) | İlişkili veri, satır bazlı yetki, giriş ve dosya depolama tek yerde |
| Telefonda veri saklama | shared_preferences | Küçük listeleri saklamak için yeterli |
| Görsel önbelleği | cached_network_image, flutter_cache_manager | Sınırlı sayıda ve süreli görsel saklama |
| QR kod | qr_flutter | Biletin QR kodu telefonda çizilir |
| Tarih ve para biçimi | intl (Türkçe) | "13 Aralık 2026", "₺1.850" gibi biçimler |
| Test | flutter_test, bloc_test, mocktail, PGlite | Birim, ekran ve veritabanı testleri |
| Bildirim | Firebase Cloud Messaging *(planlandı)* | Ücretsiz; Supabase'de hazır bildirim servisi yok |

---

## 7. Proje yapısı

Proje tek depoda üç parçadan oluşur: iki uygulama ve ikisinin de kullandığı bir ortak paket. Bağımlılıklar kök klasörde tek komutla (`flutter pub get`) kurulur.

```
turla_app/
├── apps/
│   ├── mobile/          Mobil uygulama (uygulama kimliği: com.turla.app)
│   └── web/             Web paneli
├── packages/
│   └── core/            Ortak paket: renkler, ölçüler, tema, ortak tipler, giriş, iller
├── supabase/
│   ├── migrations/      Veritabanı yapısı ve kuralları (sırayla çalışan SQL dosyaları)
│   ├── functions/
│   │   └── create-account/   Hesap açan sunucu fonksiyonu
│   ├── seed/demo.sql    Demo firma ve turlar
│   ├── tests/           Veritabanı ve sunucu fonksiyonu testleri
│   └── config.toml      Sunucu fonksiyonu ayarı
├── docs/                Bu doküman
└── .env.example         Ayar dosyası örneği (gerçek anahtarlar git'e eklenmez)
```

`packages/core` klasörüne sadece **iki uygulamanın da** ihtiyaç duyduğu şeyler konur. Sadece bir uygulamayı ilgilendiren ekran, metin ve kod o uygulamanın içinde kalır. Böylece örneğin bilet durumlarına yeni bir değer eklenince mobil ve web aynı anda güncellenmiş olur.

---

## 8. Mimari ve kod kuralları

### 8.1 Katmanlar

Her özellik üç katmana ayrılır:

```
presentation (ekranlar)  ──►  domain (iş tanımları)  ◄──  data (veri erişimi)
```

| Katman | İçinde ne var | Neye bağlı |
|---|---|---|
| **domain** | Varlıklar (ör. Tur, Bilet), veri erişim arayüzleri, hata türleri | Hiçbir şeye. Flutter'ı da Supabase'i de bilmez. |
| **data** | Veritabanı satırını nesneye çeviren modeller; sunucudan ve telefondan veri okuyan sınıflar | domain |
| **presentation** | Cubit/Bloc ve durumları, ekranlar, widget'lar | domain (somut sınıfları bağımlılık yönetimi verir) |

Bunun faydası: Ekran kodu veritabanını hiç bilmez. Sunucu değişse ya da test için sahte veri vermek gerekse ekran kodu değişmez.

### 8.2 Klasör düzeni

```
lib/
  app/          uygulamanın kökü, sayfa yönlendirmeleri, alt menü iskeleti
  core/         sabit metinler, bağımlılık kaydı, hata yardımcıları, ortak küçük widget'lar
  features/<özellik>/
    domain/       varlıklar, arayüzler, hata türleri
    data/         modeller, veri kaynakları, arayüzlerin uygulaması
    presentation/ cubit, ekranlar, widget'lar, ekran metni üreten yardımcılar
```

### 8.3 Kurallar

- **Ekranda iş mantığı yok.** Ekran sadece durumu çizer ve Cubit'teki metodu çağırır. Metin birleştirme ayrı yardımcı dosyalarda, süzme ve gruplama durum sınıfının içinde yapılır.
- **Gereksiz ara sınıf yok.** Tek satırdan ibaret "use case" sınıfları yazılmaz; Cubit doğrudan veri erişim arayüzünü çağırır.
- **İş kuralı sunucuda.** Uygulamadaki kontroller sadece kullanıcıya hızlı uyarı vermek içindir; asıl karar sunucuda verilir.
- **Sabit değerler ayrı dosyalarda.** Widget'ın içine sayı, renk ya da metin yazılmaz:
  - ölçüler: `AppSpacing`, `AppPaddings`, `AppRadius`, `AppSizes`, `AppDurations`, `AppFontSizes`
  - renkler: `AppColors`
  - metinler: `CoreStrings` (ortak), `AppStrings` (uygulamaya özel)
- **Gizli bilgi koda yazılmaz.** Supabase adresi ve anahtarı `.env` dosyasından okunur ve git'e eklenmez.
- **Büyük widget'lar ayrı dosyada** tutulur.

### 8.4 Hatalar nasıl kullanıcıya ulaşıyor?

```
veri kaynağı           veri erişim sınıfı             cubit              ekran
hatayı yakalar   ──►   hata türüne çevirir      ──►   duruma yazar  ──►  Türkçe mesaj gösterir
```

- İnternet hataları "bağlantı yok" türüne çevrilir.
- Sunucu bir kuralı reddederse (ör. koltuk kalmadı) sabit bir hata kodu döner. Bu kod ilgili hata türüne, oradan da Türkçe mesaja çevrilir.
- Yeni bir hata kodu eklendiğinde: hata türüne eklenir, mesajı yazılır ve testi yazılır.

### 8.5 Bağımlılık yönetimi

Hangi sınıfa hangi nesnenin verileceği tek bir dosyada (`core/di/injection.dart`) belirlenir:

| Ne | Kaç tane | Neden |
|---|---|---|
| Veri erişim sınıfları | Uygulama boyunca tek | Herkes aynı önbelleği kullanır |
| Oturum ve seçili şehir | Uygulama boyunca tek | Bütün ekranlar aynı durumu görür |
| Ekran Cubit'leri | Her ekran açılışında yeni | Ekran her açıldığında temiz başlar |

Testlerde gerçek sunucu yerine sahte veri kaynakları verilir. Böylece "internet yoksa ne olur?" gibi durumlar interneti kesmeden test edilebilir.

### 8.6 Sayfa yönlendirme

- Hangi sayfanın açılabileceğine tek bir fonksiyon karar verir ve bu fonksiyonun ayrıca testi vardır.
- Mobilde: oturum ve şehir yüklenene kadar açılış ekranı görünür; tur sorumlusu sadece kendi ekranlarını (`/guide` ile başlayanlar) görür, müşteri bu ekranlara giremez; giriş yapmış kullanıcı giriş ekranına dönmez; şehir seçilmemişse önce şehir seçimi açılır.
- Başka bir sayfanın üstüne açılan ekranlar (örneğin giriş) işi bitince kendini kapatır.
- Web panelinde sayfa yenilenince kullanıcı aynı sayfada kalır.

---

## 9. Mobil uygulama

### 9.1 Özellikler

| Özellik | Ne yapıyor |
|---|---|
| `auth` | Giriş (e-posta veya giriş kimliği), kayıt, oturum ve rol kontrolü |
| `city_choice` | Şehir seçimi ve seçilen şehrin saklanması |
| `tours` | Bölgelere göre tur listesi (her bölge yan yana kayar, "Tümünü gör"), arama, tur detayı, tarih seçimi |
| `tickets` | Satın alma (ad + telefon), Turlarım, bilet detayı, iptal, "QR kodun okutuldu" |
| `profile` | Misafir ve giriş yapmış kullanıcı profili, şehir değiştirme, çıkış |
| `guide` | Tur sorumlusu: atanmış tarihler, katılımcılar, QR okutma, elle "Geldi", turu bitir |

### 9.2 Ekranlar

| Adres | Ekran | Not |
|---|---|---|
| `/` | Açılış | Oturum ve şehir yüklenirken görünür |
| `/city` | Şehir seçimi | İlk açılışta zorunlu |
| `/login`, `/register` | Giriş, kayıt | İş bitince kendini kapatır |
| `/tours` | Tur listesi | Alt menü: Turlar |
| `/tours/region/:region` | Bir bölgenin tüm turları | "Tümünü gör"; turlar aynı önbellekten gelir |
| `/tours/:tourId` | Tur detayı | Tarih seçimi burada |
| `/checkout` | Demo ödeme | Alt menüsüz, tam ekran |
| `/my-tickets` | Turlarım | Alt menü: Turlarım (giriş gerekli) |
| `/my-tickets/:ticketId` | Bilet detayı ve QR | İnternetsiz açılır |
| `/profile` | Profil | Alt menü: Profil |
| `/guide` | Tur sorumlusu ana ekranı | Bugün / yaklaşan / tamamlanan tarihler |
| `/guide/departures/:departureId` | Katılımcılar | Geldi/gelmedi, süzgeç, arama, elle "Geldi", "QR okut", "Turu bitir" |
| `/guide/departures/:departureId/scan` | QR okutma | Kamera, sonuç ekranı, "Kodu elle gir" |

### 9.3 Giriş kimliği nasıl çalışıyor?

Panelden açılan hesaplar e-posta yerine bir kimlikle girer. Supabase'in giriş sistemi e-posta istediği için kimlik arka planda sabit bir alan adıyla e-postaya çevrilir:

```
REH-4821  →  reh-4821@staff.turla.app
```

Bu adreslere hiçbir zaman e-posta gönderilmez. Şifre unutulursa firma yöneticisi panelden sıfırlar. Giriş ekranında tek bir alan vardır ("E-posta veya giriş kimliği"). Yazılan değerde `@` yoksa kimlik olarak kabul edilir. Büyük-küçük harf ve boşluk farkı önemsizdir.

### 9.4 Tur sorumlusu ekranları ve veriler

- **Ana ekran tek istekle gelir:** `guide_departures` fonksiyonu tarihleri, tur adını, araç ve şoförü, bilet ve gelen sayılarını ve son bitirme talebinin durumunu birlikte döndürür.
- **Telefonda saklanan:** tarih listesi ve her tarihin katılımcı listesi son çekilen haliyle saklanır. İnternet yokken liste görünür, üstte uyarı çıkar.
- **Okutma sonrası yeniden istek yok:** okutulan ya da elle işaretlenen yolcu telefondaki listede yeşile döner, sayılar güncellenir; liste sunucudan tekrar çekilmez.
- **Sunucuya gidilen anlar:** ekran açılınca, aşağı çekince, okutma, elle işaretleme ve turu bitir.
- **Kamera:** `mobile_scanner` paketi, sadece QR biçimi. Android'de kamera izni istenir; kamerası olmayan cihaza da kurulabilir.

---

## 10. Web paneli

### 10.1 Özellikler

| Özellik | Ne yapıyor |
|---|---|
| `auth` | Panel girişi; rol ve pasif firma kontrolü |
| `companies` | Firma listesi, ekleme/düzenleme, aktif/pasif, firma yöneticisi hesabı (sistem yöneticisi) |
| `tours` | Tur listesi ve düzenleyici: Bilgiler, Program, Tarihler sekmeleri ve kapak görseli |
| `staff` | Tur sorumlusu ve dışarıdan müşteri hesapları, aktif/pasif, şifre sıfırlama |
| `tickets` | Bir tarihin katılımcıları (telefon, "tura katıldı (elle)"), yönetici iptali, "Bilet kes" |
| `completions` | Turu bitirme talepleri: onay ve ret |

### 10.2 Sayfalar

| Adres | Kim girer | Sayfa |
|---|---|---|
| `/login` | Herkes | Panel girişi |
| `/companies` | Sistem yöneticisi | Firma listesi |
| `/companies/:companyId` | Sistem yöneticisi | Firma detayı ve yöneticileri |
| `/c/:companyId/tours` | Firma alanı | Turlar |
| `/c/:companyId/tours/new` | Firma alanı | Yeni tur |
| `/c/:companyId/tours/:tourId` | Firma alanı | Tur düzenleyici |
| `/c/:companyId/staff` | Firma alanı | Personel ve müşteriler |
| `/c/:companyId/completions` | Firma alanı | Turu bitirme talepleri |

Firma yöneticisi sadece kendi firmasının sayfalarına girebilir. Sistem yöneticisi her firmanın sayfasına girebilir.

### 10.3 Çalışma şekli

- Bir işlem bitince ekran ya pencereyi kapatır ya da mesaj gösterir.
- Kayıt ekleyince ya da düzenleyince liste baştan indirilmez, sadece ilgili satır güncellenir.
- Kapak görseli yüklenmeden önce tarayıcıda küçültülür.

---

## 11. Ortak paket (turla_core)

| Klasör | İçinde ne var |
|---|---|
| `constants/` | Renkler, boşluklar, köşe yuvarlaklıkları, süreler, boyutlar, yazı boyutları, ortak metinler, telefonda saklama anahtarları |
| `enums/` | Veritabanıyla birebir aynı tipler: roller, bölgeler, bilet durumları, tarih durumları |
| `config/env.dart` | `.env` dosyasından okunan Supabase adresi ve anahtarı |
| `supabase/` | Supabase bağlantısının başlatılması |
| `theme/` | Ortak tema |
| `features/auth` | Oturum, profil ve giriş kimliği dönüşümü |
| `features/cities` | 81 il ve telefondaki kalıcı kopyası |

`.env` dosyası yoksa uygulama çökmez; eksik ayarı anlatan bir ekran gösterir.

---

## 12. Veritabanı

### 12.1 Sabit değer listeleri (enum)

| Liste | Değerler |
|---|---|
| Roller (`user_role`) | `super_admin`, `admin`, `guide`, `customer` |
| Bölgeler (`tour_region`) | `akdeniz`, `bati_karadeniz`, `dogu_karadeniz`, `marmara`, `ege`, `ic_anadolu`, `dogu_anadolu`, `guneydogu_anadolu`, `gunubirlik`, `yurtdisi` |
| Tarih durumu (`departure_status`) | `scheduled` (planlandı), `finish_requested` (bitiş onayı bekliyor), `completed` (tamamlandı), `cancelled` (iptal) |
| Bilet durumu (`ticket_status`) | `reserved`, `paid` (ödendi), `checked_in` (tura katıldı), `cancelled` (iptal), `completed` (tamamlandı), `no_show` (gelmedi) |
| Bilet kaynağı (`ticket_source`) | `app` (uygulamadan), `panel` (panelden) |
| Katılım yöntemi (`check_in_method`) | `qr` (QR okutuldu), `manual` (tur sorumlusu elle işaretledi) |
| Ödeme türü (`payment_type`) | `payment` (ödeme), `refund` (iade) |
| Ödeme yöntemi (`payment_method`) | `demo`, `manual` (elden/havale) |
| Bitirme talebi (`completion_status`) | `pending`, `approved`, `rejected` |
| Geri bildirim (`feedback_status`) | `open`, `in_progress`, `resolved` |

### 12.2 Tablolar

**Turlar ve firmalar**

| Tablo | Ne tutuyor | Önemli alanlar |
|---|---|---|
| `cities` | 81 il (numarası plaka kodu) | `id`, `name` |
| `companies` | Tur firmaları | `name`, `city_id`, `phone`, `logo_url`, `is_active` |
| `tours` | Turun kendisi | `company_id`, `title`, `description`, `extra_detail`, `price`, `city_id` (kalkış ili), `region`, `image_url`, `is_active` |
| `tour_program_days` | Gün gün program | `tour_id`, `day_no`, `title`, `activities` (liste), `sort_order` |
| `tour_departures` | Turun bir tarihi | `tour_id`, `departure_at`, `capacity`, `seats_left`, `guide_id`, `bus_plate`, `driver_name`, `driver_phone`, `status` |

**Kullanıcılar**

| Tablo | Ne tutuyor | Önemli alanlar |
|---|---|---|
| `profiles` | Her kullanıcının profili | `role`, `company_id`, `full_name`, `phone`, `login_id`, `selected_city_id`, `is_active` |

**Satış**

| Tablo | Ne tutuyor | Önemli alanlar |
|---|---|---|
| `tickets` | Biletler | `departure_id`, `user_id`, `passenger_name`, `passenger_phone`, `price_paid`, `status`, `source`, `qr_token`, `scanned_at`, `check_in_method`, `cancelled_at` |
| `payments` | Ödeme ve iade kayıtları | `ticket_id`, `type`, `method`, `amount` |

**İletişim ve işleyiş**

| Tablo | Ne tutuyor |
|---|---|
| `messages` | Tur sohbeti mesajları |
| `announcements` | Tur sorumlusunun duyuruları |
| `notifications` | Her kullanıcının bildirim kutusu |
| `device_tokens` | Bildirim göndermek için cihaz bilgileri |
| `completion_requests` | Turu bitirme talepleri |
| `feedbacks` | Firmaların geri bildirimleri |

### 12.3 Tur ve tarih neden ayrı tablolarda?

Bir tur (örneğin "Kapadokya Turu") birçok tarihte yapılır. Koltuk sayısı, tur sorumlusu, otobüs ve durum **tarihe** aittir, turun kendisine değil. Bu sayede:

- Turu bitirmek sadece o tarihi kapatır.
- Her tarihin kendi koltuk sayısı olur.
- İleride koltuk seçimi gelirse sadece tarihlerin altına bir koltuk tablosu eklemek yeterli olur.

### 12.4 Verinin bozulmasını engelleyen kurallar

- Boş koltuk sayısı eksiye düşemez ve toplam koltuğu geçemez.
- Bir bilete en fazla bir ödeme ve bir iade kaydı yazılabilir.
- Bir tarih için aynı anda tek bekleyen bitirme talebi olabilir.
- Yönetici ve tur sorumlusu mutlaka bir firmaya bağlıdır.
- Bileti olan tarih ve tur silinemez.

### 12.5 Otomatik çalışan işlemler (tetikleyiciler)

| Tetikleyici | Ne yapıyor |
|---|---|
| `handle_new_user` | Yeni kullanıcı için profil oluşturur; rolü ve firmayı sunucunun yazdığı alandan alır |
| `handle_user_app_metadata_update` | Sunucu kullanıcının rolünü sonradan yazarsa profili de günceller |
| `departures_before_write` | Yeni tarihte boş koltuğu kontenjana eşitler; kontenjan değişince boş koltuğu da aynı farkla değiştirir; atanan tur sorumlusunun aynı firmada aktif olduğunu kontrol eder |
| `messages_before_insert` | Mesajı gönderenin adını profilden yazar; kimse başkası adına mesaj atamaz |
| `announcements_fanout` | Duyuruyu sadece QR'ı okutulmuş yolcuların bildirim kutusuna dağıtır |
| `tickets_copy_customer_phone` | Bilete telefon yazılmadıysa (panelden kesilen bilet) müşterinin profil telefonunu kopyalar; profildeki telefon bozuksa bilet yine kesilir |
| `set_updated_at` | Kaydın güncellenme zamanını yazar |

---

## 13. Sunucudaki iş kuralı fonksiyonları

Bu fonksiyonlar uygulamadan çağrılır ve veritabanında **tek seferde** çalışır: ya hepsi olur ya hiçbiri olmaz. Yetki kontrolünü de kendi içlerinde yaparlar.

| Fonksiyon | Kim çağırır | Ne yapar | Döndürebileceği hatalar |
|---|---|---|---|
| `book_ticket` | Müşteri | Koltuğu azaltır, bileti ve QR kodu oluşturur, demo ödemeyi yazar, telefonu bilete (profil boşsa profile de) yazar | `only_customers_can_book`, `invalid_phone`, `departure_not_found`, `tour_not_available`, `departure_not_bookable`, `no_seats_left`, `already_has_ticket` |
| `cancel_ticket` | Bilet sahibi, firma yöneticisi | Bileti iptal eder, koltuğu geri ekler, tam iade yazar | `ticket_not_found`, `not_allowed`, `ticket_not_cancellable`, `cancellation_window_closed` |
| `scan_ticket` | O tarihin tur sorumlusu, firma yöneticisi | Bileti "tura katıldı" yapar (yöntem: QR), yolcu adı ve saatle sonucu döner | `departure_not_found`, `not_allowed`, `departure_not_active`; sonuç: `ok`, `not_found`, `wrong_departure`, `already_used`, `cancelled`, `not_paid` |
| `check_in_manually` | O tarihin tur sorumlusu, firma yöneticisi | Yolcuyu elle "tura katıldı" yapar (yöntem: elle); sonucu `scan_ticket` ile aynı biçimde döner | `ticket_not_found`, `not_allowed`, `departure_not_active`; sonuç: `ok`, `already_used`, `cancelled`, `not_paid` |
| `guide_departures` | Tur sorumlusu | Atandığı açık tarihleri ve son 2 günde tamamlananları sayılarla döndürür (başkası için boş liste) | — |
| `request_departure_completion` | Tur sorumlusu | Tarihi "bitiş onayı bekliyor" yapar, talep açar | `not_allowed`, `departure_not_active`, `departure_not_started` |
| `review_departure_completion` | Firma yöneticisi | Onay: tarihi kapatır, biletleri "tamamlandı"/"gelmedi" yapar. Ret: tarihi tekrar açar | `request_not_found`, `not_allowed`, `request_already_reviewed` |
| `admin_issue_ticket` | Firma yöneticisi | Panelden açılmış müşteriye bilet keser, ödemeyi "elden" yazar | `not_allowed`, `departure_not_found`, `tour_not_available`, `departure_not_bookable`, `invalid_customer`, `no_seats_left`, `already_has_ticket` |
| `set_profile_active` | Firma yöneticisi, sistem yöneticisi | Hesabı aktif ya da pasif yapar | `not_allowed`, `profile_not_found`, `cannot_change_self` |
| `save_tour_program` | Firma yöneticisi | Gün gün programı tek seferde kaydeder | `invalid_program` |

**Aynı anda iki kişi son koltuğu alırsa ne olur?** `book_ticket` satış yapmadan önce o tarihin satırını kilitler. İkinci kişi bekletilir; sıra ona gelince koltuk kalmadığı için `no_seats_left` hatası alır. Aynı koltuk iki kişiye satılamaz.

**QR kod nasıl üretiliyor?** Sunucuda rastgele 24 bayttan oluşturulur (48 karakter). Tahmin edilemez ve her bilette farklıdır.

---

## 14. Güvenlik

### 14.1 Satır bazlı yetki (RLS)

Veritabanında her tablo için "bu satırı kim görebilir, kim değiştirebilir?" kuralları yazılı. Uygulamada bir hata olsa bile bu kurallar atlanamaz.

| Tablo | Kim görebilir | Kim değiştirebilir |
|---|---|---|
| `cities` | Herkes | Sistem yöneticisi |
| `companies` | Aktif firmaları herkes; ayrıca kendi firması ve biletinin firması | Sistem yöneticisi |
| `tours`, `tour_program_days`, `tour_departures` | Aktif firmanın satıştaki turlarını herkes; firma kendi turlarını; bilet sahibi biletinin turunu; tur sorumlusu atandığı tarihi | Firma yöneticisi (sadece kendi firması) |
| `profiles` | Kendisi; firma yöneticisi kendi firmasındaki hesapları; sistem yöneticisi herkesi | Kişi sadece adını, telefonunu ve seçili şehrini değiştirebilir; rolünü ve firmasını değiştiremez |
| `tickets` | Bilet sahibi, firma yöneticisi, o tarihin tur sorumlusu (yolcu adı ve telefonu dahil) | **Uygulama doğrudan yazamaz**, sadece fonksiyonlar yazar |
| `payments` | Firma yöneticisi, biletin sahibi | **Uygulama doğrudan yazamaz** |
| `messages` | QR'ı okutulmuş yolcu, tur sorumlusu, firma yöneticisi | Aynı kişiler, sadece aktif tarihte |
| `announcements` | Aynı kişiler | Tur sorumlusu, firma yöneticisi |
| `notifications`, `device_tokens` | Sadece sahibi | Sadece sahibi |
| `completion_requests` | Talebi açan sorumlu, firma yöneticisi | **Uygulama doğrudan yazamaz** |

### 14.2 Tablo yetkileri

Yeni Supabase projelerinde tablolara erişim varsayılan olarak kapalı geliyor. Bu yüzden:

- Her tabloya, kurallarının yanında açıkça erişim izni de verildi.
- Giriş yapmamış kullanıcı sadece tur, tarih, il ve firma bilgilerini okuyabilir.
- Bazı tablolarda sadece belirli alanlar değiştirilebilir. Örneğin firma bir tarihin boş koltuk sayısını ya da durumunu elle değiştiremez; bunları sadece fonksiyonlar değiştirir.
- Tabloyu tamamen boşaltma yetkisi uygulamalardan kaldırıldı.
- Hesap açan sunucu fonksiyonuna sadece ihtiyacı kadar yetki verildi.

### 14.3 Rol nasıl belirleniyor?

- Rol, firma ve giriş kimliği kullanıcı kaydının **sadece sunucunun yazabildiği** bir alanında tutulur.
- Kayıt olurken biri kendi bilgisine "rol: sistem yöneticisi" yazsa bile hesabı **müşteri** olarak açılır. Bu durum testle doğrulandı.
- Mobil uygulamadan kayıt olan herkes müşteri olur.

### 14.4 Diğer önlemler

- **Pasif firma:** Firma pasife alınınca yöneticisinin yetkileri sunucuda kapanır; panel girişinde de reddedilir.
- **Anahtarlar:** Uygulamalarda sadece herkese açık olması için tasarlanmış, tek başına yetki vermeyen anahtar (publishable key) bulunur. Her şeye erişen gizli anahtar sadece sunucu fonksiyonunun içinde kullanılır.
- **Hız:** Yetki kuralları her satır için değil her sorgu için bir kez hesaplanacak şekilde yazıldı; ilişkili alanların hepsinde indeks var.

---

## 15. Dosya depolama

| Ayar | Değer |
|---|---|
| Klasör | `tour-images` (herkes görüntüleyebilir) |
| En büyük dosya | 2 MB |
| İzin verilen türler | JPEG, PNG, WebP |
| Dosya yolu | `<firma_kimliği>/<dosya_adı>` |
| Kim yükleyebilir | Sadece o firmanın yöneticisi ve sistem yöneticisi |

Görseller yüklenmeden önce küçültülür (en uzun kenar 1280 piksel, kalite %80).

---

## 16. Hesap açma fonksiyonu (create-account)

Web panelinden firma yöneticisi, tur sorumlusu ve dışarıdan müşteri hesabı açmak için kullanılan sunucu fonksiyonudur. Bu iş için her şeye erişebilen gizli anahtar gerekir; bu anahtar uygulamalara hiç verilmediği için hesap açma işlemi sunucuda yapılır.

**Kurallar:**

- İsteği gönderenin kim olduğu fonksiyonun içinde doğrulanır. Pasif hesaplar işlem yapamaz.
- Sistem yöneticisi her firmaya her türlü hesap açabilir.
- Firma yöneticisi sadece **kendi firmasına**, sadece tur sorumlusu ve müşteri açabilir. Başka bir yönetici açamaz.
- Ad en az 3, şifre en az 8 karakter olmalı. Telefon en fazla 20 karakter olabilir.
- Yönetici hesabı e-postayla açılır. Tur sorumlusu ve müşteri için kimlik üretilir: `REH-` ya da `MUS-` ve 4 rakam. Aynı kimlik varsa yenisi denenir.
- Hesaplar onaylanmış olarak açılır, e-posta gönderilmez.

**Şifre sıfırlama** (`{ action: 'reset_password', user_id }`):

- Sadece giriş kimlikli hesaplar (`REH-`, `MUS-`) sıfırlanır. E-postayla kayıt olan uygulama müşterisi ve firma yöneticisi bu yoldan sıfırlanamaz (`not_resettable`).
- Firma yöneticisi sadece kendi firmasının hesaplarını, sistem yöneticisi her firmanınkini sıfırlar. Pasif firmanın yöneticisi sıfırlayamaz.
- Yeni şifre sunucuda güvenli rastgele sayıyla üretilir ve yanıtta bir kez döner.

**Başarılı olursa:** Kullanıcı kimliği, giriş e-postası ve giriş kimliği döner.
**Hata olursa:** `not_allowed`, `invalid_role`, `company_required`, `invalid_full_name`, `weak_password`, `invalid_phone`, `invalid_email`, `not_resettable`, `account_not_found` gibi bir kod döner.

Bu kurallar ayrı bir dosyada (`rules.ts`) tutulur ve ayrıca test edilir.

---

## 17. Hata kodları

| Kod | Ne oldu | Kullanıcı ne görür |
|---|---|---|
| `only_customers_can_book` | Bilet almaya çalışan müşteri değil | Bu hesapla bilet alınamaz |
| `departure_not_found` | Tarih yok | Tarih bulunamadı |
| `tour_not_available` | Tur satıştan kalkmış ya da firma pasif | Tur artık satışta değil |
| `departure_not_bookable` | Tarih geçmiş ya da aktif değil | Bu tarih artık satışta değil |
| `no_seats_left` | Koltuk kalmadı | Kontenjan doldu |
| `already_has_ticket` | Bu tarih için zaten bilet var | Bu tarih için zaten biletin var |
| `ticket_not_found` | Bilet yok | Bilet bulunamadı |
| `ticket_not_cancellable` | Bilet iptal edilebilecek durumda değil | Bu bilet iptal edilemez |
| `cancellation_window_closed` | Kalkışa 1 saatten az kaldı | İptal süresi geçti |
| `not_allowed` | Yetki yok | Bu işlem için yetkiniz yok |
| `departure_not_active` | Tarih aktif değil | Bu tarih aktif değil |
| `departure_not_started` | Kalkış saati gelmedi | Tur henüz başlamadı |
| `request_already_reviewed` | Talep zaten sonuçlandırılmış | Bu talep zaten sonuçlandırılmış |
| `invalid_customer` | Seçilen müşteri bu firmanın müşterisi değil | Seçilen müşteri geçersiz |
| `capacity_below_sold_seats` | Kontenjan satılan biletin altına indirilmek istendi | Kontenjan satılan bilet sayısının altına düşürülemez |
| `invalid_guide` | Atanan tur sorumlusu bu firmada aktif değil | Seçilen tur sorumlusu bu firmada aktif değil |
| `cannot_change_self` | Yönetici kendi hesabını pasife almak istedi | Kendi hesabınızın durumunu değiştiremezsiniz |
| `profile_not_found` | Hesap yok | Kayıt bulunamadı |
| `invalid_program` | Program bilgisi hatalı | Girilen bilgiler geçersiz |
| `invalid_phone` | Telefon biçimi hatalı | Telefon numarası geçersiz |
| `not_resettable` | Şifresi panelden sıfırlanamayan hesap | Bu hesabın şifresi panelden sıfırlanamaz |
| `account_not_found` | Şifresi sıfırlanacak hesap yok | Kayıt bulunamadı |
| `ok` *(QR)* | Okutma başarılı | Hoş geldin! + yolcunun adı |
| `already_used` *(QR)* | Bilet daha önce okutuldu | Daha önce okutuldu (ilk okutma saati) |
| `wrong_departure` *(QR)* | Bilet başka bir tarihe ait | Başka bir tarihin bileti |
| `not_found` *(QR)* | Bu kodla bilet yok | Bilet bulunamadı |
| `cancelled` *(QR)* | Bilet iptal edilmiş | İptal edilmiş bilet |
| `not_paid` *(QR)* | Bilet ödenmemiş | Ödenmemiş bilet |

---

## 18. Testler

| Bölüm | Neyi test ediyor | Test sayısı |
|---|---|---|
| Ortak paket | İl listesinin saklanması, giriş kimliği | 13 |
| Mobil uygulama | Yönlendirme kuralları, oturum, giriş, şehir seçimi, tur listesi (yatay bölge satırı, bölge ekranı) ve önbelleği, biletler, satın alma (telefon), iptal, tur sorumlusu (tarihler, katılımcılar, QR okutma, elle Geldi, turu bitir), ekran akışları | 102 |
| Web paneli | Panel girişi, sayfa yenileme, firmalar, turlar, personel ve şifre sıfırlama, biletler (telefon, elle işareti), hata mesajları | 64 |
| Veritabanı | Tablolar, yetki kuralları, bilet alma, telefon, kontenjan, iptal süresi, iade, QR, elle Geldi, tur sorumlusunun tarih listesi, turu bitirme, dosya yetkileri | 106 |
| Hesap açma fonksiyonu | `rules.ts` içindeki kurallar (hesap açma ve şifre sıfırlama) | 29 |

**Veritabanı testleri nasıl çalışıyor?** Testler gerçek Supabase'e bağlanmaz. Bilgisayarda küçük bir PostgreSQL (PGlite) açılır, Supabase'in giriş ve depolama kısımları taklit edilir, bütün veritabanı dosyaları sırayla kurulur ve senaryolar farklı kullanıcılar olarak denenir. Yeni Supabase projelerinin "erişim varsayılan kapalı" davranışı da taklit edildiği için unutulan bir yetki testte yakalanır.

**Bir iş ne zaman bitmiş sayılır?** Kod analizinde hiç uyarı kalmamalı ve bütün testler geçmeli.

---

## 19. Veritabanı değişiklik listesi (migration)

Veritabanındaki her değişiklik sıralı bir SQL dosyası olarak saklanır. Çalıştırılmış bir dosya bir daha değiştirilmez; düzeltme gerekirse yeni bir dosya eklenir.

| # | Dosya | İçerik |
|---|---|---|
| 1 | `schema` | Sabit listeler, tablolar, indeksler |
| 2 | `functions` | Yardımcı fonksiyonlar, tetikleyiciler, iş kuralı fonksiyonları |
| 3 | `rls` | Satır bazlı yetki kuralları |
| 4 | `storage` | Görsel klasörü ve yetkileri |
| 5 | `seed_cities` | 81 il |
| 6 | `grants` | Tablo erişim izinleri |
| 7 | `hardening` | Güvenlik sıkılaştırması, eksik indeksler, kural hızı |
| 8 | `panel` | Pasif firma kuralı, program kaydetme, hesabı aktif/pasif yapma |
| 9 | `service_role_grants` | Hesap açma fonksiyonu için en az yetki |
| 10 | `sync_app_metadata` | Rol bilgisinin profile eşitlenmesi |
| 11 | `black_sea_split` | Karadeniz'in Batı ve Doğu olarak ikiye ayrılması |
| 12 | `tickets` | Bilet sahibinin okuma yetkisi, tek bilet kuralı, panelden bilet kesme |
| 13 | `guide` | Yolcu telefonu, katılım yöntemi (QR / elle), elle "Geldi", tur sorumlusunun tarih listesi |

---

## 20. Alınan kararlar

| Konu | Karar | Neden |
|---|---|---|
| Sunucu | Firebase yerine Supabase | Tur → tarih → bilet → ödeme ilişkisi ve koltuk takibi ilişkisel veritabanına daha uygun; ücretsiz planda görsel depolama da var |
| Ödeme | MVP'de demo ödeme | Gerçek ödeme altyapısı için şirket kurulması gerekiyor; akış, gerçek ödeme kolayca eklenebilecek şekilde kuruldu |
| İptal | Kalkıştan 1 saat öncesine kadar, tam iade | Müşteri için basit ve adil bir kural |
| Bilet sayısı | Müşteri her seferinde sadece kendine bir bilet alır | MVP'de yolcu ile hesap sahibi aynı kişi; çoklu yolcu sonraki sürümde |
| TC kimlik no | Sorulmuyor | Gereksiz kişisel veri tutulmuyor; gerekirse ileride eklenir |
| QR yeri | Ayrı sekme yok, Turlarım → bilet detayında | Menü sade kalıyor |
| Turu bitirme | Sadece o tarih kapanır | Aynı turun diğer tarihlerinin satışı sürmeli |
| Tur sorumlusu | Firmanın kalıcı çalışanı, tarihlere atanır | Her tur için ayrı hesap açmaya gerek kalmıyor |
| Bölgeler | Karadeniz → Batı Karadeniz ve Doğu Karadeniz | Firmaların tur kategorileri daha doğru ayrılıyor |
| İnternetsiz okutma | Yok; okutma internet ister | Çevrimdışı kuyruk çakışma kuralı ve çok iş gerektirir; MVP'de bağlantı yoksa uyarı çıkar |
| Elle "Geldi" | Var, onay penceresiyle; kayıtta "elle" yazar | Telefonu kapalı/kırık yolcu tura alınabilsin |
| Yolcu telefonu | Satın alırken istenir, bilete kopyalanır | Tur günü tur sorumlusu yolcuya ulaşabilsin |
| Şifre sıfırlama | Panelden yönetici yapar, yeni geçici şifre bir kez gösterilir | Giriş kimlikli hesapların e-postası yok |
| Koltuk seçimi | Sonraki sürüm | Veritabanı yapısı buna hazır |
| Web paneli | Flutter Web | Mobille aynı dil ve ortak kod |

---

## 21. Yol haritası ve eksikler

### 21.1 Fazlar

| Faz | İçerik | Durum |
|---|---|---|
| 0 | Altyapı, proje yapısı, veritabanı, güvenlik | Bitti |
| 1 | Mobil: giriş/kayıt, roller, şehir seçimi, tur listesi ve detayı | Bitti |
| 2 | Web paneli: firmalar, turlar, tarihler, program, görsel, hesap açma, turu bitirme onayı | Bitti |
| 3 | Bilet satın alma, Turlarım, iptal ve iade, panelde katılımcılar ve "Bilet kes" | Bitti |
| 4 | Tur sorumlusu ekranları: atanmış tarihler, katılımcılar, QR okutma, elle "Geldi", turu bitirme; yolcu telefonu; panelde şifre sıfırlama; yan yana kayan tur listesi | Bitti |
| 5 | Tur sohbeti, duyurular, bildirimler | Sırada |
| 6 | Ekran tasarımı ve demo hazırlığı | Planlandı |

### 21.2 Bilinen eksikler

- Uygulamadan kayıt olan müşteri şifresini unutursa e-postayla sıfırlama yok (e-posta bağlantısı ayarı sonra yapılacak).
- QR okutma internet ister; internetsiz okutma kuyruğu yok.
- Panelde bir tarihi "iptal edildi" yapma yok.
- Satın alırken yazılan telefon profile kaydedilir ama uygulamadaki oturum bilgisi bir sonraki girişe kadar eski kalır; ikinci satın almada telefon yeniden yazılabilir.
- Müşteri biletinin "Tura katıldı" olması canlı değil; Turlarım açılınca ya da aşağı çekince görünür (canlı dinleme Faz 5).
- E-posta onay bağlantısı tıklanınca uygulamaya geri dönmüyor (bu ayar daha sonra yapılacak).
