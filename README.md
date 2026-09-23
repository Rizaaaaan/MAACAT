# MAACAT — L.E.A.D. 2026 site

Single-page campaign site for the MAACAT marketing team. No build step, no framework —
open `index.html` in a browser and it works.

```
index.html                       the main site
staff.html                       stamp-granting screen, one per stall via ?stall=01..06
BACKEND.md                       exact steps to make the lucky draw + stamp card real
supabase-schema.sql              paste into Supabase once — see BACKEND.md
assets/
  branding/maacat-logo.png       your logo (already in place)
  css/site.css                   shared styles for both pages
  js/backend.js                  ← put your Supabase keys here (see BACKEND.md)
  posters/stall-01.jpg           ← drop the six posters here
  posters/stall-02.jpg
  ...stall-06.jpg
  map/event-map.jpg              ← drop the venue map here
```

---

## Putting it online

Drag the whole folder onto [netlify.com/drop](https://app.netlify.com/drop), or push it to
a GitHub repo and turn on GitHub Pages. Either gives you a live URL for free. You need a
real URL before you print the posters or hand out staff links — the QR codes and
`staff.html?stall=NN` links have to point somewhere.

---

## Current phase: premarketing (info only)

The public site (`index.html`) is deliberately stripped down right now — no lucky draw,
no feedback form, no stamp card, no event map. Premarketing means showing what's coming,
not the full experience yet.

None of that work is lost. `staff.html`, `assets/js/backend.js`, `supabase-schema.sql` and
`BACKEND.md` are all still here, untouched, ready for whenever you turn those features back
on. Bringing them back means re-adding the corresponding sections to `index.html` — ask for
that when the time comes rather than rebuilding from scratch.

---

## Make the lucky draw and stamp card actually work

Right now both features run in "local" mode — they work, but only on whichever single
device you're testing on. Six stalls need one shared record between them, which means a
real database. **`BACKEND.md` has the exact fifteen-minute setup** — no code to write,
just a free Supabase account, one SQL paste, and two values copied into
`assets/js/backend.js`. Do this before the event, not during it.

You'll know it's working when `staff.html` shows "Live mode" instead of "Prototype mode"
at the bottom of the grant screen.

---

## Running the stamp card on the day

Six stalls, six stamps, one grand lucky draw for anyone who collects all six.

**Staff side.** Each stall gets its own link:

```
https://yoursite.com/staff.html?stall=01
https://yoursite.com/staff.html?stall=02
...stall=06
```

Bookmark it, or tape a QR to the tablet, so staff open it once and leave it running. It
asks for a 4-digit PIN, then shows a number pad to type the participant's mobile number
and a **Grant Stamp** button.

Starting PINs (set in `supabase-schema.sql`, change them there before the event):

| Stall | PIN |
| --- | --- |
| 01 Marketing Ladder | 1101 |
| 02 Cheap or Chic? | 1102 |
| 03 Build-a-Brand | 1103 |
| 04 Maacat Snap Lab | 1104 |
| 05 PR Disaster | 1105 |
| 06 Brand Relay | 1106 |

**Visitor side.** The "My Stamp Card" section on the main site lets anyone type their
number and see which of the six they've collected. The lucky draw form further down won't
accept a submission until that number shows all six — enforced by the database itself
once you've connected Supabase, not just by the page's own JavaScript.

---

## The other things you swap in later

**Posters.** Save them as `assets/posters/stall-01.jpg` through `stall-06.jpg`. Nothing
else to change — the page picks them up automatically, and shows a numbered placeholder if
a file isn't there yet. Portrait 3:4 crops look best. Keep each under about 300KB so
phones load them fast.

**Event map.** In `index.html`, find `<!-- Swap in:` inside the `.map` block and uncomment
that line once you have `assets/map/event-map.jpg`.

---

## Editing the stalls

All six stalls live in one array near the top of `index.html`'s `<script>` block, labelled
`STALLS`. Change the text there and the cards, the modals and the poster wall all update
together — you never edit the same stall in three places. `staff.html` has its own small
copy of just the names and colours (for its header), listed separately at the top of its
script — keep the two in sync if you rename a stall.

Stall 06 and the three PR Disaster scenarios are deliberately marked as not finalised.
When you decide them, fill in `lede`, `doList`, `learnList` and delete the `pending` line.

---

## QR codes

Point each poster's QR at:

```
https://yoursite.com/?stall=01&source=poster
https://yoursite.com/?stall=02&source=poster
...
```

Opening that link scrolls to the stalls and pops that stall's panel open straight away.
The `source` parameter is what lets you measure which poster brought people in — it gets
passed through to the lucky draw entry automatically. Give different poster locations
different values (`source=canteen`, `source=entrance`) if you want to compare spots.

Generate the codes at qr-code-generator.com or similar. Test one with an actual phone
before you send anything to print.

---

## Before the day

- [ ] Real URL live
- [ ] Supabase set up per `BACKEND.md`, keys pasted into `assets/js/backend.js`
- [ ] Confirmed `staff.html` says "Live mode", not "Prototype mode"
- [ ] Six stall PINs changed from the demo values (`supabase-schema.sql` → re-run the
      `update stall_pins ...` lines from `BACKEND.md`), given only to the right staff
- [ ] One staff member per stall knows their `staff.html?stall=NN` link
- [ ] QR codes generated from the real URL and scan-tested on a phone
- [ ] Six posters dropped into `assets/posters/`
- [ ] Event map added
- [ ] One test entry submitted end-to-end: grant all 6 stamps on different devices, check
      the card on a third device, submit the lucky draw form, confirm a repeat submission
      is rejected
- [ ] Opened on an actual phone, not just a resized browser window

---

## Notes on how it's built

Mobile-first: the base CSS is the phone layout, and the media queries only add things as
the screen gets wider. Checked with no horizontal overflow at 320, 390, 430, 768 and
1280px.

Accessibility: semantic landmarks, keyboard-navigable throughout, focus trapped inside the
stall panel and returned to the card you opened it from, Escape closes, visible focus
rings, form errors sit directly under their field and the first bad field is scrolled to.
`prefers-reduced-motion` switches off every animation.

Performance: no frameworks, two web fonts, posters lazy-load, and the marquee pauses when
it scrolls off screen.

Backend: `assets/js/backend.js` is the only file that knows whether it's talking to a real
database or just `localStorage`. Both `index.html` and `staff.html` call the same handful
of functions on it (`grantStamp`, `getStatus`, `submitLuckyDraw`, `verifyPin`) without
caring which mode is active — so once you've set up Supabase, nothing else in either page
needs to change.
