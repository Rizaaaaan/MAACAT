# MAACAT — L.E.A.D. 2026 site

Single-page campaign site for the MAACAT marketing team. One HTML file, no build step,
no dependencies. Open `index.html` in a browser and it works.

```
index.html                       the whole site
BACKEND.md                       lucky draw API spec + reference code
assets/
  branding/maacat-logo.png       your logo (already in place)
  posters/stall-01.jpg           ← drop the six posters here
  posters/stall-02.jpg
  ...stall-06.jpg
  map/event-map.jpg              ← drop the venue map here
```

---

## Putting it online

Drag the whole folder onto [netlify.com/drop](https://app.netlify.com/drop) or run
`vercel` in it. Either gives you a live URL in about thirty seconds, free. You need a real
URL before you print the posters, because the QR codes have to point somewhere.

---

## The three things you swap in later

**Posters.** Save them as `assets/posters/stall-01.jpg` through `stall-06.jpg`. Nothing
else to change — the page picks them up automatically, and shows the numbered placeholder
if a file isn't there yet. Portrait 3:4 crops look best. Keep each under about 300KB so
phones load them fast.

**Event map.** In `index.html`, find `<!-- Swap in:` inside the `.map` block and
uncomment that line once you have `assets/map/event-map.jpg`.

**Lucky draw backend.** See `BACKEND.md`. Until then the form blocks duplicates only on
the phone it was filled in on, which is fine for testing and not fine on the day.

---

## Editing the stalls

All six stalls live in one array near the top of the `<script>` block, labelled `DATA`.
Change the text there and the cards, the modals and the poster wall all update together.
You never edit the same stall in three places.

Stall 06 and the PR Disaster scenarios are deliberately marked as not finalised. When you
decide them, fill in `lede`, `doList`, `learnList` and delete the `pending` line.

---

## QR codes

Point each poster's QR at:

```
https://yoursite.com/?stall=01&source=poster
https://yoursite.com/?stall=02&source=poster
...
```

Opening that link scrolls to the stalls and pops that stall's panel open straight away.
The `source` parameter is what lets you measure which poster brought people in — pass it
through to the backend once that exists. You can give different poster locations different
values (`source=canteen`, `source=entrance`) if you want to compare spots.

Generate the codes at qr-code-generator.com or similar. Test one with an actual phone
before you send anything to print.

---

## Before the day

- [ ] Real URL live, QR codes generated from it and scan-tested on a phone
- [ ] Six posters dropped into `assets/posters/`
- [ ] Event map added
- [ ] Backend endpoint live, form switched over, prototype note deleted
- [ ] One test entry submitted, then the same number rejected
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
