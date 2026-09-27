-- ============================================================
-- MAACAT — Supabase setup (lucky draw only)
-- ============================================================
-- Run this ONCE, in a new Supabase project's SQL editor
-- (left sidebar → SQL Editor → New query → paste all of this → Run).
--
-- What this gives you:
--   - One shared table every survey submission lands in
--   - A phone number can only enter once, ever — enforced by the
--     database itself, not just by the page's JavaScript
-- ============================================================

-- ---------- Table ----------

create table if not exists lucky_draw_entries (
  id              bigserial primary key,
  phone           text not null unique,
  age_group       text not null,
  favourite_stall text not null,
  why             text not null,
  improve         text,
  created_at      timestamptz not null default now()
);

-- ---------- Lock it down ----------
-- Row Level Security with no policies = nobody can read or write
-- this table directly from the browser. The only way in is
-- through the function below.

alter table lucky_draw_entries enable row level security;

-- ---------- The function the website calls ----------
-- Tries to insert. If the phone number already exists, the
-- table's UNIQUE constraint rejects it and this catches that
-- and returns the "already entered" message instead.

create or replace function submit_lucky_draw(
  p_phone text, p_age text, p_favourite_stall text,
  p_why text, p_improve text default null
)
returns json
language plpgsql
security definer
set search_path = public
as $$
begin
  begin
    insert into lucky_draw_entries (phone, age_group, favourite_stall, why, improve)
    values (p_phone, p_age, p_favourite_stall, p_why, p_improve);
  exception when unique_violation then
    return json_build_object(
      'success', false,
      'message', 'You have already entered the lucky draw.'
    );
  end;

  return json_build_object(
    'success', true,
    'message', 'You''ve entered the lucky draw! Please vote MAACAT for the best team of the event.'
  );
end;
$$;

-- ---------- Who's allowed to call it ----------
-- The website connects as the "anon" role. It gets NO direct
-- table access (RLS above blocks that) — only permission to call
-- this one function.

grant execute on function submit_lucky_draw(text, text, text, text, text) to anon;

-- ============================================================
-- Done. Next: Settings → API in the Supabase sidebar, copy the
-- "Project URL" and the "anon public" key into
-- assets/js/backend.js.
-- ============================================================
