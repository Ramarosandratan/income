-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║ Schéma — gestion de budget familial                                    ║
-- ╚══════════════════════════════════════════════════════════════════════╝

create extension if not exists "pgcrypto";

-- ── Familles ────────────────────────────────────────────────────────────────
create table public.families (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  created_at  timestamptz not null default now()
);

-- ── Profils (1 par compte auth) ───────────────────────────────────────────
create type public.user_role as enum ('master', 'member');

create table public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  family_id   uuid not null references public.families(id) on delete cascade,
  full_name   text not null,
  role        public.user_role not null default 'member',
  avatar_url  text,
  created_at  timestamptz not null default now()
);
create index on public.profiles (family_id);

-- ── Catégories ──────────────────────────────────────────────────────────────
create type public.entry_kind as enum ('expense', 'income');

create table public.categories (
  id          uuid primary key default gen_random_uuid(),
  family_id   uuid not null references public.families(id) on delete cascade,
  name        text not null,
  icon        text not null default 'category',
  color       text not null default 'FF9E9E9E',
  kind        public.entry_kind not null default 'expense',
  created_at  timestamptz not null default now()
);
create index on public.categories (family_id);

-- ── Revenus ──────────────────────────────────────────────────────────────────
create table public.incomes (
  id           uuid primary key default gen_random_uuid(),
  family_id    uuid not null references public.families(id) on delete cascade,
  member_id    uuid references public.profiles(id) on delete set null,
  source       text not null,
  amount       numeric(12,2) not null check (amount >= 0),
  period       date not null,           -- 1er du mois
  is_recurring boolean not null default false,
  created_at   timestamptz not null default now()
);
create index on public.incomes (family_id, period);

-- ── Budgets (enveloppes allouées par le maître) ──────────────────────────────
create type public.budget_type as enum ('budget', 'fixed');

create table public.budgets (
  id           uuid primary key default gen_random_uuid(),
  family_id    uuid not null references public.families(id) on delete cascade,
  member_id    uuid not null references public.profiles(id) on delete cascade,
  category_id  uuid references public.categories(id) on delete cascade,
  period       date not null,           -- 1er du mois
  amount       numeric(12,2) not null check (amount >= 0),
  type         public.budget_type not null default 'budget',
  created_at   timestamptz not null default now()
);
-- Unicité d'une enveloppe par membre/catégorie/mois.
-- (category_id null géré par un index partiel distinct.)
create unique index budgets_unique_cat
  on public.budgets (member_id, category_id, period)
  where category_id is not null;
create unique index budgets_unique_global
  on public.budgets (member_id, period)
  where category_id is null;
create index on public.budgets (family_id, period);

-- ── Dépenses ──────────────────────────────────────────────────────────────────
create type public.expense_type as enum ('daily', 'monthly', 'fixed');

create table public.expenses (
  id                    uuid primary key default gen_random_uuid(),
  family_id             uuid not null references public.families(id) on delete cascade,
  member_id             uuid not null references public.profiles(id) on delete cascade,
  category_id           uuid references public.categories(id) on delete set null,
  amount                numeric(12,2) not null check (amount > 0),
  note                  text,
  spent_at              timestamptz not null default now(),
  type                  public.expense_type not null default 'daily',
  recurring_template_id uuid,
  created_at            timestamptz not null default now()
);
create index on public.expenses (member_id, spent_at);
create index on public.expenses (family_id, spent_at);

-- ── Modèles récurrents ────────────────────────────────────────────────────────
create type public.frequency as enum ('weekly', 'monthly');

create table public.recurring_templates (
  id           uuid primary key default gen_random_uuid(),
  family_id    uuid not null references public.families(id) on delete cascade,
  member_id    uuid not null references public.profiles(id) on delete cascade,
  category_id  uuid references public.categories(id) on delete set null,
  label        text not null,
  amount       numeric(12,2) not null check (amount > 0),
  kind         public.entry_kind not null default 'expense',
  frequency    public.frequency not null default 'monthly',
  next_run     date not null,
  active       boolean not null default true,
  created_at   timestamptz not null default now()
);
create index on public.recurring_templates (active, next_run);

-- ── Objectifs d'épargne ───────────────────────────────────────────────────────
create table public.savings_goals (
  id             uuid primary key default gen_random_uuid(),
  family_id      uuid not null references public.families(id) on delete cascade,
  member_id      uuid references public.profiles(id) on delete cascade,
  name           text not null,
  target_amount  numeric(12,2) not null check (target_amount > 0),
  current_amount numeric(12,2) not null default 0 check (current_amount >= 0),
  deadline       date,
  created_at     timestamptz not null default now()
);
create index on public.savings_goals (family_id);

-- ── Alertes ────────────────────────────────────────────────────────────────────
create table public.alerts (
  id          uuid primary key default gen_random_uuid(),
  member_id   uuid not null references public.profiles(id) on delete cascade,
  kind        text not null,            -- budget_warning | budget_exceeded
  message     text not null,
  read        boolean not null default false,
  created_at  timestamptz not null default now()
);
create index on public.alerts (member_id, read);
