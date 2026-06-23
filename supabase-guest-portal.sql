-- ============================================================
--  Wedding Planner — Guest Portal migration (v1)
--  Run AFTER supabase-setup.sql. Safe to re-run.
--  Paste into Supabase → SQL Editor → Run.
-- ============================================================

create extension if not exists pgcrypto;

-- ============================================================
--  Extend weddings: add a public guest-entry token
-- ============================================================
-- The couple's own `token` is a SECRET (it can edit the plan). We need
-- a separate, less-sensitive token to put in guest-facing invite links.
-- Backfill any existing rows with a new token.
alter table public.weddings
  add column if not exists guest_entry_token text unique;
update public.weddings
   set guest_entry_token = encode(extensions.gen_random_bytes(12), 'hex')
 where guest_entry_token is null;
create index if not exists weddings_guest_entry_idx on public.weddings(guest_entry_token);

-- Backfill RPC for the couple to fetch/rotate their guest_entry_token.
create or replace function public.wp_get_guest_entry_token(p_couple_token text)
returns json
language plpgsql security definer set search_path = public as $$
declare t text; w_id uuid;
begin
  select id, guest_entry_token into w_id, t
    from public.weddings where token = p_couple_token;
  if w_id is null then return json_build_object('error','not_found'); end if;
  if t is null then
    t := encode(extensions.gen_random_bytes(12), 'hex');
    update public.weddings set guest_entry_token = t where id = w_id;
  end if;
  return json_build_object('guest_entry_token', t);
end; $$;

-- ============================================================
--  Tables
-- ============================================================

-- One row per guest. Lives under a couple (wedding_id).
-- guest_token is the secret the guest's browser holds in localStorage
-- after sign-in; all guest RPCs require it.
create table if not exists public.guests (
  id                 uuid primary key default gen_random_uuid(),
  wedding_id         uuid not null references public.weddings(id) on delete cascade,
  name               text not null default '',
  email              text,
  phone              text,
  phone_last4        text,
  signin_method      text not null check (signin_method in ('google','phone','email','pre_added')),
  google_sub         text,                              -- Google's stable user ID
  guest_token        text not null unique,              -- secret for this guest
  status             text not null default 'pending'    -- pending | approved | rejected
                     check (status in ('pending','approved','rejected')),
  plus_ones_default  int not null default 0,
  push_subscription  jsonb,                             -- Web Push subscription JSON
  last_seen_at       timestamptz,
  created_at         timestamptz not null default now(),
  approved_at        timestamptz,
  approved_by        text                               -- who approved (couple token's email or 'admin')
);
create index if not exists guests_wedding_idx       on public.guests(wedding_id);
create index if not exists guests_token_idx         on public.guests(guest_token);
create index if not exists guests_status_idx        on public.guests(wedding_id, status);
create unique index if not exists guests_wedding_email_idx
  on public.guests(wedding_id, lower(email)) where email is not null;
create unique index if not exists guests_wedding_phone4_idx
  on public.guests(wedding_id, phone_last4, lower(name))
  where phone_last4 is not null;

-- Per-event RSVP. event_id is the string id stored inside weddings.data.events[].id
create table if not exists public.guest_rsvps (
  guest_id    uuid not null references public.guests(id) on delete cascade,
  event_id    text not null,
  attending   boolean,
  plus_ones   int not null default 0,
  updated_at  timestamptz not null default now(),
  primary key (guest_id, event_id)
);
create index if not exists guest_rsvps_event_idx on public.guest_rsvps(event_id);

-- Broadcast alerts from the couple.
-- audience JSON shape:
--   {"type":"all"}
--   {"type":"event","event_id":"abc"}        -- everyone RSVPing attending=true
--   {"type":"guests","guest_ids":["...",...]}
create table if not exists public.guest_alerts (
  id          uuid primary key default gen_random_uuid(),
  wedding_id  uuid not null references public.weddings(id) on delete cascade,
  title       text not null,
  body        text not null default '',
  audience    jsonb not null default '{"type":"all"}'::jsonb,
  kind        text not null default 'manual'              -- manual | auto_t7 | auto_t1 | auto_t2h | welcome
              check (kind in ('manual','auto_t7','auto_t1','auto_t2h','welcome')),
  created_at  timestamptz not null default now()
);
create index if not exists guest_alerts_wedding_idx on public.guest_alerts(wedding_id, created_at desc);

-- Read receipts.
create table if not exists public.alert_reads (
  alert_id  uuid not null references public.guest_alerts(id) on delete cascade,
  guest_id  uuid not null references public.guests(id) on delete cascade,
  read_at   timestamptz not null default now(),
  primary key (alert_id, guest_id)
);

alter table public.guests        enable row level security;
alter table public.guest_rsvps   enable row level security;
alter table public.guest_alerts  enable row level security;
alter table public.alert_reads   enable row level security;

-- ============================================================
--  Helpers
-- ============================================================

-- Returns true if the alert's audience includes a given guest.
create or replace function public.wp_alert_matches_guest(
  p_audience jsonb, p_guest_id uuid
) returns boolean
language plpgsql stable security definer set search_path = public as $$
declare
  t text;
  ev text;
  ids jsonb;
begin
  t := p_audience->>'type';
  if t = 'all' then
    return true;
  elsif t = 'event' then
    ev := p_audience->>'event_id';
    return exists (
      select 1 from public.guest_rsvps r
       where r.guest_id = p_guest_id
         and r.event_id = ev
         and r.attending = true
    );
  elsif t = 'guests' then
    ids := p_audience->'guest_ids';
    return exists (
      select 1 from jsonb_array_elements_text(ids) x
       where x.value = p_guest_id::text
    );
  end if;
  return false;
end; $$;

-- ============================================================
--  Guest-facing RPCs (auth = p_guest_token, except signup which auths via couple_token)
-- ============================================================

-- Sign up a guest under a couple. Returns { guest_token, status, guest_id }.
-- p_guest_entry_token is the PUBLIC token from the invite link (not the
-- couple's secret token). If a pre-added guest matches on (email) OR
-- (phone_last4 + name), auto-approve. Otherwise status = 'pending'.
create or replace function public.wp_guest_signup(
  p_guest_entry_token text,
  p_method            text,
  p_name              text,
  p_email             text,
  p_phone             text,
  p_google_sub        text
) returns json
language plpgsql security definer set search_path = public as $$
declare
  w_id     uuid;
  g        public.guests%rowtype;
  tok      text;
  ph4      text;
  matched  public.guests%rowtype;
begin
  if p_method is null or p_method not in ('google','phone','email') then
    return json_build_object('error','bad_method');
  end if;

  select id into w_id from public.weddings
   where guest_entry_token = p_guest_entry_token;
  if w_id is null then
    return json_build_object('error','couple_not_found');
  end if;

  if p_phone is not null and length(p_phone) >= 4 then
    ph4 := right(regexp_replace(p_phone, '\D', '', 'g'), 4);
  end if;

  -- Try to match an existing pre_added guest (couple uploaded their list ahead of time)
  if p_email is not null then
    select * into matched from public.guests
     where wedding_id = w_id
       and lower(email) = lower(p_email)
       and status in ('pending','approved')
     limit 1;
  end if;
  if matched.id is null and ph4 is not null and p_name is not null then
    select * into matched from public.guests
     where wedding_id = w_id
       and phone_last4 = ph4
       and lower(name) = lower(p_name)
       and status in ('pending','approved')
     limit 1;
  end if;

  if matched.id is not null then
    -- existing guest signing in again or matching a pre-added entry
    update public.guests
       set signin_method = p_method,
           google_sub    = coalesce(p_google_sub, google_sub),
           email         = coalesce(p_email, email),
           phone         = coalesce(p_phone, phone),
           phone_last4   = coalesce(ph4, phone_last4),
           status        = case when status = 'pending' and signin_method = 'pre_added'
                                then 'approved' else status end,
           approved_at   = case when status = 'pending' and signin_method = 'pre_added'
                                then now() else approved_at end,
           last_seen_at  = now()
     where id = matched.id
     returning * into g;
    return json_build_object('guest_token', g.guest_token, 'status', g.status, 'guest_id', g.id);
  end if;

  -- brand new self-signup → pending
  tok := encode(extensions.gen_random_bytes(18), 'hex');
  insert into public.guests(wedding_id, name, email, phone, phone_last4,
                            signin_method, google_sub, guest_token, status, last_seen_at)
    values (w_id, coalesce(p_name,''), p_email, p_phone, ph4,
            p_method, p_google_sub, tok, 'pending', now())
    returning * into g;
  return json_build_object('guest_token', g.guest_token, 'status', g.status, 'guest_id', g.id);
end; $$;

-- Load the guest's whole portal: their info, the couple's events (with portal fields),
-- the guest's RSVPs, alerts addressed to them.
create or replace function public.wp_guest_load(p_guest_token text)
returns json
language plpgsql security definer set search_path = public as $$
declare
  g          public.guests%rowtype;
  w          public.weddings%rowtype;
  rsvps      json;
  alerts     json;
  plan_clean json;
begin
  select * into g from public.guests where guest_token = p_guest_token;
  if g.id is null then return json_build_object('error','not_found'); end if;

  update public.guests set last_seen_at = now() where id = g.id;

  select * into w from public.weddings where id = g.wedding_id;

  -- SECURITY: only approved guests receive any plan content, and even then only
  -- the guest-facing slices (schedule + "know before you go"). Budget, vendors,
  -- tasks, the full guest list and couple settings never leave the server.
  if g.status = 'approved' then
    plan_clean := json_build_object(
      'events', coalesce(w.data->'events', '[]'::jsonb),
      'know_before_general', coalesce(w.data->>'know_before_general', ''),
      'portal', coalesce(w.data->'portal', '{}'::jsonb)
    );

    select coalesce(json_agg(r), '[]'::json) into rsvps from (
      select event_id, attending, plus_ones, updated_at
        from public.guest_rsvps where guest_id = g.id
    ) r;

    select coalesce(json_agg(a order by a.created_at desc), '[]'::json) into alerts from (
      select al.id, al.title, al.body, al.kind, al.created_at,
             (ar.read_at is not null) as read
        from public.guest_alerts al
        left join public.alert_reads ar on ar.alert_id = al.id and ar.guest_id = g.id
       where al.wedding_id = g.wedding_id
         and public.wp_alert_matches_guest(al.audience, g.id)
    ) a;
  else
    plan_clean := json_build_object('events', '[]'::json, 'know_before_general', '', 'portal', '{}'::json);
    rsvps  := '[]'::json;
    alerts := '[]'::json;
  end if;

  return json_build_object(
    'guest', json_build_object(
       'id', g.id, 'name', g.name, 'email', g.email, 'phone', g.phone,
       'status', g.status, 'signin_method', g.signin_method
    ),
    'couple', json_build_object(
       'bride_name', w.bride_name, 'groom_name', w.groom_name,
       'wedding_date', w.wedding_date
    ),
    'plan_data', plan_clean,
    'rsvps', rsvps,
    'alerts', alerts
  );
end; $$;

-- Set a guest's RSVP for one event.
create or replace function public.wp_guest_rsvp(
  p_guest_token text, p_event_id text, p_attending boolean, p_plus_ones int
) returns json
language plpgsql security definer set search_path = public as $$
declare g public.guests%rowtype;
begin
  select * into g from public.guests where guest_token = p_guest_token;
  if g.id is null then return json_build_object('error','not_found'); end if;
  if g.status <> 'approved' then return json_build_object('error','not_approved'); end if;

  insert into public.guest_rsvps(guest_id, event_id, attending, plus_ones, updated_at)
    values (g.id, p_event_id, p_attending, coalesce(p_plus_ones,0), now())
    on conflict (guest_id, event_id) do update
       set attending  = excluded.attending,
           plus_ones  = excluded.plus_ones,
           updated_at = now();

  return json_build_object('ok', true);
end; $$;

-- Mark one alert read.
create or replace function public.wp_guest_mark_alert_read(
  p_guest_token text, p_alert_id uuid
) returns json
language plpgsql security definer set search_path = public as $$
declare g public.guests%rowtype;
begin
  select * into g from public.guests where guest_token = p_guest_token;
  if g.id is null then return json_build_object('error','not_found'); end if;
  insert into public.alert_reads(alert_id, guest_id) values (p_alert_id, g.id)
    on conflict do nothing;
  return json_build_object('ok', true);
end; $$;

-- Save a Web Push subscription for this guest.
create or replace function public.wp_guest_register_push(
  p_guest_token text, p_subscription jsonb
) returns json
language plpgsql security definer set search_path = public as $$
declare g public.guests%rowtype;
begin
  select * into g from public.guests where guest_token = p_guest_token;
  if g.id is null then return json_build_object('error','not_found'); end if;
  update public.guests set push_subscription = p_subscription where id = g.id;
  return json_build_object('ok', true);
end; $$;

-- ============================================================
--  Couple-facing RPCs (auth = couple's token)
-- ============================================================

-- Return full guest list + aggregates for the couple's dashboard.
create or replace function public.wp_admin_list_guests(p_couple_token text)
returns json
language plpgsql security definer set search_path = public as $$
declare
  w_id uuid;
  result json;
  totals json;
begin
  select id into w_id from public.weddings where token = p_couple_token;
  if w_id is null then return json_build_object('error','not_found'); end if;

  select coalesce(json_agg(row_to_json(r)), '[]'::json) into result from (
    select g.id, g.name, g.email, g.phone, g.signin_method, g.status,
           g.plus_ones_default, g.last_seen_at, g.created_at, g.approved_at,
           (g.push_subscription is not null) as push_enabled,
           coalesce((
             select json_agg(json_build_object(
               'event_id', r.event_id, 'attending', r.attending, 'plus_ones', r.plus_ones))
               from public.guest_rsvps r where r.guest_id = g.id
           ), '[]'::json) as rsvps
      from public.guests g
     where g.wedding_id = w_id
     order by g.created_at desc
  ) r;

  select json_build_object(
    'total',     count(*),
    'approved',  count(*) filter (where status = 'approved'),
    'pending',   count(*) filter (where status = 'pending'),
    'rejected',  count(*) filter (where status = 'rejected'),
    'push_optin',count(*) filter (where push_subscription is not null)
  ) into totals from public.guests where wedding_id = w_id;

  return json_build_object('guests', result, 'totals', totals);
end; $$;

-- Approve or reject a pending guest.
create or replace function public.wp_admin_approve_guest(
  p_couple_token text, p_guest_id uuid, p_decision text
) returns json
language plpgsql security definer set search_path = public as $$
declare w_id uuid;
begin
  if p_decision not in ('approved','rejected') then
    return json_build_object('error','bad_decision');
  end if;
  select id into w_id from public.weddings where token = p_couple_token;
  if w_id is null then return json_build_object('error','not_found'); end if;

  update public.guests
     set status = p_decision,
         approved_at = case when p_decision = 'approved' then now() else approved_at end,
         approved_by = 'couple'
   where id = p_guest_id and wedding_id = w_id;

  return json_build_object('ok', true);
end; $$;

-- Bulk pre-add guests from a CSV upload. p_rows is a JSON array of
-- { name, email, phone, plus_ones_default }. Returns counts.
create or replace function public.wp_admin_upload_guests(
  p_couple_token text, p_rows jsonb
) returns json
language plpgsql security definer set search_path = public as $$
declare
  w_id  uuid;
  rec   jsonb;
  ph4   text;
  added int := 0;
  skipped int := 0;
  tok text;
begin
  select id into w_id from public.weddings where token = p_couple_token;
  if w_id is null then return json_build_object('error','not_found'); end if;

  for rec in select * from jsonb_array_elements(p_rows)
  loop
    ph4 := null;
    if rec->>'phone' is not null and length(rec->>'phone') >= 4 then
      ph4 := right(regexp_replace(rec->>'phone', '\D', '', 'g'), 4);
    end if;

    -- skip if a guest with same email OR (phone4 + name) already exists
    if exists (
      select 1 from public.guests
       where wedding_id = w_id
         and ( (rec->>'email' is not null and lower(email) = lower(rec->>'email'))
            or (ph4 is not null and rec->>'name' is not null
                and phone_last4 = ph4 and lower(name) = lower(rec->>'name')) )
    ) then
      skipped := skipped + 1;
      continue;
    end if;

    tok := encode(extensions.gen_random_bytes(18), 'hex');
    insert into public.guests(wedding_id, name, email, phone, phone_last4,
                              signin_method, guest_token, status,
                              plus_ones_default)
      values (w_id, coalesce(rec->>'name',''), rec->>'email', rec->>'phone', ph4,
              'pre_added', tok, 'pending',
              coalesce((rec->>'plus_ones_default')::int, 0));
    added := added + 1;
  end loop;

  return json_build_object('added', added, 'skipped', skipped);
end; $$;

-- Edit one guest's editable fields.
create or replace function public.wp_admin_edit_guest(
  p_couple_token text, p_guest_id uuid, p_fields jsonb
) returns json
language plpgsql security definer set search_path = public as $$
declare w_id uuid;
begin
  select id into w_id from public.weddings where token = p_couple_token;
  if w_id is null then return json_build_object('error','not_found'); end if;
  update public.guests
     set name              = coalesce(p_fields->>'name', name),
         email             = coalesce(p_fields->>'email', email),
         phone             = coalesce(p_fields->>'phone', phone),
         plus_ones_default = coalesce((p_fields->>'plus_ones_default')::int, plus_ones_default)
   where id = p_guest_id and wedding_id = w_id;
  return json_build_object('ok', true);
end; $$;

-- Delete a guest.
create or replace function public.wp_admin_delete_guest(
  p_couple_token text, p_guest_id uuid
) returns json
language plpgsql security definer set search_path = public as $$
declare w_id uuid;
begin
  select id into w_id from public.weddings where token = p_couple_token;
  if w_id is null then return json_build_object('error','not_found'); end if;
  delete from public.guests where id = p_guest_id and wedding_id = w_id;
  return json_build_object('ok', true);
end; $$;

-- Send a broadcast alert. Audience JSON is one of:
--   {"type":"all"} | {"type":"event","event_id":"..."} | {"type":"guests","guest_ids":[...]}
create or replace function public.wp_admin_send_alert(
  p_couple_token text, p_title text, p_body text, p_audience jsonb, p_kind text
) returns json
language plpgsql security definer set search_path = public as $$
declare
  w_id uuid;
  a_id uuid;
begin
  select id into w_id from public.weddings where token = p_couple_token;
  if w_id is null then return json_build_object('error','not_found'); end if;
  insert into public.guest_alerts(wedding_id, title, body, audience, kind)
    values (w_id, coalesce(p_title,''), coalesce(p_body,''),
            coalesce(p_audience,'{"type":"all"}'::jsonb),
            coalesce(p_kind,'manual'))
    returning id into a_id;
  return json_build_object('ok', true, 'alert_id', a_id);
end; $$;

-- List alerts sent by this couple (for the dashboard's alert history).
create or replace function public.wp_admin_list_alerts(p_couple_token text)
returns json
language plpgsql security definer set search_path = public as $$
declare w_id uuid;
       result json;
begin
  select id into w_id from public.weddings where token = p_couple_token;
  if w_id is null then return json_build_object('error','not_found'); end if;
  select coalesce(json_agg(row_to_json(r) order by r.created_at desc), '[]'::json)
    into result
    from (
      select a.id, a.title, a.body, a.audience, a.kind, a.created_at,
             (select count(*) from public.alert_reads ar where ar.alert_id = a.id) as read_count
        from public.guest_alerts a
       where a.wedding_id = w_id
    ) r;
  return json_build_object('alerts', result);
end; $$;

-- ============================================================
--  Grants — expose to anon (browser) like the existing wp_* funcs
-- ============================================================

grant execute on function public.wp_get_guest_entry_token(text)                                   to anon;
grant execute on function public.wp_guest_signup(text, text, text, text, text, text)              to anon;
grant execute on function public.wp_guest_load(text)                                              to anon;
grant execute on function public.wp_guest_rsvp(text, text, boolean, int)                          to anon;
grant execute on function public.wp_guest_mark_alert_read(text, uuid)                             to anon;
grant execute on function public.wp_guest_register_push(text, jsonb)                              to anon;

grant execute on function public.wp_admin_list_guests(text)                                       to anon;
grant execute on function public.wp_admin_approve_guest(text, uuid, text)                         to anon;
grant execute on function public.wp_admin_upload_guests(text, jsonb)                              to anon;
grant execute on function public.wp_admin_edit_guest(text, uuid, jsonb)                           to anon;
grant execute on function public.wp_admin_delete_guest(text, uuid)                                to anon;
grant execute on function public.wp_admin_send_alert(text, text, text, jsonb, text)               to anon;
grant execute on function public.wp_admin_list_alerts(text)                                       to anon;

-- ============================================================
--  Notes
-- ============================================================
-- 1. Events stay inside weddings.data.events[] (existing JSONB).
--    The couple-side editor should add four optional fields to each event:
--      dress_code (text), parking_notes (text), map_link (text), know_before_notes (text)
--    No schema change needed for that — they just become new keys in the JSON.
-- 2. There is also a top-level couple-wide "know_before_general" string we'll
--    write into weddings.data (handled in the app, no SQL).
-- 3. Pre-added guests get signin_method='pre_added' and status='pending'. They
--    auto-promote to 'approved' when they actually sign in and match.

-- ============================================================
--  Missing RPCs (called by JS, not in original migration)
-- ============================================================

-- Add slug column to weddings for vanity URLs (#guestlogin-<slug>)
alter table public.weddings
  add column if not exists slug text unique;
create index if not exists weddings_slug_idx on public.weddings(slug);

-- Get or generate a couple's vanity slug.
-- Auto-generates one from bride+groom names if not set yet.
create or replace function public.wp_get_couple_slug(p_couple_token text)
returns json
language plpgsql security definer set search_path = public as $$
declare w public.weddings%rowtype; s text;
begin
  select * into w from public.weddings where token = p_couple_token;
  if w.id is null then return json_build_object('error','not_found'); end if;
  if w.slug is null then
    -- Auto-derive: lowercase first names joined by hyphen, de-duped if taken
    s := lower(regexp_replace(coalesce(w.bride_name,'') || '-' || coalesce(w.groom_name,''), '[^a-z0-9]+', '-', 'g'));
    s := trim(both '-' from s);
    if s = '' or s = '-' then s := encode(extensions.gen_random_bytes(6), 'hex'); end if;
    -- Make unique by appending 4-char suffix if collision
    if exists (select 1 from public.weddings where slug = s and id <> w.id) then
      s := s || '-' || left(encode(extensions.gen_random_bytes(4), 'hex'), 4);
    end if;
    update public.weddings set slug = s where id = w.id;
    w.slug := s;
  end if;
  return json_build_object('slug', w.slug);
end; $$;

-- Look up a couple by vanity slug — used for #guestlogin-<slug> links.
-- Returns enough info to show the sign-in screen header.
create or replace function public.wp_lookup_by_slug(p_slug text)
returns json
language plpgsql security definer set search_path = public as $$
declare w public.weddings%rowtype;
begin
  select * into w from public.weddings where lower(slug) = lower(p_slug);
  if w.id is null then return json_build_object('error','not_found'); end if;
  return json_build_object(
    'guest_entry_token', w.guest_entry_token,
    'bride_name', w.bride_name,
    'groom_name', w.groom_name,
    'wedding_date', w.wedding_date
  );
end; $$;

-- Lightweight couple info for the guest sign-in screen header (no auth required).
create or replace function public.wp_guest_couple_brief(p_guest_entry_token text)
returns json
language plpgsql security definer set search_path = public as $$
declare w public.weddings%rowtype;
begin
  select * into w from public.weddings where guest_entry_token = p_guest_entry_token;
  if w.id is null then return json_build_object('error','not_found'); end if;
  return json_build_object(
    'bride_name', w.bride_name,
    'groom_name', w.groom_name,
    'wedding_date', w.wedding_date
  );
end; $$;

-- Sign in an EXISTING guest — fail with "not_found" if no match.
-- Unlike wp_guest_signup which creates a new pending entry, this only
-- matches pre-existing guests (pre_added or already signed up).
create or replace function public.wp_guest_signin_strict(
  p_guest_entry_token text,
  p_name              text,
  p_email             text,
  p_phone             text
) returns json
language plpgsql security definer set search_path = public as $$
declare
  w_id    uuid;
  g       public.guests%rowtype;
  ph4     text;
begin
  select id into w_id from public.weddings where guest_entry_token = p_guest_entry_token;
  if w_id is null then return json_build_object('error','couple_not_found'); end if;

  if p_phone is not null and length(p_phone) >= 4 then
    ph4 := right(regexp_replace(p_phone, '\D', '', 'g'), 4);
  end if;

  -- Try email match first, then name+phone4
  if p_email is not null then
    select * into g from public.guests
     where wedding_id = w_id and lower(email) = lower(p_email)
     limit 1;
  end if;
  if g.id is null and ph4 is not null and p_name is not null then
    select * into g from public.guests
     where wedding_id = w_id and phone_last4 = ph4 and lower(name) = lower(p_name)
     limit 1;
  end if;
  -- Also match by name alone if no phone/email provided
  if g.id is null and p_name is not null then
    select * into g from public.guests
     where wedding_id = w_id and lower(name) = lower(p_name)
     limit 1;
  end if;

  if g.id is null then return json_build_object('error','not_found'); end if;
  if g.status = 'rejected' then return json_build_object('error','not_found'); end if;

  update public.guests set last_seen_at = now() where id = g.id;
  return json_build_object('guest_token', g.guest_token, 'status', g.status, 'guest_id', g.id);
end; $$;

-- Redeem a personal invite token (#i=<guest_token> links sent by couple).
-- Just validates the token and returns status — the guest_token IS the credential.
create or replace function public.wp_guest_redeem_invite(p_guest_token text)
returns json
language plpgsql security definer set search_path = public as $$
declare g public.guests%rowtype;
begin
  select * into g from public.guests where guest_token = p_guest_token;
  if g.id is null then return json_build_object('error','not_found'); end if;
  -- Auto-approve pre_added guests on first use of their personal link
  if g.status = 'pending' and g.signin_method = 'pre_added' then
    update public.guests
       set status = 'approved', approved_at = now(), approved_by = 'invite_link'
     where id = g.id;
    g.status := 'approved';
  end if;
  update public.guests set last_seen_at = now() where id = g.id;
  return json_build_object('guest_token', g.guest_token, 'guest_id', g.id, 'status', g.status);
end; $$;

-- Preview the guest portal as the couple — no auth flow, uses couple token.
-- Returns same shape as wp_guest_load so the portal UI can reuse the same renderer.
create or replace function public.wp_admin_preview_portal(p_couple_token text)
returns json
language plpgsql security definer set search_path = public as $$
declare w public.weddings%rowtype;
begin
  select * into w from public.weddings where token = p_couple_token;
  if w.id is null then return json_build_object('error','not_found'); end if;
  return json_build_object(
    'guest', json_build_object('id', null, 'name', 'Preview', 'status', 'approved'),
    'couple', json_build_object(
      'bride_name', w.bride_name, 'groom_name', w.groom_name, 'wedding_date', w.wedding_date
    ),
    'plan_data', w.data,
    'rsvps',  '[]'::json,
    'alerts', '[]'::json
  );
end; $$;

-- Additional grants
grant execute on function public.wp_get_couple_slug(text)            to anon;
grant execute on function public.wp_lookup_by_slug(text)             to anon;
grant execute on function public.wp_guest_couple_brief(text)         to anon;
grant execute on function public.wp_guest_signin_strict(text,text,text,text) to anon;
grant execute on function public.wp_guest_redeem_invite(text)        to anon;
grant execute on function public.wp_admin_preview_portal(text)       to anon;
