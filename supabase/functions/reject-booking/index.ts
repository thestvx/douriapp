import { createClient } from "jsr:@supabase/supabase-js@2";

Deno.serve(async (req) => {
  const { bookingId, reason } = await req.json();
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { error } = await supabase.rpc("reject_booking", {
    p_booking_id: bookingId,
    p_reason: reason ?? null,
  });

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 400 });
  }

  const { data: booking } = await supabase
    .from("bookings")
    .select("customer_id")
    .eq("id", bookingId)
    .single();

  await supabase.from("notifications").insert({
    user_id: booking.customer_id,
    title: "Booking Rejected",
    body: "Your booking request was rejected.",
    notification_type: "booking_rejected",
    booking_id: bookingId,
  });

  return new Response(JSON.stringify({ ok: true }), {
    headers: { "Content-Type": "application/json" },
  });
});
