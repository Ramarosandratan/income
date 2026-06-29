-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║ Ajout de 'daily' à l'enum frequency + days_of_week                  ║
-- ╚══════════════════════════════════════════════════════════════════════╝

-- Ajouter 'daily' à l'enum frequency
alter type public.frequency add value 'daily';

-- Ajouter days_of_week aux templates récurrents
-- Tableau d'entiers 1..7 (ISO 8601 : 1=lundi, 7=dimanche)
-- Utilisé pour "tous les jours" ou "jours sélectionnés"
alter table public.recurring_templates
  add column if not exists days_of_week smallint[];

-- Ajouter days_of_week aux dépenses (à titre indicatif)
alter table public.expenses
  add column if not exists days_of_week smallint[];

-- Ajouter days_of_week aux revenus
alter table public.incomes
  add column if not exists days_of_week smallint[];