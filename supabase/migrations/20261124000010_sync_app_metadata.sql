-- =============================================================================
-- Turla: app_metadata → profil eşitlemesi
--
-- Sorun: Auth Admin API (create-account Edge Function) kullanıcıyı önce rol
-- bilgisi olmadan ekliyor, app_metadata'yı hemen ardından ayrı bir UPDATE ile
-- yazıyor. handle_new_user sadece INSERT'te çalıştığı için panelden açılan
-- hesaplar 'customer' ve şirketsiz kalıyordu.
--
-- Çözüm: app_metadata'daki rol / şirket / giriş kimliği değişince profil de
-- güncellenir. app_metadata'yı sadece sunucu (service role) yazabilir; kullanıcı
-- kendi user_metadata'sını değiştirse de rolü etkilenmez.
-- =============================================================================

create or replace function public.handle_user_app_metadata_update()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  update public.profiles
  set role = coalesce((new.raw_app_meta_data ->> 'role')::public.user_role, 'customer'),
      company_id = (new.raw_app_meta_data ->> 'company_id')::uuid,
      login_id = nullif(trim(new.raw_app_meta_data ->> 'login_id'), '')
  where id = new.id;
  return new;
end;
$$;

revoke execute on function public.handle_user_app_metadata_update() from public, anon, authenticated;

create trigger on_auth_user_app_metadata_updated
  after update of raw_app_meta_data on auth.users
  for each row
  when (
    (old.raw_app_meta_data ->> 'role') is distinct from (new.raw_app_meta_data ->> 'role')
    or (old.raw_app_meta_data ->> 'company_id') is distinct from (new.raw_app_meta_data ->> 'company_id')
    or (old.raw_app_meta_data ->> 'login_id') is distinct from (new.raw_app_meta_data ->> 'login_id')
  )
  execute function public.handle_user_app_metadata_update();

-- Bu düzeltmeden önce panelden açılıp yanlış kaydedilen profiller.
update public.profiles p
set role = (u.raw_app_meta_data ->> 'role')::public.user_role,
    company_id = (u.raw_app_meta_data ->> 'company_id')::uuid,
    login_id = nullif(trim(u.raw_app_meta_data ->> 'login_id'), '')
from auth.users u
where u.id = p.id
  and u.raw_app_meta_data ? 'role'
  and (
    p.role::text is distinct from (u.raw_app_meta_data ->> 'role')
    or p.company_id::text is distinct from (u.raw_app_meta_data ->> 'company_id')
    or p.login_id is distinct from nullif(trim(u.raw_app_meta_data ->> 'login_id'), '')
  );
