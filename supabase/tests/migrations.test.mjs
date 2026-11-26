// Turla migration'larını PGlite üzerinde Supabase benzeri stub'larla test eder.
// Kullanım: supabase/tests klasöründe `npm install` sonra `npm test`
import { readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath } from "node:url";
import { PGlite } from "@electric-sql/pglite";
import { pgcrypto } from "@electric-sql/pglite/contrib/pgcrypto";

const migDir = join(fileURLToPath(new URL(".", import.meta.url)), "..", "migrations");

const db = new PGlite({ extensions: { pgcrypto } });

// ─── Supabase stub'ları ────────────────────────────────────────────────────
await db.exec(`
  create role anon nologin;
  create role authenticated nologin;
  -- Edge Function'larin kullandigi rol: RLS'i atlar ama tablo yetkisi ister.
  create role service_role nologin bypassrls;
  create schema auth;
  create schema extensions;
  create schema storage;
  grant usage on schema public, auth, extensions, storage to anon, authenticated;
  create table auth.users (
    id uuid primary key default gen_random_uuid(),
    email text,
    raw_app_meta_data jsonb default '{}'::jsonb,
    raw_user_meta_data jsonb default '{}'::jsonb
  );
  create function auth.uid() returns uuid language sql stable as $$
    select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid
  $$;
  create table storage.buckets (id text primary key, name text, public boolean,
    file_size_limit bigint, allowed_mime_types text[]);
  create table storage.objects (id uuid primary key default gen_random_uuid(),
    bucket_id text, name text);
  alter table storage.objects enable row level security;
  grant all on storage.objects to anon, authenticated;
  create function storage.foldername(name text) returns text[] language sql immutable as $$
    select (string_to_array(name, '/'))[1:array_length(string_to_array(name, '/'), 1) - 1]
  $$;
  -- Yeni Supabase projelerinin varsayılan yetkileri (postgres rolü için):
  -- tablolarda anon/authenticated'a sadece TRUNCATE/REFERENCES/TRIGGER verilir,
  -- SELECT/INSERT/UPDATE/DELETE verilmez. Fonksiyonlar PUBLIC'e açıktır.
  alter default privileges in schema public grant truncate, references, trigger on tables to anon, authenticated;
  -- Realtime yayını ve pg_net taklidi (çağrılar tabloya yazılır).
  create publication supabase_realtime;
  create schema net;
  create table net.calls (url text, body jsonb, at timestamptz default now());
  create function net.http_post(url text, body jsonb default '{}'::jsonb, params jsonb default '{}'::jsonb,
    headers jsonb default '{}'::jsonb, timeout_milliseconds int default 5000) returns bigint
    language sql as $$ insert into net.calls (url, body) values (url, body) returning 1::bigint $$;
`);

for (const file of readdirSync(migDir).filter((f) => f.endsWith('.sql')).sort()) {
  try {
    await db.exec(readFileSync(join(migDir, file), 'utf8'));
    console.log('OK   migration', file);
  } catch (e) {
    console.log('FAIL migration', file, '→', e.message);
    process.exit(1);
  }
}

// ─── Yardımcılar ───────────────────────────────────────────────────────────
let failures = 0;
const asUser = async (uid, sql, params = []) => {
  await db.exec('reset role;');
  await db.query(`select set_config('request.jwt.claim.sub', $1, false)`, [uid ?? '']);
  await db.exec(uid ? 'set role authenticated;' : 'set role anon;');
  try {
    return await db.query(sql, params);
  } finally {
    await db.exec('reset role;');
  }
};
const expectOk = async (label, fn) => {
  try { const r = await fn(); console.log('PASS', label); return r; }
  catch (e) { failures++; console.log('FAIL', label, '→', e.message); }
};
const expectError = async (label, code, fn) => {
  try { await fn(); failures++; console.log('FAIL', label, '→ hata bekleniyordu:', code); }
  catch (e) {
    if (e.message.includes(code)) console.log('PASS', label, `(${code})`);
    else { failures++; console.log('FAIL', label, '→ beklenen', code, 'gelen', e.message); }
  }
};
const scalar = async (sql, params = []) => (await db.query(sql, params)).rows[0];

// ─── Bölgeler (migration 11) ─────────────────────────────────────────────
await expectOk('tour_region: Karadeniz Batı/Doğu olarak ayrıldı, sıra uygulamayla aynı', async () => {
  const r = await scalar(`select array_to_string(enum_range(null::public.tour_region), ',') v`);
  const expected = 'akdeniz,bati_karadeniz,dogu_karadeniz,marmara,ege,ic_anadolu,dogu_anadolu,guneydogu_anadolu,gunubirlik,yurtdisi';
  if (r.v !== expected) throw new Error(r.v);
});

// ─── Test verisi ───────────────────────────────────────────────────────────
const company = (await scalar(`insert into public.companies (name, city_id) values ('Maraş Turizm', 46) returning id`)).id;
const otherCompany = (await scalar(`insert into public.companies (name, city_id) values ('Başka Firma', 34) returning id`)).id;
const mkUser = async (role, companyId, name) => (await scalar(
  `insert into auth.users (raw_app_meta_data, raw_user_meta_data) values ($1, $2) returning id`,
  [JSON.stringify(role ? { role, company_id: companyId } : {}), JSON.stringify({ full_name: name })],
)).id;

const superAdmin = await mkUser('super_admin', null, 'Süper');
const admin = await mkUser('admin', company, 'Admin Ali');
const otherAdmin = await mkUser('admin', otherCompany, 'Başka Admin');
const guide = await mkUser('guide', company, 'Rehber Rıza');
const customer = await mkUser(null, null, 'Müşteri Mehmet');
const customer2 = await mkUser(null, null, 'Müşteri Ayşe');
// Kayıt olurken user_metadata ile rol yükseltme denemesi (app_metadata boş):
const sneaky = (await scalar(
  `insert into auth.users (raw_user_meta_data) values ('{"full_name":"Sinsi","role":"super_admin"}') returning id`,
)).id;

await expectOk('profil tetikleyicisi rolleri doğru atadı', async () => {
  const r = await scalar(`select
    (select role from public.profiles where id = $1) as c,
    (select role from public.profiles where id = $2) as a,
    (select role from public.profiles where id = $3) as s`, [customer, admin, sneaky]);
  if (r.c !== 'customer' || r.a !== 'admin' || r.s !== 'customer') throw new Error(JSON.stringify(r));
});

// Admin tur + tarih ekler
const tour = await expectOk('admin kendi şirketine tur ekler', async () => (await asUser(admin,
  `insert into public.tours (company_id, title, price, city_id, region)
   values ($1, 'Göksun Doğa Turu', 750.50, 46, 'akdeniz') returning id`, [company])).rows[0].id);

await expectError('admin başka şirkete tur ekleyemez', 'row-level security', () => asUser(admin,
  `insert into public.tours (company_id, title, price, city_id, region)
   values ($1, 'Yanlış', 10, 46, 'akdeniz')`, [otherCompany]));

const futureDep = await expectOk('admin tarih ekler (2 kişilik)', async () => (await asUser(admin,
  `insert into public.tour_departures (tour_id, departure_at, capacity, guide_id)
   values ($1, now() + interval '3 days', 2, $2) returning id, seats_left, company_id`, [tour, guide])).rows[0]);
if (futureDep && (futureDep.seats_left !== 2 || futureDep.company_id !== company)) {
  failures++; console.log('FAIL seats_left/company_id tetikleyicisi', futureDep);
}
const soonDep = (await scalar(`insert into public.tour_departures (tour_id, departure_at, capacity, guide_id)
  values ($1, now() + interval '30 minutes', 5, $2) returning id`, [tour, guide])).id;
const startedDep = (await scalar(`insert into public.tour_departures (tour_id, departure_at, capacity, guide_id)
  values ($1, now() - interval '1 hour', 5, $2) returning id`, [tour, guide])).id;

await expectError('admin seats_left alanını elle değiştiremez', 'permission denied', () => asUser(admin,
  `update public.tour_departures set seats_left = 99 where id = $1`, [futureDep.id]));

await expectOk('misafir (anon) turları ve tarihleri görür', async () => {
  const r = await asUser(null, `select count(*)::int n from public.tour_departures`);
  if (r.rows[0].n !== 3) throw new Error('görülen: ' + r.rows[0].n);
});

// Bilet alma
await expectError('misafir bilet alamaz', 'permission denied', () => asUser(null,
  `select public.book_ticket($1, 'Misafir')`, [futureDep.id]));
await expectError('admin uygulamadan bilet alamaz', 'only_customers_can_book', () => asUser(admin,
  `select public.book_ticket($1, 'Admin')`, [futureDep.id]));

const t1 = await expectOk('müşteri 1 bilet alır', async () => (await asUser(customer,
  `select * from public.book_ticket($1, 'Mehmet Yılmaz')`, [futureDep.id])).rows[0]);
const t2 = await expectOk('müşteri 2 son koltuğu alır', async () => (await asUser(customer2,
  `select * from public.book_ticket($1, 'Ayşe Kaya')`, [futureDep.id])).rows[0]);
const customer3 = await mkUser(null, null, 'Müşteri Can');
await expectError('kontenjan dolunca bilet satılmaz', 'no_seats_left', () => asUser(customer3,
  `select public.book_ticket($1, 'Fazla')`, [futureDep.id]));
await expectError('kalkmış tura bilet alınamaz', 'departure_not_bookable', () => asUser(customer,
  `select public.book_ticket($1, 'Geç')`, [startedDep]));

await expectOk('bilet durumu paid, QR 48 karakter, demo ödeme kaydı var', async () => {
  const r = await scalar(`select t.status, length(t.qr_token) l,
    (select count(*)::int from public.payments p where p.ticket_id = t.id and p.type='payment' and p.method='demo' and p.amount = 750.50) pay
    from public.tickets t where t.id = $1`, [t1.id]);
  if (r.status !== 'paid' || r.l !== 48 || r.pay !== 1) throw new Error(JSON.stringify(r));
});

await expectError('müşteri bileti doğrudan yazamaz', 'permission denied', () => asUser(customer,
  `update public.tickets set status = 'checked_in' where id = $1`, [t1.id]));

await expectOk('müşteri sadece kendi biletini görür', async () => {
  const r = await asUser(customer, `select count(*)::int n from public.tickets`);
  if (r.rows[0].n !== 1) throw new Error('görülen: ' + r.rows[0].n);
});
await expectOk('başka şirketin admini bilet göremez', async () => {
  const r = await asUser(otherAdmin, `select count(*)::int n from public.tickets`);
  if (r.rows[0].n !== 0) throw new Error('görülen: ' + r.rows[0].n);
});

// İptal + iade
await expectOk('müşteri 2 iptal eder → koltuk geri gelir, tam iade', async () => {
  await asUser(customer2, `select public.cancel_ticket($1)`, [t2.id]);
  const r = await scalar(`select (select seats_left from public.tour_departures where id=$1) s,
    (select amount from public.payments where ticket_id=$2 and type='refund') refund`, [futureDep.id, t2.id]);
  if (r.s !== 1 || r.refund !== '750.50') throw new Error(JSON.stringify(r));
});
await expectError('aynı bilet ikinci kez iptal edilemez', 'ticket_not_cancellable', () => asUser(customer2,
  `select public.cancel_ticket($1)`, [t2.id]));
await expectError('müşteri başkasının biletini iptal edemez', 'not_allowed', () => asUser(customer2,
  `select public.cancel_ticket($1)`, [t1.id]));

const soonTicket = (await asUser(customer, `select id from public.book_ticket($1, 'Mehmet Yılmaz')`, [soonDep])).rows[0].id;
await expectError('kalkışa 1 saatten az kala müşteri iptal edemez', 'cancellation_window_closed', () => asUser(customer,
  `select public.cancel_ticket($1)`, [soonTicket]));
await expectOk('admin son 1 saatte de iptal edebilir', () => asUser(admin, `select public.cancel_ticket($1)`, [soonTicket]));

// QR okutma
const qr1 = (await scalar(`select qr_token from public.tickets where id = $1`, [t1.id])).qr_token;
await expectError('müşteri QR okutamaz', 'not_allowed', () => asUser(customer,
  `select public.scan_ticket($1, $2)`, [futureDep.id, qr1]));
await expectOk('rehber QR okutur → ok + yolcu adı', async () => {
  const r = (await asUser(guide, `select public.scan_ticket($1, $2) r`, [futureDep.id, qr1])).rows[0].r;
  if (!r.ok || r.passenger_name !== 'Mehmet Yılmaz') throw new Error(JSON.stringify(r));
});
await expectOk('aynı QR ikinci kez → already_used', async () => {
  const r = (await asUser(guide, `select public.scan_ticket($1, $2) r`, [futureDep.id, qr1])).rows[0].r;
  if (r.code !== 'already_used') throw new Error(JSON.stringify(r));
});
await expectOk('başka tarihte okutma → wrong_departure', async () => {
  const r = (await asUser(guide, `select public.scan_ticket($1, $2) r`, [soonDep, qr1])).rows[0].r;
  if (r.code !== 'wrong_departure') throw new Error(JSON.stringify(r));
});
await expectError('QR okutulan bilet iptal edilemez', 'ticket_not_cancellable', () => asUser(customer,
  `select public.cancel_ticket($1)`, [t1.id]));

// Chat + duyuru
await expectOk('QR okutulan müşteri mesaj yazar, ad profilden gelir', async () => {
  await asUser(customer, `insert into public.messages (departure_id, sender_id, sender_name, body)
    values ($1, $2, 'Sahte Ad', 'Merhaba')`, [futureDep.id, customer]);
  const r = await scalar(`select sender_name from public.messages limit 1`);
  if (r.sender_name !== 'Müşteri Mehmet') throw new Error(JSON.stringify(r));
});
await expectError('QR okutmamış müşteri mesaj yazamaz', 'row-level security', () => asUser(customer2,
  `insert into public.messages (departure_id, sender_id, sender_name, body) values ($1, $2, 'x', 'selam')`,
  [futureDep.id, customer2]));
await expectOk('rehber duyuru gönderir → sadece QR okutanlara bildirim', async () => {
  await asUser(guide, `insert into public.announcements (departure_id, sender_id, body) values ($1, $2, 'Otobüs 10dk sonra kalkıyor')`,
    [futureDep.id, guide]);
  const r = await scalar(`select count(*)::int n, min(user_id::text) u from public.notifications`);
  if (r.n !== 1 || r.u !== customer) throw new Error(JSON.stringify(r));
});
await expectOk('müşteri kendi bildirimini görür', async () => {
  const r = await asUser(customer, `select count(*)::int n from public.notifications`);
  if (r.rows[0].n !== 1) throw new Error('görülen ' + r.rows[0].n);
});

// Profil güncelleme sınırları
await expectOk('müşteri adını güncelleyebilir', () => asUser(customer,
  `update public.profiles set full_name = 'Mehmet Y.' where id = $1`, [customer]));
await expectError('müşteri kendini admin yapamaz', 'permission denied', () => asUser(customer,
  `update public.profiles set role = 'admin' where id = $1`, [customer]));

// Tur bitirme
await expectError('kalkmamış tarih için bitiş talebi olmaz', 'departure_not_started', () => asUser(guide,
  `select public.request_departure_completion($1)`, [futureDep.id]));
const startedTicket = (await asUser(customer2, `select id from public.book_ticket($1, 'Ayşe Kaya')`, [soonDep])).rows[0].id;
const req = await expectOk('rehber başlamış tarih için bitiş talebi açar', async () =>
  (await asUser(guide, `select id from public.request_departure_completion($1)`, [startedDep])).rows[0].id);
await expectError('rehber ikinci talep açamaz', 'departure_not_active', () => asUser(guide,
  `select public.request_departure_completion($1)`, [startedDep]));
await expectError('başka şirket admini onaylayamaz', 'not_allowed', () => asUser(otherAdmin,
  `select public.review_departure_completion($1, true)`, [req]));
await expectOk('admin onaylar → sadece o tarih kapanır', async () => {
  await asUser(admin, `select public.review_departure_completion($1, true)`, [req]);
  const r = await scalar(`select
    (select status from public.tour_departures where id=$1) started,
    (select status from public.tour_departures where id=$2) future,
    (select status from public.tour_departures where id=$3) soon`, [startedDep, futureDep.id, soonDep]);
  if (r.started !== 'completed' || r.future !== 'scheduled' || r.soon !== 'scheduled') throw new Error(JSON.stringify(r));
});
void startedTicket;

// TRUNCATE RLS'i atlar; kapalı olmalı
await expectError('kullanıcı tabloyu TRUNCATE edemez', 'permission denied', () => asUser(customer,
  `truncate public.tickets cascade`));
await expectError('misafir tura yazamaz', 'permission denied', () => asUser(null,
  `insert into public.tours (company_id, title, price, city_id, region) values ($1, 'x', 1, 46, 'ege')`, [company]));

// Storage
await expectOk('admin kendi şirket klasörüne görsel yükler', () => asUser(admin,
  `insert into storage.objects (bucket_id, name) values ('tour-images', $1)`, [`${company}/kapak.jpg`]));
await expectError('admin başka şirket klasörüne yükleyemez', 'row-level security', () => asUser(admin,
  `insert into storage.objects (bucket_id, name) values ('tour-images', $1)`, [`${otherCompany}/kapak.jpg`]));

// ─── Web paneli (migration 8) ──────────────────────────────────────────────

// Tur programı
await expectOk('admin programı kaydeder: sıra = gün no, boş aktiviteler atılır', async () => {
  const days = [
    { title: ' Göksun ', activities: ['Kahvaltı', '  ', ' Yürüyüş '] },
    { title: 'Dönüş', activities: [] },
  ];
  await asUser(admin, `select * from public.save_tour_program($1, $2::jsonb)`, [tour, JSON.stringify(days)]);
  const r = (await db.query(`select day_no, title, activities from public.tour_program_days
    where tour_id = $1 order by day_no`, [tour])).rows;
  if (r.length !== 2 || r[0].day_no !== 1 || r[0].title !== 'Göksun'
      || JSON.stringify(r[0].activities) !== '["Kahvaltı","Yürüyüş"]' || r[1].day_no !== 2) {
    throw new Error(JSON.stringify(r));
  }
});
await expectOk('program yeniden kaydedilince eskisi silinir', async () => {
  await asUser(admin, `select * from public.save_tour_program($1, $2::jsonb)`,
    [tour, JSON.stringify([{ title: 'Tek gün', activities: ['Gezi'] }])]);
  const r = await scalar(`select count(*)::int n from public.tour_program_days where tour_id = $1`, [tour]);
  if (r.n !== 1) throw new Error('gün sayısı ' + r.n);
});
await expectError('başka şirket admini programı değiştiremez', 'not_allowed', () => asUser(otherAdmin,
  `select * from public.save_tour_program($1, '[]'::jsonb)`, [tour]));
await expectError('program dizi olmalı', 'invalid_program', () => asUser(admin,
  `select * from public.save_tour_program($1, '{}'::jsonb)`, [tour]));
await expectError('misafir program kaydedemez', 'permission denied', () => asUser(null,
  `select * from public.save_tour_program($1, '[]'::jsonb)`, [tour]));

// Hesap aktif / pasif
const guide2 = await mkUser('guide', company, 'Rehber Rana');
const otherGuide = await mkUser('guide', otherCompany, 'Başka Rehber');
await expectError('admin başka şirketin rehberini pasif yapamaz', 'not_allowed', () => asUser(admin,
  `select public.set_profile_active($1, false)`, [otherGuide]));
await expectError('admin başka bir admini pasif yapamaz', 'not_allowed', () => asUser(admin,
  `select public.set_profile_active($1, false)`, [otherAdmin]));
await expectError('kimse kendi hesabını pasif yapamaz', 'cannot_change_self', () => asUser(superAdmin,
  `select public.set_profile_active($1, false)`, [superAdmin]));
await expectError('rehber hesap durumu değiştiremez', 'not_allowed', () => asUser(guide,
  `select public.set_profile_active($1, false)`, [guide2]));
await expectOk('admin kendi rehberini pasif yapar → rehber yetkisini kaybeder', async () => {
  await asUser(admin, `select public.set_profile_active($1, false)`, [guide2]);
  const dep = (await scalar(`insert into public.tour_departures (tour_id, departure_at, capacity)
    values ($1, now() + interval '5 days', 3) returning id`, [tour])).id;
  await expectError('pasif rehber tarihe atanamaz', 'invalid_guide', () => asUser(admin,
    `update public.tour_departures set guide_id = $2 where id = $1`, [dep, guide2]));
  const r = await asUser(guide2, `select public.current_user_role() r`);
  if (r.rows[0].r !== null) throw new Error('rol: ' + r.rows[0].r);
  await asUser(admin, `select public.set_profile_active($1, true)`, [guide2]);
  await asUser(admin, `update public.tour_departures set guide_id = $2 where id = $1`, [dep, guide2]);
});
await expectOk('super admin firma adminini pasif/aktif yapar', async () => {
  await asUser(superAdmin, `select public.set_profile_active($1, false)`, [otherAdmin]);
  await asUser(superAdmin, `select public.set_profile_active($1, true)`, [otherAdmin]);
});
await expectError('admin profil aktifliğini doğrudan yazamaz', 'permission denied', () => asUser(admin,
  `update public.profiles set is_active = false where id = $1`, [guide2]));

// Pasif şirket
await expectOk('super admin firmayı pasif yapar → admin yönetemez, turlar gizlenir', async () => {
  await asUser(superAdmin, `update public.companies set is_active = false where id = $1`, [company]);
  await expectError('pasif firmanın admini tur ekleyemez', 'row-level security', () => asUser(admin,
    `insert into public.tours (company_id, title, price, city_id, region)
     values ($1, 'Pasif Tur', 10, 46, 'ege')`, [company]));
  const r = await asUser(customer3, `select count(*)::int n from public.tours where company_id = $1`, [company]);
  if (r.rows[0].n !== 0) throw new Error('müşteri pasif firmanın turunu görüyor: ' + r.rows[0].n);
  const s = await asUser(superAdmin, `select count(*)::int n from public.tours where company_id = $1`, [company]);
  if (s.rows[0].n === 0) throw new Error('super admin pasif firmanın turunu görmeli');
  await asUser(superAdmin, `update public.companies set is_active = true where id = $1`, [company]);
});
await expectError('admin firma oluşturamaz', 'row-level security', () => asUser(admin,
  `insert into public.companies (name) values ('Yetkisiz Firma')`));
await expectOk('super admin firma oluşturur', () => asUser(superAdmin,
  `insert into public.companies (name, city_id) values ('Yeni Firma', 46)`));

// Auth Admin API önce metadata'sız ekler, app_metadata'yı sonra yazar — migration 10
await expectOk('admin API sırası: rol/şirket/kimlik sonradan yazılınca profil eşitlenir', async () => {
  const id = (await scalar(`insert into auth.users (raw_app_meta_data, raw_user_meta_data)
    values ('{"provider":"email"}', '{"full_name":"Sonradan Rehber"}') returning id`)).id;
  const before = await scalar(`select role from public.profiles where id = $1`, [id]);
  if (before.role !== 'customer') throw new Error('başlangıç: ' + before.role);
  await db.query(`update auth.users set raw_app_meta_data = raw_app_meta_data || $2::jsonb where id = $1`,
    [id, JSON.stringify({ role: 'guide', company_id: company, login_id: 'REH-9999' })]);
  const r = await scalar(`select role, company_id, login_id from public.profiles where id = $1`, [id]);
  if (r.role !== 'guide' || r.company_id !== company || r.login_id !== 'REH-9999') throw new Error(JSON.stringify(r));
});
await expectOk('user_metadata değişikliği rolü etkilemez', async () => {
  await db.query(`update auth.users set raw_user_meta_data = '{"role":"super_admin"}' where id = $1`, [customer]);
  const r = await scalar(`select role from public.profiles where id = $1`, [customer]);
  if (r.role !== 'customer') throw new Error(r.role);
});

// create-account Edge Function (service_role) yetkileri — migration 9
const asService = async (sql, params = []) => {
  await db.exec('set role service_role;');
  try { return await db.query(sql, params); } finally { await db.exec('reset role;'); }
};
await expectOk('service_role çağıranın profilini ve şirketi okur', async () => {
  const r = await asService(`select (select role from public.profiles where id = $1) r,
    (select count(*)::int from public.companies where id = $2) c`, [admin, company]);
  if (r.rows[0].r !== 'admin' || r.rows[0].c !== 1) throw new Error(JSON.stringify(r.rows[0]));
});
await expectOk('service_role yeni hesabın telefonunu yazar', () => asService(
  `update public.profiles set phone = '0555' where id = $1`, [guide2]));
await expectError('service_role rol değiştiremez', 'permission denied', () => asService(
  `update public.profiles set role = 'super_admin' where id = $1`, [guide2]));
await expectError('service_role bilete yazamaz', 'permission denied', () => asService(
  `delete from public.tickets`));

// ─── Faz 3: biletler (migration 12) ────────────────────────────────────────
const f3Tour = (await scalar(`insert into public.tours (company_id, title, price, city_id, region)
  values ($1, 'Faz 3 Turu', 500, 46, 'dogu_karadeniz') returning id`, [company])).id;
const f3Dep = (await scalar(`insert into public.tour_departures (tour_id, departure_at, capacity)
  values ($1, now() + interval '4 days', 3) returning id`, [f3Tour])).id;
const buyer = await mkUser(null, null, 'Alıcı Zeynep');
const outsider = await mkUser(null, null, 'Başka Müşteri');
const panelCustomer = await mkUser('customer', company, 'Panel Müşterisi');
const otherPanelCustomer = await mkUser('customer', otherCompany, 'Başka Firma Müşterisi');

const f3Ticket = await expectOk('müşteri bilet alır', async () =>
  (await asUser(buyer, `select * from public.book_ticket($1, 'Zeynep Ak')`, [f3Dep])).rows[0]);
await expectError('aynı tarihe ikinci bilet alınamaz', 'already_has_ticket', () => asUser(buyer,
  `select public.book_ticket($1, 'Zeynep Ak')`, [f3Dep]));
await expectOk('iptal edince aynı tarihe yeniden bilet alınır', async () => {
  await asUser(buyer, `select public.cancel_ticket($1)`, [f3Ticket.id]);
  await asUser(buyer, `select public.book_ticket($1, 'Zeynep Ak')`, [f3Dep]);
  const r = await scalar(`select seats_left from public.tour_departures where id = $1`, [f3Dep]);
  if (r.seats_left !== 2) throw new Error('seats_left ' + r.seats_left);
});

await expectOk('tur satıştan kalkınca ve firma pasifleşince bilet sahibi turu/tarihi/firmayı görür', async () => {
  await db.query(`update public.tours set is_active = false where id = $1`, [f3Tour]);
  await db.query(`update public.companies set is_active = false where id = $1`, [company]);
  try {
    const q = `select tk.id, d.id dep, t.title, c.name
      from public.tickets tk
      join public.tour_departures d on d.id = tk.departure_id
      join public.tours t on t.id = d.tour_id
      join public.companies c on c.id = t.company_id
      where tk.departure_id = $1`;
    const own = await asUser(buyer, q, [f3Dep]);
    if (own.rows.length !== 2 || own.rows[0].title !== 'Faz 3 Turu') throw new Error(JSON.stringify(own.rows));
    const other = await asUser(outsider, `select count(*)::int n from public.tours where id = $1`, [f3Tour]);
    if (other.rows[0].n !== 0) throw new Error('başka müşteri pasif turu görüyor');
    const guest = await asUser(null, `select count(*)::int n from public.tour_departures where id = $1`, [f3Dep]);
    if (guest.rows[0].n !== 0) throw new Error('misafir pasif turun tarihini görüyor');
  } finally {
    await db.query(`update public.companies set is_active = true where id = $1`, [company]);
    await db.query(`update public.tours set is_active = true where id = $1`, [f3Tour]);
  }
});
await expectOk('bilet sahibi ödeme ve iade kaydını görür', async () => {
  const r = await asUser(buyer, `select string_agg(type::text, ',' order by type) t from public.payments`);
  if (r.rows[0].t !== 'payment,payment,refund') throw new Error(r.rows[0].t);
});

// Panelden bilet
await expectError('müşteri panelden bilet kesemez', 'not_allowed', () => asUser(buyer,
  `select public.admin_issue_ticket($1, $2)`, [f3Dep, panelCustomer]));
await expectError('misafir panelden bilet kesemez', 'permission denied', () => asUser(null,
  `select public.admin_issue_ticket($1, $2)`, [f3Dep, panelCustomer]));
await expectError('başka firmanın admini bilet kesemez', 'not_allowed', () => asUser(otherAdmin,
  `select public.admin_issue_ticket($1, $2)`, [f3Dep, panelCustomer]));
await expectError('uygulamadan kayıtlı müşteriye panelden bilet kesilmez', 'invalid_customer', () => asUser(admin,
  `select public.admin_issue_ticket($1, $2)`, [f3Dep, outsider]));
await expectError('başka firmanın müşterisine bilet kesilmez', 'invalid_customer', () => asUser(admin,
  `select public.admin_issue_ticket($1, $2)`, [f3Dep, otherPanelCustomer]));
await expectError('rehbere bilet kesilmez', 'invalid_customer', () => asUser(admin,
  `select public.admin_issue_ticket($1, $2)`, [f3Dep, guide]));
const panelTicket = await expectOk('admin firmanın müşterisine bilet keser → paid, panel, manual ödeme, ad profilden', async () => {
  const t = (await asUser(admin, `select * from public.admin_issue_ticket($1, $2)`, [f3Dep, panelCustomer])).rows[0];
  const r = await scalar(`select (select method from public.payments where ticket_id = $1 and type = 'payment') m,
    (select seats_left from public.tour_departures where id = $2) s`, [t.id, f3Dep]);
  if (t.status !== 'paid' || t.source !== 'panel' || t.passenger_name !== 'Panel Müşterisi'
      || t.price_paid !== '500.00' || r.m !== 'manual' || r.s !== 1) throw new Error(JSON.stringify({ t, r }));
  return t;
});
await expectError('panelden aynı müşteriye ikinci bilet kesilmez', 'already_has_ticket', () => asUser(admin,
  `select public.admin_issue_ticket($1, $2)`, [f3Dep, panelCustomer]));
await expectOk('panel müşterisi kendi biletini görür', async () => {
  const r = await asUser(panelCustomer, `select count(*)::int n from public.tickets`);
  if (r.rows[0].n !== 1) throw new Error('görülen ' + r.rows[0].n);
});
await expectOk('admin panel biletini iptal eder → manual iade', async () => {
  await asUser(admin, `select public.cancel_ticket($1)`, [panelTicket.id]);
  const r = await scalar(`select method from public.payments where ticket_id = $1 and type = 'refund'`, [panelTicket.id]);
  if (r.method !== 'manual') throw new Error(JSON.stringify(r));
});
await expectOk('super admin de panelden bilet keser', () => asUser(superAdmin,
  `select public.admin_issue_ticket($1, $2, 'Elle Yazılan Ad')`, [f3Dep, panelCustomer]));
await expectError('kontenjan dolunca panelden de bilet kesilmez', 'no_seats_left', async () => {
  await asUser(admin, `select public.admin_issue_ticket($1, $2)`, [f3Dep, await mkUser('customer', company, 'Son Koltuk')]);
  const c = await mkUser('customer', company, 'Fazla Müşteri');
  await asUser(admin, `select public.admin_issue_ticket($1, $2)`, [f3Dep, c]);
});
await expectError('kalkmış tarihe panelden bilet kesilmez', 'departure_not_bookable', () => asUser(admin,
  `select public.admin_issue_ticket($1, $2)`, [startedDep, panelCustomer]));

// ─── Faz 4: rehber akışı (migration 13) ──────────────────────────────────
const f4Guide = await mkUser('guide', company, 'Rehber Deniz');
const f4Tour = (await scalar(`insert into public.tours (company_id, title, price, city_id, region)
  values ($1, 'Rehber Testi', 500, 46, 'gunubirlik') returning id`, [company])).id;
const f4Dep = (await scalar(`insert into public.tour_departures (tour_id, departure_at, capacity, guide_id, bus_plate)
  values ($1, now() + interval '2 hours', 6, $2, '46 F 4') returning id`, [f4Tour, f4Guide])).id;
await db.query(`insert into public.tour_departures (tour_id, departure_at, capacity, guide_id)
  values ($1, now() + interval '5 days', 5, $2)`, [f4Tour, guide2]);
const phoneBuyer = await mkUser(null, null, 'Telefonlu Müşteri');
const phoneBuyer2 = await mkUser(null, null, 'İkinci Müşteri');
const noShowBuyer = await mkUser(null, null, 'Gelmeyen Müşteri');

await expectError('geçersiz telefonla bilet alınmaz', 'invalid_phone', () => asUser(phoneBuyer,
  `select public.book_ticket($1, 'Telefonlu', null, 'abc')`, [f4Dep]));
const f4Ticket = await expectOk('telefonla bilet alınır, telefon bilete ve boş profile yazılır', async () => {
  const t = (await asUser(phoneBuyer,
    `select * from public.book_ticket(p_departure_id => $1, p_passenger_name => 'Telefonlu', p_passenger_phone => ' 0532 111 22 33 ')`,
    [f4Dep])).rows[0];
  const p = await scalar(`select phone from public.profiles where id = $1`, [phoneBuyer]);
  if (t.passenger_phone !== '0532 111 22 33' || p.phone !== '0532 111 22 33') throw new Error(JSON.stringify([t.passenger_phone, p.phone]));
  return t;
});
await expectOk('profilde telefon varsa satın alma onu değiştirmez', async () => {
  await db.query(`update public.profiles set phone = '0344 000 00 01' where id = $1`, [phoneBuyer2]);
  const t = (await asUser(phoneBuyer2, `select * from public.book_ticket($1, 'İkinci', null, '0555 999 88 77')`, [f4Dep])).rows[0];
  const p = await scalar(`select phone from public.profiles where id = $1`, [phoneBuyer2]);
  if (t.passenger_phone !== '0555 999 88 77' || p.phone !== '0344 000 00 01') throw new Error(JSON.stringify([t.passenger_phone, p.phone]));
});
const noShowTicket = (await asUser(noShowBuyer, `select * from public.book_ticket($1, 'Gelmeyen')`, [f4Dep])).rows[0];
await expectOk('telefonsuz eski çağrı hâlâ çalışır, telefon boş kalır', async () => {
  if (noShowTicket.passenger_phone !== null) throw new Error(noShowTicket.passenger_phone);
});
await expectOk('panelden kesilen bilete müşterinin profil telefonu kopyalanır', async () => {
  const c = await mkUser('customer', company, 'Panel Telefonlu');
  await db.query(`update public.profiles set phone = '0533 444 55 66' where id = $1`, [c]);
  const t = (await asUser(admin, `select * from public.admin_issue_ticket($1, $2)`, [f4Dep, c])).rows[0];
  if (t.passenger_phone !== '0533 444 55 66') throw new Error(t.passenger_phone);
});
await expectOk('profildeki bozuk telefon panel biletini engellemez', async () => {
  const c = await mkUser('customer', company, 'Bozuk Telefonlu');
  await db.query(`update public.profiles set phone = 'yok' where id = $1`, [c]);
  const t = (await asUser(admin, `select * from public.admin_issue_ticket($1, $2)`, [f4Dep, c])).rows[0];
  if (t.passenger_phone !== null) throw new Error(t.passenger_phone);
});

await expectOk('guide_departures: rehber sadece kendi tarihlerini, sayılarla görür', async () => {
  const r = (await asUser(f4Guide, `select * from public.guide_departures()`)).rows;
  if (r.length !== 1 || r[0].id !== f4Dep || r[0].tour_title !== 'Rehber Testi'
      || r[0].ticket_count !== 5 || r[0].checked_in_count !== 0 || r[0].last_request_status !== null) {
    throw new Error(JSON.stringify(r));
  }
});
await expectOk('guide_departures: müşteri ve admin için boş döner', async () => {
  const a = (await asUser(phoneBuyer, `select count(*)::int n from public.guide_departures()`)).rows[0].n;
  const b = (await asUser(admin, `select count(*)::int n from public.guide_departures()`)).rows[0].n;
  if (a !== 0 || b !== 0) throw new Error(a + '/' + b);
});
await expectError('misafir guide_departures çağıramaz', 'permission denied', () => asUser(null,
  `select * from public.guide_departures()`));

await expectOk('rehber katılımcıların telefonunu okur', async () => {
  const r = await asUser(f4Guide, `select count(passenger_phone)::int n from public.tickets where departure_id = $1`, [f4Dep]);
  if (r.rows[0].n !== 3) throw new Error('görülen ' + r.rows[0].n);
});
await expectOk('QR ile okutulan bilet yöntem qr olarak kaydedilir', async () => {
  const r = (await asUser(f4Guide, `select public.scan_ticket($1, $2) r`, [f4Dep, f4Ticket.qr_token])).rows[0].r;
  const m = await scalar(`select check_in_method from public.tickets where id = $1`, [f4Ticket.id]);
  if (!r.ok || !r.scanned_at || m.check_in_method !== 'qr') throw new Error(JSON.stringify([r, m]));
});
const manualTicket = (await scalar(`select id from public.tickets where departure_id = $1 and user_id = $2`, [f4Dep, phoneBuyer2])).id;
await expectError('başka tarihin rehberi elle işaretleyemez', 'not_allowed', () => asUser(guide2,
  `select public.check_in_manually($1)`, [manualTicket]));
await expectError('müşteri elle işaretleyemez', 'not_allowed', () => asUser(phoneBuyer2,
  `select public.check_in_manually($1)`, [manualTicket]));
await expectOk('rehber elle Geldi işaretler (yöntem manual)', async () => {
  const r = (await asUser(f4Guide, `select public.check_in_manually($1) r`, [manualTicket])).rows[0].r;
  const m = await scalar(`select status, check_in_method, scanned_by from public.tickets where id = $1`, [manualTicket]);
  if (!r.ok || r.passenger_name !== 'İkinci' || m.status !== 'checked_in' || m.check_in_method !== 'manual' || m.scanned_by !== f4Guide) {
    throw new Error(JSON.stringify([r, m]));
  }
});
await expectOk('aynı bilet ikinci kez elle işaretlenince already_used döner', async () => {
  const r = (await asUser(f4Guide, `select public.check_in_manually($1) r`, [manualTicket])).rows[0].r;
  if (r.ok || r.code !== 'already_used' || !r.scanned_at) throw new Error(JSON.stringify(r));
});
await expectOk('iptal edilmiş bilet elle işaretlenemez (cancelled)', async () => {
  const c = await mkUser(null, null, 'İptalci');
  const t = (await asUser(c, `select * from public.book_ticket($1, 'İptalci')`, [f4Dep])).rows[0];
  await asUser(c, `select public.cancel_ticket($1)`, [t.id]);
  const r = (await asUser(f4Guide, `select public.check_in_manually($1) r`, [t.id])).rows[0].r;
  if (r.ok || r.code !== 'cancelled') throw new Error(JSON.stringify(r));
});
await expectError('olmayan bilet elle işaretlenemez', 'ticket_not_found', () => asUser(f4Guide,
  `select public.check_in_manually(gen_random_uuid())`));
await expectOk('guide_departures sayıları okutmalardan sonra güncel (iptal sayılmaz)', async () => {
  const r = (await asUser(f4Guide, `select ticket_count, checked_in_count from public.guide_departures()`)).rows[0];
  if (r.ticket_count !== 5 || r.checked_in_count !== 2) throw new Error(JSON.stringify(r));
});
await expectError('kalkış saati gelmeden turu bitir talebi açılmaz', 'departure_not_started', () => asUser(f4Guide,
  `select public.request_departure_completion($1)`, [f4Dep]));
await expectOk('bitirme talebi reddedilirse rehber listesinde rejected görünür', async () => {
  await db.query(`update public.tour_departures set departure_at = now() - interval '1 hour' where id = $1`, [f4Dep]);
  const req = (await asUser(f4Guide, `select id from public.request_departure_completion($1)`, [f4Dep])).rows[0].id;
  const pending = (await asUser(f4Guide, `select status, last_request_status from public.guide_departures()`)).rows[0];
  if (pending.status !== 'finish_requested' || pending.last_request_status !== 'pending') throw new Error(JSON.stringify(pending));
  await asUser(admin, `select public.review_departure_completion($1, false)`, [req]);
  const r = (await asUser(f4Guide, `select status, last_request_status from public.guide_departures()`)).rows[0];
  if (r.status !== 'scheduled' || r.last_request_status !== 'rejected') throw new Error(JSON.stringify(r));
});
await expectError('bitirme talebi beklerken elle işaretlenemez', 'departure_not_active', async () => {
  await asUser(f4Guide, `select public.request_departure_completion($1)`, [f4Dep]);
  await asUser(f4Guide, `select public.check_in_manually($1)`, [noShowTicket.id]);
});
await expectOk('onaylanınca okutulanlar completed, gelmeyen no_show olur', async () => {
  const req = (await scalar(`select id from public.completion_requests where departure_id = $1 and status = 'pending'`, [f4Dep])).id;
  await asUser(admin, `select public.review_departure_completion($1, true)`, [req]);
  const a = await scalar(`select status from public.tickets where id = $1`, [f4Ticket.id]);
  const b = await scalar(`select status from public.tickets where id = $1`, [noShowTicket.id]);
  const g = (await asUser(f4Guide, `select status, checked_in_count from public.guide_departures()`)).rows[0];
  if (a.status !== 'completed' || b.status !== 'no_show' || g.status !== 'completed' || g.checked_in_count !== 2) {
    throw new Error(JSON.stringify([a, b, g]));
  }
});
await expectOk('pasif rehber guide_departures ile bir şey göremez', async () => {
  await db.query(`update public.profiles set is_active = false where id = $1`, [f4Guide]);
  const r = (await asUser(f4Guide, `select count(*)::int n from public.guide_departures()`)).rows[0].n;
  await db.query(`update public.profiles set is_active = true where id = $1`, [f4Guide]);
  if (r !== 0) throw new Error(String(r));
});

// ─── Faz 5: sohbet, duyurular, bildirimler, push (migration 14) ─────────
const f5Guide = await mkUser('guide', company, 'Rehber Selin');
const f5Tour = (await scalar(`insert into public.tours (company_id, title, price, city_id, region)
  values ($1, 'Sohbet Turu', 400, 46, 'gunubirlik') returning id`, [company])).id;
await db.query(`insert into public.tour_program_days (tour_id, day_no, title, activities)
  values ($1, 1, 'Göksun', '{Kahvaltı,Yürüyüş}')`, [f5Tour]);
await db.query(`update public.profiles set phone = '0532 000 11 22' where id = $1`, [f5Guide]);
const f5Dep = (await scalar(`insert into public.tour_departures (tour_id, departure_at, capacity, guide_id, bus_plate)
  values ($1, now() + interval '2 hours', 10, $2, '46 S 5') returning id`, [f5Tour, f5Guide])).id;
const chatIn = await mkUser(null, null, 'Gelen Yolcu');
const chatPaid = await mkUser(null, null, 'Bekleyen Yolcu');
const chatIn2 = await mkUser(null, null, 'Diğer Gelen');
const inTicket = (await asUser(chatIn, `select * from public.book_ticket($1, 'Gelen Yolcu')`, [f5Dep])).rows[0];
await asUser(chatPaid, `select * from public.book_ticket($1, 'Bekleyen Yolcu')`, [f5Dep]);
const in2Ticket = (await asUser(chatIn2, `select * from public.book_ticket($1, 'Diğer Gelen')`, [f5Dep])).rows[0];
await asUser(f5Guide, `select public.scan_ticket($1, $2)`, [f5Dep, inTicket.qr_token]);
await asUser(f5Guide, `select public.check_in_manually($1)`, [in2Ticket.id]);

await expectOk('Realtime yayınında sadece messages ve tickets var', async () => {
  const r = await scalar(`select string_agg(tablename, ',' order by tablename) t from pg_publication_tables where pubname = 'supabase_realtime'`);
  if (r.t !== 'messages,tickets') throw new Error(r.t);
});

const msg1 = await expectOk('okutulmuş yolcu mesaj yazar; ad ve rol profilden (taklit edilemez)', async () => {
  const m = (await asUser(chatIn, `insert into public.messages (departure_id, sender_id, sender_name, sender_role, body)
    values ($1, $2, 'Sahte Ad', 'super_admin', 'Merhaba') returning *`, [f5Dep, f5Guide])).rows[0];
  if (m.sender_id !== chatIn || m.sender_name !== 'Gelen Yolcu' || m.sender_role !== 'customer') throw new Error(JSON.stringify(m));
  return m;
});
await expectOk('rehber mesajı Tur sorumlusu rolüyle kaydedilir', async () => {
  const m = (await asUser(f5Guide, `insert into public.messages (departure_id, body) values ($1, 'Hoş geldiniz') returning sender_role`, [f5Dep])).rows[0];
  if (m.sender_role !== 'guide') throw new Error(m.sender_role);
});
await expectOk('firma admini panelden yazar (rol admin)', async () => {
  const m = (await asUser(admin, `insert into public.messages (departure_id, body) values ($1, 'Firma burada') returning sender_role`, [f5Dep])).rows[0];
  if (m.sender_role !== 'admin') throw new Error(m.sender_role);
});
await expectError('QR okutulmamış yolcu yazamaz', 'row-level security', () => asUser(chatPaid,
  `insert into public.messages (departure_id, body) values ($1, 'Ben de')`, [f5Dep]));
await expectError('başka firmanın admini yazamaz', 'row-level security', () => asUser(otherAdmin,
  `insert into public.messages (departure_id, body) values ($1, 'Selam')`, [f5Dep]));
await expectOk('okutulmamış yolcu ve başka admin sohbeti göremez; üyeler görür', async () => {
  const q = `select count(*)::int n from public.messages where departure_id = $1`;
  const a = (await asUser(chatPaid, q, [f5Dep])).rows[0].n;
  const b = (await asUser(otherAdmin, q, [f5Dep])).rows[0].n;
  const c = (await asUser(chatIn2, q, [f5Dep])).rows[0].n;
  const d = (await asUser(f5Guide, q, [f5Dep])).rows[0].n;
  if (a !== 0 || b !== 0 || c !== 3 || d !== 3) throw new Error([a, b, c, d].join('/'));
});
await expectOk('yolcu başkasının mesajını silemez, kendininkini siler', async () => {
  const other = (await asUser(chatIn2, `delete from public.messages where id = $1 returning id`, [msg1.id])).rows.length;
  const own = (await asUser(chatIn, `delete from public.messages where id = $1 returning id`, [msg1.id])).rows.length;
  if (other !== 0 || own !== 1) throw new Error(other + '/' + own);
});
await expectOk('rehber yolcunun mesajını silebilir', async () => {
  const m = (await asUser(chatIn2, `insert into public.messages (departure_id, body) values ($1, 'Silinecek') returning id`, [f5Dep])).rows[0];
  const n = (await asUser(f5Guide, `delete from public.messages where id = $1 returning id`, [m.id])).rows.length;
  if (n !== 1) throw new Error(String(n));
});
await expectError('dakikada 20 mesajdan fazlası rate_limited', 'rate_limited', async () => {
  for (let i = 0; i < 21; i++) {
    await asUser(chatIn2, `insert into public.messages (departure_id, body) values ($1, $2)`, [f5Dep, 'm' + i]);
  }
});
await expectError('2000 karakterden uzun mesaj yazılmaz', 'check constraint', () => asUser(chatIn,
  `insert into public.messages (departure_id, body) values ($1, repeat('a', 2001))`, [f5Dep]));

await expectOk('participant_departure_info: okutulmuş yolcu rehber telefonu, program ve açık sohbet görür', async () => {
  const r = (await asUser(chatIn, `select public.participant_departure_info($1) r`, [f5Dep])).rows[0].r;
  if (r.tour_title !== 'Sohbet Turu' || r.guide_name !== 'Rehber Selin' || r.guide_phone !== '0532 000 11 22'
      || r.chat_open !== true || r.ticket_status !== 'checked_in' || r.program.length !== 1
      || r.program[0].activities[1] !== 'Yürüyüş' || r.bus_plate !== '46 S 5') throw new Error(JSON.stringify(r));
});
await expectOk('participant_departure_info: okutulmamış yolcuda sohbet kapalı, duyuru yok', async () => {
  const r = (await asUser(chatPaid, `select public.participant_departure_info($1) r`, [f5Dep])).rows[0].r;
  if (r.chat_open !== false || r.last_announcement !== null) throw new Error(JSON.stringify(r));
});
await expectError('participant_departure_info: bileti olmayan çağıramaz', 'not_allowed', () => asUser(customer2,
  `select public.participant_departure_info($1)`, [f5Dep]));
await expectError('participant_departure_info: misafir çağıramaz', 'permission denied', () => asUser(null,
  `select public.participant_departure_info($1)`, [f5Dep]));

// Duyuru + bildirim + push
await expectOk('push adresi yokken duyuru bildirime düşer ama HTTP çağrısı yapılmaz', async () => {
  await asUser(f5Guide, `insert into public.announcements (departure_id, body) values ($1, 'Mola 10 dk')`, [f5Dep]);
  const n = await scalar(`select count(*)::int n from net.calls`);
  if (n.n !== 0) throw new Error(String(n.n));
});
await db.query(`insert into private.settings (key, value) values ('push_function_url', 'https://ornek.test/functions/v1/send-push')`);
await expectOk('duyuru sadece okutulmuş yolculara gider ve tek HTTP çağrısıyla push tetiklenir', async () => {
  await asUser(f5Guide, `insert into public.announcements (departure_id, body) values ($1, 'Otobüse dönüyoruz')`, [f5Dep]);
  const calls = (await db.query(`select url, body from net.calls`)).rows;
  const users = (await db.query(`select string_agg(user_id::text, ',' order by user_id) u from public.notifications where body = 'Otobüse dönüyoruz'`)).rows[0].u;
  const expected = [chatIn, chatIn2].sort().join(',');
  if (calls.length !== 1 || calls[0].body.notification_ids.length !== 2 || users !== expected) throw new Error(JSON.stringify({ calls, users }));
});
await expectOk('participant_departure_info son duyuruyu verir', async () => {
  const r = (await asUser(chatIn, `select public.participant_departure_info($1) r`, [f5Dep])).rows[0].r;
  if (r.last_announcement?.body !== 'Otobüse dönüyoruz') throw new Error(JSON.stringify(r.last_announcement));
});
await expectError('yolcu duyuru gönderemez', 'row-level security', () => asUser(chatIn,
  `insert into public.announcements (departure_id, body) values ($1, 'Ben duyururum')`, [f5Dep]));
await expectError('dakikada 5 duyurudan fazlası rate_limited', 'rate_limited', async () => {
  for (let i = 0; i < 4; i++) {
    await asUser(f5Guide, `insert into public.announcements (departure_id, body) values ($1, $2)`, [f5Dep, 'd' + i]);
  }
});
await expectOk('yolcu bildirimini okundu yapar ama içeriğini değiştiremez', async () => {
  const r = (await asUser(chatIn, `update public.notifications set is_read = true where user_id = $1 returning id`, [chatIn])).rows.length;
  if (r < 2) throw new Error(String(r));
  try { await asUser(chatIn, `update public.notifications set body = 'x'`); throw new Error('body değişti'); }
  catch (e) { if (!e.message.includes('permission denied')) throw e; }
});
await expectOk('service_role push_sent_at yazar, token okur; bildirim içeriğine yazamaz', async () => {
  await db.exec('set role service_role;');
  try {
    await db.query(`update public.notifications set push_sent_at = now() where user_id = $1`, [chatIn]);
    await db.query(`select token from public.device_tokens`);
    try { await db.query(`update public.notifications set body = 'x'`); throw new Error('body değişti'); }
    catch (e) { if (!e.message.includes('permission denied')) throw e; }
  } finally { await db.exec('reset role;'); }
});

// Cihaz token'ı
const fakeToken = 'fcm-token-' + 'x'.repeat(30);
await expectOk('register_device_token: aynı token başka hesapla girişte yeni hesaba geçer', async () => {
  await asUser(chatIn, `select public.register_device_token($1, 'android')`, [fakeToken]);
  await asUser(chatIn2, `select public.register_device_token($1, 'android')`, [fakeToken]);
  const r = await scalar(`select user_id from public.device_tokens where token = $1`, [fakeToken]);
  if (r.user_id !== chatIn2) throw new Error(r.user_id);
  const seen = (await asUser(chatIn, `select count(*)::int n from public.device_tokens`)).rows[0].n;
  if (seen !== 0) throw new Error('eski hesap token görüyor');
});
await expectOk('çıkışta kullanıcı kendi tokenını siler', async () => {
  const n = (await asUser(chatIn2, `delete from public.device_tokens where token = $1 returning token`, [fakeToken])).rows.length;
  if (n !== 1) throw new Error(String(n));
});
await expectError('çok kısa token reddedilir', 'invalid_token', () => asUser(chatIn,
  `select public.register_device_token('abc', 'android')`));
await expectError('misafir token kaydedemez', 'permission denied', () => asUser(null,
  `select public.register_device_token($1, 'android')`, [fakeToken]));

// Tur bitince sohbet gizlenir
await expectOk('tur bitince sohbet yolcu ve rehberden gizlenir, admin görür, mesajlar DB de kalır', async () => {
  await db.query(`update public.tour_departures set departure_at = now() - interval '1 hour' where id = $1`, [f5Dep]);
  const req = (await asUser(f5Guide, `select id from public.request_departure_completion($1)`, [f5Dep])).rows[0].id;
  const q = `select count(*)::int n from public.messages where departure_id = $1`;
  const pendingSeen = (await asUser(chatIn2, q, [f5Dep])).rows[0].n;
  await asUser(admin, `select public.review_departure_completion($1, true)`, [req]);
  const a = (await asUser(chatIn2, q, [f5Dep])).rows[0].n;
  const g = (await asUser(f5Guide, q, [f5Dep])).rows[0].n;
  const ad = (await asUser(admin, q, [f5Dep])).rows[0].n;
  const all = (await scalar(q, [f5Dep])).n;
  if (pendingSeen === 0 || a !== 0 || g !== 0 || ad !== all || all === 0) throw new Error([pendingSeen, a, g, ad, all].join('/'));
});
await expectError('bitmiş tura mesaj yazılamaz (admin de)', 'row-level security', () => asUser(admin,
  `insert into public.messages (departure_id, body) values ($1, 'Geç kaldım')`, [f5Dep]));
await expectError('bitmiş tura duyuru gönderilemez', 'row-level security', () => asUser(admin,
  `insert into public.announcements (departure_id, body) values ($1, 'Geç')`, [f5Dep]));
await expectError('bitmiş turda participant_departure_info kapalı', 'not_allowed', () => asUser(chatIn,
  `select public.participant_departure_info($1)`, [f5Dep]));

// Super admin → firma duyuruları
await expectOk('super admin tüm firmalara ve tek firmaya duyuru yayınlar', async () => {
  await asUser(superAdmin, `insert into public.company_announcements (title, body) values ('Bakım', 'Pazar gece bakım var')`);
  await asUser(superAdmin, `insert into public.company_announcements (company_id, title, body) values ($1, 'Size özel', 'Sözleşme yenileme')`, [company]);
});
await expectOk('firma admini genel + kendi duyurusunu görür, başka firma özeli görmez, müşteri hiçbirini', async () => {
  const q = `select count(*)::int n from public.company_announcements`;
  const a = (await asUser(admin, q)).rows[0].n;
  const o = (await asUser(otherAdmin, q)).rows[0].n;
  const c = (await asUser(customer, q)).rows[0].n;
  const g = (await asUser(f5Guide, q)).rows[0].n;
  if (a !== 2 || o !== 1 || c !== 0 || g !== 0) throw new Error([a, o, c, g].join('/'));
});
await expectError('firma admini firma duyurusu yazamaz', 'row-level security', () => asUser(admin,
  `insert into public.company_announcements (title, body) values ('Benden', 'Herkese')`));
await expectOk('duyuruyu yazan super admin olarak kaydedilir', async () => {
  const r = await scalar(`select count(*)::int n from public.company_announcements where created_by = $1`, [superAdmin]);
  if (r.n !== 2) throw new Error(String(r.n));
});

// Firma → super admin geri bildirim
await expectOk('firma admini geri bildirim yollar, super admin görür ve durumu değiştirir', async () => {
  const f = (await asUser(admin, `insert into public.feedbacks (company_id, created_by, title, body)
    values ($1, $2, 'Öneri', 'Rapor ekranı olsun') returning id`, [company, admin])).rows[0].id;
  const o = (await asUser(otherAdmin, `select count(*)::int n from public.feedbacks`)).rows[0].n;
  const s = (await asUser(superAdmin, `update public.feedbacks set status = 'resolved' where id = $1 returning status`, [f])).rows[0];
  if (o !== 0 || s.status !== 'resolved') throw new Error(JSON.stringify([o, s]));
});
await expectError('firma admini başka firma adına geri bildirim yazamaz', 'row-level security', () => asUser(admin,
  `insert into public.feedbacks (company_id, created_by, title, body) values ($1, $2, 'Sahte', 'x')`, [otherCompany, admin]));

console.log(failures === 0 ? '\nTÜM TESTLER GEÇTİ' : `\n${failures} TEST BAŞARISIZ`);
process.exit(failures === 0 ? 0 : 1);
