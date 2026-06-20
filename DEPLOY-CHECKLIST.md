# Deploy checklist

**Most checks are auto-run by `deploy.sh`.** This page is only for the things a human still has to do.

If `deploy.sh` succeeded but you skip this — most of the time it's fine. After any change that touches **dates, events, RSVPs, the guest portal, or the couple's data shape**, do the full smoke. Otherwise the 30-sec fast-path is enough.

---

## ⚡ Fast-path (30 seconds, every deploy)

Wait ~60 sec after push for GitHub Pages, then in your normal Chrome tab on the live site:

- [ ] **Hard refresh** (Cmd+Shift+R). Page loads. No console errors.
- [ ] **Your existing planner opens** (`#w=YOUR_TOKEN`) — data is intact, last edits are there.
- [ ] If your change touched UI, you can see it.

If anything's broken: `git revert HEAD && git push` rolls back the frontend in ~60s. (SQL doesn't roll back — see `RUNBOOK.md`.)

---

## 🔬 Full smoke (3 minutes, when the change is risky)

Risky = dates, events, RSVPs, save/load shape, sign-in flow, money, anything in `wp_*` SQL.

Open the live site in an **incognito window** (Cmd+Shift+N) so cached state doesn't lie to you.

- [ ] **Couple signup** — fresh fake email, lands in planner.
- [ ] **Guest sign-up via slug** — open `…/#guestlogin-aanya-vihaan`, sign in as `Priya` + last 4 `3210`. Should auto-approve, land in portal.
- [ ] **Guest sees the right dates and times** — Mehndi shows `Fri, Dec 3 · 4:00 PM` (not Thu or 4 AM). Open it on **your phone** if your change touched date/time at all.
- [ ] **Per-guest invite link** — open Aanya's planner, Guests tab, click 📧 on any guest. Modal opens, URL is non-empty.
- [ ] **Save round-trip** — rename a task, wait 30s, reload, it persists.
- [ ] **Admin still works** — `#admin`, key `weddingadmin`, you see the couple list.

---

## 🪤 The "wedding-day test"

Before pushing anything that affects guests:

> *It's Feb 11, 2027 at 11pm. A non-tech-savvy aunt has 47% battery and is trying to find the venue address on her iPhone 8. Would this change confuse her?*

If yes — don't ship. Or gate it behind a flag.

---

## What `deploy.sh` checks for you (no human needed)

You don't need to verify these — `deploy.sh` blocks the deploy if any fail:

- JS syntax errors in any inline `<script>`
- Hard-coded secrets (`sb_secret_`, `SUPABASE_PAT=`, raw bearer tokens)
- Debug leftovers (`alert("test")`, `console.log("debug")`, `TODO: remove`)
- Destructive SQL in `migrations/pending/` (`drop table`, `delete from X;` without `where`)

To bypass on purpose: `SKIP_CHECKS=1 ./deploy.sh "msg"` (commit message will be tagged `[skipped checks]`).

---

## Things to think about later (not enforced yet)

These were in the original checklist but apply only once we're past Phase 1:

- Service-worker `CACHE_NAME` bump on each deploy (avoids stale PWA cache for returning guests)
- Nightly Supabase backup verified green before deploying anything risky
- Staging environment for risky changes
- User-facing change → draft the announcement message first

Add these when you have real users.

