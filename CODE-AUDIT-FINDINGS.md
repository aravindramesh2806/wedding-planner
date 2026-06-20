# Code Audit — 2026-06-20

Scope: `/Users/aravind/Documents/Claude/Projects/Wedding Planner/index.html` (~2,600 lines, single-file app).
Method: read top-to-bottom, then grepped for `await rpc`, `innerHTML`, date constructors, money/currency, party/heads, ID interpolation in event handlers. Each finding below quotes the line I read; "verified" means I read it, "suspect" means I'm reasoning from context.

---

## 🔴 Critical (will confuse or lose users)

- **[Line 1528] `g.name.split(...)` crashes if a guest has no name.** Verified.
  `const msg = ` + "`" + `Hi ${g.name.split(/\s+/)[0]||""}!...` + "`" + `. `addGuest()` validates name on the planning side, but `S.guests` can be hydrated from cloud (`adoptCouple`) or sample data; if a guest object ever lacks a `name`, opening the invite modal throws and the modal stays in the "Setting up… ⌛" state forever. Why it matters: this is the "Copy WhatsApp link" flow — failure here means a guest never gets the link. Fix: `(g.name||"").split(/\s+/)[0]||"there"`.

- **[Lines 845–846] `toggleEventTask` / `delEventTask` crash when `ev.tasks` is undefined.** Verified.
  `const t=ev.tasks.find(...)` — if a cloud-loaded event predates the `tasks:[]` initializer, `ev.tasks` is `undefined` and `.find` throws. `renderEvents()` defensively does `ev.tasks||[]`, but the click handlers do not. Why it matters: after a cloud sync the user clicks a checkbox and the whole tab silently fails (no re-render, console error). Fix: guard with `ev.tasks=ev.tasks||[]` at top of each handler.

- **[Line 1271] CSV upload silently drops/scrambles rows with commas in names.** Verified.
  `const parts = l.split(",").map(s=>s.trim());` — a guest "Smith, Jr." or a quoted email becomes two columns, shifting every subsequent field. Why it matters: a 200-row bulk import looks like it worked ("Added 200 guests") but their phones/emails are wrong, breaking sign-in. Fix: a tiny CSV parser that respects `"…"`, or warn the user about quoting.

- **[Line 1109] RSVP pill displays raw fallback `r.event_id.slice(0,6)` if the event no longer exists.** Verified.
  `const nm = ev ? ev.name : r.event_id.slice(0,6);` then `esc(nm)`. Why it matters: if the couple deletes an event after a guest RSVP'd, the guest table shows cryptic hex like `a1b2c3` colored red/green, looking broken. Fix: show "(deleted event)" or omit the pill entirely.

- **[Line 1086] Pending-approval inbox shows `new Date(g.created_at).toLocaleString()` with no null guard.** Verified.
  If `created_at` is `null`/missing for any pending row, the date renders as `"Invalid Date"` — visible to the couple in their approval inbox. Same pattern at lines 1118, 1146, 2377, 2469 (alerts). Why it matters: looks broken; could make the couple distrust the data. Fix: `g.created_at ? new Date(g.created_at).toLocaleString() : "—"`.

---

## 🟡 Important (degrades trust but not catastrophic)

- **[Lines 1039–1063, 1786] `ppLoad*` and `startPolling` swallow ALL errors with empty `catch(e){}`.** Verified.
  Five RPCs in a row (`wp_get_couple_slug`, `wp_get_guest_entry_token`, `wp_admin_list_guests`, `wp_admin_list_alerts`, `wp_load`) silently no-op on failure. The poller at line 1786 hides Supabase outages completely — the user sees stale data with no indication. Suggested: at minimum surface "Couldn't sync — last update X min ago" once two polls in a row fail.

- **[Line 597] Countdown "Months" uses `Math.ceil(diff/30.4)` and can be off by one.** Verified.
  e.g. 31 days from today shows "2 Months". For a wedding 30 days away you'd expect "1 month". Why it matters: this is the headline number on every page load. The 4 date/time bugs Aravind just fixed were the same vein. Fix: compute calendar-month diff via `Date` math, not 30.4-day average.

- **[Line 543] `money()` uses `maximumFractionDigits:0`, truncating any actual decimals.** Verified.
  A vendor "Cost" of `$1234.56` displays as `$1,235` (rounded). The CSV/bar chart and dashboard totals all use the same `money()`. Why it matters: numbers won't reconcile with vendor invoices ("you said $1,235, the bill says $1,234.56"). Fix: show 2 decimals, or at least keep them when fractional.

- **[Line 587, 631, 635, 916] `fmtDate(s)` (`{month:"short",day:"numeric"}`) drops the year.** Verified.
  Events listed on Dashboard / Events tab and "Up next" tasks show "Feb 12" with no year. For a 12-month engagement that's fine; for two events 11 months apart it's ambiguous. Suggested: include year when the event is >180 days away.

- **[Line 597] Weeks uses `Math.floor(diff/7)`; on day 6 it shows "0 Weeks".** Verified.
  6 days away → "Days: 6, Weeks: 0, Months: 1" — the zero is jarring. Suggested: hide Weeks when <1, or round.

- **[Line 752, 755] Vendors table renders `money(v.cost)` and `money(v.paid)` even when both are 0** — shows `$0` for every research-stage vendor instead of `—`. Cosmetic but ubiquitous on a fresh vendors page. Same for budget table (line 696-697).

- **[Line 619, 906, 974] `Number(g.party)||1` silently treats blank/0 party as 1.** Verified.
  A user who types `0` (e.g. "the Garcia family — no plus-ones, just the family of 4 = put 0 because the head is counted separately"?) gets quietly bumped to 1, double-counting. Edge but possible. Suggested: only fall back to 1 if NaN; treat 0 as 0.

- **[Lines 1198–1213] `ppApprove()` alert on failure is generic, hides which guest failed.** Verified. Couple sees "Couldn't update guest. Check your connection." with no name — and the optimistic UI state was never updated, so they don't know who the failure was for. Suggested: include the guest's name in the alert.

- **[Lines 1247, 1267] `ppUploadCsv` errors → `alert("Upload failed.")`** with no detail. Same for line 1219 (`alert("Delete failed.")`). When a server returns `{error:"..."}` we don't even check — we wrap in try/catch only. Suggested: also inspect `r.error` after the `await`.

- **[Line 2562] Guest portal poller fires every 15s and re-renders the entire tab.** Verified.
  There's a smart skip ("Don't clobber the tab if the user is actively interacting"), but the check is `isEditable` only — a guest scrolling through Venues mid-poll loses scroll position. Suggested: only re-render if data actually changed.

- **[Line 1486–1496] `syncGuestToPortal` is called from `renderGuests()` for every guest missing a `portal_token`, in serial without rate limit.** Verified at line 856.
  A first sign-in with 200 cloud-loaded guests hits the RPC 200 times sequentially before the UI settles. Why it matters: slow first paint, possible server rate-limit. Suggested: batch or background-throttle.

- **[Line 1567] Sample data carries forward `S.settings.pinA/pinB`** but overwrites `partnerA/B` to "Alex & Sam". Verified. If a user with PINs set loads sample data, the new "Alex/Sam" can't unlock since the old hash was tied to the old names' UX context — actually it still works because `hashPin` doesn't include names. Suspect ok, but the names mismatch is jarring.

- **[Line 595] `S.settings.date+"T00:00:00"`** assumes a clean `YYYY-MM-DD`. If the cloud ever returns an ISO timestamp (`2027-02-12T00:00:00Z`), the concatenation produces an invalid `…T00:00:00Z…T00:00:00` string and `new Date` becomes Invalid Date → countdown shows `NaN Days`. Suspect — only triggered if backend changes shape. Suggested: defensive `if(/^\d{4}-\d{2}-\d{2}$/.test(date))`.

---

## 🔵 Nice to have (polish)

- **[Line 800–836] Events on the couple Events tab render in insertion order**, not date order. Easy to fix — guest-side schedule already sorts (line 2347). Couple should see the same chronological view.

- **[Line 1534] `onclick="navigator.clipboard?.writeText('${esc(url)}')"`** — `esc()` HTML-escapes `&` to `&amp;`. URL doesn't currently contain `&`, but if it ever did (e.g. query-string fallback), the clipboard would get `&amp;`. Use `encodeURIComponent` of the JS literal context instead.

- **[Line 1469] `value="${esc(g?.party||1)}"`** in the Add-guest modal — for an existing guest with `party===0` this shows `1`. Likely fine but worth knowing.

- **[Line 1593] Sample guests miss the `events` property**, so they show as invited to all events. Fine for a sample but worth a note.

- **Mobile**: the nav.tabs row at top is `position:sticky` and contains 7 tabs (`Dashboard, Checklist, Budget, Events, Guests, Vendors, Guest portal`). On a 360px iPhone they wrap to two rows, eating ~80px of viewport. Consider collapsing into a `<select>` on narrow viewports.

- **Mobile**: tap targets — `.icon-btn` is `padding:4px 7px` (line 80 area) → roughly 28×28px. Apple's HIG asks for 44×44. Touch the delete-guest "X" on iPhone and you often miss.

- **Modal**: `.modal{max-width:440px;max-height:90vh;overflow:auto}` (line 122). On iOS Safari with the URL bar shown, `90vh` overflows the visible area; the bottom action buttons get hidden under the URL bar. Consider `max-height:85svh` (small-viewport height).

- **Accessibility**: form `<input>` elements use `<label class="fl">` floats (visible labels) but not `<label for="…">` — screen readers don't associate them. Easy fix: add `for` matching the input `id`.

- **Accessibility**: RSVP buttons use color only (`background:#10b981` green vs `#94a3b8` gray) to show selected state. Add a `✓` glyph or `aria-pressed`.

- **[Line 1322, 1419, 1660] `value="${esc(s.venue)}"`** — esc replaces `"` with `&quot;` correctly, so this is safe. But an HTML escape inside a JS template literal that becomes an attribute value is one rename away from a bug. Verified safe today.

- **[Line 1693] `esc(...partnerA+...+partnerB)`** in lock screen kicker is fine but the concatenation `s.partnerA && s.partnerB ? " 💕 " : ""` is awkward; if only one is set you get just one name. Cosmetic.

- **Race**: `scheduleCloudSave` debounces to 700ms (line 1779) and `startPolling` polls every 7s (line 1786). If a save lands at the same time as a poll, `adoptCouple` overwrites the in-flight local state with whatever the server returned — silently reverting the user's last keystroke. Suspect — protected partially by `applyingRemote` flag but not by request ordering. Worth a stress test (two browser tabs, rapid edits).

- **[Line 994] `tbl.closest(".card").scrollIntoView`** — if `tbl` is null (renders before DOM mount) the chain throws. Defensive `?.` would help.

- **[Line 2589] `gpSignOut` doesn't clear `G.entry`**, just nulls the token. Next sign-in might use a stale entry. Cosmetic.

- **Print stylesheet** (line 183–201) only handles the Guests tab. Other tabs (budget, vendors) print as the screen UI — fine but worth knowing if users try.

- **[Line 1786] `startPolling` doesn't pause when the tab is hidden** — burns network/quota on a backgrounded tab. Add `document.visibilityState` check.

---

## ✅ Things that look solid (positive findings)

- **HTML escaping is disciplined.** `esc()` is used on every user-controlled string interpolated into innerHTML — names, vendor names, venue, alert title/body, meal preferences, dress codes. I looked specifically for XSS vectors and didn't find one that survives.

- **Money/heads always reduce with `Number(x)||0` fallbacks** — no `NaN` propagation in totals.

- **Date parsing uses `+"T00:00:00"` everywhere** (correct local-time pattern) for bare YYYY-MM-DD inputs. The fix Aravind already shipped is consistently applied (lines 583, 594, 635, 681, 1922, 2310, 2341).

- **`gpFmtTime` (line 2313)** correctly normalizes both "16:00" and "4:00 PM" by detecting `\b(am|pm)\b` and recomputing AM/PM after promoting to 24h.

- **`isVenueHiddenForGuests` (line 2338)** logic is correct: hidden=true with no reveal_at = always hidden; hidden=true with reveal_at in past = reveal.

- **Polling skip on focused inputs (line 2581)** prevents the obvious "re-render wiped my keystroke" pattern in the guest RSVP page.

- **Confirmation prompts** before destructive actions (delete vendor, delete event, reject guest, replace with sample) are consistently present.

- **Currency rendering** uses the locale-correct number formatter (`toLocaleString(c.locale, ...)`) — Indian rupees correctly group as 1,00,000 not 100,000.

- **Service worker registration** (last line) is wrapped in `if('serviceWorker' in navigator)` and the failure is swallowed silently — safe for incognito/older browsers.

- **`encodeURIComponent` is used** on user content fed into WhatsApp/SMS/mailto URLs (line 1535–1537).

---

**Confidence note:** I read the file end-to-end and grep-verified every finding marked "Verified". The "Suspect" findings I labeled explicitly. I did not run the code in a browser or against the live Supabase backend.
