-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║ Ajout de frequency_day sur incomes                                 ║
-- ╚══════════════════════════════════════════════════════════════════════╝
-- weekly   → 1=lundi … 7=dimanche
-- monthly  → 1…31 (jour du mois)
-- yearly   → 1…31 (jour du mois, mois = period)

alter table public.incomes
  add column if not exists frequency_day smallint;

create index if not exists incomes_frequency_day_idx on public.incomes (frequency_day);
