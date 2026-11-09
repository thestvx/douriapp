import "jsr:@supabase/functions-js/edge-runtime.d.ts";

/// DOURI WhatsApp OTP delivery — Supabase Auth "Send SMS" hook.
///
/// Flow:
///   1. The Flutter app calls `supabase.auth.signInWithOtp(phone: ...)`.
///   2. Supabase Auth generates the 6-digit OTP, stores it, and POSTs it
///      to this function (configured as the Send SMS hook in the dashboard).
///   3. This function delivers the code over WhatsApp via Meta's Cloud API
///      using an approved AUTHENTICATION template (copy-code button).
///   4. The app calls `supabase.auth.verifyOtp(phone, token, type: 'sms')`
///      and Supabase checks the code. This function never sees or stores
///      the code beyond the single request — Supabase owns generation,
///      storage and verification.
///
/// Env vars (set with `supabase secrets set ...`):
///   WHATSAPP_ACCESS_TOKEN      Permanent System User token with
///                              whatsapp_business_messaging permission.
///   WHATSAPP_PHONE_NUMBER_ID   Numeric sender phone-number ID from
///                              Meta WhatsApp > API Setup (not the number).
///   WHATSAPP_TEMPLATE_NAME     Approved AUTHENTICATION template name
///                              (default: "douri_otp").
///   WHATSAPP_TEMPLATE_LANGUAGE Template language code (default: "en_US").
///   SEND_SMS_HOOK_SECRET       Optional. The `v1,whsec_...` secret
///                              generated when the hook is enabled in the
///                              Supabase dashboard. When set, the incoming
///                              Standard Webhooks signature is verified and
///                              unsigned requests are rejected.

const GRAPH_API_VERSION = "v21.0";

function base64ToBytes(b64: string): Uint8Array {
  const bin = atob(b64);
  const bytes = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
  return bytes;
}

function timingSafeEqual(a: Uint8Array, b: Uint8Array): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a[i] ^ b[i];
  return diff === 0;
}

/// Verify a Standard Webhooks signature (webhook-id / webhook-timestamp /
/// webhook-signature headers, signed content `${id}.${timestamp}.${body}`).
async function verifyHookSignature(
  req: Request,
  rawBody: string,
  secret: string,
): Promise<boolean> {
  const id = req.headers.get("webhook-id");
  const timestamp = req.headers.get("webhook-timestamp");
  const signatureHeader = req.headers.get("webhook-signature");
  if (!id || !timestamp || !signatureHeader) return false;

  // Secret arrives as `v1,whsec_<base64>`; the HMAC key is the decoded part.
  const whsec = secret.replace(/^v1,whsec_/, "");
  const key = await crypto.subtle.importKey(
    "raw",
    base64ToBytes(whsec),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signed = await crypto.subtle.sign(
    "HMAC",
    key,
    new TextEncoder().encode(`${id}.${timestamp}.${rawBody}`),
  );

  for (const part of signatureHeader.split(" ")) {
    const [version, value] = part.split(",");
    if (version !== "v1" || !value) continue;
    try {
      if (timingSafeEqual(new Uint8Array(signed), base64ToBytes(value))) {
        return true;
      }
    } catch {
      // Ignore malformed signature parts.
    }
  }
  return false;
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  const rawBody = await req.text();

  // 1. Authenticate the caller when a hook secret is configured.
  const hookSecret = Deno.env.get("SEND_SMS_HOOK_SECRET") ?? "";
  if (hookSecret) {
    const ok = await verifyHookSignature(req, rawBody, hookSecret);
    if (!ok) {
      console.error("send-whatsapp-otp: invalid hook signature");
      return new Response("Unauthorized", { status: 401 });
    }
  }

  // 2. Parse the Send SMS hook payload: { user: { phone }, sms: { otp } }.
  let payload: { user?: { phone?: string }; sms?: { otp?: string } };
  try {
    payload = JSON.parse(rawBody);
  } catch {
    return new Response("Bad request", { status: 400 });
  }
  const phone = payload.user?.phone ?? "";
  const otp = payload.sms?.otp ?? "";
  if (!phone || !otp) {
    console.error("send-whatsapp-otp: missing phone or otp in payload");
    return new Response("Bad request", { status: 400 });
  }

  const accessToken = Deno.env.get("WHATSAPP_ACCESS_TOKEN") ?? "";
  const phoneNumberId = Deno.env.get("WHATSAPP_PHONE_NUMBER_ID") ?? "";
  const templateName = Deno.env.get("WHATSAPP_TEMPLATE_NAME") ?? "douri_otp";
  const templateLanguage =
    Deno.env.get("WHATSAPP_TEMPLATE_LANGUAGE") ?? "en_US";
  if (!accessToken || !phoneNumberId) {
    console.error(
      "send-whatsapp-otp: WHATSAPP_ACCESS_TOKEN / WHATSAPP_PHONE_NUMBER_ID not set",
    );
    return new Response("Server misconfigured", { status: 500 });
  }

  // 3. Send the OTP as an approved AUTHENTICATION template. WhatsApp wants
  // the recipient in digits only (no +, spaces or dashes) and the code in
  // both the body and the copy-code button. Note: Meta stores the copy-code
  // button as a URL button, so the send payload must use sub_type "url"
  // (sending "copy_code" fails with error 132018).
  const to = phone.replace(/\D/g, "");
  const url =
    `https://graph.facebook.com/${GRAPH_API_VERSION}/${phoneNumberId}/messages`;
  const res = await fetch(url, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      messaging_product: "whatsapp",
      recipient_type: "individual",
      to,
      type: "template",
      template: {
        name: templateName,
        language: { code: templateLanguage },
        components: [
          {
            type: "body",
            parameters: [{ type: "text", text: otp }],
          },
          {
            type: "button",
            sub_type: "url",
            index: "0",
            parameters: [{ type: "text", text: otp }],
          },
        ],
      },
    }),
  });

  if (!res.ok) {
    const detail = await res.text();
    console.error(
      `send-whatsapp-otp: WhatsApp API ${res.status} for ${to}: ${detail}`,
    );
    return new Response("WhatsApp delivery failed", { status: 502 });
  }

  const sent = await res.json();
  console.log(`send-whatsapp-otp: OTP sent via WhatsApp to ${to}`, sent);

  // 4. Supabase expects an EMPTY body with a 200 on success — returning a
  // JSON receipt can make Supabase treat the hook call as failed even
  // though the message was sent.
  return new Response(null, { status: 200 });
});
