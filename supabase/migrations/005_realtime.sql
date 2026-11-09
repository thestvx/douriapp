-- DOURI realtime publication (live queue)
--
-- Run in the Supabase SQL Editor after 001–004.
--
-- The app's live queue screens use Supabase Realtime (`.stream()`) on
-- `queue_entries`, `daily_queues`, `bookings` and `notifications`.
-- Realtime only delivers changes for tables in the `supabase_realtime`
-- publication; without this, the live streams can fail or never update.
-- The loop is idempotent — already-published tables are skipped.

do $$
declare
  t text;
begin
  foreach t in array['daily_queues', 'queue_entries', 'bookings', 'notifications'] loop
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = t
    ) then
      execute format('alter publication supabase_realtime add table %I', t);
    end if;
  end loop;
end $$;
