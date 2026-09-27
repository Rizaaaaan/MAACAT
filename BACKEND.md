# MAACAT — Making the lucky draw survey real

The survey works right now, and the duplicate-number check works — but only on one
device at a time, because it's saving to that browser's own local storage. Every visitor
on their own phone needs to share one record, or the same number could enter from two
different phones. That's the one thing that has to change before this runs for real.

## The fifteen-minute setup: Supabase

You don't need to hire a developer or run a server.

**1. Create the database.**
Go to [supabase.com](https://supabase.com), sign up free, click **New project**. Pick any
name and password and wait about a minute for it to spin up.

**2. Create the table.**
Left sidebar → **SQL Editor** → **New query**. Open `supabase-schema.sql` (sitting next to
this file), copy the whole thing, paste it in, click **Run**. That one paste creates the
table, locks it down so nobody can read or write it directly from a browser, and creates
the one function the site calls.

**3. Get your two keys.**
Left sidebar → **Settings** → **API**. You need:
- **Project URL** — looks like `https://abcdxyzcompany.supabase.co`
- **anon public** key — a long string starting with `eyJ...` (NOT the `service_role` key
  further down the page — that one must never appear in a website)

**4. Paste them in.**
Open `assets/js/backend.js` in any text editor. Near the top:

```js
const SUPABASE_URL = '';        // paste your Project URL between the quotes
const SUPABASE_ANON_KEY = '';   // paste your anon public key between the quotes
```

Fill both in, save, re-upload that one file to wherever the site is hosted. That's it —
every visitor's submission now goes to the same shared table, and the duplicate check is
enforced by the database itself, not just by the page's own JavaScript.

**5. Test it before the event, not during it.**
Open `internal-test.html`, submit a test entry, check it landed in Supabase's Table
Editor. Submit the same number again, confirm it gets rejected. Do this before you rely on
it in front of a crowd.

---

## What "already entered" actually means

The `phone` column in the `lucky_draw_entries` table has a `unique` constraint on it —
Postgres itself refuses a second row with the same number, no matter which device or how
many people submit at the exact same moment. The website's JavaScript never decides this;
it just reports back whatever the database decided. That's the difference between a real
duplicate check and one that only looks like it works.

---

## Getting the data out

Supabase → **Table Editor** → `lucky_draw_entries` shows every row in a spreadsheet-like
view you can sort and filter directly, or click **Export** → **CSV** to open it in Excel
or Google Sheets.

The reason the form asks what it asks:

| Question | What it answers |
| --- | --- |
| Age group | Who the stalls actually reached |
| Favourite stall | Which of the six earned its space |
| Why | The quotable line for next year's pitch |
| Improve | The only field that changes anything |

---

## If something goes wrong on the day

If the site can't reach Supabase (bad wifi, Supabase having a moment), the popup will say
"Connection problem — try again" rather than silently losing the entry. Worth telling
whoever's minding the stall to just have people retry once if they see that message.
