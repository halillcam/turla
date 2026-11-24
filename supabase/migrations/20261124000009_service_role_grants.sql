-- =============================================================================
-- Turla: create-account Edge Function'ının tablo yetkileri
--
-- Yeni Supabase projelerinde public tablolar service_role'e de varsayılan
-- olarak açılmıyor. service_role RLS'i atlar ama tablo yetkisi (GRANT) yine
-- gerekir. Sadece fonksiyonun ihtiyacı kadar yetki verilir:
--   - çağıranın rolünü/şirketini okumak (profiles)
--   - hedef şirketi kontrol etmek (companies)
--   - yeni hesabın telefonunu yazmak (profiles.phone)
-- Hesabın kendisi Auth Admin API ile açılır; profil tetikleyiciyle oluşur.
-- =============================================================================

grant usage on schema public to service_role;
grant select on public.profiles, public.companies to service_role;
grant update (phone) on public.profiles to service_role;
