# MAACAT — L.E.A.D. 2026 site

Single-page campaign site for the MAACAT marketing team. No build step, no framework —
open `index.html` in a browser and it works.

```
index.html                       the public site
internal-test.html               private page to test the lucky draw before launch
BACKEND.md                       exact steps to make the survey save for real
supabase-schema.sql              paste into Supabase once — see BACKEND.md
assets/
  branding/                      logo + icon (already in place)
  css/site.css                   shared styles
  js/backend.js                  ← put your Supabase keys here (see BACKEND.md)
  posters/stall-01.jpg           ← drop the six posters here
  posters/stall-02.jpg
  ...stall-06.jpg
  map/                           unused for now
```

---

## Current phase: premarketing (info only)

The public site (`index.html`) is deliberately info-only right now — no lucky draw form
visible yet. `internal-test.html` is where the team tests that feature before it goes
live, without exposing it to premarketing visitors. It isn't linked from anywhere on the
public site — only reachable if you know the direct URL.

On event day, the form and popup from `internal-test.html` get added to `index.html`
proper, and `internal-test.html` gets deleted.

---

## Putting it online

Drag the whole folder onto [netlify.com/drop](https://app.netlify.com/drop), or push it to
a GitHub repo and turn on GitHub Pages. Either gives you a live URL for free.

---

## Make the lucky draw actually save

Right now it runs in "local" mode — it works, but only on whichever single device you're
testing on. **`BACKEND.md` has the exact fifteen-minute setup** — no code to write, just a
free Supabase account, one SQL paste, and two values copied into `assets/js/backend.js`.

You'll know it's working when `internal-test.html` shows "Live" instead of "Local" under
the page title.

---

## Testing before launch

1. Open `internal-test.html`.
2. Fill in the form with a test phone number, submit. You should get a green popup:
   *"You've entered the lucky draw! Please vote MAACAT for the best team of the event."*
3. Submit again with the exact same number. You should get an orange popup instead:
   *"You have already entered the lucky draw."*
4. Try a different number — should succeed again.
5. If you've set up Supabase, check **Table Editor → lucky_draw_entries** to confirm the
   rows are actually there, not just showing a nice popup with nothing saved behind it.

---

## Editing the stalls

The list of stalls that shows in the survey's "favourite stall" question lives near the
top of `internal-test.html`'s `<script>` block (`STALLS`), and separately in `index.html`
for the stall cards and modals. Keep the names in sync between the two if you rename one.

---

## QR codes

Point each poster's QR at:

```
https://yoursite.com/?stall=01
https://yoursite.com/?stall=02
...
```

Opening that link scrolls to the stalls and pops that stall's panel open straight away.

Generate the codes at qr-code-generator.com or similar. Test one with an actual phone
before you send anything to print.

---

## Before the day

- [ ] Real URL live
- [ ] Supabase set up per `BACKEND.md`, keys pasted into `assets/js/backend.js`
- [ ] Confirmed `internal-test.html` says "Live", not "Local"
- [ ] Lucky draw form and popup merged into `index.html`, `internal-test.html` deleted
- [ ] One test entry submitted end-to-end, confirmed in Supabase, then a repeat of the
      same number confirmed as rejected
- [ ] QR codes generated from the real URL and scan-tested on a phone
- [ ] Six posters dropped into `assets/posters/`
- [ ] Opened on an actual phone, not just a resized browser window

---

## Notes on how it's built

Mobile-first: the base CSS is the phone layout, and the media queries only add things as
the screen gets wider. Checked with no horizontal overflow at 320, 390, 430, 768 and
1280px.

Accessibility: semantic landmarks, keyboard-navigable throughout, focus trapped inside the
stall panel and the result popup, Escape closes both, visible focus rings, form errors sit
directly under their field. `prefers-reduced-motion` switches off every animation.

Backend: `assets/js/backend.js` is the only file that knows whether it's talking to a real
database or just `localStorage`. The page calls one function on it — `submitLuckyDraw` —
without caring which mode is active, so once you've set up Supabase, nothing else needs to
change.
