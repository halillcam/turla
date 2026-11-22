# Turla

Turla, butik tur firmaları ile müşterilerini aynı yerde buluşturan bir tur satış ve tur günü yönetim uygulamasıdır.

Küçük ve orta ölçekli tur firmaları satışlarını çoğunlukla telefon, mesajlaşma uygulamaları ve el ile tutulan listelerle yürütüyor. Kontenjanın kaçta kaç dolduğu, kimin ödeme yaptığı, otobüse kimin bindiği ve yolculara son dakika bilgisinin nasıl ulaştırılacağı gibi işler hem firma hem de müşteri için yorucu ve hataya açık. Turla bu süreci tek bir sistemde topluyor: müşteri turu telefonundan bulup bilet alıyor, firma turlarını ve katılımcılarını panelden yönetiyor, tur sorumlusu da tur günü yolcuları QR kod ile karşılayıp onlarla uygulama üzerinden iletişim kuruyor.

Proje Kahramanmaraş'ta geliştiriliyor ve şu an MVP aşamasında.

## Kimler ne yapıyor

**Misafir.** Uygulamayı açan herkes giriş yapmadan şehrini seçip o şehirden kalkan turları bölgelere göre görebilir, tur detayını, programını ve kalan kontenjanı inceleyebilir. Bilet almak için giriş yapması gerekir.

**Müşteri.** Kayıt olup giriş yaptıktan sonra turun uygun bir tarihini seçip bilet alır. Bilet alındığında ona özel, tek kullanımlık bir QR kod oluşur. Bu QR kod internet olmadan da açılabilir, çünkü tur günü otobüste bağlantı olmayabilir. Müşteri biletini kalkıştan en geç bir saat öncesine kadar iptal edebilir; iptal edilen koltuk tekrar satışa açılır ve ödenen tutarın tamamı iade olarak kaydedilir. Tur günü QR kodu okutulduktan sonra tur sohbetine katılır ve tur sorumlusunun duyurularını alır.

**Tur sorumlusu (rehber).** Firmanın kalıcı bir çalışanıdır ve tur tarihlerine atanır. Atandığı tarihte katılımcı listesini görür, gelenleri ve gelmeyenleri ayırt eder, QR kodları okutur, yolculara duyuru gönderir ve sohbete katılır. Tur bittiğinde "turu bitir" talebi gönderir.

**Şirket yöneticisi (web paneli).** Turları, tarihleri, kontenjanı, araç ve şoför bilgisini, tur programını ve görselleri yönetir. Rehber hesaplarını açar ve tarihlere atar. Telefonla ya da ofisten bilet alan müşterileri sisteme kendisi ekleyebilir. Rehberin gönderdiği bitiş talebini onaylar; onay yalnızca o tarihi kapatır, aynı turun diğer tarihleri etkilenmez.

**Super admin.** Sisteme firma ekler, firmaları açıp kapatır, tüm verileri görür ve firmalara duyuru gönderir.

## Nasıl çalışıyor

Uygulamanın verisi Supabase üzerinde, PostgreSQL veritabanında tutuluyor. Para ve kontenjanla ilgili hiçbir işlem telefonda yapılmıyor. Bilet alma, iptal ve iade, QR okutma ve tur bitirme veritabanındaki fonksiyonlarla tek bir işlem halinde yürütülüyor. Örneğin iki kişi aynı anda son koltuğu almaya çalışırsa koltuğu yalnızca biri alabilir. QR kodu tahmin edilemeyecek şekilde sunucuda üretiliyor ve bir kez okutulduktan sonra tekrar kullanılamıyor.

Kimin hangi veriyi görebileceğini satır bazlı güvenlik kuralları (Row Level Security) belirliyor. Bir firma yalnızca kendi turlarını ve biletlerini görür, müşteri yalnızca kendi biletlerini görür, tur sohbetine de yalnızca QR kodu okutulmuş yolcular ve o tarihin rehberi yazabilir. Kayıt olan biri kendine yönetici yetkisi veremez.

Gerçek ödeme altyapısı henüz bağlı değil. MVP'de ödeme adımı bir demo ekranı ile gösteriliyor ve kayıtlar "demo ödeme" olarak tutuluyor. Şirket kuruluşu tamamlandığında gerçek ödeme altyapısı aynı yapının üzerine eklenecek.

Değişmeyen veriler cihazda saklanıyor. Örneğin 81 il listesi ilk açılışta bir kez veritabanından çekiliyor ve sonraki açılışlarda sunucuya istek atılmadan cihazdan okunuyor.

## Teknolojiler

- Flutter (mobil uygulama ve web paneli)
- Bloc (state yönetimi), get_it (bağımlılık yönetimi)
- Supabase: PostgreSQL, Auth, Storage, Row Level Security
- Firebase Cloud Messaging (push bildirimleri, planlanan)

## Proje yapısı

Depo, iki uygulamanın ve ortak paketin birlikte tutulduğu bir monorepo olarak düzenlendi.

| Klasör | İçerik |
|---|---|
| `apps/mobile` | Mobil uygulama: misafir, müşteri ve rehber ekranları |
| `apps/web` | Web paneli: şirket yöneticisi ve super admin ekranları |
| `packages/core` | Ortak paket: sabitler, tema, enum'lar, ortam ayarları, Supabase bağlantısı ve iki uygulamanın da kullandığı veri katmanları (ör. iller) |
| `supabase/migrations` | Veritabanı şeması, iş kuralı fonksiyonları, güvenlik kuralları, yetkiler ve il listesi |
| `supabase/tests` | Veritabanı testleri. Supabase'e bağlanmadan, bilgisayarda çalışan gömülü bir PostgreSQL ile çalışır |

## Kurulum

Flutter 3.44 veya üzeri ve bir Supabase projesi gerekir.

1. Bağımlılıkları kök dizinden tek komutla kurun:
   ```
   flutter pub get
   ```
2. `.env.example` dosyasını `.env` adıyla kopyalayın ve Supabase projenizin adresini ve publishable key değerini yazın. Bu dosya git'e eklenmez.
3. `supabase/migrations` klasöründeki dosyaları sırasıyla Supabase SQL Editor'de çalıştırın ya da Supabase CLI ile `supabase db push` komutunu kullanın.
4. Uygulamayı çalıştırın. VS Code kullanıyorsanız "Turla Mobil" ve "Turla Web Panel" başlatma ayarları hazırdır. Komut satırından:
   ```
   cd apps/mobile
   flutter run --dart-define-from-file=../../.env
   ```
   ```
   cd apps/web
   flutter run -d chrome --dart-define-from-file=../../.env
   ```

`.env` tanımlı değilse uygulama çökmez, eksik ayarları anlatan bir ekran gösterir.

## Testler

Ortak paketin birim testleri:
```
cd packages/core
flutter test
```

Veritabanı testleri şemayı baştan kurar, ardından bilet alma, kontenjan dolması, iptal süresi, iade, QR'ın tek kullanımlık olması, sohbet ve duyuru yetkileri, tur bitirme onayı ve görsel yükleme yetkileri gibi senaryoları dener:
```
cd supabase/tests
npm install
npm test
```

## Kod kuralları

- State yönetimi Bloc ile yapılır. Widget'larda iş mantığı bulunmaz.
- Büyük widget'lar ilgili özelliğin `widgets` klasöründe, her biri ayrı dosyada tutulur.
- Sabit metinler `strings.dart` dosyalarında, renk, boşluk, köşe, süre ve boyut değerleri `packages/core/lib/src/constants` altındaki dosyalarda tanımlanır. Widget'larda sayı ya da renk doğrudan yazılmaz.
- Adres ve anahtarlar yalnızca `.env` üzerinden okunur, koda yazılmaz.
- Her özellik `data`, `domain` ve `presentation` katmanlarına ayrılır.
- Veritabanına yeni bir tablo eklendiğinde güvenlik kuralının yanında tablo yetkisi (`GRANT`) de yazılır. Yeni Supabase projeleri tabloları varsayılan olarak uygulamaya açmaz.

## Yol haritası

- [x] Altyapı, veritabanı şeması, iş kuralları ve güvenlik kuralları
- [ ] Giriş, roller, şehir seçimi, tur listesi ve tur detayı
- [ ] Web paneli: firma, tur, tarih ve görsel yönetimi
- [ ] Bilet alma, QR bilet, Turlarım, iptal ve iade
- [ ] Rehber: QR okutma, katılımcı listesi, turu bitirme
- [ ] Sohbet, duyurular ve push bildirimleri
- [ ] Sonraki sürümler: gerçek ödeme altyapısı, koltuk seçimi
