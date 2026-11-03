// Watoa huduma wa kutuma ujumbe: SMS (Beem / Africa's Talking), WhatsApp Cloud API, Resend (email).
// Funguo zote zinasomwa kutoka kwenye secrets za Supabase (supabase secrets set ...).

export type SendResult = { ok: true; providerId?: string } | { ok: false; error: string };

const env = (k: string, fallback?: string): string => {
  const v = Deno.env.get(k) ?? fallback;
  if (v === undefined || v === "") throw new Error(`Secret haipo: ${k}`);
  return v;
};

async function readError(res: Response): Promise<string> {
  const body = await res.text();
  return `HTTP ${res.status}: ${body.slice(0, 300)}`;
}

// ---------------------------------------------------------------------------
// SMS
// ---------------------------------------------------------------------------
export async function sendSms(to: string, message: string): Promise<SendResult> {
  const provider = Deno.env.get("SMS_PROVIDER") ?? "beem";
  try {
    return provider === "africastalking"
      ? await sendSmsAfricasTalking(to, message)
      : await sendSmsBeem(to, message);
  } catch (e) {
    return { ok: false, error: String(e) };
  }
}

// https://docs.beem.africa  (POST /v1/send)
async function sendSmsBeem(to: string, message: string): Promise<SendResult> {
  const auth = btoa(`${env("BEEM_API_KEY")}:${env("BEEM_SECRET_KEY")}`);
  const res = await fetch("https://apisms.beem.africa/v1/send", {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: `Basic ${auth}` },
    body: JSON.stringify({
      source_addr: env("BEEM_SENDER_ID", "INFO"),
      schedule_time: "",
      encoding: 0,
      message,
      recipients: [{ recipient_id: 1, dest_addr: to }],
    }),
  });
  if (!res.ok) return { ok: false, error: await readError(res) };
  const data = await res.json();
  if (data.successful === false) return { ok: false, error: data.message ?? "Beem imekataa" };
  return { ok: true, providerId: data.request_id != null ? String(data.request_id) : undefined };
}

// https://developers.africastalking.com/docs/sms/sending
async function sendSmsAfricasTalking(to: string, message: string): Promise<SendResult> {
  const form = new URLSearchParams({
    username: env("AT_USERNAME"),
    to: `+${to}`,
    message,
  });
  const from = Deno.env.get("AT_SENDER_ID");
  if (from) form.set("from", from);

  const host = env("AT_USERNAME") === "sandbox"
    ? "https://api.sandbox.africastalking.com"
    : "https://api.africastalking.com";
  const res = await fetch(`${host}/version1/messaging`, {
    method: "POST",
    headers: {
      apiKey: env("AT_API_KEY"),
      Accept: "application/json",
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: form,
  });
  if (!res.ok) return { ok: false, error: await readError(res) };
  const data = await res.json();
  const r = data?.SMSMessageData?.Recipients?.[0];
  if (!r || r.status !== "Success") {
    return { ok: false, error: r?.status ?? data?.SMSMessageData?.Message ?? "Africa's Talking imekataa" };
  }
  return { ok: true, providerId: r.messageId };
}

// ---------------------------------------------------------------------------
// WhatsApp Cloud API (Meta)
// Ujumbe wa kwanza kwa mteja lazima uwe "template" iliyokubaliwa na Meta.
// Template inayotarajiwa (angalia README): header ya picha + body yenye {{1}}..{{4}}.
// ---------------------------------------------------------------------------
export async function sendWhatsApp(
  to: string,
  params: { imageUrl?: string; guestName: string; eventTitle: string; eventDate: string; rsvpUrl: string },
): Promise<SendResult> {
  try {
    const version = Deno.env.get("WHATSAPP_API_VERSION") ?? "v21.0";
    const url = `https://graph.facebook.com/${version}/${env("WHATSAPP_PHONE_NUMBER_ID")}/messages`;

    const components: unknown[] = [];
    if (params.imageUrl) {
      components.push({ type: "header", parameters: [{ type: "image", image: { link: params.imageUrl } }] });
    }
    components.push({
      type: "body",
      parameters: [params.guestName, params.eventTitle, params.eventDate, params.rsvpUrl].map((text) => ({
        type: "text",
        text,
      })),
    });

    const res = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: `Bearer ${env("WHATSAPP_TOKEN")}` },
      body: JSON.stringify({
        messaging_product: "whatsapp",
        to,
        type: "template",
        template: {
          name: env("WHATSAPP_TEMPLATE_NAME", "mwaliko_kadi"),
          language: { code: env("WHATSAPP_TEMPLATE_LANG", "sw") },
          components,
        },
      }),
    });
    if (!res.ok) return { ok: false, error: await readError(res) };
    const data = await res.json();
    return { ok: true, providerId: data?.messages?.[0]?.id };
  } catch (e) {
    return { ok: false, error: String(e) };
  }
}

// ---------------------------------------------------------------------------
// Email (Resend)  https://resend.com/docs/api-reference/emails/send-email
// ---------------------------------------------------------------------------
export async function sendEmail(to: string, subject: string, html: string): Promise<SendResult> {
  try {
    const res = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: `Bearer ${env("RESEND_API_KEY")}` },
      body: JSON.stringify({ from: env("EMAIL_FROM"), to: [to], subject, html }),
    });
    if (!res.ok) return { ok: false, error: await readError(res) };
    const data = await res.json();
    return { ok: true, providerId: data?.id };
  } catch (e) {
    return { ok: false, error: String(e) };
  }
}
