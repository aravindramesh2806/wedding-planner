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
- Couple data is one JSON blob `{tasks,budget,events,guests,vendors,settings}` stored per couple in Supabase.
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
- GOTCHA 2: It's now a PWA with a service worker — after a deploy, refresh once (Cmd+Shift+R) to clear the cached old version.
- GOTCHA 3: `wp_save` overwrites the whole data blob. To edit a live couple's data, always
  load → merge → save (never blind-save).
- GOTCHA 4: The assistant's host file tools (Read/Edit/Write) get EPERM on the repo folder;
  edit via shell (python/sed) instead, or edit the backup folder `~/Documents/Claude/Projects/Wedding Planner`
  and then `cp` it into the repo folder before pushing.
- GOTCHA 5: After running `node --check` on inline JS, always verify by viewing the actual file — sed/python
  anchor matches can drift if earlier edits already moved things around.

## Already done
Couple signup + private links, cross-device sync, admin console (list, signup link, planner links,
delete-with-warning, key sign-in), guest list (inline side dropdown, party, meal, invite toggle,
accommodation/Stay toggle, RSVP dropdown), per-event guest tracking (expand arrow → event checkboxes +
headcount per event), per-event checklists with notes dropdown, public guest RSVP, currency (USD/INR),
8 themes, PWA (installable, heart icon), Lucidchart-style flow diagrams (flows.html).

### Shipped 2026-06-15
- **Guest list tools**: live name search, sort (Name / Side / RSVP), meal-summary pills (counts
  weighted by party size), Download CSV (Name, Side, Party, Meal, Invited, Accommodation, RSVP),
  and Print button (CSS isolates the guests panel for print).
- **Clickable event-headcount pills**: click any pill in "Headcount per event" to filter the guest
  list to only that event's invitees. Active pill goes solid + ✕; "Show all events" button clears
  the filter. Works alongside search + sort.
- **Budget upgrades**: each item now has `dueDate`, `paidBy`, `paid` fields. Table shows overdue
  (red) / upcoming (accent within 14 days) / paid (muted ✓) styling on the Due column. Inline
  paid checkbox per row. Add-budget modal updated. New **Spend by category** card with an
  inline SVG bar chart (hides itself when nothing has actual spend).
- **Vendors tab**: new top-level tab with name / category / contact / status (researching / booked /
  paid) / cost / paid columns; expandable notes per row; summary cards (count, committed total,
  paid total). `S.vendors` is wired into `cloudPayload()` and `adoptCouple()`, with a safety
  `if(!S.vendors) S.vendors=[]` on load for existing couples whose blob predates the field.

## PENDING FEATURES TO BUILD
*(none from the original handoff — pick the next one)*

Suggestions to consider:
- **Customizable guest portal**: let the couple style their guest-facing portal —
  upload a cover photo / hero banner, set a custom welcome message, write a
  "Our story" section (how we met, our journey), add a photo gallery, pick
  fonts and a color palette beyond the 8 built-in themes. Also: optional
  custom domain alias (so the URL feels personal), and per-event hero images.
  This is a high-value differentiator vs Joy/Zola — your portal should feel
  like *your* wedding, not a template.
- **Seating chart**: assign guests to tables; counts per table; print-friendly layout.
- **Day-of timeline**: minute-by-minute schedule with location + point person per item.
- **Save-the-date / RSVP email templates**: copy-to-clipboard blocks pre-filled with the couple's
  link.
- **Thank-you note tracker**: per-guest sent/not-sent toggle, like the existing Invite checkbox.
- **Plus-one tracking**: explicit plus-one flag per guest, with name slot.
- **Notifications**: simple "what's due in the next N days" digest on the dashboard, pulling
  from budget dueDates + event dates.

## Housekeeping
- Rotate the Supabase `sb_secret_…` key (it was pasted in an earlier chat). Supabase → Settings →
  API Keys → Secret keys → Roll. The app doesn't use it, so rotating won't break anything.

## Tips to save tokens in the new chat
- Start fresh (this file + repo carry the context).
- Prefer `node --check` syntax checks over browser screenshots for verification.
- Batch features into fewer pushes — last batch shipped guest tools + budget + vendors in one push.
