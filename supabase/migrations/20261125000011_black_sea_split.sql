-- =============================================================================
-- Turla: Karadeniz bölgesi ikiye ayrıldı (Batı Karadeniz / Doğu Karadeniz)
--
-- Enum değeri silinemediği için 'karadeniz' yeniden adlandırılır: mevcut
-- Karadeniz turları (yaylalar, Uzungöl, Ayder) Doğu Karadeniz'e geçer.
-- Batı Karadeniz yeni değer olarak hemen önüne eklenir (liste sırası korunur).
-- =============================================================================

alter type public.tour_region rename value 'karadeniz' to 'dogu_karadeniz';
alter type public.tour_region add value if not exists 'bati_karadeniz' before 'dogu_karadeniz';
