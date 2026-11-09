-- DOURI initial schema

create extension if not exists "uuid-ossp";

create table if not exists profiles (
  id text primary key,
  full_name text not null,
  phone_number text,
  email text,
  app_role text not null default 'customer' check (app_role in ('customer','barber','admin')),
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists barber_shops (
  id uuid primary key default uuid_generate_v4(),
  owner_id text not null references profiles(id) on delete cascade,
  shop_name text not null,
  description text,
  address text,
  latitude double precision,
  longitude double precision,
  phone_number text,
  logo_url text,
  cover_image_url text,
  working_hours jsonb default '{}'::jsonb,
  appointment_duration int not null default 30,
  maximum_daily_bookings int not null default 30,
  is_open boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists shop_services (
  id uuid primary key default uuid_generate_v4(),
  barber_shop_id uuid not null references barber_shops(id) on delete cascade,
  service_name text not null,
  description text,
  duration_minutes int not null default 30,
  price numeric(10,2),
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists bookings (
  id uuid primary key default uuid_generate_v4(),
  customer_id text not null references profiles(id) on delete cascade,
  barber_shop_id uuid not null references barber_shops(id) on delete cascade,
  customer_name text not null,
  customer_phone text not null,
  booking_date date not null,
  booking_time text not null,
  queue_number int,
  status text not null default 'PENDING' check (status in ('PENDING','CONFIRMED','REJECTED','CANCELLED','COMPLETED','SKIPPED')),
  rejection_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (barber_shop_id, booking_date, booking_time)
);

create table if not exists daily_queues (
  id uuid primary key default uuid_generate_v4(),
  barber_shop_id uuid not null references barber_shops(id) on delete cascade,
  queue_date date not null,
  queue_status text not null default 'INACTIVE' check (queue_status in ('INACTIVE','ACTIVE','PAUSED','ENDED')),
  current_queue_number int,
  last_assigned_number int not null default 0,
  started_at timestamptz,
  ended_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (barber_shop_id, queue_date)
);

create table if not exists queue_entries (
  id uuid primary key default uuid_generate_v4(),
  daily_queue_id uuid not null references daily_queues(id) on delete cascade,
  booking_id uuid not null references bookings(id) on delete cascade,
  customer_id text not null references profiles(id) on delete cascade,
  queue_number int not null,
  status text not null default 'WAITING' check (status in ('WAITING','APPROACHING','CURRENT','COMPLETED','SKIPPED','CANCELLED')),
  called_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists notifications (
  id uuid primary key default uuid_generate_v4(),
  user_id text not null references profiles(id) on delete cascade,
  title text not null,
  body text not null,
  notification_type text not null,
  booking_id uuid references bookings(id) on delete set null,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists reviews (
  id uuid primary key default uuid_generate_v4(),
  customer_id text not null references profiles(id) on delete cascade,
  barber_shop_id uuid not null references barber_shops(id) on delete cascade,
  rating int not null check (rating between 1 and 5),
  comment text,
  created_at timestamptz not null default now()
);

create table if not exists device_tokens (
  id uuid primary key default uuid_generate_v4(),
  user_id text not null references profiles(id) on delete cascade,
  fcm_token text not null,
  platform text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, fcm_token)
);

-- indexes
create index if not exists idx_bookings_customer on bookings(customer_id);
create index if not exists idx_bookings_shop on bookings(barber_shop_id);
create index if not exists idx_queue_entries_daily on queue_entries(daily_queue_id);
create index if not exists idx_notifications_user on notifications(user_id);

-- RLS
alter table profiles enable row level security;
alter table barber_shops enable row level security;
alter table shop_services enable row level security;
alter table bookings enable row level security;
alter table daily_queues enable row level security;
alter table queue_entries enable row level security;
alter table notifications enable row level security;
alter table reviews enable row level security;
alter table device_tokens enable row level security;

-- profiles policies
create policy "profiles_select_own" on profiles for select using ((auth.jwt() ->> 'sub') = id);
create policy "profiles_update_own" on profiles for update using ((auth.jwt() ->> 'sub') = id);
create policy "profiles_insert_own" on profiles for insert with check ((auth.jwt() ->> 'sub') = id);

-- barber_shops policies
create policy "shops_select_all" on barber_shops for select using (true);
create policy "shops_manage_own" on barber_shops for all using (owner_id = (auth.jwt() ->> 'sub')) with check (owner_id = (auth.jwt() ->> 'sub'));

-- shop_services policies
create policy "services_select_all" on shop_services for select using (true);
create policy "services_manage_own" on shop_services for all using (
  exists (select 1 from barber_shops s where s.id = shop_services.barber_shop_id and s.owner_id = (auth.jwt() ->> 'sub'))
) with check (
  exists (select 1 from barber_shops s where s.id = shop_services.barber_shop_id and s.owner_id = (auth.jwt() ->> 'sub'))
);

-- bookings policies
create policy "bookings_select_own_or_shop" on bookings for select using (
  customer_id = (auth.jwt() ->> 'sub') or
  exists (select 1 from barber_shops s where s.id = bookings.barber_shop_id and s.owner_id = (auth.jwt() ->> 'sub'))
);
create policy "bookings_insert_customer" on bookings for insert with check (customer_id = (auth.jwt() ->> 'sub'));
create policy "bookings_update_shop" on bookings for update using (
  exists (select 1 from barber_shops s where s.id = bookings.barber_shop_id and s.owner_id = (auth.jwt() ->> 'sub'))
);

-- daily_queues policies
create policy "queues_select_all" on daily_queues for select using (true);
create policy "queues_manage_own" on daily_queues for all using (
  exists (select 1 from barber_shops s where s.id = daily_queues.barber_shop_id and s.owner_id = (auth.jwt() ->> 'sub'))
) with check (
  exists (select 1 from barber_shops s where s.id = daily_queues.barber_shop_id and s.owner_id = (auth.jwt() ->> 'sub'))
);

-- queue_entries policies
create policy "entries_select_own_or_shop" on queue_entries for select using (
  customer_id = (auth.jwt() ->> 'sub') or
  exists (
    select 1 from daily_queues q join barber_shops s on s.id = q.barber_shop_id
    where q.id = queue_entries.daily_queue_id and s.owner_id = (auth.jwt() ->> 'sub')
  )
);

-- notifications policies
create policy "notifications_select_own" on notifications for select using (user_id = (auth.jwt() ->> 'sub'));
create policy "notifications_update_own" on notifications for update using (user_id = (auth.jwt() ->> 'sub'));

-- device_tokens policies
create policy "tokens_manage_own" on device_tokens for all using (user_id = (auth.jwt() ->> 'sub')) with check (user_id = (auth.jwt() ->> 'sub'));

-- reviews policies
create policy "reviews_select_all" on reviews for select using (true);
create policy "reviews_insert_own" on reviews for insert with check (customer_id = (auth.jwt() ->> 'sub'));
