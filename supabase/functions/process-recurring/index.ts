// Edge Function : process-recurring
// Génère les écritures (dépenses/revenus) à partir des modèles récurrents
// arrivés à échéance (next_run <= aujourd'hui), puis avance next_run.
//
// À planifier via pg_cron / Supabase Scheduled Functions (ex. tous les jours) :
//   select cron.schedule('process-recurring', '0 6 * * *',
//     $$ select net.http_post('https://<projet>.functions.supabase.co/process-recurring',
//        headers := '{"Authorization":"Bearer <service-role>"}') $$);

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

Deno.serve(async (_req) => {
  const url = Deno.env.get("SUPABASE_URL")!;
  const service = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const db = createClient(url, service);

  const today = new Date();
  const todayStr = today.toISOString().slice(0, 10);

  const { data: templates, error } = await db
    .from("recurring_templates")
    .select("*")
    .eq("active", true)
    .lte("next_run", todayStr);

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
    });
  }

  let generated = 0;
  for (const t of templates ?? []) {
    if (t.kind === "income") {
      await db.from("incomes").insert({
        family_id: t.family_id,
        member_id: t.member_id,
        source: t.label,
        amount: t.amount,
        period: firstOfMonth(today),
        is_recurring: true,
      });
    } else {
      await db.from("expenses").insert({
        family_id: t.family_id,
        member_id: t.member_id,
        category_id: t.category_id,
        amount: t.amount,
        note: t.label,
        spent_at: today.toISOString(),
        type: "fixed",
        recurring_template_id: t.id,
      });
    }
    generated++;

    await db
      .from("recurring_templates")
      .update({ next_run: advance(t.next_run, t.frequency) })
      .eq("id", t.id);
  }

  return new Response(JSON.stringify({ ok: true, generated }), {
    headers: { "Content-Type": "application/json" },
  });
});

function firstOfMonth(d: Date): string {
  return new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), 1))
    .toISOString()
    .slice(0, 10);
}

function advance(date: string, frequency: string): string {
  const d = new Date(date + "T00:00:00Z");
  if (frequency === "weekly") {
    d.setUTCDate(d.getUTCDate() + 7);
  } else {
    d.setUTCMonth(d.getUTCMonth() + 1);
  }
  return d.toISOString().slice(0, 10);
}
