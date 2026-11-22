-- =============================================================================
-- Turla: Supabase advisor önerilerine göre sıkılaştırma ve performans
--
-- 1) Tetikleyici fonksiyonları RPC olarak çağrılamaz.
-- 2) Yabancı anahtarlara indeks.
-- 3) RLS'de auth.uid() ve parametresiz yardımcılar (select ...) ile sarılır:
--    satır başına değil sorgu başına bir kez hesaplanır.
-- 4) "for all" politikaları insert/update/delete olarak ayrılır; böylece SELECT
--    için tek politika çalışır.
--
-- Not: current_user_role / is_super_admin / can_manage_company gibi yardımcılar
-- RLS içinde kullanıldığı için çağrılabilir kalır; sadece oturumdaki kullanıcının
-- kendi bilgisini döndürürler.
-- =============================================================================

-- ─── 1) Tetikleyici fonksiyonları ────────────────────────────────────────────

revoke execute on function public.announcements_fanout() from public, anon, authenticated;
revoke execute on function public.announcements_before_insert() from public, anon, authenticated;
revoke execute on function public.departures_before_write() from public, anon, authenticated;
revoke execute on function public.messages_before_insert() from public, anon, authenticated;
revoke execute on function public.set_updated_at() from public, anon, authenticated;

-- ─── 2) Yabancı anahtar indeksleri ───────────────────────────────────────────

create index if not exists announcements_sender_idx on public.announcements (sender_id);
create index if not exists companies_city_idx on public.companies (city_id);
create index if not exists completion_guide_idx on public.completion_requests (guide_id);
create index if not exists completion_reviewed_by_idx on public.completion_requests (reviewed_by);
create index if not exists feedbacks_created_by_idx on public.feedbacks (created_by);
create index if not exists messages_sender_idx on public.messages (sender_id);
create index if not exists notifications_announcement_idx on public.notifications (announcement_id);
create index if not exists notifications_departure_idx on public.notifications (departure_id);
create index if not exists payments_created_by_idx on public.payments (created_by);
create index if not exists profiles_selected_city_idx on public.profiles (selected_city_id);
create index if not exists tickets_scanned_by_idx on public.tickets (scanned_by);

-- ─── 3 + 4) Politikaların yeniden yazılması ──────────────────────────────────

-- Şehirler
drop policy cities_write on public.cities;
create policy cities_insert on public.cities for insert
  with check ((select public.is_super_admin()));
create policy cities_update on public.cities for update
  using ((select public.is_super_admin())) with check ((select public.is_super_admin()));
create policy cities_delete on public.cities for delete
  using ((select public.is_super_admin()));

-- Şirketler
drop policy companies_super_admin_write on public.companies;
create policy companies_insert on public.companies for insert
  with check ((select public.is_super_admin()));
create policy companies_update on public.companies for update
  using ((select public.is_super_admin())) with check ((select public.is_super_admin()));
create policy companies_delete on public.companies for delete
  using ((select public.is_super_admin()));

-- Profiller: tek okuma, tek güncelleme, super admin silme
drop policy profiles_read on public.profiles;
drop policy profiles_update_self on public.profiles;
drop policy profiles_update_by_admin on public.profiles;
drop policy profiles_super_admin_all on public.profiles;

create policy profiles_read on public.profiles for select using (
  id = (select auth.uid())
  or (select public.is_super_admin())
  or (company_id is not null and public.can_manage_company(company_id))
);

-- Kendi profili; şirket admini kendi şirketinin rehber/müşterisi; super admin herkes.
-- Hangi kolonların değişebileceği GRANT ile sınırlıdır (rol/şirket değişmez).
create policy profiles_update on public.profiles for update using (
  id = (select auth.uid())
  or (select public.is_super_admin())
  or (role in ('guide', 'customer') and company_id is not null and public.can_manage_company(company_id))
) with check (
  id = (select auth.uid())
  or (select public.is_super_admin())
  or (role in ('guide', 'customer') and company_id is not null and public.can_manage_company(company_id))
);

create policy profiles_delete on public.profiles for delete
  using ((select public.is_super_admin()));

-- Turlar
drop policy tours_manage on public.tours;
create policy tours_insert on public.tours for insert
  with check (public.can_manage_company(company_id));
create policy tours_update on public.tours for update
  using (public.can_manage_company(company_id)) with check (public.can_manage_company(company_id));
create policy tours_delete on public.tours for delete
  using (public.can_manage_company(company_id));

-- Tur programı
drop policy program_manage on public.tour_program_days;
create policy program_insert on public.tour_program_days for insert with check (
  exists (select 1 from public.tours t where t.id = tour_id and public.can_manage_company(t.company_id))
);
create policy program_update on public.tour_program_days for update using (
  exists (select 1 from public.tours t where t.id = tour_id and public.can_manage_company(t.company_id))
) with check (
  exists (select 1 from public.tours t where t.id = tour_id and public.can_manage_company(t.company_id))
);
create policy program_delete on public.tour_program_days for delete using (
  exists (select 1 from public.tours t where t.id = tour_id and public.can_manage_company(t.company_id))
);

-- Tur tarihleri
drop policy departures_read on public.tour_departures;
drop policy departures_manage on public.tour_departures;
create policy departures_read on public.tour_departures for select using (
  exists (select 1 from public.tours t where t.id = tour_id)   -- tours_read uygulanır
  or guide_id = (select auth.uid())
);
create policy departures_insert on public.tour_departures for insert with check (
  exists (select 1 from public.tours t where t.id = tour_id and public.can_manage_company(t.company_id))
);
create policy departures_update on public.tour_departures for update using (
  exists (select 1 from public.tours t where t.id = tour_id and public.can_manage_company(t.company_id))
) with check (
  exists (select 1 from public.tours t where t.id = tour_id and public.can_manage_company(t.company_id))
);
create policy departures_delete on public.tour_departures for delete using (
  exists (select 1 from public.tours t where t.id = tour_id and public.can_manage_company(t.company_id))
);

-- Biletler / ödemeler
alter policy tickets_read on public.tickets using (
  user_id = (select auth.uid())
  or public.can_manage_company(company_id)
  or public.is_departure_guide(departure_id)
);
alter policy payments_read on public.payments using (
  public.can_manage_company(company_id)
  or exists (select 1 from public.tickets t where t.id = ticket_id and t.user_id = (select auth.uid()))
);

-- Mesajlar
alter policy messages_delete on public.messages using (
  sender_id = (select auth.uid())
  or public.is_departure_guide(departure_id)
  or exists (
    select 1 from public.tour_departures d
    where d.id = departure_id and public.can_manage_company(d.company_id)
  )
);

-- Bildirimler / cihazlar / tur bitirme / geri bildirim
alter policy notifications_read on public.notifications using (user_id = (select auth.uid()));
alter policy notifications_mark_read on public.notifications
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
alter policy notifications_delete on public.notifications using (user_id = (select auth.uid()));
alter policy device_tokens_own on public.device_tokens
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
alter policy completion_read on public.completion_requests
  using (guide_id = (select auth.uid()) or public.can_manage_company(company_id));
alter policy feedbacks_insert on public.feedbacks with check (
  (select public.current_user_role()) = 'admin'
  and company_id = (select public.current_company_id())
  and created_by = (select auth.uid())
);
alter policy feedbacks_super_admin on public.feedbacks
  using ((select public.is_super_admin())) with check ((select public.is_super_admin()));
