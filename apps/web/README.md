# turla_web

Turla web paneli (Flutter web). Sadece **super admin** ve **aktif firmanın şirket yöneticisi** girebilir; müşteri ve tur sorumlusu hesapları reddedilir.

## Ekranlar

- **Firmalar** (super admin): firma oluşturma/düzenleme, aktif/pasif, firma yöneticisi hesabı açma, "Firmayı yönet" ile firmanın alanına geçiş.
- **Turlar**: tur ekleme/düzenleme, satışa aç/kapat, silme (bileti olan tur silinemez), kapak görseli (yüklemeden önce en uzun kenar 1280 px'e küçültülür, `tour-images/<firma>/`).
- **Program**: gün gün başlık ve etkinlikler; tek istekte kaydedilir (`save_tour_program`).
- **Tarihler**: kalkış tarihi/saati, kontenjan, tur sorumlusu ataması, araç ve şoför bilgisi.
- **Personel ve müşteriler**: tur sorumlusu ve dışarıdan müşteri hesabı açma (giriş kimliği `REH-1234` / `MUS-1234` sunucuda üretilir), aktif/pasif.
- **Tur bitirme talepleri**: rehberin talebini onayla (sadece o tarih kapanır) veya reddet.

## Sunucu tarafı

- Hesap açma: `supabase/functions/create-account` (Edge Function, service role). Kurallar `rules.ts` içinde.
- Panel fonksiyonları: `supabase/migrations/20261124000008_panel.sql`.
- Fonksiyonun tablo yetkileri (`service_role`): `20261124000009_service_role_grants.sql`.
- Rol/firma/giriş kimliği eşitlemesi: `20261124000010_sync_app_metadata.sql`. Auth Admin API kullanıcıyı önce metadata'sız ekleyip `app_metadata`'yı sonra yazdığı için profil bu tetikleyiciyle güncellenir.
- Testler: `supabase/tests` içinde `npm test` (SQL + Edge Function kuralları), burada `flutter test`.
