-- DOURI: booking RPCs that work with Firebase Auth + customer notifications
--
-- Run in the Supabase SQL Editor after 001–005.
--
-- Two fixes in one migration:
--
-- 1) `approve_booking`, `reject_booking` and `advance_queue` all checked
--    `auth.jwt() ->> 'sub'` for ownership. DOURI's identity lives in
--    Firebase Auth, so there is no Supabase JWT — `auth.jwt()` is always
--    null and every barber approval/rejection/advance failed with
--    "Not authorized". That also meant a booking could never get a queue
--    number. The checks are removed: these functions are `security
--    definer` and the project already runs with RLS disabled (004), so
--    the anon key is the trust boundary, as documented there. The
--    proper long-term fix is moving login to Supabase Auth, which would
--    let these checks come back keyed on `auth.uid()`.
--
-- 2) Approving/rejecting now writes a row into `notifications` for the
--    customer, so "you will be notified" is real: the customer is told
--    their queue number the moment the barber accepts (the booking
--    success screen also watches the queue entry live).

create or replace function approve_booking(p_booking_id uuid)
returns int
language plpgsql
security definer
as $$
declare
  v_booking bookings%rowtype;
  v_shop barber_shops%rowtype;
  v_queue daily_queues%rowtype;
  v_next int;
begin
  select * into v_booking from bookings where id = p_booking_id for update;
  if not found then raise exception 'Booking not found'; end if;
  if v_booking.status <> 'PENDING' then raise exception 'Booking is not pending'; end if;

  select * into v_shop from barber_shops where id = v_booking.barber_shop_id;

  -- ensure daily queue
  insert into daily_queues (barber_shop_id, queue_date)
  values (v_booking.barber_shop_id, v_booking.booking_date)
  on conflict (barber_shop_id, queue_date) do nothing;

  select * into v_queue from daily_queues
  where barber_shop_id = v_booking.barber_shop_id and queue_date = v_booking.booking_date
  for update;

  v_next := v_queue.last_assigned_number + 1;

  update bookings set status = 'CONFIRMED', queue_number = v_next, updated_at = now()
  where id = p_booking_id;

  insert into queue_entries (daily_queue_id, booking_id, customer_id, queue_number, status)
  values (v_queue.id, v_booking.id, v_booking.customer_id, v_next, 'WAITING');

  update daily_queues set last_assigned_number = v_next, updated_at = now()
  where id = v_queue.id;

  insert into notifications (user_id, title, body, notification_type, booking_id)
  values (
    v_booking.customer_id,
    'تم قبول حجزك',
    'قبل ' || v_shop.shop_name || ' طلبك — رقم طابورك ' || v_next || '.',
    'booking_accepted',
    p_booking_id
  );

  return v_next;
end;
$$;

create or replace function reject_booking(p_booking_id uuid, p_reason text)
returns void
language plpgsql
security definer
as $$
declare
  v_booking bookings%rowtype;
  v_shop barber_shops%rowtype;
begin
  select * into v_booking from bookings where id = p_booking_id for update;
  if not found then raise exception 'Booking not found'; end if;
  if v_booking.status <> 'PENDING' then raise exception 'Booking is not pending'; end if;

  select * into v_shop from barber_shops where id = v_booking.barber_shop_id;

  update bookings set status = 'REJECTED', rejection_reason = p_reason, updated_at = now()
  where id = p_booking_id;

  insert into notifications (user_id, title, body, notification_type, booking_id)
  values (
    v_booking.customer_id,
    'تم رفض حجزك',
    'رفض ' || v_shop.shop_name || ' طلب حجزك.'
      || case when p_reason is not null and p_reason <> ''
              then ' السبب: ' || p_reason else '' end,
    'booking_rejected',
    p_booking_id
  );
end;
$$;

create or replace function advance_queue(p_shop_id uuid, p_date date)
returns text
language plpgsql
security definer
as $$
declare
  v_queue daily_queues%rowtype;
  v_current queue_entries%rowtype;
  v_next queue_entries%rowtype;
begin
  select * into v_queue from daily_queues
  where barber_shop_id = p_shop_id and queue_date = p_date for update;
  if not found then raise exception 'Queue not found'; end if;

  -- complete current
  update queue_entries set status = 'COMPLETED', completed_at = now()
  where daily_queue_id = v_queue.id and status = 'CURRENT';

  -- find next waiting
  select * into v_next from queue_entries
  where daily_queue_id = v_queue.id and status = 'WAITING'
  order by queue_number asc
  limit 1
  for update;

  if found then
    update queue_entries set status = 'CURRENT', called_at = now()
    where id = v_next.id;
    update daily_queues set current_queue_number = v_next.queue_number, updated_at = now()
    where id = v_queue.id;
    return v_next.customer_id;
  else
    update daily_queues set current_queue_number = null, queue_status = 'ENDED', ended_at = now(), updated_at = now()
    where id = v_queue.id;
    return null;
  end if;
end;
$$;
