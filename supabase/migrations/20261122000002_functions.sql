-- =============================================================================
-- Turla: yardımcı fonksiyonlar, tetikleyiciler ve iş kuralı fonksiyonları (RPC)
--
-- Kritik işlemler (bilet alma, iptal/iade, QR okutma, tur bitirme) burada,
-- tek transaction içinde yapılır. İstemci bu tablolara doğrudan yazamaz.
--
-- Hata kodları: fonksiyonlar `raise exception '<kod>'` ile sabit bir kod
-- döndürür; uygulama bu kodu kullanıcı mesajına çevirir.
-- =============================================================================

-- ─── Oturumdaki kullanıcı bilgisi ────────────────────────────────────────────
-- security definer: RLS politikaları içinden profiles tablosunu okurken
-- sonsuz döngüye girmemek için.

create or replace function public.current_user_role()
returns public.user_role
language sql stable security definer set search_path = ''
as $$
  select p.role from public.profiles p where p.id = auth.uid() and p.is_active;
$$;

create or replace function public.current_company_id()
returns uuid
language sql stable security definer set search_path = ''
as $$
  select p.company_id from public.profiles p where p.id = auth.uid() and p.is_active;
$$;

create or replace function public.is_super_admin()
returns boolean
language sql stable security definer set search_path = ''
as $$
  select coalesce(public.current_user_role() = 'super_admin', false);
$$;

-- Oturumdaki kullanıcı bu şirketin admini mi (veya super admin mi)?
create or replace function public.can_manage_company(p_company_id uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select public.is_super_admin()
      or (public.current_user_role() = 'admin' and public.current_company_id() = p_company_id);
$$;

-- Oturumdaki kullanıcı bu tarihin rehberi mi?
create or replace function public.is_departure_guide(p_departure_id uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.tour_departures d
    where d.id = p_departure_id
      and d.guide_id = auth.uid()
      and public.current_user_role() = 'guide'
  );
$$;

-- Oturumdaki kullanıcı bu tarihte QR'ı okutulmuş bir katılımcı mı?
create or replace function public.is_checked_in_participant(p_departure_id uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.tickets t
    where t.departure_id = p_departure_id
      and t.user_id = auth.uid()
      and t.status in ('checked_in', 'completed')
  );
$$;

-- ─── updated_at ──────────────────────────────────────────────────────────────

create or replace function public.set_updated_at()
returns trigger
language plpgsql set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger companies_updated_at before update on public.companies
  for each row execute function public.set_updated_at();
create trigger profiles_updated_at before update on public.profiles
  for each row execute function public.set_updated_at();
create trigger tours_updated_at before update on public.tours
  for each row execute function public.set_updated_at();
create trigger departures_updated_at before update on public.tour_departures
  for each row execute function public.set_updated_at();
create trigger tickets_updated_at before update on public.tickets
  for each row execute function public.set_updated_at();
create trigger feedbacks_updated_at before update on public.feedbacks
  for each row execute function public.set_updated_at();

-- ─── Yeni kullanıcı → profil ─────────────────────────────────────────────────
-- Rol ve şirket SADECE app_metadata'dan okunur. app_metadata'yı yalnızca
-- sunucu (service role / Edge Function) yazabilir; kullanıcı kayıt olurken
-- kendine admin rolü veremez. Normal kayıt her zaman 'customer' olur.

create or replace function public.handle_new_user()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  insert into public.profiles (id, role, company_id, full_name, login_id)
  values (
    new.id,
    coalesce((new.raw_app_meta_data ->> 'role')::public.user_role, 'customer'),
    (new.raw_app_meta_data ->> 'company_id')::uuid,
    coalesce(nullif(trim(new.raw_user_meta_data ->> 'full_name'), ''), ''),
    nullif(trim(new.raw_app_meta_data ->> 'login_id'), '')
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ─── Tur tarihi kuralları ────────────────────────────────────────────────────

create or replace function public.departures_before_write()
returns trigger
language plpgsql security definer set search_path = ''
as $$
declare
  v_guide public.profiles;
begin
  if tg_op = 'INSERT' then
    select t.company_id into new.company_id from public.tours t where t.id = new.tour_id;
    new.seats_left := new.capacity;
  else
    if new.tour_id <> old.tour_id or new.company_id <> old.company_id then
      raise exception 'departure_owner_change_not_allowed';
    end if;
    -- Kontenjan değişirse boş koltuk sayısı aynı farkla güncellenir.
    if new.capacity <> old.capacity then
      new.seats_left := old.seats_left + (new.capacity - old.capacity);
      if new.seats_left < 0 then
        raise exception 'capacity_below_sold_seats';
      end if;
    end if;
  end if;

  -- Rehber, aynı şirketin aktif bir rehberi olmalı (sadece atama değişince kontrol edilir;
  -- böylece koltuk sayısı güncellemeleri sonradan pasifleşen bir rehber yüzünden bozulmaz).
  if new.guide_id is not null
     and (tg_op = 'INSERT' or new.guide_id is distinct from old.guide_id) then
    select * into v_guide from public.profiles p where p.id = new.guide_id;
    if v_guide.id is null or v_guide.role <> 'guide' or not v_guide.is_active
       or v_guide.company_id is distinct from new.company_id then
      raise exception 'invalid_guide';
    end if;
  end if;

  return new;
end;
$$;

create trigger departures_before_write
  before insert or update on public.tour_departures
  for each row execute function public.departures_before_write();

-- ─── Mesaj gönderen adı ──────────────────────────────────────────────────────
-- Gönderen adı istemciden alınmaz, profilden yazılır (başkası adına yazılamaz).

create or replace function public.messages_before_insert()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  new.sender_id := auth.uid();
  select coalesce(nullif(p.full_name, ''), 'Katılımcı') into new.sender_name
  from public.profiles p where p.id = auth.uid();
  return new;
end;
$$;

create trigger messages_before_insert
  before insert on public.messages
  for each row execute function public.messages_before_insert();

-- ─── Duyuru → katılımcı bildirimleri ─────────────────────────────────────────
-- Duyuru sadece QR'ı okutulmuş katılımcılara dağıtılır.

create or replace function public.announcements_fanout()
returns trigger
language plpgsql security definer set search_path = ''
as $$
declare
  v_title text;
begin
  select t.title into v_title
  from public.tour_departures d join public.tours t on t.id = d.tour_id
  where d.id = new.departure_id;

  insert into public.notifications (user_id, title, body, departure_id, announcement_id)
  select distinct tk.user_id, coalesce(v_title, 'Tur duyurusu'), new.body, new.departure_id, new.id
  from public.tickets tk
  where tk.departure_id = new.departure_id
    and tk.status = 'checked_in';

  return new;
end;
$$;

create trigger announcements_fanout
  after insert on public.announcements
  for each row execute function public.announcements_fanout();

create or replace function public.announcements_before_insert()
returns trigger
language plpgsql set search_path = ''
as $$
begin
  new.sender_id := auth.uid();
  return new;
end;
$$;

create trigger announcements_before_insert
  before insert on public.announcements
  for each row execute function public.announcements_before_insert();

-- =============================================================================
-- İş kuralı fonksiyonları (uygulamadan supabase.rpc(...) ile çağrılır)
-- =============================================================================

-- ─── Bilet satın alma (demo ödeme) ───────────────────────────────────────────
-- Satırı kilitleyerek kontenjanı düşürür: aynı anda iki kişi son koltuğu
-- alamaz. MVP'de ödeme demo olarak kaydedilir.

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

-- ─── Bilet iptali ve iade ────────────────────────────────────────────────────
-- Müşteri: kalkıştan en geç 1 saat öncesine kadar iptal edebilir.
-- Şirket admini: tur tamamlanmadıysa her zaman iptal edebilir.
-- Koltuk geri eklenir; ödeme varsa tutarın tamamı iade olarak kaydedilir.

create or replace function public.cancel_ticket(p_ticket_id uuid)
returns public.tickets
language plpgsql security definer set search_path = ''
as $$
declare
  v_ticket public.tickets;
  v_departure public.tour_departures;
  v_payment public.payments;
  v_is_owner boolean;
begin
  select * into v_ticket from public.tickets where id = p_ticket_id for update;
  if v_ticket.id is null then
    raise exception 'ticket_not_found';
  end if;

  v_is_owner := v_ticket.user_id = auth.uid();
  if not v_is_owner and not public.can_manage_company(v_ticket.company_id) then
    raise exception 'not_allowed';
  end if;

  if v_ticket.status not in ('reserved', 'paid') then
    raise exception 'ticket_not_cancellable';
  end if;

  select * into v_departure from public.tour_departures
  where id = v_ticket.departure_id
  for update;

  if v_departure.status in ('completed', 'cancelled') then
    raise exception 'ticket_not_cancellable';
  end if;
  if v_is_owner and not public.can_manage_company(v_ticket.company_id)
     and now() > v_departure.departure_at - interval '1 hour' then
    raise exception 'cancellation_window_closed';
  end if;

  update public.tickets
  set status = 'cancelled', cancelled_at = now()
  where id = v_ticket.id
  returning * into v_ticket;

  update public.tour_departures set seats_left = seats_left + 1 where id = v_departure.id;

  select * into v_payment from public.payments
  where ticket_id = v_ticket.id and type = 'payment';

  if v_payment.id is not null then
    insert into public.payments (ticket_id, company_id, type, method, amount, created_by)
    values (v_ticket.id, v_ticket.company_id, 'refund', v_payment.method, v_payment.amount, auth.uid());
  end if;

  return v_ticket;
end;
$$;

-- ─── QR okutma ───────────────────────────────────────────────────────────────
-- Sadece o tarihin rehberi (veya şirket admini) okutabilir. Bilet tek
-- kullanımlıktır. Sonuç JSON döner: { ok, code, ticket_id, passenger_name }
-- code: ok | not_found | wrong_departure | already_used | cancelled | not_paid

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
      'ticket_id', v_ticket.id, 'passenger_name', v_ticket.passenger_name);
  end if;
  if v_ticket.status = 'cancelled' then
    return jsonb_build_object('ok', false, 'code', 'cancelled');
  end if;
  if v_ticket.status <> 'paid' then
    return jsonb_build_object('ok', false, 'code', 'not_paid');
  end if;

  update public.tickets
  set status = 'checked_in', scanned_at = now(), scanned_by = auth.uid()
  where id = v_ticket.id;

  return jsonb_build_object('ok', true, 'code', 'ok',
    'ticket_id', v_ticket.id, 'passenger_name', v_ticket.passenger_name);
end;
$$;

-- ─── Turu bitir talebi (rehber) ──────────────────────────────────────────────

create or replace function public.request_departure_completion(p_departure_id uuid)
returns public.completion_requests
language plpgsql security definer set search_path = ''
as $$
declare
  v_departure public.tour_departures;
  v_request public.completion_requests;
begin
  if not public.is_departure_guide(p_departure_id) then
    raise exception 'not_allowed';
  end if;

  select * into v_departure from public.tour_departures where id = p_departure_id for update;

  if v_departure.status <> 'scheduled' then
    raise exception 'departure_not_active';
  end if;
  if v_departure.departure_at > now() then
    raise exception 'departure_not_started';
  end if;

  update public.tour_departures set status = 'finish_requested' where id = v_departure.id;

  insert into public.completion_requests (departure_id, company_id, guide_id)
  values (v_departure.id, v_departure.company_id, auth.uid())
  returning * into v_request;

  return v_request;
end;
$$;

-- ─── Turu bitir onayı / reddi (şirket admini) ────────────────────────────────
-- Onay: SADECE bu tarih kapanır. QR'ı okutulanlar 'completed', okutulmayanlar
-- 'no_show' olur. Ret: tarih yeniden aktif olur.

create or replace function public.review_departure_completion(p_request_id uuid, p_approve boolean)
returns public.completion_requests
language plpgsql security definer set search_path = ''
as $$
declare
  v_request public.completion_requests;
begin
  select * into v_request from public.completion_requests where id = p_request_id for update;
  if v_request.id is null then
    raise exception 'request_not_found';
  end if;
  if not public.can_manage_company(v_request.company_id) then
    raise exception 'not_allowed';
  end if;
  if v_request.status <> 'pending' then
    raise exception 'request_already_reviewed';
  end if;

  if p_approve then
    update public.tour_departures set status = 'completed' where id = v_request.departure_id;

    update public.tickets set status = 'completed'
    where departure_id = v_request.departure_id and status = 'checked_in';

    update public.tickets set status = 'no_show'
    where departure_id = v_request.departure_id and status in ('reserved', 'paid');
  else
    update public.tour_departures set status = 'scheduled' where id = v_request.departure_id;
  end if;

  update public.completion_requests
  set status = case when p_approve then 'approved'::public.completion_status
                    else 'rejected'::public.completion_status end,
      reviewed_by = auth.uid(),
      reviewed_at = now()
  where id = v_request.id
  returning * into v_request;

  return v_request;
end;
$$;

-- ─── Çalıştırma yetkileri ────────────────────────────────────────────────────
-- İş kuralı fonksiyonları sadece giriş yapmış kullanıcılar tarafından çağrılabilir.

revoke execute on function public.book_ticket(uuid, text, text) from public, anon;
revoke execute on function public.cancel_ticket(uuid) from public, anon;
revoke execute on function public.scan_ticket(uuid, text) from public, anon;
revoke execute on function public.request_departure_completion(uuid) from public, anon;
revoke execute on function public.review_departure_completion(uuid, boolean) from public, anon;

grant execute on function public.book_ticket(uuid, text, text) to authenticated;
grant execute on function public.cancel_ticket(uuid) to authenticated;
grant execute on function public.scan_ticket(uuid, text) to authenticated;
grant execute on function public.request_departure_completion(uuid) to authenticated;
grant execute on function public.review_departure_completion(uuid, boolean) to authenticated;

-- Tetikleyici fonksiyonları doğrudan çağrılamaz.
revoke execute on function public.handle_new_user() from public, anon, authenticated;
