-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║ Correctifs (revue de code)                                              ║
-- ╚══════════════════════════════════════════════════════════════════════╝

-- ── #0 : Grants de base pour les rôles Supabase ──────────────────────────────
-- Sans ces grants, les politiques RLS ne peuvent pas s'appliquer car le rôle
-- n'a aucun privilège de base (SELECT, INSERT, etc.) sur les tables.
grant usage on schema public to anon, authenticated, service_role;
grant all on all tables    in schema public to anon, authenticated, service_role;
grant all on all sequences in schema public to anon, authenticated, service_role;
grant all on all functions in schema public to anon, authenticated, service_role;
alter default privileges for role postgres in schema public
  grant all on tables    to anon, authenticated, service_role;
alter default privileges for role postgres in schema public
  grant all on sequences to anon, authenticated, service_role;
alter default privileges for role postgres in schema public
  grant all on functions to anon, authenticated, service_role;

-- ── #1 : upsert de budget compatible avec les index uniques PARTIELS ──────────
-- L'ON CONFLICT (member_id,category_id,period) ne peut pas inférer un index
-- partiel sans son prédicat. On passe par une RPC NULL-safe (is not distinct
-- from) qui fait update-sinon-insert. SECURITY INVOKER : la RLS budgets_write
-- (maître uniquement) s'applique normalement.
create or replace function public.upsert_budget(
  p_member uuid,
  p_category uuid,
  p_period date,
  p_amount numeric,
  p_type public.budget_type
)
returns public.budgets
language plpgsql
as $$
declare
  v_row public.budgets;
begin
  update public.budgets
     set amount = p_amount, type = p_type
   where member_id = p_member
     and period = p_period
     and category_id is not distinct from p_category
  returning * into v_row;

  if not found then
    insert into public.budgets (family_id, member_id, category_id, period, amount, type)
    values (public.auth_family_id(), p_member, p_category, p_period, p_amount, p_type)
    returning * into v_row;
  end if;

  return v_row;
end;
$$;

-- ── #3 / #4 : onboarding du maître via trigger sur auth.users ─────────────────
-- Crée la famille + le profil maître + les catégories par défaut AU MOMENT de
-- l'inscription (dans la transaction GoTrue), sans dépendre d'une session ni
-- d'un appel RPC ultérieur. Atomique => pas de compte orphelin.
-- Ne s'active que si l'inscription porte un "family_name" dans les métadonnées
-- (auto-inscription maître). Les membres créés par l'Edge Function (sans
-- family_name) sont ignorés ici : leur profil est inséré par la fonction.
create or replace function public.handle_new_user()
returns trigger
language plpgsql security definer set search_path = public
as $$
declare
  v_family_id uuid;
begin
  if new.raw_user_meta_data ? 'family_name' then
    insert into public.families (name)
      values (new.raw_user_meta_data->>'family_name')
      returning id into v_family_id;

    insert into public.profiles (id, family_id, full_name, role)
      values (new.id, v_family_id,
              coalesce(new.raw_user_meta_data->>'full_name', 'Maître'), 'master')
      on conflict (id) do nothing;

    insert into public.categories (family_id, name, icon, color, kind) values
      (v_family_id, 'Alimentation',  'restaurant',      'FF4CAF50', 'expense'),
      (v_family_id, 'Transport',     'directions_car',  'FF2196F3', 'expense'),
      (v_family_id, 'Logement',      'home',            'FF795548', 'expense'),
      (v_family_id, 'Loisirs',       'sports_esports',  'FF9C27B0', 'expense'),
      (v_family_id, 'Santé',         'favorite',        'FFE91E63', 'expense'),
      (v_family_id, 'Factures',      'receipt_long',    'FFFF9800', 'expense'),
      (v_family_id, 'Salaire',       'payments',        'FF009688', 'income');
  end if;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- L'ancienne RPC d'amorçage n'est plus utilisée (remplacée par le trigger).
drop function if exists public.bootstrap_family(text, text);

-- ── #5 : déduplication d'alerte sur la PÉRIODE et non sur created_at ──────────
alter table public.alerts add column if not exists period date;

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
    return new;
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

  -- Une seule alerte non lue par membre / type / mois budgétaire (la période
  -- de la dépense, et non la date de création de l'alerte).
  if not exists (
    select 1 from public.alerts
     where member_id = new.member_id and kind = v_kind and read = false
       and period = v_period
  ) then
    insert into public.alerts (member_id, kind, message, period)
      values (new.member_id, v_kind, v_msg, v_period);
  end if;

  return new;
end;
$$;
