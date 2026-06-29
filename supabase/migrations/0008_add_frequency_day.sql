-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║ Fréquence étendue : yearly + frequency_day                          ║
-- ╚══════════════════════════════════════════════════════════════════════╝

-- Ajouter 'yearly' à l'enum frequency
alter type public.frequency add value 'yearly';

-- Ajouter frequency_day aux templates récurrents
-- weekly   → 1=lundi … 7=dimanche
-- monthly  → 1…31 (jour du mois)
-- yearly   → 1…31 (jour du mois, mois = next_run)
alter table public.recurring_templates
  add column if not exists frequency_day smallint;

-- Ajouter frequency_day aux dépenses (à titre indicatif)
alter table public.expenses
  add column if not exists frequency_day smallint;
