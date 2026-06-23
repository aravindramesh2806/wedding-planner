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

### Shipped 2026-06-22 — Guest portal v1 (LIVE)
- Guest portal deployed and smoke-tested live. Sign-in screen resolves couple name via
  `wp_guest_couple_brief`; SQL migration (`supabase-guest-portal.sql`, incl. 6 added RPCs) run in Supabase.
- Routes working: `#guestlogin-<slug>` (per-couple), `#g=<token>`, `#i=<invite>`, `#preview=`.
- Fixed: removed hardcoded `VANITY_GUEST_ENTRY` (was pinning bare `#guestlogin` to one test couple).
  Bare `#guestlogin` now shows the "valid invite link needed" screen. Multi-tenant correct.
- Returning guests auto-resume via per-couple token in localStorage (note: incognito keeps this
  across navigations until ALL incognito windows close — looks like "logged in without signing in").
- SECURITY FIX (2026-06-22): `wp_guest_load` previously returned the couple's FULL `data` blob
  (budget, vendors, tasks, full guest list, settings) to ANY token holder regardless of status.
  Rewrote it to (a) gate plan/rsvps/alerts behind status='approved', and (b) return only the
  guest-facing slices: `events` + `know_before_general`. Re-run `supabase-guest-portal.sql` in
  Supabase to apply (safe to re-run; uses create-or-replace). No index.html change needed.
- STILL TO VERIFY: alerts round-trip; the 6 guest pages on mobile.
- SMALLER FOLLOW-UP: `hide_venue` is enforced only client-side — the venue string is still sent
  for hidden events. Consider blanking hidden-venue fields server-side in wp_guest_load too.

### Shipped 2026-06-22 — Guest portal redesign + customization (NOT yet deployed)
Big visual + feature upgrade to the guest portal. All in index.html + 1 SQL change.
- **Premium redesign**: serif display fonts (Google Fonts), cinematic hero, LIVE ticking countdown,
  elegant event timeline with per-event emoji icons, dress-code pills, refined cards/alerts/RSVP.
  Mobile-first. New CSS is driven by --gp-* vars so it is theme-independent of the planner's 8 themes.
- **6 couple-selectable portal designs** (GP_DESIGNS): Blush & Gold, Sage & Linen, Midnight & Champagne,
  Terracotta & Sand, Maroon & Marigold, Classic Noir. Each = palette + font pairing.
- **Full customization** (couple, in Guest portal tab): pick design, optional custom accent color,
  heading font override, cover photo URL, welcome message.
- **Section show/hide toggles**: couple controls which tabs guests see — Schedule, Venues, Travel,
  FAQ, Our Story, Photos. Guest tabs render only enabled sections that also have content.
- **New guest sections + couple editors**: Travel & Stay (airport/shuttle/contact + hotels list),
  FAQ (Q/A pairs), Our Story (text + photo). Photos tab is a "coming soon" teaser.
- **Data**: new S.portal object; wired into blank, cloudPayload(), adoptCouple(), ensurePortal()/blankPortal().
- **SQL**: wp_guest_load now also returns `portal` (gated behind status=approved, like events). Re-run
  supabase-guest-portal.sql. wp_admin_preview_portal already returns full blob, so couple Preview works.

DEPLOY STEPS (not done yet):
  1. cp index.html into repo, commit, push (GitHub Pages).
  2. Re-run supabase-guest-portal.sql in Supabase (safe; create-or-replace).
  3. Couple side: open planner -> Guest portal tab -> pick design, toggle sections, fill Travel/FAQ/Story.
  4. Verify live via guest portal + couple "Preview portal" button.
Backup of pre-redesign index.html saved in outputs as index.backup-*.html.

### Shipped 2026-06-23 — Guest portal redesign LIVE + hide_venue server-side fix
- Deployed the guest portal redesign (premium fonts, live countdown, 6 GP_DESIGNS, Travel/FAQ/Our Story,
  section show/hide). index.html pushed; supabase-guest-portal.sql re-run in Supabase.
- SECURITY FIX: wp_guest_load now strips `venue` + `map_link` server-side for events whose venue is
  hidden (mirrors client isVenueHiddenForGuests: hidden if hide_venue and reveal_at absent or future).
  Hidden-event venue strings no longer leave the server. Verified valid Postgres + node --check on JS.
- STILL TO VERIFY post-deploy: hidden-venue shows "To be revealed" for an approved test guest;
  alerts round-trip; the 6 guest pages on mobile.
- KNOWN MINOR: wp_admin_preview_portal still returns full blob, so couple Preview shows hidden venues
  (not a leak; Preview just won't show the guest "To be revealed" state). Polish item.

### Shipped 2026-06-23 (b) — Invite link moved to guest portal
- Removed the "Guest invite link" card from the couple DASHBOARD; added an "Invite others" share card
  to the GUEST PORTAL home (gpRenderHome) so approved guests can forward the couple-wide invite link.
  New helpers gpInviteUrl()/gpCopyInvite(); G.slug now stored in guestBootBySlug. Couple-wide link
  built from G.slug (#guestlogin-<slug>) or fallback G.entry (#g=<token>). Couple still approves signups.
- Couple can still copy their invite link from the couple-side "Guest portal" admin tab (ppCopyLink).
- Dead-but-harmless: dRenderGuestLink/dCopyGuestLink/dOpenGuestLink remain and no-op (elements removed).
- index.html only (no SQL change). node --check passed.

### Shipped 2026-06-23 (c) — Auto-updating PWA (no more stale cache)
- Root cause of stale guest portals after deploy: sw.js was network-first but used the browser HTTP
  cache, so deploys lagged until the tab/app fully closed.
- New sw.js: HTML/JS navigations fetch with cache:'no-store' (always fresh); other assets stay
  cache-first for offline; activate now deletes old-version caches.
- index.html SW registration now uses {updateViaCache:'none'} and auto-reloads the page once on
  'controllerchange' (when a new SW takes control) — clients self-update.
- deploy.sh now copies sw.js AND auto-bumps `const CACHE='wp-<timestamp>'` on every deploy, so each
  push forces the new SW to install/activate and clients refresh automatically. No manual version bump.
- NOTE: sw.js now lives in the backup folder too (source of truth) and is in deploy.sh's copy list.

## PENDING FEATURES TO BUILD

### Priority order
1. **Finish guest portal functionality** (current focus) — flows below until rock solid
2. **Guest portal UI polish (v2)** — *do this after functionality is settled.* Areas to revisit:
   - Stronger hero / cover treatment on the Home tab (couple photo or banner image)
   - Polished event cards with per-event icons (💍 ceremony, 🍸 cocktail, 💃 sangeet, etc.)
   - Smoother transitions between tabs (fade-in)
   - Better empty states
   - Tighter mobile spacing — most guests will be on phones
   - Optional dark mode
3. **Customizable guest portal** (see below — bigger feature, can absorb the polish work)

### Suggestions to consider:
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
- **Shared photo album** *(Phase 2/3)*: guests upload photos from the guest portal into
  a couple-specific shared album; couple can also post wedding pics to the same album. All
  approved guests can browse. Couple moderates (approve/delete). Storage: Supabase Storage
  buckets (no new dependency). Open questions: free-tier storage cap, moderation flow
  (auto-publish vs couple-approve), public shareable link vs approved-guests-only.
  Strategic value: strong referral mechanic — guests who see it want it for their own wedding.


## Housekeeping
- Rotate the Supabase `sb_secret_…` key (it was pasted in an earlier chat). Supabase → Settings →
  API Keys → Secret keys → Roll. The app doesn't use it, so rotating won't break anything.

## Tips to save tokens in the new chat
- Start fresh (this file + repo carry the context).
- Prefer `node --check` syntax checks over browser screenshots for verification.
- Batch features into fewer pushes — last batch shipped guest tools + budget + vendors in one push.
