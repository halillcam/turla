-- =============================================================================
-- Turla: tur sorumlusu (rehber) akışı (Faz 4)
--
-- 1) Yolcu telefonu: bilete kopyalanır (rehber arayabilsin, panelde görünsün).
--    Uygulamadan alırken müşteri yazar; profilinde telefon yoksa oraya da kaydedilir.
--    Panelden kesilen bilette müşterinin profil telefonu kopyalanır.
-- 2) Katılım nasıl işaretlendi: 'qr' (okutuldu) veya 'manual' (rehber elle "Geldi" dedi).
-- 3) check_in_manually: müşterinin telefonu kapalı/kırıksa rehber listeden işaretler.
-- 4) guide_departures: rehberin ana ekranı tek istekte (kalkışlar + geldi/gelmedi sayıları
--    + bitirme talebi durumu).
-- =============================================================================

-- ─── 1-2) Yeni sütunlar ──────────────────────────────────────────────────────

create type public.check_in_method as enum ('qr', 'manual');

alter table public.tickets
  add column passenger_phone text
    check (passenger_phone is null or passenger_phone ~ '^[0-9+() -]{7,20}$'),
  add column check_in_method public.check_in_method;

-- Telefon biçimi: rakam, boşluk, +, -, parantez; 7-20 karakter. Boş metin null sayılır.
create or replace function public.normalize_phone(p_phone text)
returns text
language plpgsql immutable set search_path = ''
as $$
declare
  v_phone text := nullif(trim(coalesce(p_phone, '')), '');
begin
  if v_phone is not null and v_phone !~ '^[0-9+() -]{7,20}$' then
    raise exception 'invalid_phone';
  end if;
  return v_phone;
end;
$$;

revoke execute on function public.normalize_phone(text) from public, anon;
grant execute on function public.normalize_phone(text) to authenticated;

-- ─── Bilet satın alma: telefon eklendi ──────────────────────────────────────
-- Eski imza kaldırılır; aynı adla iki fonksiyon olsaydı PostgREST hangisini
-- çağıracağını seçemezdi. Yeni parametre isteğe bağlı olduğu için eski istemci de çalışır.

drop function public.book_ticket(uuid, text, text);

create function public.book_ticket(
  p_departure_id uuid,
  p_passenger_name text,
  p_tc_no text default null,
  p_passenger_phone text default null
)
returns public.tickets
language plpgsql security definer set search_path = ''
as $$
declare
  v_departure public.tour_departures;
  v_tour public.tours;
  v_ticket public.tickets;
  v_phone text;
begin
  if auth.uid() is null or public.current_user_role() is distinct from 'customer' then
    raise exception 'only_customers_can_book';
  end if;

  v_phone := public.normalize_phone(p_passenger_phone);

  -- Satır kilidi: aynı anda iki kişi son koltuğu alamaz, aynı kişi iki bilet alamaz.
  select * into v_departure from public.tour_departures
  where id = p_departure_id
  for update;

  if v_departure.id is null then
    raise exception 'departure_not_found';
  end if;

  select * into v_tour from public.tours where id = v_departure.tour_id;

  if not v_tour.is_active
     or not exists (select 1 from public.companies c where c.id = v_tour.company_id and c.is_active) then
    raise exception 'tour_not_available';
  end if;
  if v_departure.status <> 'scheduled' or v_departure.departure_at <= now() then
    raise exception 'departure_not_bookable';
  end if;
  if exists (
    select 1 from public.tickets t
    where t.departure_id = v_departure.id and t.user_id = auth.uid()
      and t.status in ('reserved', 'paid', 'checked_in')
  ) then
    raise exception 'already_has_ticket';
  end if;
  if v_departure.seats_left <= 0 then
    raise exception 'no_seats_left';
  end if;

  update public.tour_departures set seats_left = seats_left - 1 where id = v_departure.id;

  insert into public.tickets (
    departure_id, company_id, user_id, passenger_name, passenger_phone, tc_no,
    price_paid, status, source, qr_token
  ) values (
    v_departure.id, v_departure.company_id, auth.uid(), trim(p_passenger_name), v_phone,
    nullif(trim(p_tc_no), ''),
    v_tour.price, 'paid', 'app', encode(extensions.gen_random_bytes(24), 'hex')
  )
  returning * into v_ticket;

  if v_tour.price > 0 then
    insert into public.payments (ticket_id, company_id, type, method, amount, created_by)
    values (v_ticket.id, v_ticket.company_id, 'payment', 'demo', v_tour.price, auth.uid());
  end if;

  -- Bir sonraki satın almada form dolu gelsin diye profile de yazılır (boşsa).
  if v_phone is not null then
    update public.profiles set phone = v_phone
    where id = auth.uid() and nullif(trim(coalesce(phone, '')), '') is null;
  end if;

  return v_ticket;
end;
$$;

revoke execute on function public.book_ticket(uuid, text, text, text) from public, anon;
grant execute on function public.book_ticket(uuid, text, text, text) to authenticated;

-- Panelden kesilen bilete müşterinin profil telefonu kopyalanır.
create or replace function public.copy_customer_phone_to_ticket()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  if new.passenger_phone is null then
    select public.normalize_phone(p.phone) into new.passenger_phone
    from public.profiles p where p.id = new.user_id;
  end if;
  return new;
exception when others then
  -- Profildeki eski/bozuk telefon bilet kesmeyi engellemez.
  new.passenger_phone := null;
  return new;
end;
$$;

revoke execute on function public.copy_customer_phone_to_ticket() from public, anon, authenticated;

create trigger tickets_copy_customer_phone
  before insert on public.tickets
  for each row execute function public.copy_customer_phone_to_ticket();

-- ─── QR okutma: yöntem 'qr' olarak kaydedilir ───────────────────────────────

create or replace function public.scan_ticket(p_departure_id uuid, p_qr_token text)
returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_departure public.tour_departures;
  v_ticket public.tickets;
begin
  select * into v_departure from public.tour_departures where id = p_departure_id;
  if v_departure.id is null then
    raise exception 'departure_not_found';
  end if;
  if not public.is_departure_guide(p_departure_id)
     and not public.can_manage_company(v_departure.company_id) then
    raise exception 'not_allowed';
  end if;
  if v_departure.status <> 'scheduled' then
    raise exception 'departure_not_active';
  end if;

  select * into v_ticket from public.tickets
  where qr_token = trim(p_qr_token)
  for update;

  if v_ticket.id is null then
    return jsonb_build_object('ok', false, 'code', 'not_found');
  end if;
  if v_ticket.departure_id <> p_departure_id then
    return jsonb_build_object('ok', false, 'code', 'wrong_departure');
  end if;
  if v_ticket.status = 'checked_in' then
    return jsonb_build_object('ok', false, 'code', 'already_used',
      'ticket_id', v_ticket.id, 'passenger_name', v_ticket.passenger_name,
      'scanned_at', v_ticket.scanned_at);
  end if;
  if v_ticket.status = 'cancelled' then
    return jsonb_build_object('ok', false, 'code', 'cancelled',
      'ticket_id', v_ticket.id, 'passenger_name', v_ticket.passenger_name);
  end if;
  if v_ticket.status <> 'paid' then
    return jsonb_build_object('ok', false, 'code', 'not_paid',
      'ticket_id', v_ticket.id, 'passenger_name', v_ticket.passenger_name);
  end if;

  update public.tickets
  set status = 'checked_in', scanned_at = now(), scanned_by = auth.uid(), check_in_method = 'qr'
  where id = v_ticket.id
  returning * into v_ticket;

  return jsonb_build_object('ok', true, 'code', 'ok',
    'ticket_id', v_ticket.id, 'passenger_name', v_ticket.passenger_name,
    'scanned_at', v_ticket.scanned_at);
end;
$$;

-- ─── 3) Elle "Geldi" ─────────────────────────────────────────────────────────
-- Yanıt scan_ticket ile aynı biçimde (istemci tek sonuç ekranı kullanır).

create or replace function public.check_in_manually(p_ticket_id uuid)
returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_ticket public.tickets;
  v_departure public.tour_departures;
begin
  select * into v_ticket from public.tickets where id = p_ticket_id for update;
  if v_ticket.id is null then
    raise exception 'ticket_not_found';
  end if;

  select * into v_departure from public.tour_departures where id = v_ticket.departure_id;
  if not public.is_departure_guide(v_departure.id)
     and not public.can_manage_company(v_departure.company_id) then
    raise exception 'not_allowed';
  end if;
  if v_departure.status <> 'scheduled' then
    raise exception 'departure_not_active';
  end if;

  if v_ticket.status = 'checked_in' then
    return jsonb_build_object('ok', false, 'code', 'already_used',
      'ticket_id', v_ticket.id, 'passenger_name', v_ticket.passenger_name,
      'scanned_at', v_ticket.scanned_at);
  end if;
  if v_ticket.status = 'cancelled' then
    return jsonb_build_object('ok', false, 'code', 'cancelled',
      'ticket_id', v_ticket.id, 'passenger_name', v_ticket.passenger_name);
  end if;
  if v_ticket.status <> 'paid' then
    return jsonb_build_object('ok', false, 'code', 'not_paid',
      'ticket_id', v_ticket.id, 'passenger_name', v_ticket.passenger_name);
  end if;

  update public.tickets
  set status = 'checked_in', scanned_at = now(), scanned_by = auth.uid(), check_in_method = 'manual'
  where id = v_ticket.id
  returning * into v_ticket;

  return jsonb_build_object('ok', true, 'code', 'ok',
    'ticket_id', v_ticket.id, 'passenger_name', v_ticket.passenger_name,
    'scanned_at', v_ticket.scanned_at);
end;
$$;

revoke execute on function public.check_in_manually(uuid) from public, anon;
grant execute on function public.check_in_manually(uuid) to authenticated;

-- ─── 4) Rehberin kalkışları ──────────────────────────────────────────────────
-- Planlanmış ve bitirme talebi bekleyen tarihler + son 2 günde tamamlananlar.
-- Tur satıştan kaldırılmış olsa da rehber atandığı tarihi görür (tur adı buradan gelir).

create or replace function public.guide_departures()
returns table (
  id uuid,
  tour_id uuid,
  tour_title text,
  company_name text,
  departure_at timestamptz,
  status public.departure_status,
  capacity integer,
  bus_plate text,
  driver_name text,
  driver_phone text,
  ticket_count integer,
  checked_in_count integer,
  last_request_status public.completion_status
)
language sql stable security definer set search_path = ''
as $$
  select d.id, d.tour_id, t.title, c.name, d.departure_at, d.status, d.capacity,
         d.bus_plate, d.driver_name, d.driver_phone,
         (select count(*)::int from public.tickets k
          where k.departure_id = d.id and k.status <> 'cancelled'),
         (select count(*)::int from public.tickets k
          where k.departure_id = d.id and k.status in ('checked_in', 'completed')),
         (select r.status from public.completion_requests r
          where r.departure_id = d.id order by r.created_at desc limit 1)
  from public.tour_departures d
  join public.tours t on t.id = d.tour_id
  join public.companies c on c.id = d.company_id
  where public.current_user_role() = 'guide'
    and d.guide_id = auth.uid()
    and (d.status in ('scheduled', 'finish_requested')
         or (d.status = 'completed' and d.departure_at > now() - interval '2 days'))
  order by d.departure_at;
$$;

revoke execute on function public.guide_departures() from public, anon;
grant execute on function public.guide_departures() to authenticated;
