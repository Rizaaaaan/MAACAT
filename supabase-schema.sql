-- ============================================================
-- MAACAT — Supabase setup
-- ============================================================
-- Run this ONCE, in a new Supabase project's SQL editor
-- (left sidebar → SQL Editor → New query → paste all of this → Run).
--
-- What this gives you:
--   - A shared stamp record every stall's device reads/writes
--   - A shared lucky-draw entry table with duplicate-number blocking
--   - PIN checking that happens on the server, never in a webpage
--
-- Nothing here needs Node, a server, or anyone on the team who
-- codes. This is the entire backend.
-- ============================================================

-- ---------- Tables ----------

create table if not exists stall_pins (
  stall_id  text primary key,
  pin       text not null
);

create table if not exists stamp_grants (
  id         bigserial primary key,
  phone      text not null,
  stall_id   text not null references stall_pins(stall_id),
  granted_at timestamptz not null default now(),
  unique (phone, stall_id)
);

create table if not exists lucky_draw_entries (
  id              bigserial primary key,
  phone           text not null unique,
  age_group       text not null,
  favourite_stall text not null,
  why             text not null,
  improve         text,
  source          text,
  created_at      timestamptz not null default now()
);

-- ---------- Starting PINs ----------
-- Change these to whatever you actually want to hand out.
-- You can re-run just this block later to change a PIN:
--   update stall_pins set pin = '4471' where stall_id = '03';

insert into stall_pins (stall_id, pin) values
  ('01','1101'), ('02','1102'), ('03','1103'),
  ('04','1104'), ('05','1105'), ('06','1106')
on conflict (stall_id) do nothing;

-- ---------- Lock every table down ----------
-- Row Level Security with no policies = nobody can read or write
-- these tables directly, from the browser, at all. The only way
-- in is through the functions below, which run with elevated
-- rights and decide for themselves what's allowed.

alter table stall_pins enable row level security;
alter table stamp_grants enable row level security;
alter table lucky_draw_entries enable row level security;

-- ---------- Functions the website actually calls ----------

-- Checks a PIN without ever returning it. staff.html calls this
-- once, when a stall's device is unlocked for the day.
create or replace function verify_stall_pin(p_stall_id text, p_pin text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  return exists (
    select 1 from stall_pins
    where stall_id = p_stall_id and pin = p_pin
  );
end;
$$;

-- Records a stamp. Returns success, or "already stamped" if that
-- phone already has this stall's stamp — the database itself
-- enforces that, via the unique constraint above.
create or replace function grant_stamp(p_stall_id text, p_phone text)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count int;
begin
  begin
    insert into stamp_grants (phone, stall_id) values (p_phone, p_stall_id);
  exception when unique_violation then
    return json_build_object('success', false, 'message', 'Already stamped for this stall.');
  end;

  select count(*) into v_count from stamp_grants where phone = p_phone;
  return json_build_object(
    'success', true,
    'stamp_count', v_count,
    'full_card', v_count = 6
  );
end;
$$;

-- Read-only progress check. index.html calls this for the
-- "My Stamp Card" section.
create or replace function get_stamp_status(p_phone text)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_stamps text[];
begin
  select array_agg(stall_id order by stall_id) into v_stamps
  from stamp_grants where phone = p_phone;
  v_stamps := coalesce(v_stamps, array[]::text[]);
  return json_build_object(
    'stamps', v_stamps,
    'stamp_count', array_length(v_stamps, 1),
    'full_card', coalesce(array_length(v_stamps, 1), 0) = 6
  );
end;
$$;

-- The grand draw entry. Refuses anything short of a full card,
-- and refuses a phone number that's already entered — both
-- checked here, not in the page's JavaScript, so neither rule
-- can be skipped by editing the page.
create or replace function submit_lucky_draw(
  p_phone text, p_age text, p_favourite_stall text,
  p_why text, p_improve text default null, p_source text default null
)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count int;
begin
  select count(*) into v_count from stamp_grants where phone = p_phone;
  if v_count < 6 then
    return json_build_object(
      'success', false,
      'message', format('This number has %s of 6 stamps. Visit the remaining stalls, then come back.', v_count)
    );
  end if;

  begin
    insert into lucky_draw_entries (phone, age_group, favourite_stall, why, improve, source)
    values (p_phone, p_age, p_favourite_stall, p_why, p_improve, p_source);
  exception when unique_violation then
    return json_build_object('success', false, 'message', 'This mobile number has already entered the lucky draw.');
  end;

  return json_build_object('success', true, 'message', 'You''re in! Good luck.');
end;
$$;

-- ---------- Who's allowed to call what ----------
-- The website connects as the "anon" role. It gets NO direct
-- table access (RLS above already blocks that) — only permission
-- to call these four functions.

grant execute on function verify_stall_pin(text, text)          to anon;
grant execute on function grant_stamp(text, text)                to anon;
grant execute on function get_stamp_status(text)                 to anon;
grant execute on function submit_lucky_draw(text, text, text, text, text, text) to anon;

-- ============================================================
-- Done. Next: Settings → API in the Supabase sidebar, copy the
-- "Project URL" and the "anon public" key into
-- assets/js/backend.js, and every device pointed at this site
-- shares this data from then on.
-- ============================================================
