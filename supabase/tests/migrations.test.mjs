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
await expectError('kontenjan dolunca bilet satılmaz', 'no_seats_left', () => asUser(customer,
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

console.log(failures === 0 ? '\nTÜM TESTLER GEÇTİ' : `\n${failures} TEST BAŞARISIZ`);
process.exit(failures === 0 ? 0 : 1);
