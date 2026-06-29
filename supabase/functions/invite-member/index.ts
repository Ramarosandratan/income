// Edge Function : invite-member
// Crée un nouveau compte membre dans la famille du maître appelant.
// Réservé au rôle « master » (vérifié via le JWT de l'appelant).
//
// Body attendu : { email: string, full_name: string, password?: string }

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Max-Age": "86400",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: cors });
  }

  try {
    const authHeader = req.headers.get("Authorization") ?? "";
    const url = Deno.env.get("SUPABASE_URL")!;
    const anon = Deno.env.get("SUPABASE_ANON_KEY")!;
    const service = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    // Client « appelant » : sert à vérifier le rôle via RLS.
    const caller = createClient(url, anon, {
      global: { headers: { Authorization: authHeader } },
    });

    // Id de l'appelant (depuis le JWT) : indispensable car un maître voit TOUS
    // les profils de sa famille — sans ce filtre, .single() échouerait dès qu'un
    // membre existe.
    const { data: userData } = await caller.auth.getUser();
    const callerId = userData.user?.id;
    if (!callerId) {
      return json({ error: "non authentifié" }, 401);
    }

    const { data: me, error: meErr } = await caller
      .from("profiles")
      .select("family_id, role")
      .eq("id", callerId)
      .single();

    if (meErr || !me) {
      return json({ error: "non authentifié" }, 401);
    }
    if (me.role !== "master") {
      return json({ error: "réservé au maître" }, 403);
    }

    const { email, full_name, password } = await req.json();
    if (!email || !full_name) {
      return json({ error: "email et full_name requis" }, 400);
    }

    // Client admin (service role) : crée le compte et le profil.
    const admin = createClient(url, service);
    const tempPassword = password ?? crypto.randomUUID().slice(0, 12);

    const { data: created, error: createErr } =
      await admin.auth.admin.createUser({
        email,
        password: tempPassword,
        email_confirm: true,
        user_metadata: { full_name },
      });
    if (createErr || !created.user) {
      const msg = friendlyAuthError(createErr?.message ?? "") ||
        createErr?.message ||
        "Échec de la création du compte.";
      return json({ error: msg }, 400);
    }

    const { error: profErr } = await admin.from("profiles").insert({
      id: created.user.id,
      family_id: me.family_id,
      full_name,
      role: "member",
    });
    if (profErr) {
      // Rollback du compte si le profil échoue.
      await admin.auth.admin.deleteUser(created.user.id);
      return json({ error: profErr.message }, 400);
    }

    return json({
      ok: true,
      member_id: created.user.id,
      temp_password: tempPassword,
    });
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
}

function friendlyAuthError(message: string): string | null {
  const m = message.toLowerCase();
  if (m.includes("user already registered") ||
      (m.includes("duplicate") && m.includes("email"))) {
    return "Un compte existe déjà avec cet email.";
  }
  if (m.includes("password should be at least")) {
    return "Le mot de passe doit contenir au moins 6 caractères.";
  }
  if (m.includes("invalid email")) {
    return "Format d'email invalide.";
  }
  if (m.includes("rate limit")) {
    return "Trop de tentatives. Veuillez réessayer dans quelques minutes.";
  }
  return null;
}
