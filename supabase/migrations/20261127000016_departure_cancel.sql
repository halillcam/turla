-- =============================================================================
-- Turla 16: panelden kalkış tarihi iptali (Faz 6)
--
-- cancel_departure(departure): firmanın yöneticisi (veya super admin) başlamamış bir
-- tarihi iptal eder. Tek işlemde:
--   * tarih 'cancelled' olur, boş koltuk kapasiteye döner;
--   * geçerli biletler (reserved / paid / checked_in) iptal edilir;
--   * her ödeme için tam iade kaydı yazılır (cancel_ticket ile aynı kural);
--   * bileti olan her hesaba bildirim düşer (push tetikleyicisi bunu telefona iletir).
-- Hata kodları: departure_not_found, not_allowed, departure_not_cancellable.
-- =============================================================================

create or replace function public.cancel_departure(p_departure_id uuid)
returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_departure public.tour_departures;
  v_title text;
  v_when text;
  v_cancelled int;
  v_refunded numeric(10, 2);
begin
  select * into v_departure from public.tour_departures where id = p_departure_id for update;
  if v_departure.id is null then
    raise exception 'departure_not_found';
  end if;
  if not public.can_manage_company(v_departure.company_id) then
    raise exception 'not_allowed';
  end if;
  if v_departure.status <> 'scheduled' or v_departure.departure_at <= now() then
    raise exception 'departure_not_cancellable';
  end if;

  select title into v_title from public.tours where id = v_departure.tour_id;
  v_when := to_char(v_departure.departure_at at time zone 'Europe/Istanbul', 'DD.MM.YYYY HH24:MI');

  with cancelled as (
    update public.tickets
    set status = 'cancelled', cancelled_at = now()
    where departure_id = v_departure.id and status in ('reserved', 'paid', 'checked_in')
    returning id, user_id, company_id
  ),
  refunds as (
    insert into public.payments (ticket_id, company_id, type, method, amount, created_by)
    select p.ticket_id, p.company_id, 'refund', p.method, p.amount, auth.uid()
    from public.payments p
    join cancelled c on c.id = p.ticket_id
    where p.type = 'payment'
    returning amount
  ),
  notified as (
    insert into public.notifications (user_id, title, body, departure_id)
    select distinct c.user_id,
      'Tur tarihi iptal edildi',
      v_title || ' · ' || v_when || ' tarihi firma tarafından iptal edildi. '
        || 'Ödediğin tutarın tamamı iade edilecek.',
      v_departure.id
    from cancelled c
    where c.user_id is not null
    returning 1
  )
  select (select count(*) from cancelled), coalesce((select sum(amount) from refunds), 0)
  into v_cancelled, v_refunded;

  update public.tour_departures
  set status = 'cancelled', seats_left = capacity
  where id = v_departure.id;

  return jsonb_build_object('cancelled_tickets', v_cancelled, 'refunded_total', v_refunded);
end;
$$;

revoke execute on function public.cancel_departure(uuid) from public, anon;
grant execute on function public.cancel_departure(uuid) to authenticated;
