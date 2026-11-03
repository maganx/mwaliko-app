// POST /functions/v1/send-invitations
// Body: { event_id: string, guest_ids?: string[], channels: ("sms"|"whatsapp"|"email")[] }
// Inatuma mwaliko kwa kila mwalikwa kwa njia zilizochaguliwa, na kuandika matokeo kwenye "deliveries".
// App inatuma waalikwa kwa vikundi (mf. 25 kwa mara moja) ili function isizidi muda wake.

import { createClient } from "npm:@supabase/supabase-js@2.45.4";
import { sendEmail, sendSms, sendWhatsApp, type SendResult } from "../_shared/providers.ts";

type Channel = "sms" | "whatsapp" | "email";
const CHANNELS: Channel[] = ["sms", "whatsapp", "email"];
const MAX_GUESTS_PER_CALL = 50;

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...cors, "Content-Type": "application/json" } });

function formatDate(iso: string): string {
  return new Date(iso).toLocaleString("sw-TZ", {
    timeZone: Deno.env.get("EVENT_TIMEZONE") ?? "Africa/Dar_es_Salaam",
    weekday: "long",
    day: "numeric",
    month: "long",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}

const escapeHtml = (s: string) =>
  s.replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]!);

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "Tumia POST" }, 405);

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const authHeader = req.headers.get("Authorization") ?? "";

  // Client ya mtumiaji: RLS inahakikisha anaona matukio yake tu.
  const userClient = createClient(supabaseUrl, Deno.env.get("SUPABASE_ANON_KEY")!, {
    global: { headers: { Authorization: authHeader } },
  });
  // Client ya admin: kuandika kwenye "deliveries" (mtumiaji hana ruhusa ya kuandika moja kwa moja).
  const admin = createClient(supabaseUrl, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

  const { data: { user } } = await userClient.auth.getUser();
  if (!user) return json({ error: "Hujaingia (login)" }, 401);

  let body: { event_id?: string; guest_ids?: string[]; channels?: string[] };
  try {
    body = await req.json();
  } catch {
    return json({ error: "Body si JSON sahihi" }, 400);
  }

  const channels = (body.channels ?? []).filter((c): c is Channel => CHANNELS.includes(c as Channel));
  if (!body.event_id || channels.length === 0) {
    return json({ error: "event_id na channels zinahitajika" }, 400);
  }
  if (body.guest_ids && body.guest_ids.length > MAX_GUESTS_PER_CALL) {
    return json({ error: `Waalikwa wasizidi ${MAX_GUESTS_PER_CALL} kwa mara moja` }, 400);
  }

  const { data: event, error: eventError } = await userClient
    .from("events")
    .select("*")
    .eq("id", body.event_id)
    .maybeSingle();
  if (eventError) return json({ error: eventError.message }, 500);
  if (!event) return json({ error: "Tukio halikupatikana" }, 404);

  let guestQuery = userClient.from("guests").select("*").eq("event_id", event.id).order("name");
  if (body.guest_ids?.length) guestQuery = guestQuery.in("id", body.guest_ids);
  else guestQuery = guestQuery.limit(MAX_GUESTS_PER_CALL);
  const { data: guests, error: guestsError } = await guestQuery;
  if (guestsError) return json({ error: guestsError.message }, 500);

  const rsvpBase = Deno.env.get("RSVP_BASE_URL") ?? "";
  const publicUrl = (path?: string | null) =>
    path ? admin.storage.from("cards").getPublicUrl(path).data.publicUrl : undefined;
  const eventDate = formatDate(event.event_date);
  const hosts = event.host_names ? `${event.host_names} ` : "";

  const summary = { sent: 0, failed: 0, skipped: 0, results: [] as unknown[] };

  for (const guest of guests ?? []) {
    const rsvpUrl = rsvpBase ? `${rsvpBase}?t=${guest.rsvp_token}` : "";
    const cardUrl = publicUrl(guest.card_path) ?? publicUrl(event.card_config?.custom_image_path);

    const tasks: Promise<void>[] = channels.map(async (channel) => {
      let result: SendResult;
      if (channel === "sms") {
        if (!guest.phone) return void summary.skipped++;
        const sms = `Habari ${guest.name}, ${hosts}wanakualika kwenye ${event.title}, ${eventDate}` +
          (event.venue ? `, ${event.venue}` : "") +
          (rsvpUrl ? `. Kadi yako na kuthibitisha: ${rsvpUrl}` : ".");
        result = await sendSms(guest.phone, sms);
      } else if (channel === "whatsapp") {
        if (!guest.phone) return void summary.skipped++;
        result = await sendWhatsApp(guest.phone, {
          imageUrl: cardUrl,
          guestName: guest.name,
          eventTitle: event.title,
          eventDate,
          rsvpUrl: rsvpUrl || "-",
        });
      } else {
        if (!guest.email) return void summary.skipped++;
        const html = `
          <div style="font-family:Georgia,serif;max-width:560px;margin:auto;text-align:center;color:#222">
            <p>Habari <b>${escapeHtml(guest.name)}</b>,</p>
            <p>${escapeHtml(hosts)}wanayo furaha kukualika kwenye</p>
            <h2 style="margin:8px 0">${escapeHtml(event.title)}</h2>
            <p>${escapeHtml(eventDate)}${event.venue ? `<br>${escapeHtml(event.venue)}` : ""}</p>
            ${cardUrl ? `<img src="${cardUrl}" alt="Kadi ya mwaliko" style="width:100%;border-radius:12px;margin:16px 0">` : ""}
            ${rsvpUrl ? `<p><a href="${rsvpUrl}" style="background:#7a1f3d;color:#fff;padding:12px 24px;border-radius:24px;text-decoration:none">Thibitisha kuhudhuria</a></p>` : ""}
          </div>`;
        result = await sendEmail(guest.email, `Mwaliko: ${event.title}`, html);
      }

      if (result.ok) summary.sent++;
      else summary.failed++;
      summary.results.push({ guest_id: guest.id, channel, ...result });

      await admin.from("deliveries").insert({
        event_id: event.id,
        guest_id: guest.id,
        channel,
        status: result.ok ? "sent" : "failed",
        provider_message_id: result.ok ? result.providerId ?? null : null,
        error: result.ok ? null : result.error,
      });
    });

    await Promise.all(tasks);
  }

  return json(summary);
});
