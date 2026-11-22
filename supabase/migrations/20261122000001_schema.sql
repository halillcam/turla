-- =============================================================================
-- Turla: temel şema
-- Tablolar, enum tipleri ve indeksler.
-- =============================================================================

create extension if not exists pgcrypto with schema extensions;

-- ─── Enum tipleri ────────────────────────────────────────────────────────────

create type public.user_role as enum ('super_admin', 'admin', 'guide', 'customer');

create type public.tour_region as enum (
  'akdeniz', 'karadeniz', 'marmara', 'ege', 'ic_anadolu',
  'dogu_anadolu', 'guneydogu_anadolu', 'gunubirlik', 'yurtdisi'
);

create type public.departure_status as enum ('scheduled', 'finish_requested', 'completed', 'cancelled');

create type public.ticket_status as enum ('reserved', 'paid', 'checked_in', 'cancelled', 'completed', 'no_show');

create type public.ticket_source as enum ('app', 'panel');

create type public.payment_type as enum ('payment', 'refund');

-- MVP'de gerçek ödeme yok: 'demo' (uygulamadaki demo ödeme ekranı) ve
-- 'manual' (firmanın elden/havale ile aldığı ödeme). Gerçek altyapı gelince
-- buraya yeni değer eklenir.
create type public.payment_method as enum ('demo', 'manual');

create type public.completion_status as enum ('pending', 'approved', 'rejected');

create type public.feedback_status as enum ('open', 'in_progress', 'resolved');

-- ─── Şehirler ────────────────────────────────────────────────────────────────

create table public.cities (
  id          smallint primary key,          -- plaka kodu
  name        text not null unique
);

-- ─── Şirketler ───────────────────────────────────────────────────────────────

create table public.companies (
  id          uuid primary key default gen_random_uuid(),
  name        text not null check (char_length(name) between 2 and 120),
  city_id     smallint references public.cities (id),
  phone       text,
  logo_url    text,
  is_active   boolean not null default true,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- ─── Profiller (auth.users ile 1-1) ──────────────────────────────────────────

create table public.profiles (
  id                uuid primary key references auth.users (id) on delete cascade,
  role              public.user_role not null default 'customer',
  company_id        uuid references public.companies (id) on delete set null,
  full_name         text not null default '',
  phone             text,
  tc_no             text check (tc_no is null or tc_no ~ '^[0-9]{11}$'),
  -- Panelden açılan hesaplar (rehber, dışarıdan eklenen müşteri) için giriş kimliği.
  login_id          text unique,
  selected_city_id  smallint references public.cities (id),
  is_active         boolean not null default true,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),
  -- admin ve rehber mutlaka bir şirkete bağlıdır.
  constraint profiles_company_required
    check (role not in ('admin', 'guide') or company_id is not null)
);

create index profiles_company_idx on public.profiles (company_id);

-- ─── Turlar ──────────────────────────────────────────────────────────────────

create table public.tours (
  id            uuid primary key default gen_random_uuid(),
  company_id    uuid not null references public.companies (id) on delete cascade,
  title         text not null check (char_length(title) between 3 and 160),
  description   text not null default '',
  extra_detail  text not null default '',
  price         numeric(10, 2) not null check (price >= 0),
  city_id       smallint not null references public.cities (id),
  region        public.tour_region not null,
  image_url     text,
  is_active     boolean not null default true,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create index tours_company_idx on public.tours (company_id);
create index tours_city_active_idx on public.tours (city_id) where is_active;

-- Tur programı (gün gün)
create table public.tour_program_days (
  id          uuid primary key default gen_random_uuid(),
  tour_id     uuid not null references public.tours (id) on delete cascade,
  day_no      smallint not null check (day_no >= 1),
  title       text not null default '',
  activities  text[] not null default '{}',
  sort_order  smallint not null default 0,
  unique (tour_id, day_no)
);

-- ─── Tur tarihleri (kalkışlar) ───────────────────────────────────────────────
-- Kontenjan, rehber, araç ve durum tarih bazındadır. "Turu bitir" sadece bu
-- satırı kapatır; aynı turun diğer tarihleri etkilenmez.

create table public.tour_departures (
  id            uuid primary key default gen_random_uuid(),
  tour_id       uuid not null references public.tours (id) on delete cascade,
  company_id    uuid not null references public.companies (id) on delete cascade, -- tours'tan trigger ile kopyalanır
  departure_at  timestamptz not null,
  capacity      integer not null check (capacity > 0),
  seats_left    integer not null check (seats_left >= 0),
  guide_id      uuid references public.profiles (id) on delete set null,
  bus_plate     text,
  driver_name   text,
  driver_phone  text,
  status        public.departure_status not null default 'scheduled',
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  constraint departures_seats_within_capacity check (seats_left <= capacity)
);

create index departures_tour_idx on public.tour_departures (tour_id, departure_at);
create index departures_guide_idx on public.tour_departures (guide_id) where guide_id is not null;
create index departures_company_idx on public.tour_departures (company_id);

-- ─── Biletler ────────────────────────────────────────────────────────────────
-- Biletler istemciden doğrudan yazılamaz; sadece fonksiyonlar (book_ticket,
-- cancel_ticket, scan_ticket ...) üzerinden değişir.

create table public.tickets (
  id              uuid primary key default gen_random_uuid(),
  departure_id    uuid not null references public.tour_departures (id) on delete restrict,
  company_id      uuid not null references public.companies (id) on delete restrict,
  user_id         uuid not null references public.profiles (id) on delete restrict,
  passenger_name  text not null check (char_length(passenger_name) between 2 and 120),
  tc_no           text check (tc_no is null or tc_no ~ '^[0-9]{11}$'),
  price_paid      numeric(10, 2) not null check (price_paid >= 0),
  status          public.ticket_status not null default 'reserved',
  source          public.ticket_source not null default 'app',
  -- Sunucuda üretilen, tahmin edilemez tek kullanımlık QR değeri.
  qr_token        text not null unique,
  scanned_at      timestamptz,
  scanned_by      uuid references public.profiles (id) on delete set null,
  cancelled_at    timestamptz,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index tickets_user_idx on public.tickets (user_id, created_at desc);
create index tickets_departure_idx on public.tickets (departure_id);
create index tickets_company_idx on public.tickets (company_id);

-- ─── Ödemeler ve iadeler ─────────────────────────────────────────────────────

create table public.payments (
  id          uuid primary key default gen_random_uuid(),
  ticket_id   uuid not null references public.tickets (id) on delete restrict,
  company_id  uuid not null references public.companies (id) on delete restrict,
  type        public.payment_type not null,
  method      public.payment_method not null,
  amount      numeric(10, 2) not null check (amount > 0),
  created_by  uuid references public.profiles (id) on delete set null,
  created_at  timestamptz not null default now()
);

create index payments_ticket_idx on public.payments (ticket_id);
create index payments_company_idx on public.payments (company_id, created_at desc);

-- Bir bilete en fazla bir ödeme ve bir iade.
create unique index payments_one_per_type on public.payments (ticket_id, type);

-- ─── Tur iletişimi ───────────────────────────────────────────────────────────

create table public.messages (
  id            uuid primary key default gen_random_uuid(),
  departure_id  uuid not null references public.tour_departures (id) on delete cascade,
  sender_id     uuid not null references public.profiles (id) on delete cascade,
  sender_name   text not null,   -- sadece ad-soyad görünür
  body          text not null check (char_length(body) between 1 and 2000),
  created_at    timestamptz not null default now()
);

create index messages_departure_idx on public.messages (departure_id, created_at);

create table public.announcements (
  id            uuid primary key default gen_random_uuid(),
  departure_id  uuid not null references public.tour_departures (id) on delete cascade,
  sender_id     uuid not null references public.profiles (id) on delete cascade,
  body          text not null check (char_length(body) between 1 and 1000),
  created_at    timestamptz not null default now()
);

create index announcements_departure_idx on public.announcements (departure_id, created_at desc);

-- Kullanıcıya özel bildirim kutusu (duyurular buraya dağıtılır).
create table public.notifications (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid not null references public.profiles (id) on delete cascade,
  title            text not null,
  body             text not null,
  departure_id     uuid references public.tour_departures (id) on delete cascade,
  announcement_id  uuid references public.announcements (id) on delete cascade,
  is_read          boolean not null default false,
  created_at       timestamptz not null default now()
);

create index notifications_user_idx on public.notifications (user_id, created_at desc);

-- Push bildirimi için cihaz token'ları (FCM).
create table public.device_tokens (
  token       text primary key,
  user_id     uuid not null references public.profiles (id) on delete cascade,
  platform    text not null check (platform in ('android', 'ios', 'web')),
  updated_at  timestamptz not null default now()
);

create index device_tokens_user_idx on public.device_tokens (user_id);

-- ─── Operasyon ───────────────────────────────────────────────────────────────

create table public.completion_requests (
  id            uuid primary key default gen_random_uuid(),
  departure_id  uuid not null references public.tour_departures (id) on delete cascade,
  company_id    uuid not null references public.companies (id) on delete cascade,
  guide_id      uuid not null references public.profiles (id) on delete cascade,
  status        public.completion_status not null default 'pending',
  reviewed_by   uuid references public.profiles (id) on delete set null,
  reviewed_at   timestamptz,
  created_at    timestamptz not null default now()
);

-- Bir tarih için aynı anda tek bekleyen talep.
create unique index completion_one_pending
  on public.completion_requests (departure_id) where status = 'pending';
create index completion_company_idx on public.completion_requests (company_id, created_at desc);

create table public.feedbacks (
  id          uuid primary key default gen_random_uuid(),
  company_id  uuid not null references public.companies (id) on delete cascade,
  created_by  uuid not null references public.profiles (id) on delete cascade,
  title       text not null check (char_length(title) between 3 and 160),
  body        text not null check (char_length(body) between 1 and 4000),
  status      public.feedback_status not null default 'open',
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create index feedbacks_company_idx on public.feedbacks (company_id, created_at desc);
