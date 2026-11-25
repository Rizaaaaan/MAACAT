# MAACAT — VARA Expo 2026 site

`index.html` is the whole site: styles and lucky-draw code are inside it.
The only other files it uses are the logos in `assets/branding/` (already on the site).

## To update the live site
GitHub repo → Add file → Upload files → drag in `index.html` → Commit.
Wait ~2 minutes, then reload maacat.com (if it still looks old, open it in an incognito tab).

## Lucky draw
1. supabase.com → your project → Resume project (free projects pause after a week idle).
2. SQL Editor → paste `supabase-vara-update.sql` → Run (once).

Pick a winner (SQL Editor):
  select phone, age_group, favourite_stall from lucky_draw_entries
  where event = 'VARA EXPO 2026' order by random() limit 1;

## Quick edits (top of the last <script> in index.html)
EXPO_OPENS (countdown, set to 4 PM) · LUCKY_DRAW_COPY (popup text) · ACTIVITIES · MASCOT_LINES
