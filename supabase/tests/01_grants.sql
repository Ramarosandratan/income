-- ⚠️ FICHIER DE TEST UNIQUEMENT. À appliquer APRÈS les migrations.
-- Droits que Supabase accorde aux rôles `authenticated`/`anon`. La RLS reste
-- appliquée par-dessus ces droits.
grant usage on schema public to authenticated, anon;
grant select, insert, update, delete on all tables in schema public to authenticated;
grant execute on all functions in schema public to authenticated, anon;
grant usage on schema auth to authenticated, anon;
grant execute on function auth.uid() to authenticated, anon;
grant select on auth.users to authenticated;
