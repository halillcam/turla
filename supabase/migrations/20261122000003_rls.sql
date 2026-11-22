-- =============================================================================
-- Turla: Row Level Security (satır bazlı yetki)
--
-- Kural: her tablo RLS ile kapalı başlar, sadece aşağıdaki politikalar açar.
-- Bilet, ödeme ve tur bitirme tablolarına istemci doğrudan yazamaz;
-- bu işlemler 20261122000002_functions.sql içindeki fonksiyonlarla yapılır.
-- =============================================================================

alter table public.cities               enable row level security;
alter table public.companies            enable row level security;
alter table public.profiles             enable row level security;
alter table public.tours                enable row level security;
alter table public.tour_program_days    enable row level security;
alter table public.tour_departures      enable row level security;
alter table public.tickets              enable row level security;
alter table public.payments             enable row level security;
alter table public.messages             enable row level security;
alter table public.announcements        enable row level security;
alter table public.notifications        enable row level security;
alter table public.device_tokens        enable row level security;
alter table public.completion_requests  enable row level security;
alter table public.feedbacks            enable row level security;

-- ─── Şehirler: herkes okur, sadece super admin yazar ────────────────────────

create policy cities_read on public.cities
  for select using (true);

create policy cities_write on public.cities
  for all using (public.is_super_admin()) with check (public.is_super_admin());

-- ─── Şirketler ───────────────────────────────────────────────────────────────
-- Aktif şirketler herkese açık (tur detayında firma adı görünür).

create policy companies_read on public.companies
  for select using (is_active or public.can_manage_company(id));

create policy companies_super_admin_write on public.companies
  for all using (public.is_super_admin()) with check (public.is_super_admin());

-- ─── Profiller ───────────────────────────────────────────────────────────────

create policy profiles_read on public.profiles
  for select using (
    id = auth.uid()
    or public.is_super_admin()
    or (company_id is not null and public.can_manage_company(company_id))
  );

-- Kullanıcı kendi profilini güncelleyebilir; hangi kolonlar olduğu aşağıdaki
-- GRANT ile sınırlıdır (rol, şirket, aktiflik değiştirilemez).
create policy profiles_update_self on public.profiles
  for update using (id = auth.uid()) with check (id = auth.uid());

-- Şirket admini kendi şirketinin rehber/müşteri profillerini güncelleyebilir.
create policy profiles_update_by_admin on public.profiles
  for update using (
    role in ('guide', 'customer') and company_id is not null and public.can_manage_company(company_id)
  ) with check (
    role in ('guide', 'customer') and company_id is not null and public.can_manage_company(company_id)
  );

create policy profiles_super_admin_all on public.profiles
  for all using (public.is_super_admin()) with check (public.is_super_admin());

revoke update on public.profiles from authenticated;
grant update (full_name, phone, tc_no, selected_city_id) on public.profiles to authenticated;
-- Profiller sadece auth tetikleyicisiyle oluşturulur.
revoke insert, delete on public.profiles from authenticated, anon;

-- ─── Turlar ve program: herkes aktif olanları okur, şirket admini yönetir ──

create policy tours_read on public.tours
  for select using (
    (is_active and exists (select 1 from public.companies c where c.id = company_id and c.is_active))
    or public.can_manage_company(company_id)
  );

create policy tours_manage on public.tours
  for all using (public.can_manage_company(company_id))
  with check (public.can_manage_company(company_id));

create policy program_read on public.tour_program_days
  for select using (
    exists (select 1 from public.tours t where t.id = tour_id)  -- tours_read politikası uygulanır
  );

create policy program_manage on public.tour_program_days
  for all using (
    exists (select 1 from public.tours t where t.id = tour_id and public.can_manage_company(t.company_id))
  ) with check (
    exists (select 1 from public.tours t where t.id = tour_id and public.can_manage_company(t.company_id))
  );

-- ─── Tur tarihleri ───────────────────────────────────────────────────────────

create policy departures_read on public.tour_departures
  for select using (
    exists (select 1 from public.tours t where t.id = tour_id)  -- tours_read politikası uygulanır
    or guide_id = auth.uid()
  );

-- Admin tarih ekler/günceller; koltuk sayısı (seats_left) ve durum (status)
-- aşağıdaki GRANT ile istemciden değiştirilemez, sadece fonksiyonlar değiştirir.
create policy departures_manage on public.tour_departures
  for all using (
    exists (select 1 from public.tours t where t.id = tour_id and public.can_manage_company(t.company_id))
  ) with check (
    exists (select 1 from public.tours t where t.id = tour_id and public.can_manage_company(t.company_id))
  );

revoke insert, update on public.tour_departures from authenticated;
grant insert (tour_id, departure_at, capacity, guide_id, bus_plate, driver_name, driver_phone)
  on public.tour_departures to authenticated;
grant update (departure_at, capacity, guide_id, bus_plate, driver_name, driver_phone)
  on public.tour_departures to authenticated;

-- ─── Biletler: sadece okuma (yazma fonksiyonlarla) ──────────────────────────

create policy tickets_read on public.tickets
  for select using (
    user_id = auth.uid()
    or public.can_manage_company(company_id)
    or public.is_departure_guide(departure_id)
  );

revoke insert, update, delete on public.tickets from authenticated, anon;

-- ─── Ödemeler: sadece okuma ──────────────────────────────────────────────────

create policy payments_read on public.payments
  for select using (
    public.can_manage_company(company_id)
    or exists (select 1 from public.tickets t where t.id = ticket_id and t.user_id = auth.uid())
  );

revoke insert, update, delete on public.payments from authenticated, anon;

-- ─── Mesajlar (tur sohbeti) ──────────────────────────────────────────────────
-- Okuma ve yazma: QR'ı okutulmuş katılımcılar, o tarihin rehberi ve şirket admini.

create policy messages_read on public.messages
  for select using (
    public.is_checked_in_participant(departure_id)
    or public.is_departure_guide(departure_id)
    or exists (
      select 1 from public.tour_departures d
      where d.id = departure_id and public.can_manage_company(d.company_id)
    )
  );

create policy messages_insert on public.messages
  for insert with check (
    exists (select 1 from public.tour_departures d where d.id = departure_id and d.status = 'scheduled')
    and (
      public.is_checked_in_participant(departure_id)
      or public.is_departure_guide(departure_id)
      or exists (
        select 1 from public.tour_departures d
        where d.id = departure_id and public.can_manage_company(d.company_id)
      )
    )
  );

create policy messages_delete on public.messages
  for delete using (
    sender_id = auth.uid()
    or public.is_departure_guide(departure_id)
    or exists (
      select 1 from public.tour_departures d
      where d.id = departure_id and public.can_manage_company(d.company_id)
    )
  );

revoke update on public.messages from authenticated, anon;

-- ─── Duyurular: rehber ve admin yazar, katılımcılar okur ────────────────────

create policy announcements_read on public.announcements
  for select using (
    public.is_checked_in_participant(departure_id)
    or public.is_departure_guide(departure_id)
    or exists (
      select 1 from public.tour_departures d
      where d.id = departure_id and public.can_manage_company(d.company_id)
    )
  );

create policy announcements_insert on public.announcements
  for insert with check (
    public.is_departure_guide(departure_id)
    or exists (
      select 1 from public.tour_departures d
      where d.id = departure_id and public.can_manage_company(d.company_id)
    )
  );

revoke update, delete on public.announcements from authenticated, anon;

-- ─── Bildirim kutusu: kullanıcı sadece kendininkini okur / okundu yapar ─────

create policy notifications_read on public.notifications
  for select using (user_id = auth.uid());

create policy notifications_mark_read on public.notifications
  for update using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy notifications_delete on public.notifications
  for delete using (user_id = auth.uid());

revoke insert, update on public.notifications from authenticated, anon;
grant update (is_read) on public.notifications to authenticated;

-- ─── Cihaz token'ları: kullanıcı kendi token'larını yönetir ─────────────────

create policy device_tokens_own on public.device_tokens
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ─── Tur bitirme talepleri: okuma (yazma fonksiyonlarla) ────────────────────

create policy completion_read on public.completion_requests
  for select using (guide_id = auth.uid() or public.can_manage_company(company_id));

revoke insert, update, delete on public.completion_requests from authenticated, anon;

-- ─── Geri bildirimler: şirket admini yazar, super admin yönetir ─────────────

create policy feedbacks_read on public.feedbacks
  for select using (public.can_manage_company(company_id));

create policy feedbacks_insert on public.feedbacks
  for insert with check (
    public.current_user_role() = 'admin'
    and company_id = public.current_company_id()
    and created_by = auth.uid()
  );

create policy feedbacks_super_admin on public.feedbacks
  for update using (public.is_super_admin()) with check (public.is_super_admin());

revoke update on public.feedbacks from authenticated;
grant update (status) on public.feedbacks to authenticated;
