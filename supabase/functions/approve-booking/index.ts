import { createClient } from "jsr:@supabase/supabase-js@2";

Deno.serve(async (req) => {
  const { bookingId } = await req.json();
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { data: queueNumber, error } = await supabase.rpc("approve_booking", {
    p_booking_id: bookingId,
  });

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 400 });
  }

  // Fetch booking to notify customer.
  const { data: booking } = await supabase
    .from("bookings")
    .select("customer_id")
    .eq("id", bookingId)
    .single();

  await supabase.from("notifications").insert({
    user_id: booking.customer_id,
    title: "Booking Approved",
    body: `Your booking has been confirmed! Your queue number is ${String(queueNumber).padStart(2, "0")}.`,
    notification_type: "booking_approved",
    booking_id: bookingId,
  });

  return new Response(JSON.stringify({ queueNumber }), {
    headers: { "Content-Type": "application/json" },
  });
});
