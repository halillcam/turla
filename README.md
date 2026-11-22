# Turla

Butik tur firmaları için tur satış ve tur günü operasyon uygulaması.

| Klasör | İçerik |
|---|---|
| `apps/mobile` | Mobil uygulama (misafir, müşteri, rehber) — Flutter + Bloc |
| `apps/web` | Web paneli (şirket admini, super admin) — Flutter Web + Bloc |
| `packages/core` | Ortak paket: sabitler (`constants/`), tema, enum'lar, `.env` okuma, Supabase başlatma |
| `supabase/migrations` | Veritabanı şeması, iş kuralı fonksiyonları, RLS, depolama, şehir verisi |
| `supabase/tests` | Migration ve iş kuralı testleri (Supabase gerekmeden, PGlite ile) |

## Kurulum

1. Kök dizinde bağımlılıkları kurun (pub workspace, tek komut):
   ```
   flutter pub get
   ```
2. `.env.example` dosyasını `.env` olarak kopyalayıp Supabase **Project URL** ve **Publishable key** değerlerini girin. `.env` git'e eklenmez.
3. Supabase Dashboard > SQL Editor'de `supabase/migrations` içindeki dosyaları **sırasıyla** çalıştırın
   (veya Supabase CLI ile `supabase db push`).
4. Uygulamayı çalıştırın (VS Code'da "Turla Mobil" / "Turla Web Panel" başlatma ayarları hazır):
   ```
   cd apps/mobile
   flutter run --dart-define-from-file=../../.env
   ```
   ```
   cd apps/web
   flutter run -d chrome --dart-define-from-file=../../.env
   ```

## Kod kuralları

- State management: **Bloc**. Widget'larda iş mantığı yok; mantık Bloc/repository katmanında.
- Büyük widget'lar ilgili feature'ın `widgets/` klasöründe, her biri ayrı dosyada.
- Sabit metinler `strings.dart` içinde `const` (ortak olanlar `CoreStrings`, uygulamaya özel olanlar `AppStrings`).
- Renk, boşluk, köşe, süre, boyut, yazı boyutu: `packages/core/lib/src/constants/` altındaki dosyalardan.
  Widget'larda sayı/renk elle yazılmaz.
- Anahtar ve adresler sadece `.env`'den okunur, koda yazılmaz.
- Feature yapısı: `features/<ad>/{data,domain,presentation}`; bağımlılıklar `core/di/injection.dart` içinde `get_it` ile kaydedilir.

## İş kuralları (sunucuda)

Bilet, ödeme ve tur bitirme tablolarına uygulama doğrudan yazamaz. Bu işlemler
`supabase.rpc(...)` ile çağrılan fonksiyonlarla, tek transaction içinde yapılır:

| Fonksiyon | Ne yapar |
|---|---|
| `book_ticket(departure_id, passenger_name, tc_no)` | Koltuğu kilitleyerek düşürür, bileti ve tek kullanımlık QR'ı oluşturur, demo ödeme kaydeder |
| `cancel_ticket(ticket_id)` | Müşteri kalkıştan 1 saat öncesine kadar iptal eder; koltuk geri eklenir, ödenen tutarın tamamı iade kaydedilir |
| `scan_ticket(departure_id, qr_token)` | Rehber QR okutur; bilet tek kullanımlıktır |
| `request_departure_completion(departure_id)` | Rehber "turu bitir" talebi açar |
| `review_departure_completion(request_id, approve)` | Admin onaylar/reddeder; **sadece o tarih** kapanır |

Fonksiyonların döndürdüğü hata kodları (`no_seats_left`, `cancellation_window_closed`, `not_allowed` ...)
uygulamada kullanıcı mesajına çevrilir.

**Yetkiler:** Yeni Supabase projelerinde tablolar `anon`/`authenticated` rollerine varsayılan olarak
açılmaz. Yeni bir tablo eklendiğinde RLS politikasının yanında `GRANT` da yazılmalıdır
(örnek: `20261122000006_grants.sql`). `TRUNCATE` istemci rollerinden kaldırılmıştır.

Testler:
```
cd supabase/tests
npm install
npm test
```
