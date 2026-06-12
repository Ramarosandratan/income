-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║ Données de démonstration (local uniquement, via `supabase db reset`)    ║
-- ║                                                                          ║
-- ║ Comptes créés (mot de passe : « password ») :                           ║
-- ║   parent@demo.test  (maître)                                            ║
-- ║   alice@demo.test   (membre)                                            ║
-- ║   bruno@demo.test   (membre)                                            ║
-- ╚══════════════════════════════════════════════════════════════════════╝

-- Identifiants fixes pour faciliter les références.
\set fam     '11111111-1111-1111-1111-111111111111'
\set master  '22222222-2222-2222-2222-222222222222'
\set alice   '33333333-3333-3333-3333-333333333333'
\set bruno   '44444444-4444-4444-4444-444444444444'

-- ── Comptes d'authentification ───────────────────────────────────────────────
insert into auth.users
  (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
   created_at, updated_at, raw_app_meta_data, raw_user_meta_data)
values
  ('00000000-0000-0000-0000-000000000000', :'master', 'authenticated', 'authenticated',
   'parent@demo.test', crypt('password', gen_salt('bf')), now(), now(), now(),
   '{"provider":"email","providers":["email"]}', '{}'),
  ('00000000-0000-0000-0000-000000000000', :'alice', 'authenticated', 'authenticated',
   'alice@demo.test', crypt('password', gen_salt('bf')), now(), now(), now(),
   '{"provider":"email","providers":["email"]}', '{}'),
  ('00000000-0000-0000-0000-000000000000', :'bruno', 'authenticated', 'authenticated',
   'bruno@demo.test', crypt('password', gen_salt('bf')), now(), now(), now(),
   '{"provider":"email","providers":["email"]}', '{}');

insert into auth.identities
  (id, user_id, provider_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
values
  (gen_random_uuid(), :'master', 'parent@demo.test',
   json_build_object('sub', :'master', 'email', 'parent@demo.test'), 'email', now(), now(), now()),
  (gen_random_uuid(), :'alice', 'alice@demo.test',
   json_build_object('sub', :'alice', 'email', 'alice@demo.test'), 'email', now(), now(), now()),
  (gen_random_uuid(), :'bruno', 'bruno@demo.test',
   json_build_object('sub', :'bruno', 'email', 'bruno@demo.test'), 'email', now(), now(), now());

-- ── Famille + profils ─────────────────────────────────────────────────────────
insert into public.families (id, name) values (:'fam', 'Famille Démo');

insert into public.profiles (id, family_id, full_name, role) values
  (:'master', :'fam', 'Parent Démo', 'master'),
  (:'alice',  :'fam', 'Alice',       'member'),
  (:'bruno',  :'fam', 'Bruno',       'member');

-- ── Catégories ──────────────────────────────────────────────────────────────
insert into public.categories (id, family_id, name, icon, color, kind) values
  ('aaaaaaa1-0000-0000-0000-000000000001', :'fam', 'Alimentation', 'restaurant',     'FF4CAF50', 'expense'),
  ('aaaaaaa1-0000-0000-0000-000000000002', :'fam', 'Transport',    'directions_car', 'FF2196F3', 'expense'),
  ('aaaaaaa1-0000-0000-0000-000000000003', :'fam', 'Loisirs',      'sports_esports', 'FF9C27B0', 'expense'),
  ('aaaaaaa1-0000-0000-0000-000000000004', :'fam', 'Logement',     'home',           'FF795548', 'expense'),
  ('aaaaaaa1-0000-0000-0000-000000000005', :'fam', 'Salaire',      'payments',       'FF009688', 'income');

-- ── Revenus du mois courant ───────────────────────────────────────────────────
insert into public.incomes (family_id, member_id, source, amount, period, is_recurring) values
  (:'fam', :'master', 'Salaire parent', 3200, date_trunc('month', now())::date, true),
  (:'fam', :'alice',  'Argent de poche', 50,  date_trunc('month', now())::date, true);

-- ── Budgets du mois courant ───────────────────────────────────────────────────
insert into public.budgets (family_id, member_id, category_id, period, amount, type) values
  (:'fam', :'alice', 'aaaaaaa1-0000-0000-0000-000000000001', date_trunc('month', now())::date, 200, 'budget'),
  (:'fam', :'alice', 'aaaaaaa1-0000-0000-0000-000000000003', date_trunc('month', now())::date, 80,  'budget'),
  (:'fam', :'bruno', 'aaaaaaa1-0000-0000-0000-000000000001', date_trunc('month', now())::date, 150, 'budget'),
  (:'fam', :'bruno', null,                                    date_trunc('month', now())::date, 100, 'budget');

-- ── Quelques dépenses ─────────────────────────────────────────────────────────
insert into public.expenses (family_id, member_id, category_id, amount, note, spent_at, type) values
  (:'fam', :'alice', 'aaaaaaa1-0000-0000-0000-000000000001', 35.50, 'Courses',     now() - interval '2 days', 'daily'),
  (:'fam', :'alice', 'aaaaaaa1-0000-0000-0000-000000000003', 22.00, 'Cinéma',      now() - interval '1 day',  'daily'),
  (:'fam', :'bruno', 'aaaaaaa1-0000-0000-0000-000000000001', 48.90, 'Restaurant',  now() - interval '3 days', 'daily'),
  (:'fam', :'bruno', 'aaaaaaa1-0000-0000-0000-000000000002', 60.00, 'Essence',     now(),                     'monthly');

-- ── Objectif d'épargne familial ───────────────────────────────────────────────
insert into public.savings_goals (family_id, member_id, name, target_amount, current_amount, deadline) values
  (:'fam', null, 'Vacances été', 1500, 400, (date_trunc('year', now()) + interval '7 months')::date);

-- ── Modèle récurrent (loyer) ─────────────────────────────────────────────────
insert into public.recurring_templates (family_id, member_id, category_id, label, amount, kind, frequency, next_run) values
  (:'fam', :'master', 'aaaaaaa1-0000-0000-0000-000000000004', 'Loyer', 950, 'expense', 'monthly',
   (date_trunc('month', now()) + interval '1 month')::date);
