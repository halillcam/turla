-- =============================================================================
-- Turla: demo verisi (geliştirme ve sunum için)
--
-- "Maraş Doğa Turizm (Demo)" firması ve Kahramanmaraş'tan kalkan 5 tur ekler.
-- Kalkış tarihleri çalıştırıldığı güne göre ileri tarihli oluşturulur.
-- Tekrar çalıştırmadan önce aşağıdaki temizleme komutunu çalıştırın.
--
-- Temizlemek için (turlar, tarihler ve programlar da silinir):
--   delete from public.companies where name = 'Maraş Doğa Turizm (Demo)';
-- =============================================================================

do $$
declare
  v_company uuid;
  v_tour uuid;
  v_day date := (now() at time zone 'Europe/Istanbul')::date;
begin
  insert into public.companies (name, city_id, phone)
  values ('Maraş Doğa Turizm (Demo)', 46, '0344 000 00 00')
  returning id into v_company;

  -- 1) Kapadokya
  insert into public.tours (company_id, title, description, extra_detail, price, city_id, region)
  values (
    v_company,
    'Kapadokya Turu (2 Gün)',
    'Peri bacaları, yeraltı şehirleri ve Göreme Açık Hava Müzesi. Sabah erken saatte '
      || 'Kahramanmaraş''tan hareket edilir, geceleme Ürgüp''te taş otelde yapılır.',
    'Fiyata ulaşım, 1 gece konaklama, sabah kahvaltısı ve rehberlik dahildir. '
      || 'Balon turu ve müze girişleri fiyata dahil değildir.',
    1850, 46, 'ic_anadolu'
  ) returning id into v_tour;
  insert into public.tour_departures (tour_id, departure_at, capacity, bus_plate, driver_name)
  values
    (v_tour, ((v_day + 5) + time '07:00') at time zone 'Europe/Istanbul', 40, '46 ABC 101', 'Mehmet Kaya'),
    (v_tour, ((v_day + 12) + time '07:00') at time zone 'Europe/Istanbul', 40, '46 ABC 101', 'Mehmet Kaya'),
    (v_tour, ((v_day + 19) + time '07:00') at time zone 'Europe/Istanbul', 40, '46 ABC 101', 'Mehmet Kaya');
  insert into public.tour_program_days (tour_id, day_no, title, activities, sort_order) values
    (v_tour, 1, 'Göreme ve Uçhisar', array[
      '07:00 Kahramanmaraş çıkış', 'Derinkuyu Yeraltı Şehri', 'Göreme Açık Hava Müzesi',
      'Uçhisar Kalesi''nde gün batımı', 'Ürgüp''te otele yerleşme'], 1),
    (v_tour, 2, 'Vadiler ve dönüş', array[
      'Kahvaltı', 'Paşabağ ve Devrent vadileri', 'Avanos''ta çömlek atölyesi',
      '16:00 dönüş yolculuğu'], 2);

  -- 2) Nemrut
  insert into public.tours (company_id, title, description, extra_detail, price, city_id, region)
  values (
    v_company,
    'Nemrut Dağı Gün Doğumu',
    'Gece yola çıkılır, Nemrut Dağı''nın zirvesinde dev heykellerin arasında gün doğumu izlenir. '
      || 'Dönüşte Cendere Köprüsü ve Arsameia ziyaret edilir.',
    'Zirvede hava soğuk olur; kalın mont getirmeniz önerilir. Kahvaltı paketi verilir.',
    1200, 46, 'guneydogu_anadolu'
  ) returning id into v_tour;
  insert into public.tour_departures (tour_id, departure_at, capacity, bus_plate, driver_name)
  values
    (v_tour, ((v_day + 8) + time '23:30') at time zone 'Europe/Istanbul', 30, '46 DEF 202', 'Ali Demir');
  insert into public.tour_program_days (tour_id, day_no, title, activities, sort_order) values
    (v_tour, 1, 'Zirve ve gün doğumu', array[
      '23:30 Kahramanmaraş çıkış', '05:30 Nemrut zirvesinde gün doğumu', 'Kahvaltı molası',
      'Cendere Köprüsü ve Arsameia', '14:00 dönüş'], 1);

  -- 3) Yerköprü Şelalesi
  insert into public.tours (company_id, title, description, extra_detail, price, city_id, region)
  values (
    v_company,
    'Göksun Yerköprü Şelalesi',
    'Kahramanmaraş''ın saklı cennetlerinden Yerköprü Şelalesi ve çevresinde doğa yürüyüşü. '
      || 'Öğle yemeği şelale kenarında alabalık.',
    'Rahat yürüyüş ayakkabısı önerilir. Öğle yemeği fiyata dahildir.',
    450, 46, 'gunubirlik'
  ) returning id into v_tour;
  insert into public.tour_departures (tour_id, departure_at, capacity, bus_plate, driver_name)
  values
    (v_tour, ((v_day + 3) + time '08:30') at time zone 'Europe/Istanbul', 25, '46 GHI 303', 'Hasan Yıldız'),
    (v_tour, ((v_day + 10) + time '08:30') at time zone 'Europe/Istanbul', 25, '46 GHI 303', 'Hasan Yıldız');
  insert into public.tour_program_days (tour_id, day_no, title, activities, sort_order) values
    (v_tour, 1, 'Şelale ve yürüyüş', array[
      '08:30 Kahramanmaraş çıkış', 'Yerköprü Şelalesi', 'Doğa yürüyüşü (yaklaşık 2 saat)',
      'Alabalık öğle yemeği', '17:00 dönüş'], 1);

  -- 4) Doğu Karadeniz
  insert into public.tours (company_id, title, description, extra_detail, price, city_id, region)
  values (
    v_company,
    'Karadeniz Yaylaları (4 Gün)',
    'Uzungöl, Ayder ve Pokut yaylaları, Sümela Manastırı ve Rize''de çay bahçeleri.',
    'Fiyata ulaşım, 3 gece konaklama, sabah ve akşam yemekleri dahildir.',
    6500, 46, 'dogu_karadeniz'
  ) returning id into v_tour;
  insert into public.tour_departures (tour_id, departure_at, capacity, bus_plate, driver_name)
  values
    (v_tour, ((v_day + 20) + time '21:00') at time zone 'Europe/Istanbul', 35, '46 JKL 404', 'Mehmet Kaya');
  insert into public.tour_program_days (tour_id, day_no, title, activities, sort_order) values
    (v_tour, 1, 'Yolculuk ve Sümela', array['Gece yolculuğu', 'Sümela Manastırı', 'Trabzon''da konaklama'], 1),
    (v_tour, 2, 'Uzungöl', array['Uzungöl çevresinde serbest zaman', 'Rize''de çay bahçesi'], 2),
    (v_tour, 3, 'Ayder ve Pokut', array['Ayder Yaylası', 'Pokut Yaylası''nda gün batımı'], 3),
    (v_tour, 4, 'Dönüş', array['Kahvaltı', 'Dönüş yolculuğu'], 4);

  -- 5) Gaziantep
  insert into public.tours (company_id, title, description, extra_detail, price, city_id, region)
  values (
    v_company,
    'Gaziantep Lezzet Turu',
    'Zeugma Mozaik Müzesi, Bakırcılar Çarşısı ve şehrin en bilinen lezzet durakları.',
    'Müze girişi ve tadımlar fiyata dahildir.',
    600, 46, 'gunubirlik'
  ) returning id into v_tour;
  insert into public.tour_departures (tour_id, departure_at, capacity, bus_plate, driver_name)
  values
    (v_tour, ((v_day + 6) + time '08:00') at time zone 'Europe/Istanbul', 30, '46 MNO 505', 'Ali Demir'),
    (v_tour, ((v_day + 13) + time '08:00') at time zone 'Europe/Istanbul', 30, '46 MNO 505', 'Ali Demir');
  insert into public.tour_program_days (tour_id, day_no, title, activities, sort_order) values
    (v_tour, 1, 'Müze ve lezzet durakları', array[
      '08:00 Kahramanmaraş çıkış', 'Zeugma Mozaik Müzesi', 'Bakırcılar Çarşısı',
      'Beyran ve katmer tadımı', 'Baklava atölyesi', '18:00 dönüş'], 1);
end $$;
