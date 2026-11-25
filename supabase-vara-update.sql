-- ============================================================
-- MAACAT — lucky draw update for VARA EXPO 2026
-- ============================================================
-- Run this ONCE in your existing Supabase project:
--   left sidebar → SQL Editor → New query → paste all of this → Run.
-- Safe to run more than once. Keeps every L.E.A.D. 2026 entry.
--
-- What it changes:
--   - Every entry is tagged with the event it came from
--   - "One entry per number" becomes one entry per number PER EVENT,
--     so people who already entered at L.E.A.D. 2026 can enter again
--     at VARA Expo (otherwise they'd see "already entered")
--   - The database double-checks the phone number and answers too
-- ============================================================

-- ---------- 1. Tag entries with their event ----------
alter table lucky_draw_entries add column if not exists event text;
update lucky_draw_entries set event = 'L.E.A.D. 2026' where event is null;
alter table lucky_draw_entries alter column event set default 'VARA EXPO 2026';
alter table lucky_draw_entries alter column event set not null;

-- ---------- 2. One entry per number, per event ----------
-- Remove the old "phone must be unique forever" rule, whatever it's called
do $$
declare c record;
begin
  for c in
    select con.conname
    from pg_constraint con
    join pg_class rel on rel.oid = con.conrelid
    join pg_attribute att on att.attrelid = rel.oid and att.attname = 'phone'
    where rel.relname = 'lucky_draw_entries'
      and con.contype = 'u'
      and con.conkey = array[att.attnum]
  loop
    execute format('alter table lucky_draw_entries drop constraint %I', c.conname);
  end loop;
end $$;

create unique index if not exists lucky_draw_entries_event_phone_key
  on lucky_draw_entries (event, phone);

-- ---------- 3. New version of the function the website calls ----------
drop function if exists submit_lucky_draw(text, text, text, text, text);

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

-- Tell the API about the new function straight away
notify pgrst, 'reload schema';

-- ============================================================
-- Done. Handy queries for the expo (run them in the SQL Editor):
--
--   VARA entries, newest first:
--     select * from lucky_draw_entries
--     where event = 'VARA EXPO 2026' order by created_at desc;
--
--   How many so far:
--     select count(*) from lucky_draw_entries where event = 'VARA EXPO 2026';
--
--   Pick a random winner:
--     select phone, age_group, favourite_stall from lucky_draw_entries
--     where event = 'VARA EXPO 2026' order by random() limit 1;
-- ============================================================
