-- =============================================================================
-- Turla: pg_net eklentisi public yerine extensions şemasında olsun (advisor 0014).
-- Migration 14 ilk uygulandığında eklenti public'e kurulmuştu; yeni kurulumda
-- 14 zaten extensions'a kurar ve bu dosya bir şey yapmaz. Fonksiyonlar her
-- durumda net şemasındadır (net.http_post), tetikleyici değişmez.
-- =============================================================================

do $$
begin
  if exists (
    select 1 from pg_extension e join pg_namespace n on n.oid = e.extnamespace
    where e.extname = 'pg_net' and n.nspname = 'public'
  ) then
    drop extension pg_net;
    create extension pg_net with schema extensions;
  end if;
end;
$$;
