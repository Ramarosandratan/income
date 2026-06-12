-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║ Fonctions, RPC et déclencheurs                                          ║
-- ╚══════════════════════════════════════════════════════════════════════╝

-- ── Helpers d'autorisation ────────────────────────────────────────────────
-- security definer pour éviter la récursion RLS quand on lit profiles depuis
-- une policy sur profiles.

create or replace function public.auth_family_id()
returns uuid
language sql stable security definer set search_path = public
as $$
  select family_id from public.profiles where id = auth.uid();
$$;

create or replace function public.auth_is_master()
returns boolean
language sql stable security definer set search_path = public
as $$
  select coalesce(
    (select role = 'master' from public.profiles where id = auth.uid()),
    false
  );
$$;

-- ── Bootstrap : crée la famille + le profil maître pour l'utilisateur courant ──
create or replace function public.bootstrap_family(
  p_full_name text,
  p_family_name text
)
returns uuid
language plpgsql security definer set search_path = public
as $$
declare
  v_family_id uuid;
begin
  if auth.uid() is null then
    raise exception 'non authentifié';
  end if;
  if exists (select 1 from public.profiles where id = auth.uid()) then
    raise exception 'profil déjà existant';
  end if;

  insert into public.families (name) values (p_family_name)
    returning id into v_family_id;

  insert into public.profiles (id, family_id, full_name, role)
    values (auth.uid(), v_family_id, p_full_name, 'master');

  -- Catégories de départ.
  insert into public.categories (family_id, name, icon, color, kind) values
    (v_family_id, 'Alimentation',  'restaurant',      'FF4CAF50', 'expense'),
    (v_family_id, 'Transport',     'directions_car',  'FF2196F3', 'expense'),
    (v_family_id, 'Logement',      'home',            'FF795548', 'expense'),
    (v_family_id, 'Loisirs',       'sports_esports',  'FF9C27B0', 'expense'),
    (v_family_id, 'Santé',         'favorite',        'FFE91E63', 'expense'),
    (v_family_id, 'Factures',      'receipt_long',    'FFFF9800', 'expense'),
    (v_family_id, 'Salaire',       'payments',        'FF009688', 'income');

  return v_family_id;
end;
$$;

-- ── Recopie des budgets vers le mois suivant ─────────────────────────────────
create or replace function public.copy_budgets_to_next_month(p_from_period date)
returns integer
language plpgsql security definer set search_path = public
as $$
declare
  v_count integer;
begin
  if not public.auth_is_master() then
    raise exception 'réservé au maître';
  end if;

  insert into public.budgets (family_id, member_id, category_id, period, amount, type)
  select family_id, member_id, category_id,
         (date_trunc('month', p_from_period) + interval '1 month')::date,
         amount, type
  from public.budgets
  where family_id = public.auth_family_id()
    and period = date_trunc('month', p_from_period)::date
  on conflict do nothing;

  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

-- ── Contribution à un objectif d'épargne ─────────────────────────────────────
create or replace function public.add_savings_contribution(
  p_goal_id uuid,
  p_amount numeric
)
returns void
language plpgsql security definer set search_path = public
as $$
begin
  update public.savings_goals
     set current_amount = current_amount + p_amount
   where id = p_goal_id
     and family_id = public.auth_family_id();
end;
$$;

-- ── Déclencheur d'alerte budgétaire ──────────────────────────────────────────
-- À chaque dépense, recalcule l'enveloppe globale du membre pour le mois et
-- crée une alerte si le seuil 80 % (avertissement) ou 100 % (dépassement) est
-- franchi — sans dupliquer une alerte non lue du même type pour ce mois.
create or replace function public.check_budget_alert()
returns trigger
language plpgsql security definer set search_path = public
as $$
declare
  v_period date := date_trunc('month', new.spent_at)::date;
  v_allocated numeric;
  v_spent numeric;
  v_ratio numeric;
  v_kind text;
  v_msg text;
begin
  select coalesce(sum(amount), 0) into v_allocated
    from public.budgets
   where member_id = new.member_id and period = v_period;

  if v_allocated <= 0 then
    return new; -- pas d'enveloppe définie : rien à signaler
  end if;

  select coalesce(sum(amount), 0) into v_spent
    from public.expenses
   where member_id = new.member_id
     and date_trunc('month', spent_at)::date = v_period;

  v_ratio := v_spent / v_allocated;

  if v_ratio >= 1 then
    v_kind := 'budget_exceeded';
    v_msg := 'Budget du mois dépassé : ' || to_char(v_spent, 'FM999G999D00')
             || ' / ' || to_char(v_allocated, 'FM999G999D00') || ' €';
  elsif v_ratio >= 0.8 then
    v_kind := 'budget_warning';
    v_msg := 'Attention : ' || round(v_ratio * 100) || ' % du budget consommé';
  else
    return new;
  end if;

  if not exists (
    select 1 from public.alerts
     where member_id = new.member_id and kind = v_kind and read = false
       and date_trunc('month', created_at)::date = v_period
  ) then
    insert into public.alerts (member_id, kind, message)
      values (new.member_id, v_kind, v_msg);
  end if;

  return new;
end;
$$;

create trigger trg_check_budget_alert
  after insert on public.expenses
  for each row execute function public.check_budget_alert();
