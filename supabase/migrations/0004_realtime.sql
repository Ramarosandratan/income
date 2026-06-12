-- Active la synchro temps réel sur les tables consommées en streaming par les
-- apps (dépenses du membre, alertes).
alter publication supabase_realtime add table public.expenses;
alter publication supabase_realtime add table public.alerts;
alter publication supabase_realtime add table public.budgets;
