// deno-lint-ignore-file no-explicit-any
// Webhook ya WhatsApp Cloud API: inapokea taarifa za "delivered" / "read" / "failed"
// na kusasisha jedwali la "deliveries".
// Weka URL hii kwenye Meta App Dashboard > WhatsApp > Configuration > Webhook,
// na verify token sawa na secret WHATSAPP_VERIFY_TOKEN. Deploy na --no-verify-jwt.

import { createClient } from "npm:@supabase/supabase-js@2.45.4";

const STATUS_MAP: Record<string, string> = {
  sent: "sent",
  delivered: "delivered",
  read: "read",
  failed: "failed",
};

// Meta inasaini kila POST kwa HMAC-SHA256 ya App Secret (header X-Hub-Signature-256).
async function validSignature(raw: string, header: string | null): Promise<boolean> {
  const secret = Deno.env.get("WHATSAPP_APP_SECRET");
  if (!secret) return false;
  if (!header?.startsWith("sha256=")) return false;
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const mac = new Uint8Array(await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(raw)));
  const expected = Array.from(mac, (b) => b.toString(16).padStart(2, "0")).join("");
  const given = header.slice("sha256=".length);
  if (given.length !== expected.length) return false;
  let diff = 0;
  for (let i = 0; i < expected.length; i++) diff |= expected.charCodeAt(i) ^ given.charCodeAt(i);
  return diff === 0;
}

Deno.serve(async (req) => {
  const url = new URL(req.url);

  // Uthibitisho wa mwanzo kutoka Meta
  if (req.method === "GET") {
    const ok = url.searchParams.get("hub.mode") === "subscribe" &&
      url.searchParams.get("hub.verify_token") === Deno.env.get("WHATSAPP_VERIFY_TOKEN");
    return ok ? new Response(url.searchParams.get("hub.challenge") ?? "") : new Response("Forbidden", { status: 403 });
  }

  if (req.method !== "POST") return new Response("Method not allowed", { status: 405 });

  const raw = await req.text();
  if (!(await validSignature(raw, req.headers.get("X-Hub-Signature-256")))) {
    return new Response("Invalid signature", { status: 401 });
  }

  const admin = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  let payload: any = null;
  try {
    payload = JSON.parse(raw);
  } catch {
    return new Response("Bad JSON", { status: 400 });
  }

  for (const entry of payload?.entry ?? []) {
    for (const change of entry.changes ?? []) {
      for (const s of change.value?.statuses ?? []) {
        const status = STATUS_MAP[s.status];
        if (!status || !s.id) continue;
        await admin
          .from("deliveries")
          .update({ status, error: s.errors?.[0]?.title ?? null })
          .eq("provider_message_id", s.id)
          .eq("channel", "whatsapp");
      }
    }
  }

  // Meta inahitaji jibu la 200 haraka
  return new Response("ok");
});
