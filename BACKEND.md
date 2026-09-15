# MAACAT — Lucky draw backend

The site works right now as a static page. The one thing it **cannot** do on its own is
stop the same mobile number entering the lucky draw twice, and it cannot save your
responses anywhere you can read them later.

Right now the form uses `localStorage`, which only knows about entries made on **that one
phone**. Anyone on a different phone can re-enter the same number. That is fine for
testing, not fine on the day.

This file is what you hand to whoever wires up the backend.

---

## 1. What needs to exist

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

## 2. Rules the endpoint must enforce

1. **Normalise the phone number before checking.** Strip spaces, dashes, `+960`.
   `+960 777-1234`, `9607771234` and `7771234` must all collide.
2. **Unique constraint on the phone column in the database**, not just an `if` statement
   in your code. Two people submitting at the same second will otherwise both get through.
3. Validate length (7–15 digits) server-side too. Never trust the browser.
4. Rate limit by IP — a few submissions per minute is plenty for a real stall queue.
5. Never return the entries list to the browser. Reading the data is an admin job.

---

## 3. Table shape

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

## 4. Reference implementation (Next.js route handler)

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

## 5. Switching the frontend over

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

## 6. If you don't want to run a server

A no-backend option that still blocks duplicates properly:

- **Supabase** — free tier, gives you Postgres plus a REST endpoint. Put the unique
  constraint on `phone`, write through an Edge Function so the key stays off the page.
- **Airtable / Google Apps Script** — easier, but you have to do the duplicate check in
  the script, and it will not hold up under two simultaneous submissions. Acceptable for a
  one-day event with a queue at the stall.

Given the event is one day with people submitting one at a time at a stall, Apps Script is
honestly good enough. Supabase is the better answer if you want the data afterwards.

---

## 7. What to look at after the event

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
