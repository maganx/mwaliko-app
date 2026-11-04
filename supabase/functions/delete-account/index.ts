// POST /functions/v1/delete-account
// Body: { confirm: "FUTA" }
// Inafuta akaunti ya mteja aliyeingia: picha zake zote kwenye bucket "cards", kisha mtumiaji wa auth.
// Kufuta auth.users kunafuta kwa cascade: profiles, wallets, payments, credit_transactions, events,
// guests na deliveries. (Sharti la App Store 5.1.1(v) na Google Play: kufuta akaunti ndani ya app.)

import { createClient, type SupabaseClient } from "npm:@supabase/supabase-js@2.45.4";

const BUCKET = "cards";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...cors, "Content-Type": "application/json" } });

/** Njia zote za mafaili chini ya `prefix` (storage haina list ya ndani kwa ndani, kwa hiyo tunashuka folda kwa folda). */
async function listAll(admin: SupabaseClient, prefix: string): Promise<string[]> {
  const paths: string[] = [];
  const pageSize = 1000;
  for (let offset = 0;; offset += pageSize) {
    const { data, error } = await admin.storage.from(BUCKET).list(prefix, { limit: pageSize, offset });
    if (error) throw error;
    for (const item of data ?? []) {
      const path = `${prefix}/${item.name}`;
      // Folda haina id; faili lina id.
      if (item.id == null) paths.push(...(await listAll(admin, path)));
      else paths.push(path);
    }
    if (!data || data.length < pageSize) break;
  }
  return paths;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "Tumia POST" }, 405);

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const userClient = createClient(supabaseUrl, Deno.env.get("SUPABASE_ANON_KEY")!, {
    global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } },
  });
  const admin = createClient(supabaseUrl, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

  const { data: { user } } = await userClient.auth.getUser();
  if (!user) return json({ error: "Hujaingia (login)" }, 401);

  let body: { confirm?: string };
  try {
    body = await req.json();
  } catch {
    return json({ error: "Body si JSON sahihi" }, 400);
  }
  if (body.confirm !== "FUTA") return json({ error: 'Thibitisha kwa kuandika "FUTA"' }, 400);

  try {
    const files = await listAll(admin, user.id);
    for (let i = 0; i < files.length; i += 100) {
      const { error } = await admin.storage.from(BUCKET).remove(files.slice(i, i + 100));
      if (error) throw error;
    }
    const { error } = await admin.auth.admin.deleteUser(user.id);
    if (error) throw error;
    return json({ deleted: true, files: files.length });
  } catch (e) {
    console.error("delete-account", user.id, e);
    return json({ error: "Imeshindikana kufuta akaunti. Jaribu tena au wasiliana na msaada." }, 500);
  }
});
