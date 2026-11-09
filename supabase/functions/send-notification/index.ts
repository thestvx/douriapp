import "jsr:@supabase/functions-js/edge-runtime.d.ts";

Deno.serve(async (req) => {
  const { token, title, body } = await req.json();
  // TODO: Use Firebase HTTP v1 with service account stored in secrets.
  console.log("Send notification", token, title, body);
  return new Response(JSON.stringify({ ok: true }), {
    headers: { "Content-Type": "application/json" },
  });
});
