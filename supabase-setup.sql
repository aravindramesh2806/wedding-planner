-- ============================================================
--  Wedding Planner — Supabase database setup
--  Paste this whole file into Supabase → SQL Editor → Run.
--  Safe to run more than once.
-- ============================================================

create extension if not exists pgcrypto;

-- One row per couple. token = the secret in their private URL (#w=<token>).
create table if not exists public.weddings (
  id            uuid primary key default gen_random_uuid(),
  bride_name    text not null default '',
  groom_name    text not null default '',
  wedding_date  date,
  token         text not null unique,
  rsvp_token    text unique,
  email         text,
  data          jsonb not null default '{}'::jsonb,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);
create index if not exists weddings_token_idx on public.weddings(token);
create unique index if not exists weddings_rsvp_token_idx on public.weddings(rsvp_token);

-- Lock the table: no direct access with the public key.
-- All access goes through the SECURITY DEFINER functions below.
alter table public.weddings enable row level security;

-- ---------- ADMIN KEY ----------
-- This protects the master "/#admin=..." page that lists every couple.
-- >>> CHANGE the string below to your own secret before sharing anything. <<<
create or replace function public.wp_admin_key() returns text
language sql immutable as $$ select 'wedding-admin-3892'::text $$;

-- ---------- signup: create a couple, return their private token ----------
create or replace function public.wp_signup(p_bride text, p_groom text, p_date date)
returns json language plpgsql security definer set search_path = public as $$
declare t text; wid uuid;
begin
  t := encode(extensions.gen_random_bytes(18), 'hex');
  insert into public.weddings(bride_name, groom_name, wedding_date, token)
    values (coalesce(p_bride,''), coalesce(p_groom,''), p_date, t)
    returning id into wid;
  return json_build_object('token', t, 'id', wid);
end; $$;

-- ---------- load: a couple's plan, by their token ----------
create or replace function public.wp_load(p_token text)
returns json language plpgsql security definer set search_path = public as $$
declare w public.weddings%rowtype;
begin
  select * into w from public.weddings where token = p_token;
  if w.id is null then return json_build_object('error','not_found'); end if;
  return json_build_object('bride_name', w.bride_name, 'groom_name', w.groom_name,
                           'wedding_date', w.wedding_date, 'data', w.data,
                           'updated_at', w.updated_at);
end; $$;

-- ---------- save: write a couple's plan ----------
create or replace function public.wp_save(p_token text, p_data jsonb,
                                          p_bride text, p_groom text, p_date date)
returns json language plpgsql security definer set search_path = public as $$
declare w public.weddings%rowtype;
begin
  select * into w from public.weddings where token = p_token;
  if w.id is null then return json_build_object('error','not_found'); end if;
  update public.weddings
     set data = p_data,
         bride_name = coalesce(p_bride, bride_name),
         groom_name = coalesce(p_groom, groom_name),
         wedding_date = coalesce(p_date, wedding_date),
         updated_at = now()
   where token = p_token;
  return json_build_object('ok', true, 'updated_at', now());
end; $$;

-- ---------- admin: list every couple (key-protected) ----------
create or replace function public.wp_admin_list(p_key text)
returns json language plpgsql security definer set search_path = public as $$
declare result json;
begin
  if p_key is null or p_key <> public.wp_admin_key() then
    return json_build_object('error','unauthorized');
  end if;
  select coalesce(json_agg(r), '[]'::json) into result from (
    select bride_name, groom_name, wedding_date, created_at, token,
           coalesce(jsonb_array_length(data->'guests'), 0) as guests,
           coalesce(jsonb_array_length(data->'tasks'),  0) as tasks
    from public.weddings
    order by created_at desc
  ) r;
  return json_build_object('couples', result);
end; $$;

-- ---------- admin: delete a couple (key-protected) ----------
create or replace function public.wp_admin_delete(p_key text, p_token text)
returns json language plpgsql security definer set search_path = public as $$
begin
  if p_key is null or p_key <> public.wp_admin_key() then
    return json_build_object('error','unauthorized');
  end if;
  delete from public.weddings where token = p_token;
  return json_build_object('ok', true);
end; $$;

-- ---------- expose functions to the public (anon) key ----------
grant execute on function public.wp_signup(text, text, date)               to anon;
grant execute on function public.wp_load(text)                             to anon;
grant execute on function public.wp_save(text, jsonb, text, text, date)    to anon;
grant execute on function public.wp_admin_list(text)                       to anon;
grant execute on function public.wp_admin_delete(text, text)               to anon;
