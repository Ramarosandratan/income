-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║ Row Level Security                                                      ║
-- ║                                                                          ║
-- ║  master : accès complet aux données de SA famille                       ║
-- ║  member : ses propres dépenses (lecture/écriture), lecture seule de ses  ║
-- ║           budgets/catégories ; aucun accès aux données des autres        ║
-- ╚══════════════════════════════════════════════════════════════════════╝

alter table public.families            enable row level security;
alter table public.profiles            enable row level security;
alter table public.categories          enable row level security;
alter table public.incomes             enable row level security;
alter table public.budgets             enable row level security;
alter table public.expenses            enable row level security;
alter table public.recurring_templates enable row level security;
alter table public.savings_goals       enable row level security;
alter table public.alerts              enable row level security;

-- ── families ────────────────────────────────────────────────────────────────
create policy families_select on public.families
  for select using (id = public.auth_family_id());
create policy families_update on public.families
  for update using (public.auth_is_master() and id = public.auth_family_id());

-- ── profiles ──────────────────────────────────────────────────────────────────
create policy profiles_select on public.profiles
  for select using (
    id = auth.uid()
    or (public.auth_is_master() and family_id = public.auth_family_id())
  );
create policy profiles_update on public.profiles
  for update using (
    id = auth.uid()
    or (public.auth_is_master() and family_id = public.auth_family_id())
  );

-- ── categories (lecture famille, écriture maître) ─────────────────────────────
create policy categories_select on public.categories
  for select using (family_id = public.auth_family_id());
create policy categories_write on public.categories
  for all using (public.auth_is_master() and family_id = public.auth_family_id())
  with check (public.auth_is_master() and family_id = public.auth_family_id());

-- ── incomes (maître : famille ; membre : les siens en lecture) ────────────────
create policy incomes_select on public.incomes
  for select using (
    family_id = public.auth_family_id()
    and (public.auth_is_master() or member_id = auth.uid())
  );
create policy incomes_write on public.incomes
  for all using (public.auth_is_master() and family_id = public.auth_family_id())
  with check (public.auth_is_master() and family_id = public.auth_family_id());

-- ── budgets (maître écrit ; membre lit les siens) ─────────────────────────────
create policy budgets_select on public.budgets
  for select using (
    family_id = public.auth_family_id()
    and (public.auth_is_master() or member_id = auth.uid())
  );
create policy budgets_write on public.budgets
  for all using (public.auth_is_master() and family_id = public.auth_family_id())
  with check (public.auth_is_master() and family_id = public.auth_family_id());

-- ── expenses (membre gère les siennes ; maître voit/édite tout) ───────────────
create policy expenses_select on public.expenses
  for select using (
    family_id = public.auth_family_id()
    and (public.auth_is_master() or member_id = auth.uid())
  );
create policy expenses_insert on public.expenses
  for insert with check (
    family_id = public.auth_family_id()
    and (public.auth_is_master() or member_id = auth.uid())
  );
create policy expenses_update on public.expenses
  for update using (
    family_id = public.auth_family_id()
    and (public.auth_is_master() or member_id = auth.uid())
  );
create policy expenses_delete on public.expenses
  for delete using (
    family_id = public.auth_family_id()
    and (public.auth_is_master() or member_id = auth.uid())
  );

-- ── recurring_templates (maître gère ; membre lit les siens) ──────────────────
create policy recurring_select on public.recurring_templates
  for select using (
    family_id = public.auth_family_id()
    and (public.auth_is_master() or member_id = auth.uid())
  );
create policy recurring_write on public.recurring_templates
  for all using (public.auth_is_master() and family_id = public.auth_family_id())
  with check (public.auth_is_master() and family_id = public.auth_family_id());

-- ── savings_goals (maître gère ; membre lit les siens + familiaux) ────────────
create policy savings_select on public.savings_goals
  for select using (
    family_id = public.auth_family_id()
    and (public.auth_is_master() or member_id is null or member_id = auth.uid())
  );
create policy savings_write on public.savings_goals
  for all using (public.auth_is_master() and family_id = public.auth_family_id())
  with check (public.auth_is_master() and family_id = public.auth_family_id());

-- ── alerts (membre : les siennes ; maître : celles de sa famille) ─────────────
create policy alerts_select on public.alerts
  for select using (
    member_id = auth.uid()
    or (public.auth_is_master()
        and member_id in (select id from public.profiles
                          where family_id = public.auth_family_id()))
  );
create policy alerts_update on public.alerts
  for update using (
    member_id = auth.uid()
    or (public.auth_is_master()
        and member_id in (select id from public.profiles
                          where family_id = public.auth_family_id()))
  );
