-- =====================================================================
-- Salone Transport Hub - database schema (PostgreSQL on Supabase)
-- PROG 202 Final Project. Run this file first in the Supabase SQL Editor.
-- Naming: lower case with underscores, plural table names.
-- =====================================================================

create extension if not exists pg_trgm;   -- fast text search on names

-- ---------------------------------------------------------------------
-- Enumerated types
-- ---------------------------------------------------------------------
create type user_role      as enum ('passenger', 'driver', 'administrator');
create type request_status as enum ('pending', 'awaiting_passenger', 'confirmed', 'completed', 'cancelled');
create type report_status  as enum ('pending_review', 'under_review', 'closed');

-- ---------------------------------------------------------------------
-- Lookup tables
-- ---------------------------------------------------------------------
create table driver_types (
  driver_type text primary key
);

create table transport_modes (
  mode_name        text primary key,
  driver_type      text         not null references driver_types (driver_type),
  seat_capacity    smallint     not null check (seat_capacity > 0),
  is_per_passenger boolean      not null,
  base_fare_nle    numeric(8,2) not null check (base_fare_nle >= 0),
  rate_per_km_nle  numeric(6,3) not null check (rate_per_km_nle >= 0)
);

create table places (
  place_id         smallint generated always as identity primary key,
  name             text     not null unique check (length(btrim(name)) > 0),
  area             text     not null check (area in ('City', 'Peninsula', 'Lungi', 'North', 'Southeast')),
  km_from_freetown smallint not null check (km_from_freetown >= 0)
);
create index places_name_trgm on places using gin (name gin_trgm_ops);

-- ---------------------------------------------------------------------
-- People: one profile per Supabase Auth user, plus driver details
-- ---------------------------------------------------------------------
create table profiles (
  id                 uuid primary key references auth.users (id) on delete cascade,
  username           text        not null unique check (username ~ '^[a-z0-9_]{3,30}$'),
  full_name          text        not null check (length(btrim(full_name)) >= 2),
  phone              text        not null check (phone ~ '^\+[1-9][0-9]{7,14}$'),
  role               user_role   not null default 'passenger',
  country            text        not null default 'Sierra Leone',
  preferred_currency text        not null default 'NLe' check (preferred_currency in ('NLe', 'USD', 'EUR', 'GBP', 'CNY')),
  theme_dark         boolean     not null default false,
  accent             text        not null default 'green' check (accent in ('green', 'blue', 'purple', 'orange')),
  is_suspended       boolean     not null default false,
  suspend_reason     text,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now(),
  check (not is_suspended or suspend_reason is not null)
);
create index profiles_role_idx on profiles (role);
create index profiles_name_trgm on profiles using gin (full_name gin_trgm_ops);

create table drivers (
  profile_id          uuid primary key references profiles (id) on delete cascade,
  driver_type         text        not null references driver_types (driver_type),
  vehicle_description text        not null check (length(btrim(vehicle_description)) >= 2),
  plate_number        text        not null unique check (length(btrim(plate_number)) >= 3),
  is_verified         boolean     not null default false,
  verified_at         timestamptz,
  verified_by         uuid references profiles (id) on delete set null,
  created_at          timestamptz not null default now(),
  check (not is_verified or verified_at is not null)
);
create index drivers_type_idx on drivers (driver_type);

-- ---------------------------------------------------------------------
-- Fares and their history
-- ---------------------------------------------------------------------
create table fares (
  fare_id       bigint generated always as identity primary key,
  mode_name     text not null references transport_modes (mode_name),
  from_place_id smallint references places (place_id),
  to_place_id   smallint references places (place_id),
  is_flat       boolean       not null default false,   -- flat "pole to pole" fare
  amount_nle    numeric(10,2) check (amount_nle >= 0),  -- null = at the rider's discretion
  fare_type     text          not null,
  source        text          not null check (source in ('Official price list', 'Published sample (news)', 'Administrator update')),
  effective_from date         not null default current_date,
  updated_by    uuid references profiles (id) on delete set null,
  created_at    timestamptz   not null default now(),
  updated_at    timestamptz   not null default now(),
  check (
    (is_flat and from_place_id is null and to_place_id is null)
    or (not is_flat and from_place_id is not null and to_place_id is not null and from_place_id <> to_place_id)
  )
);
-- one fare per mode and route, in either direction; one flat fare per mode
create unique index fares_route_unique on fares (mode_name, least(from_place_id, to_place_id), greatest(from_place_id, to_place_id)) where not is_flat;
create unique index fares_flat_unique  on fares (mode_name) where is_flat;
create index fares_mode_idx on fares (mode_name);

create table fare_history (
  history_id      bigint generated always as identity primary key,
  fare_id         bigint not null references fares (fare_id) on delete cascade,
  old_amount_nle  numeric(10,2),
  new_amount_nle  numeric(10,2),
  changed_by      uuid references profiles (id) on delete set null,
  changed_at      timestamptz not null default now()
);
create index fare_history_fare_idx on fare_history (fare_id);

-- ---------------------------------------------------------------------
-- Transport requests, declined drivers and payments
-- ---------------------------------------------------------------------
create table transport_requests (
  request_id           bigint generated always as identity primary key,
  request_code         text generated always as ('REQ-' || request_id::text) stored,
  passenger_id         uuid     not null references profiles (id) on delete cascade,
  driver_id            uuid references drivers (profile_id) on delete restrict,
  pickup_place_id      smallint not null references places (place_id),
  destination_place_id smallint not null references places (place_id),
  mode_name            text     not null references transport_modes (mode_name),
  people               smallint not null check (people >= 1),
  free_seats           smallint not null default 0 check (free_seats >= 0),
  scheduled_at         timestamptz,                       -- null = as soon as possible
  note                 text check (length(note) <= 300),
  fare_text            text,
  fare_total_nle       numeric(12,2) check (fare_total_nle >= 0),
  pay_currency         text not null default 'NLe' check (pay_currency in ('NLe', 'USD', 'EUR', 'GBP', 'CNY')),
  pay_amount           numeric(12,2) check (pay_amount >= 0),
  pay_rate_nle         numeric(12,4) check (pay_rate_nle > 0),
  status               request_status not null default 'pending',
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now(),
  completed_at         timestamptz,
  check (pickup_place_id <> destination_place_id),
  check ((status = 'completed') = (completed_at is not null)),
  check (status <> 'pending' or driver_id is null),
  check (status not in ('awaiting_passenger', 'confirmed', 'completed') or driver_id is not null)
);
create index requests_passenger_idx on transport_requests (passenger_id, created_at desc);
create index requests_driver_idx    on transport_requests (driver_id, status);
create index requests_status_idx    on transport_requests (status, mode_name);

create table declined_drivers (
  request_id bigint not null references transport_requests (request_id) on delete cascade,
  driver_id  uuid   not null references drivers (profile_id) on delete cascade,
  declined_at timestamptz not null default now(),
  primary key (request_id, driver_id)
);

create table payments (
  payment_id bigint generated always as identity primary key,
  request_id bigint not null unique references transport_requests (request_id) on delete cascade,
  method     text   not null check (method in ('Cash to driver', 'Mobile money (demo)', 'Card (demo)')),
  currency   text   not null check (currency in ('NLe', 'USD', 'EUR', 'GBP', 'CNY')),
  amount     numeric(12,2) not null check (amount >= 0),
  status     text   not null default 'approved (demo)',
  paid_at    timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- Reviews, reports, notifications and audit trail
-- ---------------------------------------------------------------------
create table reviews (
  review_id    bigint generated always as identity primary key,
  request_id   bigint   not null unique references transport_requests (request_id) on delete cascade,
  driver_id    uuid     not null references drivers (profile_id) on delete cascade,
  passenger_id uuid     not null references profiles (id) on delete cascade,
  rating       smallint not null check (rating between 1 and 5),
  comment      text     check (length(comment) <= 500),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);
create index reviews_driver_idx on reviews (driver_id, created_at desc);

create table fare_reports (
  report_id            bigint generated always as identity primary key,
  passenger_id         uuid     not null references profiles (id) on delete cascade,
  pickup_place_id      smallint not null references places (place_id),
  destination_place_id smallint not null references places (place_id),
  mode_name            text     not null references transport_modes (mode_name),
  reported_amount_nle  numeric(10,2) not null check (reported_amount_nle > 0),
  system_fare_text     text,
  note                 text check (length(note) <= 500),
  status               report_status not null default 'pending_review',
  admin_response       text,
  reviewed_by          uuid references profiles (id) on delete set null,
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now(),
  check (pickup_place_id <> destination_place_id)
);
create index fare_reports_passenger_idx on fare_reports (passenger_id);
create index fare_reports_status_idx on fare_reports (status);

create table user_reports (
  report_id   bigint generated always as identity primary key,
  reporter_id uuid   not null references profiles (id) on delete cascade,
  subject_id  uuid   not null references profiles (id) on delete cascade,
  request_id  bigint not null references transport_requests (request_id) on delete cascade,
  report_text text   not null check (length(btrim(report_text)) >= 10),
  is_reviewed boolean not null default false,
  response    text,
  reviewed_by uuid references profiles (id) on delete set null,
  created_at  timestamptz not null default now(),
  check (reporter_id <> subject_id)
);
create index user_reports_open_idx on user_reports (is_reviewed);

create table notifications (
  notification_id bigint generated always as identity primary key,
  recipient_id    uuid not null references profiles (id) on delete cascade,
  message         text not null check (length(btrim(message)) > 0),
  request_id      bigint references transport_requests (request_id) on delete set null,
  is_read         boolean not null default false,
  created_at      timestamptz not null default now()
);
create index notifications_recipient_idx on notifications (recipient_id, is_read, created_at desc);

create table audit_logs (
  log_id     bigint generated always as identity primary key,
  actor_id   uuid references profiles (id) on delete set null,
  action     text not null,
  table_name text not null,
  record_id  text,
  details    jsonb,
  created_at timestamptz not null default now()
);
create index audit_logs_created_idx on audit_logs (created_at desc);
