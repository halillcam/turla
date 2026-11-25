-- =============================================================================
-- Turla: bilet satın alma, Turlarım ve panelden bilet (Faz 3)
--
-- 1) Bilet sahibi, biletinin turunu / tarihini / firmasını her zaman görür
--    (tur satıştan kaldırılsa, tarih tamamlansa veya firma pasife alınsa bile).
-- 2) Aynı kişi aynı tarihe ikinci geçerli bilet alamaz (yolcu = hesap sahibi).
-- 3) admin_issue_ticket: firma admini, firmanın dışarıdan eklediği müşteriye
--    panelden bilet keser; ödeme 'manual' (elden / havale) kaydedilir.
-- =============================================================================

-- ─── 1) Bilet sahibinin okuma yetkisi ────────────────────────────────────────
-- security definer: politikalar birbirini çağırırken (tours ↔ tour_departures)
-- sonsuz döngü olmaması ve misafirin tickets tablosuna yetkisi olmaması için.

create or replace function public.has_ticket_on_departure(p_departure_id uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select auth.uid() is not null and exists (
    select 1 from public.tickets t
    where t.departure_id = p_departure_id and t.user_id = auth.uid()
  );
$$;

create or replace function public.has_ticket_on_tour(p_tour_id uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select auth.uid() is not null and exists (
    select 1 from public.tickets t
    join public.tour_departures d on d.id = t.departure_id
    where d.tour_id = p_tour_id and t.user_id = auth.uid()
  );
$$;

create or replace function public.has_ticket_with_company(p_company_id uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select auth.uid() is not null and exists (
    select 1 from public.tickets t
    where t.company_id = p_company_id and t.user_id = auth.uid()
  );
$$;

grant execute on function public.has_ticket_on_departure(uuid) to anon, authenticated;
grant execute on function public.has_ticket_on_tour(uuid) to anon, authenticated;
grant execute on function public.has_ticket_with_company(uuid) to anon, authenticated;

alter policy companies_read on public.companies using (
  is_active or public.can_manage_company(id) or public.has_ticket_with_company(id)
);

alter policy tours_read on public.tours using (
  (is_active and exists (select 1 from public.companies c where c.id = company_id and c.is_active))
  or public.can_manage_company(company_id)
  or public.has_ticket_on_tour(id)
);

alter policy departures_read on public.tour_departures using (
  exists (select 1 from public.tours t where t.id = tour_id)   -- tours_read uygulanır
  or guide_id = (select auth.uid())
  or public.has_ticket_on_departure(id)
);

-- ─── 2) Bilet satın alma: aynı tarihe tek geçerli bilet ──────────────────────

create or replace function public.book_ticket(
  p_departure_id uuid,
  p_passenger_name text,
  p_tc_no text default null
)
returns public.tickets
language plpgsql security definer set search_path = ''
as $$
declare
  v_departure public.tour_departures;
  v_tour public.tours;
  v_ticket public.tickets;
begin
  if auth.uid() is null or public.current_user_role() is distinct from 'customer' then
    raise exception 'only_customers_can_book';
  end if;

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
    departure_id, company_id, user_id, passenger_name, tc_no,
    price_paid, status, source, qr_token
  ) values (
    v_departure.id, v_departure.company_id, auth.uid(), trim(p_passenger_name), nullif(trim(p_tc_no), ''),
    v_tour.price, 'paid', 'app', encode(extensions.gen_random_bytes(24), 'hex')
  )
  returning * into v_ticket;

  if v_tour.price > 0 then
    insert into public.payments (ticket_id, company_id, type, method, amount, created_by)
    values (v_ticket.id, v_ticket.company_id, 'payment', 'demo', v_tour.price, auth.uid());
  end if;

  return v_ticket;
end;
$$;

-- ─── 3) Panelden bilet kesme ─────────────────────────────────────────────────
-- Sadece şirket admini (veya super admin), sadece o şirketin panelden açılmış
-- aktif müşterisine. Tur satışa kapalı olsa da kesilebilir (firma kararı);
-- tarih planlanmış ve ileri tarihli olmalı, koltuk olmalı.

create or replace function public.admin_issue_ticket(
  p_departure_id uuid,
  p_customer_id uuid,
  p_passenger_name text default null
)
returns public.tickets
language plpgsql security definer set search_path = ''
as $$
declare
  v_departure public.tour_departures;
  v_customer public.profiles;
  v_price numeric(10, 2);
  v_ticket public.tickets;
begin
  select * into v_departure from public.tour_departures
  where id = p_departure_id
  for update;

  if v_departure.id is null then
    raise exception 'departure_not_found';
  end if;
  if not public.can_manage_company(v_departure.company_id) then
    raise exception 'not_allowed';
  end if;

  select * into v_customer from public.profiles where id = p_customer_id;
  if v_customer.id is null or v_customer.role <> 'customer' or not v_customer.is_active
     or v_customer.company_id is distinct from v_departure.company_id then
    raise exception 'invalid_customer';
  end if;

  if v_departure.status <> 'scheduled' or v_departure.departure_at <= now() then
    raise exception 'departure_not_bookable';
  end if;
  if exists (
    select 1 from public.tickets t
    where t.departure_id = v_departure.id and t.user_id = v_customer.id
      and t.status in ('reserved', 'paid', 'checked_in')
  ) then
    raise exception 'already_has_ticket';
  end if;
  if v_departure.seats_left <= 0 then
    raise exception 'no_seats_left';
  end if;

  select t.price into v_price from public.tours t where t.id = v_departure.tour_id;

  update public.tour_departures set seats_left = seats_left - 1 where id = v_departure.id;

  insert into public.tickets (
    departure_id, company_id, user_id, passenger_name,
    price_paid, status, source, qr_token
  ) values (
    v_departure.id, v_departure.company_id, v_customer.id,
    coalesce(nullif(trim(p_passenger_name), ''), v_customer.full_name),
    v_price, 'paid', 'panel', encode(extensions.gen_random_bytes(24), 'hex')
  )
  returning * into v_ticket;

  if v_price > 0 then
    insert into public.payments (ticket_id, company_id, type, method, amount, created_by)
    values (v_ticket.id, v_ticket.company_id, 'payment', 'manual', v_price, auth.uid());
  end if;

  return v_ticket;
end;
$$;

revoke execute on function public.admin_issue_ticket(uuid, uuid, text) from public, anon;
grant execute on function public.admin_issue_ticket(uuid, uuid, text) to authenticated;
