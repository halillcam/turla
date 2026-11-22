-- =============================================================================
-- Turla: dosya depolama (tur ve şirket görselleri)
--
-- Görseller yüklemeden önce istemcide küçültülür (en uzun kenar 1280 px).
-- Dosya yolu: <company_id>/<dosya_adı>  → admin sadece kendi şirket klasörüne yazar.
-- =============================================================================

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'tour-images',
  'tour-images',
  true,                                   -- herkes okuyabilir (tur listesi misafire açık)
  2097152,                                -- 2 MB üst sınır
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do nothing;

create policy tour_images_read on storage.objects
  for select using (bucket_id = 'tour-images');

create policy tour_images_insert on storage.objects
  for insert to authenticated with check (
    bucket_id = 'tour-images'
    and public.can_manage_company(((storage.foldername(name))[1])::uuid)
  );

create policy tour_images_update on storage.objects
  for update to authenticated using (
    bucket_id = 'tour-images'
    and public.can_manage_company(((storage.foldername(name))[1])::uuid)
  );

create policy tour_images_delete on storage.objects
  for delete to authenticated using (
    bucket_id = 'tour-images'
    and public.can_manage_company(((storage.foldername(name))[1])::uuid)
  );
