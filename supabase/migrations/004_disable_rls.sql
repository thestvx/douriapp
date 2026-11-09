-- DOURI: disable RLS on app tables (fix 42501 on signup)
--
-- Run in the Supabase SQL Editor after 001 / 002 / 003.
--
-- Why: the `profiles` table (and others) has Row Level Security enabled
-- in this project, but there is no INSERT policy for it — so creating a
-- profile during signup fails with:
--   "new row violates row-level security policy for table 'profiles'
--    (code 42501)"
-- DOURI's identity lives in Firebase Auth, not Supabase Auth, so there
-- is no Supabase JWT for RLS policies to check (`auth.uid()` is always
-- null from the app). Per-user RLS therefore cannot work in this
-- architecture; the tables are accessed with the publishable (anon) key
-- as the migrations originally assumed. If login ever moves to Supabase
-- Auth, re-enable RLS here and add policies keyed on `auth.uid()`.

alter table if exists profiles disable row level security;
alter table if exists barber_shops disable row level security;
alter table if exists shop_services disable row level security;
alter table if exists bookings disable row level security;
alter table if exists daily_queues disable row level security;
alter table if exists queue_entries disable row level security;
alter table if exists notifications disable row level security;
alter table if exists reviews disable row level security;
alter table if exists device_tokens disable row level security;
