-- DOURI signup fields (email/password auth, barber onboarding)
--
-- Run after 001_init.sql / 002_functions.sql in the Supabase SQL Editor.
-- The barber signup wizard collects the number of chairs; there was no
-- column for it yet, so it is added here. Working hours already live in
-- barber_shops.working_hours (jsonb) and the salon address in `address`.

alter table if exists barber_shops
  add column if not exists chairs_count int not null default 1;
