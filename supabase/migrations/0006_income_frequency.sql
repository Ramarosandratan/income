-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║ Remplacer is_recurring par frequency dans la table incomes         ║
-- ╚══════════════════════════════════════════════════════════════════════╝

-- Supprimer la colonne is_recurring
alter table public.incomes
drop column if exists is_recurring;

-- Ajouter la colonne frequency
alter table public.incomes
add column frequency public.frequency not null default 'monthly';


