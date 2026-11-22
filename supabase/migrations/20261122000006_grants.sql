-- =============================================================================
-- Turla: tablo ve fonksiyon yetkileri (GRANT)
--
-- Yeni Supabase projelerinde public tablolar anon/authenticated rollerine
-- varsayılan olarak açılmaz. Yetkiler burada açıkça verilir; hangi satırın
-- görüleceğine/değişeceğine RLS politikaları (20261122000003_rls.sql) karar verir.
--
-- anon          = giriş yapmamış misafir
-- authenticated = giriş yapmış kullanıcı (müşteri, rehber, admin, super admin)
-- =============================================================================

-- TRUNCATE RLS'i atlar; istemci rollerinden tamamen kaldırılır.
revoke truncate on all tables in schema public from anon, authenticated;

-- ─── Misafir: sadece katalog okuma ───────────────────────────────────────────

grant select on
  public.cities,
  public.companies,
  public.tours,
  public.tour_program_days,
  public.tour_departures
to anon;

-- ─── Giriş yapmış kullanıcı ──────────────────────────────────────────────────

grant select on all tables in schema public to authenticated;

-- Katalog yönetimi (RLS: super admin / ilgili şirketin admini)
grant insert, update, delete on public.cities to authenticated;
grant insert, update, delete on public.companies to authenticated;
grant insert, update, delete on public.tours to authenticated;
grant insert, update, delete on public.tour_program_days to authenticated;
grant delete on public.tour_departures to authenticated;
-- tour_departures insert/update kolon bazında 20261122000003_rls.sql içinde verilir.

-- İletişim
grant insert, delete on public.messages to authenticated;
grant insert on public.announcements to authenticated;
grant delete on public.notifications to authenticated;
grant insert, update, delete on public.device_tokens to authenticated;

-- Geri bildirim
grant insert on public.feedbacks to authenticated;

-- profiles, tickets, payments, completion_requests: yazma yetkisi YOK.
-- (profiles kolon bazlı update 20261122000003_rls.sql içinde; diğerleri fonksiyonlarla.)

-- ─── RLS içinde kullanılan yardımcı fonksiyonlar ─────────────────────────────
-- Politikalar sorguyu yapan rolün yetkisiyle çalışır; misafir de çağırabilmeli.

grant execute on function public.current_user_role() to anon, authenticated;
grant execute on function public.current_company_id() to anon, authenticated;
grant execute on function public.is_super_admin() to anon, authenticated;
grant execute on function public.can_manage_company(uuid) to anon, authenticated;
grant execute on function public.is_departure_guide(uuid) to anon, authenticated;
grant execute on function public.is_checked_in_participant(uuid) to anon, authenticated;
