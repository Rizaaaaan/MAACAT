# MAACAT — VARA Expo 2026 site

Single-page site for MAACAT, the student marketing club at MNU, for VARA Expo 2026
(26–28 November · Education Zone · Hulhumalé Central Park). No build step — open
`index.html` in a browser and it works.

```
index.html                     the whole site (content + settings at the top of the <script>)
assets/css/site.css            styles
assets/js/backend.js           lucky draw → Supabase (keys + event name live here)
assets/branding/               logo + cat icon
supabase-vara-update.sql       run ONCE on the existing Supabase project (see below)
supabase-schema.sql            only for a brand-new Supabase project
```

---

## Before the expo — do these in order

1. **Wake up Supabase.** The free plan pauses a project after a week with no activity,
   which is why the lucky draw said "Couldn't submit". Go to supabase.com → your project →
   **Resume project**. Wait a few minutes until the dashboard shows it running.

2. **Run the update.** Supabase → **SQL Editor** → **New query** → paste all of
   `supabase-vara-update.sql` → **Run**. This keeps every L.E.A.D. entry but tags it
   "L.E.A.D. 2026", so people who entered last time can enter again at VARA. Without it
   the draw still works, but anyone who entered at L.E.A.D. would be told "already
   entered".

3. **Upload to GitHub.** Open the repo → **Add file → Upload files** → drag in
   `index.html` and the `assets` folder → **Commit**. (Don't delete the `CNAME` file —
   that's what keeps maacat.com working.) The old `assets/posters/` folder isn't used
   any more; delete it whenever you like.

4. **Test on a real phone.** Open maacat.com, fill in the lucky draw with your own number
   → green "You're in!" with confetti. Submit the same number again → yellow "Already
   entered". Then delete your test row in Supabase → **Table Editor** →
   `lucky_draw_entries`.

---

## During the expo

Supabase → **SQL Editor**:

```sql
-- VARA entries, newest first
select * from lucky_draw_entries where event = 'VARA EXPO 2026' order by created_at desc;

-- how many so far
select count(*) from lucky_draw_entries where event = 'VARA EXPO 2026';

-- pick a random winner
select phone, age_group, favourite_stall from lucky_draw_entries
where event = 'VARA EXPO 2026' order by random() limit 1;
```

Or **Table Editor → lucky_draw_entries → Export → CSV** to open everything in Excel.

---

## Quick edits (all near the top of the `<script>` in index.html)

| What | Where |
| --- | --- |
| Countdown opening time (set to 4 PM) | `EXPO_OPENS` |
| Popup wording ("You're in!", errors) | `LUCKY_DRAW_COPY` |
| Activity names, descriptions, steps | `ACTIVITIES` |
| Mascot speech-bubble lines | `MASCOT_LINES` |
| Event name the draw is tagged with | `LUCKY_DRAW_EVENT` in `assets/js/backend.js` |

The countdown counts to the opening, shows "Live now · Day X of 3" during the expo, and
hides itself after 28 November. The cat logo stays.

**Next event:** change `LUCKY_DRAW_EVENT` in `backend.js` (e.g. `'NEXT EVENT 2027'`) and
the draw starts fresh. Every older entry stays saved under its own event name.

---

## Links

- `maacat.com/?activity=01` … `?activity=04` opens that activity straight away (good for QR
  codes). Old `?stall=` links still work.
- Google Analytics events: `activity_open`, `cat_pick`, `mascot_tap`,
  `lucky_draw_submit` (with result), `open_maps`, `add_to_calendar`, `instagram`, `tiktok`.

## How it's built

Mobile-first, checked with no sideways scrolling at 320, 375, 390, 430, 768, 1024, 1280
and 1440px. Keyboard-navigable, focus stays inside the activity panel and popup, Escape
closes them, and `prefers-reduced-motion` turns off the animations and confetti.
