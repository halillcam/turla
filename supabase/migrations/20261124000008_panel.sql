-- =============================================================================
-- Turla: web paneli (Faz 2)
--
-- 1) Pasif şirketin admini şirketi yönetemez (can_manage_company).
-- 2) save_tour_program: gün gün programı tek transaction içinde kaydeder.
-- 3) set_profile_active: hesabı aktif/pasif yapar (rol ve şirket kuralıyla).
--
-- Hesap açma (firma admini, rehber, dışarıdan müşteri) Edge Function ile
-- yapılır: supabase/functions/create-account. Rol ve şirket app_metadata'ya
-- yazılır, profil handle_new_user tetikleyicisiyle oluşur.
-- =============================================================================

-- ─── 1) Pasif şirket yönetilemez ─────────────────────────────────────────────
-- Super admin şirketi pasife aldığında o şirketin admini tur, tarih, personel
-- ve onay işlemi yapamaz. Super admin her şirketi yönetmeye devam eder.

create or replace function public.can_manage_company(p_company_id uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select public.is_super_admin()
      or (
        public.current_user_role() = 'admin'
        and public.current_company_id() = p_company_id
        and exists (select 1 from public.companies c where c.id = p_company_id and c.is_active)
      );
$$;

-- ─── 2) Tur programı kaydetme ────────────────────────────────────────────────
-- p_days: [{ "title": "...", "activities": ["...", "..."] }, ...]
-- Gün numarası dizideki sıradır (1'den başlar). Önceki program silinip yenisi
-- yazılır; boş aktiviteler atılır. security invoker: tablo politikaları
-- (program_insert / program_delete) geçerlidir.

create or replace function public.save_tour_program(p_tour_id uuid, p_days jsonb)
returns setof public.tour_program_days
language plpgsql security invoker set search_path = ''
as $$
begin
  if not exists (
    select 1 from public.tours t
    where t.id = p_tour_id and public.can_manage_company(t.company_id)
  ) then
    raise exception 'not_allowed';
  end if;
  if p_days is null or jsonb_typeof(p_days) <> 'array' then
    raise exception 'invalid_program';
  end if;

  delete from public.tour_program_days where tour_id = p_tour_id;

  return query
  insert into public.tour_program_days (tour_id, day_no, title, activities, sort_order)
  select
    p_tour_id,
    x.ord::smallint,
    coalesce(trim(x.day ->> 'title'), ''),
    coalesce(
      array(
        select trim(a.value)
        from jsonb_array_elements_text(
          case when jsonb_typeof(x.day -> 'activities') = 'array'
               then x.day -> 'activities' else '[]'::jsonb end
        ) as a(value)
        where trim(a.value) <> ''
      ),
      '{}'
    ),
    x.ord::smallint
  from jsonb_array_elements(p_days) with ordinality as x(day, ord)
  returning *;
end;
$$;

revoke execute on function public.save_tour_program(uuid, jsonb) from public, anon;
grant execute on function public.save_tour_program(uuid, jsonb) to authenticated;

-- ─── 3) Hesap aktif / pasif ──────────────────────────────────────────────────
-- Super admin: super admin dışındaki tüm hesaplar.
-- Şirket admini: kendi şirketinin rehber ve müşteri hesapları.
-- Kimse kendi hesabını değiştiremez. Pasif hesap giriş yapamaz ve
-- current_user_role() null döndüğü için hiçbir yetkisi kalmaz.

create or replace function public.set_profile_active(p_profile_id uuid, p_active boolean)
returns public.profiles
language plpgsql security definer set search_path = ''
as $$
declare
  v_profile public.profiles;
begin
  select * into v_profile from public.profiles where id = p_profile_id for update;
  if v_profile.id is null then
    raise exception 'profile_not_found';
  end if;
  if v_profile.id = auth.uid() then
    raise exception 'cannot_change_self';
  end if;
  if v_profile.role = 'super_admin' then
    raise exception 'not_allowed';
  end if;
  if not (
    public.is_super_admin()
    or (
      v_profile.role in ('guide', 'customer')
      and v_profile.company_id is not null
      and public.can_manage_company(v_profile.company_id)
    )
  ) then
    raise exception 'not_allowed';
  end if;

  update public.profiles set is_active = p_active where id = v_profile.id
  returning * into v_profile;

  return v_profile;
end;
$$;

revoke execute on function public.set_profile_active(uuid, boolean) from public, anon;
grant execute on function public.set_profile_active(uuid, boolean) to authenticated;
