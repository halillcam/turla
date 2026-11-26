-- =============================================================================
-- Turla: tur sohbeti, duyurular, bildirimler ve push (Faz 5)
--
-- 1) Sohbet kuralı: QR'ı okutulmuş yolcu ve o tarihin rehberi sohbeti sadece
--    tarih açıkken (scheduled / finish_requested) görür; tur bitince sohbet
--    onlardan tamamen gizlenir ama mesajlar DB'de kalır. Firma admini panelden
--    her zaman okur (denetim). Yazma sadece 'scheduled' tarihte.
-- 2) Gönderenin rolü mesaja yazılır ("Tur sorumlusu" / "Firma" etiketi için).
-- 3) Spam sınırı: kullanıcı başına dakikada 20 mesaj, 5 duyuru (rate_limited).
-- 4) participant_departure_info: müşterinin "Aktif tur" ekranı tek istekte;
--    rehberin adı/telefonu sadece o tarihte geçerli bileti olana ve tur bitene kadar.
-- 5) register_device_token: aynı telefonda hesap değişince token yeni hesaba geçer.
-- 6) Realtime: sadece messages ve tickets yayında (istemci yalnızca sohbet ekranı /
--    bilet detayı açıkken abone olur). RLS her aboneye ayrı uygulanır.
-- 7) Push: notifications'a satır eklenince (tek istekte) send-push Edge Function'ı
--    pg_net ile çağrılır. Fonksiyon gelen kimliklere güvenmez: sadece gönderilmemiş,
--    yeni bildirimleri kendisi okuyup gönderir; adres private.settings'te.
-- 8) company_announcements: super admin → firmalara panel duyurusu.
-- =============================================================================

-- ─── 1) Sohbet görünürlüğü ───────────────────────────────────────────────────

create or replace function public.is_departure_chat_member(p_departure_id uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.tour_departures d
    where d.id = p_departure_id
      and d.status in ('scheduled', 'finish_requested')
      and (
        (d.guide_id = auth.uid() and public.current_user_role() = 'guide')
        or exists (
          select 1 from public.tickets t
          where t.departure_id = d.id and t.user_id = auth.uid() and t.status = 'checked_in'
        )
      )
  );
$$;

grant execute on function public.is_departure_chat_member(uuid) to anon, authenticated;

create or replace function public.can_manage_departure(p_departure_id uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.tour_departures d
    where d.id = p_departure_id and public.can_manage_company(d.company_id)
  );
$$;

grant execute on function public.can_manage_departure(uuid) to anon, authenticated;

alter policy messages_read on public.messages using (
  public.is_departure_chat_member(departure_id) or public.can_manage_departure(departure_id)
);

alter policy messages_insert on public.messages with check (
  exists (select 1 from public.tour_departures d where d.id = departure_id and d.status = 'scheduled')
  and (public.is_departure_chat_member(departure_id) or public.can_manage_departure(departure_id))
);

-- Yolcu kendi mesajını, rehber kendi tarihindekileri tur açıkken siler; admin her zaman.
alter policy messages_delete on public.messages using (
  (public.is_departure_chat_member(departure_id)
    and (sender_id = (select auth.uid()) or public.is_departure_guide(departure_id)))
  or public.can_manage_departure(departure_id)
);

-- ─── 2-3) Gönderen rolü ve spam sınırı ───────────────────────────────────────

alter table public.messages add column sender_role public.user_role not null default 'customer';

create index messages_sender_time_idx on public.messages (sender_id, created_at desc);
create index announcements_sender_time_idx on public.announcements (sender_id, created_at desc);

create or replace function public.messages_before_insert()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  new.sender_id := auth.uid();
  new.created_at := now();
  select coalesce(nullif(p.full_name, ''), 'Katılımcı'), p.role
    into new.sender_name, new.sender_role
  from public.profiles p where p.id = auth.uid();

  if (select count(*) from public.messages m
      where m.sender_id = new.sender_id and m.created_at > now() - interval '1 minute') >= 20 then
    raise exception 'rate_limited';
  end if;
  return new;
end;
$$;

create or replace function public.announcements_before_insert()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  new.sender_id := auth.uid();
  new.created_at := now();
  if (select count(*) from public.announcements a
      where a.sender_id = new.sender_id and a.created_at > now() - interval '1 minute') >= 5 then
    raise exception 'rate_limited';
  end if;
  return new;
end;
$$;

revoke execute on function public.messages_before_insert() from public, anon, authenticated;
revoke execute on function public.announcements_before_insert() from public, anon, authenticated;

-- Duyuru sadece açık (scheduled) tarihe yazılır.
alter policy announcements_insert on public.announcements with check (
  exists (select 1 from public.tour_departures d where d.id = departure_id and d.status = 'scheduled')
  and (public.is_departure_guide(departure_id) or public.can_manage_departure(departure_id))
);

-- ─── 4) Müşterinin aktif tur ekranı ──────────────────────────────────────────

create or replace function public.participant_departure_info(p_departure_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_ticket public.tickets;
  v_result jsonb;
begin
  select * into v_ticket from public.tickets t
  where t.departure_id = p_departure_id and t.user_id = auth.uid()
    and t.status in ('paid', 'checked_in')
  order by t.created_at desc limit 1;
  if v_ticket.id is null then
    raise exception 'not_allowed';
  end if;

  select jsonb_build_object(
    'departure_id', d.id,
    'tour_id', t.id,
    'tour_title', t.title,
    'departure_at', d.departure_at,
    'status', d.status,
    'ticket_status', v_ticket.status,
    'bus_plate', d.bus_plate,
    'driver_name', d.driver_name,
    'driver_phone', d.driver_phone,
    'company_name', c.name,
    'company_phone', c.phone,
    'guide_name', nullif(g.full_name, ''),
    'guide_phone', g.phone,
    'chat_open', d.status = 'scheduled' and v_ticket.status = 'checked_in',
    'program', coalesce((
      select jsonb_agg(jsonb_build_object('day_no', p.day_no, 'title', p.title, 'activities', p.activities)
                       order by p.sort_order, p.day_no)
      from public.tour_program_days p where p.tour_id = t.id), '[]'::jsonb),
    'last_announcement', (
      select jsonb_build_object('body', a.body, 'created_at', a.created_at)
      from public.announcements a
      where a.departure_id = d.id and v_ticket.status = 'checked_in'
      order by a.created_at desc limit 1)
  ) into v_result
  from public.tour_departures d
  join public.tours t on t.id = d.tour_id
  join public.companies c on c.id = d.company_id
  left join public.profiles g on g.id = d.guide_id and g.is_active
  where d.id = p_departure_id and d.status in ('scheduled', 'finish_requested');

  if v_result is null then
    raise exception 'departure_not_active';
  end if;
  return v_result;
end;
$$;

revoke execute on function public.participant_departure_info(uuid) from public, anon;
grant execute on function public.participant_departure_info(uuid) to authenticated;

-- ─── 5) Cihaz token'ı ────────────────────────────────────────────────────────

create or replace function public.register_device_token(p_token text, p_platform text)
returns void
language plpgsql security definer set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'not_allowed';
  end if;
  if p_token is null or char_length(p_token) not between 20 and 4096 then
    raise exception 'invalid_token';
  end if;
  insert into public.device_tokens (token, user_id, platform, updated_at)
  values (p_token, auth.uid(), p_platform, now())
  on conflict (token) do update
    set user_id = excluded.user_id, platform = excluded.platform, updated_at = now();
end;
$$;

revoke execute on function public.register_device_token(text, text) from public, anon;
grant execute on function public.register_device_token(text, text) to authenticated;

-- ─── 6) Realtime yayını ──────────────────────────────────────────────────────

do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    alter publication supabase_realtime add table public.messages, public.tickets;
  end if;
end;
$$;

-- ─── 7) Push ─────────────────────────────────────────────────────────────────

do $$
begin
  if exists (select 1 from pg_available_extensions where name = 'pg_net') then
    create extension if not exists pg_net with schema extensions;
  end if;
end;
$$;

alter table public.notifications add column push_sent_at timestamptz;

-- API'ye açık olmayan ayar tablosu (send-push adresi burada; boşsa push yok).
create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

create table private.settings (
  key    text primary key,
  value  text not null
);
revoke all on private.settings from public, anon, authenticated;

create or replace function public.notifications_push()
returns trigger
language plpgsql security definer set search_path = ''
as $$
declare
  v_url text;
  v_ids jsonb;
begin
  select s.value into v_url from private.settings s where s.key = 'push_function_url';
  if v_url is null then
    return null;
  end if;
  select jsonb_agg(n.id) into v_ids from new_rows n;
  if v_ids is null then
    return null;
  end if;
  perform net.http_post(
    url := v_url,
    body := jsonb_build_object('notification_ids', v_ids),
    headers := '{"Content-Type": "application/json"}'::jsonb,
    timeout_milliseconds := 5000
  );
  return null;
end;
$$;

revoke execute on function public.notifications_push() from public, anon, authenticated;

create trigger notifications_push
  after insert on public.notifications
  referencing new table as new_rows
  for each statement execute function public.notifications_push();

-- send-push Edge Function'ının yetkileri (service_role, en az yetki).
grant select on public.notifications, public.device_tokens to service_role;
grant update (push_sent_at) on public.notifications to service_role;
grant delete on public.device_tokens to service_role;

-- ─── 8) Super admin → firma duyuruları ───────────────────────────────────────

create table public.company_announcements (
  id          uuid primary key default gen_random_uuid(),
  company_id  uuid references public.companies (id) on delete cascade, -- null = tüm firmalar
  title       text not null check (char_length(title) between 3 and 160),
  body        text not null check (char_length(body) between 1 and 4000),
  created_by  uuid references public.profiles (id) on delete set null,
  created_at  timestamptz not null default now()
);

create index company_announcements_company_idx on public.company_announcements (company_id, created_at desc);
create index company_announcements_created_by_idx on public.company_announcements (created_by);

alter table public.company_announcements enable row level security;

create policy company_announcements_read on public.company_announcements
  for select using (
    (select public.is_super_admin())
    or ((select public.current_user_role()) = 'admin'
        and (company_id is null or company_id = (select public.current_company_id()))
        and public.can_manage_company((select public.current_company_id())))
  );

create policy company_announcements_insert on public.company_announcements
  for insert with check ((select public.is_super_admin()));

create policy company_announcements_delete on public.company_announcements
  for delete using ((select public.is_super_admin()));

create or replace function public.company_announcements_before_insert()
returns trigger
language plpgsql set search_path = ''
as $$
begin
  new.created_by := auth.uid();
  new.created_at := now();
  return new;
end;
$$;

revoke execute on function public.company_announcements_before_insert() from public, anon, authenticated;

create trigger company_announcements_before_insert
  before insert on public.company_announcements
  for each row execute function public.company_announcements_before_insert();

revoke all on public.company_announcements from anon, authenticated;
grant select, insert, delete on public.company_announcements to authenticated;

-- Geri bildirim: super admin tüm firmalarınkini okur (can_manage_company), durumu değiştirir.
-- Firma admini kendi firmasınınkini okur ve yazar (Faz 0 politikaları yeterli).
