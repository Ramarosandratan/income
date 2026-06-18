-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║ Remplacer is_recurring par frequency dans la table incomes         ║
-- ╚══════════════════════════════════════════════════════════════════════╝

-- Ajouter la colonne frequency (provisoirement nullable)
alter table public.incomes
add column frequency public.frequency not null default 'monthly';

-- Supprimer la colonne is_recurring
alter table public.incomes
drop column is_recurring;
