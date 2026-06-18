-- Tests d'intégration backend (RLS, déclencheurs, RPC).
-- Lancés via `scripts/run-backend-tests.ps1`. Toute assertion échouée lève une
-- exception ; avec psql -v ON_ERROR_STOP=1 le code retour devient non nul.
--
-- Identités simulées via la GUC app.uid (voir 00_auth_shim.sql) + bascule de
-- rôle vers `authenticated` pour que la RLS s'applique réellement.

-- ── T1 : le maître voit toute la famille ─────────────────────────────────────
do $$
declare n int;
begin
  perform set_config('role','authenticated',true);
  perform set_config('app.uid','22222222-2222-2222-2222-222222222222',true);
  select count(*) into n from public.profiles;
  if n <> 3 then raise exception 'T1 profiles maître: attendu 3, obtenu %', n; end if;
  select count(*) into n from public.expenses;
  if n <> 4 then raise exception 'T1 expenses maître: attendu 4, obtenu %', n; end if;
  select count(*) into n from public.budgets;
  if n <> 4 then raise exception 'T1 budgets maître: attendu 4, obtenu %', n; end if;
  raise notice 'T1 OK — le maître voit 3 profils / 4 dépenses / 4 budgets';
end $$;

-- ── T2 : un membre ne voit que ses propres données ───────────────────────────
do $$
declare n int;
begin
  perform set_config('role','authenticated',true);
  perform set_config('app.uid','33333333-3333-3333-3333-333333333333',true);
  select count(*) into n from public.profiles;
  if n <> 1 then raise exception 'T2 profiles alice: attendu 1, obtenu %', n; end if;
  select count(*) into n from public.expenses;
  if n <> 2 then raise exception 'T2 expenses alice: attendu 2, obtenu %', n; end if;
  select count(*) into n from public.expenses
    where member_id = '44444444-4444-4444-4444-444444444444';
  if n <> 0 then raise exception 'T2 alice voit les dépenses de bruno (fuite RLS): %', n; end if;
  raise notice 'T2 OK — alice ne voit que ses 2 dépenses, 0 de bruno';
end $$;

-- ── T3 : un membre ne peut pas écrire de budget ──────────────────────────────
do $$
declare ok boolean := false;
begin
  perform set_config('role','authenticated',true);
  perform set_config('app.uid','33333333-3333-3333-3333-333333333333',true);
  begin
    insert into public.budgets (family_id, member_id, period, amount)
    values ('11111111-1111-1111-1111-111111111111',
            '33333333-3333-3333-3333-333333333333',
            date_trunc('month', now())::date, 99);
  exception when others then
    ok := true; -- refusé par la RLS, attendu
  end;
  if not ok then raise exception 'T3 un membre a pu écrire un budget (RLS trop permissive)'; end if;
  raise notice 'T3 OK — écriture de budget refusée pour un membre';
end $$;

-- ── T4 : un membre saisit SA dépense, pas celle d'un autre ───────────────────
do $$
declare ok boolean := false; new_id uuid;
begin
  perform set_config('role','authenticated',true);
  perform set_config('app.uid','33333333-3333-3333-3333-333333333333',true);
  insert into public.expenses (family_id, member_id, category_id, amount, spent_at, type)
  values ('11111111-1111-1111-1111-111111111111',
          '33333333-3333-3333-3333-333333333333',
          'aaaaaaa1-0000-0000-0000-000000000001', 1, now(), 'daily')
  returning id into new_id;
  delete from public.expenses where id = new_id; -- nettoyage pour ne pas fausser T6
  begin
    insert into public.expenses (family_id, member_id, amount, spent_at, type)
    values ('11111111-1111-1111-1111-111111111111',
            '44444444-4444-4444-4444-444444444444', 1, now(), 'daily');
  exception when others then ok := true; end;
  if not ok then raise exception 'T4 alice a pu saisir une dépense pour bruno'; end if;
  raise notice 'T4 OK — saisie propre autorisée, saisie pour autrui refusée';
end $$;

-- ── T5 : upsert_budget (correctif #1) — pas de doublon, mise à jour OK ────────
do $$
declare n int; v_amount numeric; p date := date_trunc('month', now())::date;
begin
  perform set_config('role','authenticated',true);
  perform set_config('app.uid','22222222-2222-2222-2222-222222222222',true); -- maître
  perform public.upsert_budget('33333333-3333-3333-3333-333333333333',
      'aaaaaaa1-0000-0000-0000-000000000001', p, 100, 'budget');
  perform public.upsert_budget('33333333-3333-3333-3333-333333333333',
      'aaaaaaa1-0000-0000-0000-000000000001', p, 250, 'budget');
  select count(*), max(amount) into n, v_amount from public.budgets
   where member_id='33333333-3333-3333-3333-333333333333'
     and category_id='aaaaaaa1-0000-0000-0000-000000000001' and period=p;
  if n <> 1 then raise exception 'T5 doublon budget catégorisé: % lignes', n; end if;
  if v_amount <> 250 then raise exception 'T5 montant catégorisé: attendu 250, obtenu %', v_amount; end if;
  perform public.upsert_budget('44444444-4444-4444-4444-444444444444', null, p, 50, 'budget');
  perform public.upsert_budget('44444444-4444-4444-4444-444444444444', null, p, 75, 'budget');
  select count(*), max(amount) into n, v_amount from public.budgets
   where member_id='44444444-4444-4444-4444-444444444444'
     and category_id is null and period=p;
  if n <> 1 then raise exception 'T5 doublon budget global: % lignes', n; end if;
  if v_amount <> 75 then raise exception 'T5 montant global: attendu 75, obtenu %', v_amount; end if;
  raise notice 'T5 OK — upsert_budget met à jour sans créer de doublon (catégorisé + global)';
end $$;

-- ── T6 : déclencheur d'alerte (correctif #5) — seuils + déduplication ─────────
do $$
declare p date := date_trunc('month', now())::date;
        v_alloc numeric; v_spent numeric; n_warn int; n_exc int;
begin
  perform set_config('role','authenticated',true);
  perform set_config('app.uid','33333333-3333-3333-3333-333333333333',true); -- alice
  select coalesce(sum(amount),0) into v_alloc from public.budgets
    where member_id='33333333-3333-3333-3333-333333333333' and period=p;
  select coalesce(sum(amount),0) into v_spent from public.expenses
    where member_id='33333333-3333-3333-3333-333333333333'
      and date_trunc('month', spent_at)::date = p;

  insert into public.expenses (family_id, member_id, category_id, amount, spent_at, type)
  values ('11111111-1111-1111-1111-111111111111','33333333-3333-3333-3333-333333333333',
          'aaaaaaa1-0000-0000-0000-000000000001', (0.85*v_alloc - v_spent), now(), 'daily');
  select count(*) into n_warn from public.alerts
    where member_id='33333333-3333-3333-3333-333333333333' and kind='budget_warning' and period=p;
  if n_warn <> 1 then raise exception 'T6 alerte avertissement: attendu 1, obtenu %', n_warn; end if;

  insert into public.expenses (family_id, member_id, category_id, amount, spent_at, type)
  values ('11111111-1111-1111-1111-111111111111','33333333-3333-3333-3333-333333333333',
          'aaaaaaa1-0000-0000-0000-000000000001', (0.30*v_alloc), now(), 'daily');
  select count(*) into n_exc from public.alerts
    where member_id='33333333-3333-3333-3333-333333333333' and kind='budget_exceeded' and period=p;
  if n_exc <> 1 then raise exception 'T6 alerte dépassement: attendu 1, obtenu %', n_exc; end if;

  insert into public.expenses (family_id, member_id, category_id, amount, spent_at, type)
  values ('11111111-1111-1111-1111-111111111111','33333333-3333-3333-3333-333333333333',
          'aaaaaaa1-0000-0000-0000-000000000001', 5, now(), 'daily');
  select count(*) into n_exc from public.alerts
    where member_id='33333333-3333-3333-3333-333333333333' and kind='budget_exceeded' and period=p;
  if n_exc <> 1 then raise exception 'T6 doublon alerte dépassement: %', n_exc; end if;
  raise notice 'T6 OK — alertes 80%% / 100%% créées une seule fois (déduplication par période)';
end $$;

-- ── T7 : onboarding maître via trigger (correctifs #3/#4) ─────────────────────
do $$
declare new_uid uuid := gen_random_uuid(); v_fam uuid; v_role text; n_cat int;
begin
  insert into auth.users (id, email, raw_user_meta_data, raw_app_meta_data, created_at, updated_at)
  values (new_uid, 'chef@test.fr',
          '{"family_name":"Famille Test","full_name":"Chef Test"}', '{}', now(), now());
  select family_id, role into v_fam, v_role from public.profiles where id = new_uid;
  if v_fam is null then raise exception 'T7 aucun profil créé par le trigger d''onboarding'; end if;
  if v_role <> 'master' then raise exception 'T7 rôle attendu master, obtenu %', v_role; end if;
  select count(*) into n_cat from public.categories where family_id = v_fam;
  if n_cat <> 7 then raise exception 'T7 catégories par défaut: attendu 7, obtenu %', n_cat; end if;
  raise notice 'T7 OK — inscription crée famille + profil maître + 7 catégories (atomique)';
end $$;

select '✅ TOUS LES TESTS BACKEND SONT PASSÉS' as resultat;
