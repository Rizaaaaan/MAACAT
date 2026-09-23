# MAACAT — Making the lucky draw and stamp card real

The site works right now as a static page, and the stamp card and lucky draw both
*appear* to work — but only on one device at a time. Every stall's tablet has its own
private memory. Stall 03's tablet has no idea what stall 01 stamped ten minutes ago. That
is the one thing that has to change before this runs for real.

## The fastest path: Supabase (do this)

You don't need to hire a developer or run a server. Fifteen minutes, no code written by
you, and it's done.

**1. Create the database.**
Go to [supabase.com](https://supabase.com), sign up free, click **New project**. Pick any
name and password (save the password somewhere — you won't need it again unless you reset
it) and wait about a minute for it to spin up.

**2. Create the tables.**
In the left sidebar, click **SQL Editor** → **New query**. Open `supabase-schema.sql`
(sitting next to this file), copy the whole thing, paste it in, click **Run**. That one
paste creates every table, locks them down so nobody can read or write them directly from
a browser, and creates the six starting PINs (`1101`–`1106`).

**3. Get your two keys.**
Left sidebar → **Settings** → **API**. You need two things off that page:
- **Project URL** — looks like `https://abcdxyzcompany.supabase.co`
- **anon public** key — a long string starting with `eyJ...` (NOT the `service_role` key
  further down the page — that one must never appear in a website)

**4. Paste them in.**
Open `assets/js/backend.js` in any text editor. Near the top:

```js
const SUPABASE_URL = '';        // paste your Project URL between the quotes
const SUPABASE_ANON_KEY = '';   // paste your anon public key between the quotes
```

Fill both in, save, re-upload `assets/js/backend.js` to wherever the site is hosted
(same drag-and-drop process as any other file update). That's it — every stall's device
and the main site now read and write the same shared data. No further code changes.

**5. Change the PINs.**
The six PINs from the script are the ones in this README's staff table — public in this
document, so change them. Back in Supabase's SQL Editor, run six lines like:

```sql
update stall_pins set pin = '4471' where stall_id = '03';
```

one per stall, with whatever PINs you're actually going to hand out.

**6. Test it before the event, not during it.**
Open `staff.html?stall=01` on your phone, enter the PIN, grant a stamp to a test number.
Open the main site on a *different* device, check that number's stamp card — it should
show the stamp. If it does, every stall sharing one record is working.

Everything below this point is reference material — what the SQL script actually does,
how to read the data afterwards, and an alternative for later if you outgrow this. You
don't need to read it to get the thing working.

---

## Reference: the lucky draw API contract

This is what `submit_lucky_draw` in `supabase-schema.sql` already implements. Useful if
you ever move off Supabase onto your own server — otherwise you can skip to §8 for the
stamp card equivalent.

### What needs to exist

One endpoint:

```
POST /api/lucky-draw
Content-Type: application/json
```

### Request body

```json
{
  "age": "21–24",
  "phone": "7771234",
  "favouriteStall": "03 — Build-a-Brand",
  "why": "The random brief made it fun",
  "improve": "More time on the timer"
}
```

### Responses

Duplicate number:

```json
{ "success": false, "message": "This mobile number has already entered the lucky draw." }
```

New entry saved:

```json
{ "success": true, "message": "You're in! Good luck." }
```

The frontend already handles both shapes — it reads `success` and prints `message`.

---

### Rules the endpoint must enforce

1. **Normalise the phone number before checking.** Strip spaces, dashes, `+960`.
   `+960 777-1234`, `9607771234` and `7771234` must all collide.
2. **Unique constraint on the phone column in the database**, not just an `if` statement
   in your code. Two people submitting at the same second will otherwise both get through.
3. Validate length (7–15 digits) server-side too. Never trust the browser.
4. Rate limit by IP — a few submissions per minute is plenty for a real stall queue.
5. Never return the entries list to the browser. Reading the data is an admin job.

---

### Table shape

```sql
CREATE TABLE lucky_draw_entries (
  id              SERIAL PRIMARY KEY,
  phone           VARCHAR(20)  NOT NULL UNIQUE,   -- the duplicate guard
  age_group       VARCHAR(20)  NOT NULL,
  favourite_stall VARCHAR(60)  NOT NULL,
  why             TEXT,
  improve         TEXT,
  source          VARCHAR(40),                    -- from ?source= on the QR link
  created_at      TIMESTAMPTZ  NOT NULL DEFAULT now()
);
```

`source` is the bit people forget. Fill it from the URL parameter so you can tell which
poster actually brought people in.

---

### Alternative implementation (Next.js route handler, if you outgrow Supabase)

```ts
// app/api/lucky-draw/route.ts
import { NextResponse } from 'next/server';
import { sql } from '@/lib/db';

const normalise = (raw: string) =>
  raw.replace(/\D/g, '').replace(/^960/, '');

export async function POST(req: Request) {
  const body = await req.json();
  const phone = normalise(String(body.phone ?? ''));

  if (phone.length < 7 || phone.length > 15) {
    return NextResponse.json(
      { success: false, message: 'Enter a valid mobile number.' },
      { status: 400 }
    );
  }
  if (!body.age || !body.favouriteStall || !body.why) {
    return NextResponse.json(
      { success: false, message: 'Some answers are missing.' },
      { status: 400 }
    );
  }

  try {
    await sql`
      INSERT INTO lucky_draw_entries (phone, age_group, favourite_stall, why, improve, source)
      VALUES (${phone}, ${body.age}, ${body.favouriteStall},
              ${body.why}, ${body.improve ?? null}, ${body.source ?? null})
    `;
    return NextResponse.json({ success: true, message: "You're in! Good luck." });
  } catch (err: any) {
    // 23505 = unique violation, i.e. this number already entered
    if (err.code === '23505') {
      return NextResponse.json({
        success: false,
        message: 'This mobile number has already entered the lucky draw.'
      });
    }
    return NextResponse.json(
      { success: false, message: 'Something went wrong. Try once more.' },
      { status: 500 }
    );
  }
}
```

The duplicate check is the database rejecting the insert, not a lookup before it. That is
the part that survives two people submitting at the same time.

---

### Switching the frontend over to a custom server

In `index.html`, find `submitEntry()`. Delete the prototype block and uncomment the fetch
above it:

```js
async function submitEntry(payload){
  const res = await fetch('/api/lucky-draw', {
    method:'POST',
    headers:{'Content-Type':'application/json'},
    body: JSON.stringify(payload)
  });
  return res.json();
}
```

Then delete the `.proto-note` paragraph under the submit button.

---

### If you don't want to run your own server

(This is what the Supabase path above already gives you — this section is for weighing
it against the alternatives.)

A no-backend option that still blocks duplicates properly:

- **Supabase** — free tier, gives you Postgres plus a REST endpoint. Put the unique
  constraint on `phone`, write through an Edge Function so the key stays off the page.
- **Airtable / Google Apps Script** — easier, but you have to do the duplicate check in
  the script, and it will not hold up under two simultaneous submissions. Acceptable for a
  one-day event with a queue at the stall.

Given the event is one day with people submitting one at a time at a stall, Apps Script is
honestly good enough. Supabase is the better answer if you want the data afterwards.

---

## What to look at after the event

The reason the form asks what it asks:

| Question | What it answers |
| --- | --- |
| Age group | Who the stalls actually reached |
| Favourite stall | Which of the six earned its space |
| Why | The quotable line for next year's pitch |
| Improve | The only field that changes anything |
| `source` param | Which poster location was worth printing |
| Entries ÷ footfall | Your conversion rate from visitor to respondent |

Last year's dot board got ~150 responses. That is the number to beat.

**Getting the data out:** Supabase → **Table Editor** → `lucky_draw_entries` shows every
row in a spreadsheet-like view you can sort and filter directly, or click **Export** →
CSV to open it in Excel or Sheets. `stamp_grants` works the same way if you want to see
which stalls people actually finished versus dropped off at.

---

## Reference: how the stamp card functions work

This is what `supabase-schema.sql` already set up when you ran it in step 2 above. Read
this if you want to understand what the SQL actually did, change how it works, or move it
to your own server later.

Last year this was a physical card. This version has two things that need a real
backend: the lucky draw entry above, and the stamp card below. They share a phone number
as the join key, so build them together.

The idea: winning a stall's game earns a stamp. Collect all six and the grand lucky draw
unlocks. Right now `index.html` and `staff.html` both read/write
`localStorage['maacat_stamps_prototype']`, which only works because it's one browser on
one device. On the day, six stalls means six separate phones or tablets — they need to
share one record, which means a server.

### Endpoints

```
POST /api/stamps/grant
Content-Type: application/json

{ "stallId": "03", "pin": "1103", "phone": "7771234" }
```

Responses:

```json
{ "success": true, "stampCount": 3, "fullCard": false }
{ "success": false, "message": "Already stamped for this stall." }
{ "success": false, "message": "Wrong PIN for this stall." }
```

```
GET /api/stamps/status?phone=7771234
```

```json
{ "phone": "7771234", "stamps": ["01","02","03"], "stampCount": 3, "fullCard": false }
```

The "My Stamp Card" section on the main site calls this to render the six slots. Right
now it reads localStorage instead — swap `readStampsFor()` in `index.html` for a `fetch`
to this endpoint.

### The PIN check has to move server-side

`staff.html` currently checks the PIN against a plain object sitting in the page's own
JavaScript. That stops a random visitor from tapping the tablet, but anyone who opens dev
tools can read all six PINs in about ten seconds. Fine for a prototype, not fine for the
actual event.

Move the real check into `/api/stamps/grant`: the frontend still asks for a PIN so staff
get an immediate "wrong PIN" without a round trip, but the server independently verifies
`pin` against the stored value for that `stallId` before writing anything. If someone
edits `staff.html` locally to skip the client-side check, the server still rejects the
grant. Store the six PINs hashed — same idea as a password table, so a leak doesn't hand
out all six in plaintext.

### Table shape

```sql
CREATE TABLE stamp_grants (
  id         SERIAL PRIMARY KEY,
  phone      VARCHAR(20) NOT NULL,
  stall_id   VARCHAR(2)  NOT NULL,
  granted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (phone, stall_id)          -- one stamp per phone per stall, ever
);

CREATE TABLE stall_pins (
  stall_id  VARCHAR(2) PRIMARY KEY,
  pin_hash  TEXT NOT NULL
);
```

`UNIQUE (phone, stall_id)` is what "already stamped" actually means — same pattern as the
phone unique constraint on the lucky draw table, just two columns instead of one.

### Reference implementation (Next.js)

```ts
// app/api/stamps/grant/route.ts
import { NextResponse } from 'next/server';
import { sql } from '@/lib/db';
import bcrypt from 'bcryptjs';

const normalise = (raw: string) => raw.replace(/\D/g, '').replace(/^960/, '');

export async function POST(req: Request) {
  const { stallId, pin, phone: rawPhone } = await req.json();
  const phone = normalise(String(rawPhone ?? ''));

  const [row] = await sql`SELECT pin_hash FROM stall_pins WHERE stall_id = ${stallId}`;
  if (!row || !(await bcrypt.compare(pin, row.pin_hash))) {
    return NextResponse.json({ success: false, message: 'Wrong PIN for this stall.' }, { status: 401 });
  }

  try {
    await sql`INSERT INTO stamp_grants (phone, stall_id) VALUES (${phone}, ${stallId})`;
  } catch (err: any) {
    if (err.code === '23505') {
      return NextResponse.json({ success: false, message: 'Already stamped for this stall.' });
    }
    throw err;
  }

  const rows = await sql`SELECT stall_id FROM stamp_grants WHERE phone = ${phone}`;
  const stampCount = rows.length;
  return NextResponse.json({ success: true, stampCount, fullCard: stampCount === 6 });
}
```

### Tying it to the lucky draw

`/api/lucky-draw` (section 4) should check `stampCount === 6` for that phone before
accepting the submission — the same query the `/status` endpoint runs. That way "must
collect all six" is enforced in one place the frontend can't bypass, rather than only in
`index.html`'s JavaScript gate.

### Offline risk

Six stalls hitting one server over event wifi is the most likely thing to break on the
day. Two options, ranked by effort:

- **Cheap:** on a failed request, `staff.html` shows "no signal — write the number down"
  and staff keep a physical backup list, entered later. Costs nothing to build, costs
  someone twenty minutes after the event.
- **Better:** the grant screen queues failed grants in the tablet's own localStorage and
  retries automatically once the connection returns. More code, no manual backfill.

Given this runs for one day, the cheap option is a reasonable place to stop.
