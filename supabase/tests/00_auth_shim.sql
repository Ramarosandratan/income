-- ⚠️ FICHIER DE TEST UNIQUEMENT — ne pas appliquer à une vraie base Supabase.
-- Émulation minimale du schéma `auth` et des rôles fournis par Supabase, afin
-- de pouvoir appliquer les migrations public/ et tester la RLS sur un Postgres
-- nu (sans la stack Supabase). En production, ces objets existent déjà.

create extension if not exists pgcrypto;

create schema if not exists auth;

create table if not exists auth.users (
  instance_id        uuid,
  id                 uuid primary key,
  aud                text,
  role               text,
  email              text,
  encrypted_password text,
  email_confirmed_at timestamptz,
  created_at         timestamptz,
  updated_at         timestamptz,
  raw_app_meta_data  jsonb,
  raw_user_meta_data jsonb
);

create table if not exists auth.identities (
  id              uuid,
  user_id         uuid references auth.users(id) on delete cascade,
  provider_id     text,
  identity_data   jsonb,
  provider        text,
  last_sign_in_at timestamptz,
  created_at      timestamptz,
  updated_at      timestamptz
);

-- auth.uid() lit l'identité simulée depuis une GUC de session (app.uid).
-- En production, Supabase la dérive du JWT.
create or replace function auth.uid()
returns uuid language sql stable as $$
  select nullif(current_setting('app.uid', true), '')::uuid;
$$;

do $$ begin
  if not exists (select 1 from pg_roles where rolname = 'authenticated') then
    create role authenticated nologin;
  end if;
  if not exists (select 1 from pg_roles where rolname = 'anon') then
    create role anon nologin;
  end if;
  if not exists (select 1 from pg_roles where rolname = 'service_role') then
    create role service_role nologin bypassrls;
  end if;
end $$;

do $$ begin
  if not exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    create publication supabase_realtime;
  end if;
end $$;
