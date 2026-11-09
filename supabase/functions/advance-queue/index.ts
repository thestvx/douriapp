import { createClient } from "jsr:@supabase/supabase-js@2";

Deno.serve(async (req) => {
  const { shopId, date } = await req.json();
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { data: customerId, error } = await supabase.rpc("advance_queue", {
    p_shop_id: shopId,
    p_date: date,
  });

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 400 });
  }

  if (customerId) {
    await supabase.from("notifications").insert({
      user_id: customerId,
      title: "Your Turn",
      body: "Your turn has arrived! Please get ready.",
      notification_type: "turn_arrived",
    });
  }

  return new Response(JSON.stringify({ customerId }), {
    headers: { "Content-Type": "application/json" },
  });
});
