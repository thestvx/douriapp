-- DOURI realtime publication (live queue)
--
-- Run in the Supabase SQL Editor after 001–004.
--
-- The app's live queue screens use Supabase Realtime (`.stream()`) on
-- `queue_entries`, `daily_queues`, `bookings` and `notifications`.
-- Realtime only delivers changes for tables in the `supabase_realtime`
-- publication; without this, the live streams can fail or never update.
-- Each block is idempotent — already-published tables are skipped.

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'daily_queues'
  ) then
    alter publication supabase_realtime add table daily_queues;
  end if;

  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'queue_entries'
  ) then
    alter publication supabase_realtime add table queue_entries;
  end if;

  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'bookings'
  ) then
    alter publication supabase_realtime add table bookings;
  end if;

  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'notifications'
  ) then
    alter publication supabase_realtime add table notifications;
  end if;
end $$;
