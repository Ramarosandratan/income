-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║ Ajout de la colonne frequency sur expenses                          ║
-- ╚══════════════════════════════════════════════════════════════════════╝

alter table public.expenses
  add column if not exists frequency public.frequency;
