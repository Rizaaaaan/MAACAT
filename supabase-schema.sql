-- ============================================================
-- MAACAT — Supabase setup for a BRAND-NEW project (lucky draw only)
-- ============================================================
-- Already have the L.E.A.D. 2026 project? Don't use this file —
-- run supabase-vara-update.sql instead.
--
-- New project: left sidebar → SQL Editor → New query → paste all
-- of this → Run. Then copy Settings → API "Project URL" and the
-- "anon public" key into assets/js/backend.js.
-- ============================================================

create table if not exists lucky_draw_entries (
  id              bigserial primary key,
  event           text not null default 'VARA EXPO 2026',
  phone           text not null,
  age_group       text not null,
  favourite_stall text not null,
  why             text not null,
  improve         text,
  created_at      timestamptz not null default now()
);

-- One entry per phone number, per event
create unique index if not exists lucky_draw_entries_event_phone_key
  on lucky_draw_entries (event, phone);

-- Row Level Security with no policies = nobody can read or write the
-- table directly from a browser. The only way in is the function below.
alter table lucky_draw_entries enable row level security;

create or replace function submit_lucky_draw(
  p_phone text, p_age text, p_favourite_stall text,
  p_why text, p_improve text default null,
  p_event text default 'VARA EXPO 2026'
)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_phone text := regexp_replace(coalesce(p_phone, ''), '\D', '', 'g');
  v_event text := coalesce(nullif(trim(p_event), ''), 'VARA EXPO 2026');
begin
  if length(v_phone) < 7 or length(v_phone) > 15 then
    return json_build_object('success', false, 'status', 'invalid',
      'message', 'Please enter a valid mobile number.');
  end if;

  if coalesce(trim(p_age), '') = ''
     or coalesce(trim(p_favourite_stall), '') = ''
     or coalesce(trim(p_why), '') = '' then
    return json_build_object('success', false, 'status', 'invalid',
      'message', 'Please answer every question.');
  end if;

  begin
    insert into lucky_draw_entries (event, phone, age_group, favourite_stall, why, improve)
    values (
      v_event, v_phone, trim(p_age), trim(p_favourite_stall),
      left(trim(p_why), 1000),
      nullif(left(trim(coalesce(p_improve, '')), 1000), '')
    );
  exception when unique_violation then
    return json_build_object('success', false, 'status', 'duplicate',
      'message', 'You have already entered the lucky draw.');
  end;

  return json_build_object('success', true, 'status', 'ok',
    'message', 'You''ve entered the lucky draw!');
end;
$$;

grant execute on function submit_lucky_draw(text, text, text, text, text, text) to anon;
