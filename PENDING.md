# Wedding Planner — handoff & pending features

Paste this whole file into a new chat to continue the project.

## What this is
A free, multi-tenant wedding-planning web app. Single-file front end (`index.html`, no build step)
+ Supabase (Postgres) backend + GitHub Pages hosting.
- Live signup: https://aravindramesh2806.github.io/wedding-planner/
- Admin console: add `#admin` to the URL, sign in with the admin key `weddingadmin`
- Repo (source of truth): the connected folder `~/Documents/Claude/Projects/wedding-planner-repo`
- GitHub: github.com/aravindramesh2806/wedding-planner (branch `main`)
- Supabase project ref `vjncnjalnxdkyzbdrxck`; publishable key is hardcoded in index.html (safe, browser key).
  Admin key lives in SQL function `wp_admin_key()`.

## How it works (architecture)
- Routing by URL hash: `#admin` (admin), `#rsvp=TOKEN` (public guest RSVP), `#w=TOKEN` (couple planner), none = signup.
- Couple data is one JSON blob `{tasks,budget,events,guests,settings}` stored per couple in Supabase.
- Secure RPCs (RLS on, SECURITY DEFINER): `wp_signup`, `wp_load`, `wp_save`, `wp_rsvp_info`,
  `wp_rsvp_submit`, `wp_admin_list`, `wp_admin_delete`. Tables locked down; only these functions are exposed.
- Front end edits the in-memory `S` object, calls `save()` (writes localStorage + debounced `wp_save` to cloud),
  and polls `wp_load` every ~7s to sync across devices.

## How to make changes (IMPORTANT)
- Edit `index.html` in the repo folder. It's one file: `<style>`, HTML panels, then a big `<script>`.
- Deploy = user runs in Terminal:
  `cd ~/Documents/Claude/Projects/wedding-planner-repo && git add -A && git commit -m "msg" && git push`
  Then GitHub Pages rebuilds in ~1 min.
- GOTCHA 1: Do NOT run git from the assistant's sandbox — it leaves `.git/*.lock` files that block the user.
  If a lock error appears, user runs: `find .git -name '*.lock' -delete` then commits again.
- GOTCHA 2: It's now a PWA with a service worker — after a deploy, refresh once to clear the cached old version.
- GOTCHA 3: `wp_save` overwrites the whole data blob. To edit a live couple's data, always
  load → merge → save (never blind-save).
- GOTCHA 4: The assistant's host file tools (Read/Edit/Write) get EPERM on the repo folder;
  edit via shell (python/sed) instead, or edit the backup folder `~/Documents/Claude/Projects/Wedding Planner`.

## Already done
Couple signup + private links, cross-device sync, admin console (list, signup link, planner links,
delete-with-warning, key sign-in), guest list (inline side dropdown, party, meal, invite toggle,
accommodation/Stay toggle, RSVP dropdown), per-event guest tracking (expand arrow → event checkboxes +
headcount per event), per-event checklists with notes dropdown, public guest RSVP, currency (USD/INR),
8 themes, PWA (installable, heart icon), Lucidchart-style flow diagrams (flows.html).

## UNPUSHED local changes (push first)
The "accommodation (Stay)" column and "per-event guest tracking" are built locally but may not be pushed yet.
Run the deploy command above first.

## PENDING FEATURES TO BUILD

### 1. Guest list tools
- Search box above the guest table that filters rows by name (live).
- Sort control: by name, by side, by RSVP.
- Meal/dietary summary: a small line or pills showing counts per meal value (e.g., Veg: 12, Chicken: 4).
- Export: a "Download CSV" button (name, side, party, meal, invited, accommodation, rsvp) and a "Print" button.
- All client-side in renderGuests / the Guests panel.

### 2. Budget upgrades
- Add fields to each budget item: due date, paid-by (free text or Bride/Groom/Both), paid status.
- Show overdue/upcoming due dates.
- A spend-by-category chart (can use a simple inline SVG bar chart or Chart.js from CDN — note the
  PWA service worker is network-first so CDN is fine online).
- Budget data is `S.budget` array of {id,item,category,est,actual,...}. Update add-budget modal + table + dashboard.

### 3. Vendor tracker (new tab)
- New "Vendors" tab + panel (add a tab in the nav and a panel section).
- Each vendor: name, type/category (photographer, caterer, venue, decor, etc.), contact (phone/email),
  cost, amount paid, status (researching / booked / paid), notes.
- Add `S.vendors` array to the data model (default []), include it in `cloudPayload()` and `adoptCouple()`
  so it syncs. Table + add-vendor modal + maybe a total committed/paid summary.

### Housekeeping
- Rotate the Supabase `sb_secret_…` key (it was pasted in an earlier chat). Supabase → Settings →
  API Keys → Secret keys → Roll. The app doesn't use it, so rotating won't break anything.

## Tips to save tokens in the new chat
- Start fresh (this file + repo carry the context).
- Prefer code/syntax checks over browser screenshots for verification.
- Batch features into fewer pushes.
