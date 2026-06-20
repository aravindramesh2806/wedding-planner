# Wedding Planner — Operations Runbook

When something is broken, find the symptom below and follow the steps. Goal: every scenario resolvable in <15 min by one tired person on a phone.

Keep this file short. If a section gets long, link out.

---

## How you'll find out something is broken

In priority order:
1. **UptimeRobot email/SMS** — site is down or returns 5xx.
2. **Sentry email** — JS error spike or new error class on production.
3. **GitHub Actions email** — nightly backup failed, or CI failed on a push.
4. **A guest texts you** — the most common one for now. Take the screenshot, then check the dashboards before assuming it's user error.

If you get an alert at 2am and the issue is not "data lost" or "site totally down," go back to sleep. Triage in the morning.

---

## Scenario 1 — Site is down (UptimeRobot says 4xx/5xx, or "can't connect")

**Is it GitHub Pages or Supabase?**

```
curl -I https://<your-domain>/                              # GitHub Pages
curl -I https://vjncnjalnxdkyzbdrxck.supabase.co/rest/v1/   # Supabase
```

- **Pages 404** → repo was renamed, branch was renamed, or `CNAME` file got deleted. Check https://github.com/aravindramesh2806/wedding-planner/settings/pages — re-select `main` branch, root.
- **Pages 5xx** → very rare, GitHub-side. Check https://www.githubstatus.com. Wait it out; nothing you can do.
- **Supabase 503 / "project paused"** → see Scenario 2.
- **Both green but UptimeRobot still red** → your monitor URL is wrong, or DNS broke. `dig <your-domain>` should resolve to the GitHub Pages IPs (185.199.108.153 etc).

---

## Scenario 2 — Supabase project paused (free tier auto-pauses after 7 days idle)

Symptom: all RPCs return `503` or a "project paused" page. Frontend shows "save failed" everywhere.

1. Go to https://supabase.com/dashboard/project/vjncnjalnxdkyzbdrxck.
2. Click **Restore project**. Takes 1–3 min.
3. Verify with `curl https://vjncnjalnxdkyzbdrxck.supabase.co/rest/v1/ -H "apikey: <publishable_key>"` returns `{}` or similar (not HTML).
4. Reload the live site. Make sure save/load works.
5. **Prevent recurrence** — Healthchecks.io cron pings `wp_load` every 6h to keep the project active. Verify https://healthchecks.io shows green. If it's not set up yet, that's a 10-min task (see DEVOPS-PLAN section 3).

---

## Scenario 3 — Supabase free-tier quota hit (DB size, bandwidth, or row count)

Symptom: writes fail with `permission denied` or `quota exceeded`; reads still work.

1. Dashboard → **Project Settings → Usage**. Find which limit you hit:
   - **DB size > 500MB** → see Scenario 6 (pruning).
   - **Egress > 5GB/mo** → likely the JSON blob is getting big and being re-fetched every 7s by every open tab. Short-term: in `index.html`, bump the poll interval from 7s to 30s. Long-term: switch to Realtime subscriptions or move to a paid tier.
   - **Auth MAU > 50k** → not applicable (we don't use Supabase Auth for couples), ignore.
2. If you can't fix in 10 min and paying customers are affected, upgrade to Supabase Pro ($25/mo). Plan a refund/credit for anyone who lost time.

---

## Scenario 4 — Buggy deploy went live (regression, broken page, JS error spike)

1. **Roll back the frontend immediately:**
   ```
   cd ~/Documents/Claude/Projects/wedding-planner-repo
   git revert HEAD --no-edit
   git push
   ```
   Live in ~60s. Tell users to hard-refresh (Cmd+Shift+R / pull-to-refresh on iOS) to clear the service-worker cache.

2. **If the bug was a SQL migration**, the revert above doesn't undo it. Open Supabase SQL editor and write an inverse migration manually. Test on staging first. SQL changes are not auto-rollbackable — this is why the checklist requires idempotent migrations.

3. **Post-mortem (5 min, in the commit message of the fix):** what shipped, what broke, what would have caught it. Add a checklist item if relevant.

---

## Scenario 5 — Couple's data disappeared / corrupted

**This is the scariest scenario. Stay calm. Don't write.**

1. **Do NOT let the affected couple use the app.** Email them: "We see the issue, we're restoring your data, please don't make any edits or it'll overwrite the restore. ETA 30 min."
2. Identify the couple's wedding row:
   ```sql
   select id, token, data->'settings'->>'coupleName' as name, updated_at
     from weddings where token = '<their-token>';
   ```
3. Pull the latest backup from the `wedding-planner-backups` repo (private GH repo, see DEVOPS plan). Find the most recent dump that contains good data for that wedding_id.
4. Restore just that row's `data` JSON:
   ```sql
   begin;
   update weddings set data = '<json-from-backup>'::jsonb where id = '<wedding_id>';
   -- verify in a select before commit
   select data->'settings' from weddings where id = '<wedding_id>';
   commit;
   ```
5. Tell the couple it's done. Apologize. Ask them what they were doing when it broke (helps prevent recurrence).
6. **Root-cause it.** The most likely cause is `wp_save` blind-overwriting because the in-memory `S` was stale or empty. Check the index.html save path. Add a server-side guard (e.g. refuse to save if the new blob is >50% smaller than the existing one).

---

## Scenario 6 — DB is filling up

1. Check what's big:
   ```sql
   select pg_size_pretty(pg_total_relation_size('weddings'));
   select pg_size_pretty(pg_total_relation_size('guest_alerts'));
   select pg_size_pretty(pg_total_relation_size('alert_reads'));
   ```
2. Most likely culprit: `alert_reads` for old weddings, or `weddings.data` JSON for couples who uploaded huge photo data URLs into settings.
3. Prune:
   ```sql
   -- delete alerts and reads from weddings whose wedding date is >90 days past
   delete from guest_alerts
    where wedding_id in (
      select id from weddings
       where (data->'settings'->>'weddingDate')::date < now() - interval '90 days'
    );
   ```
4. `vacuum full` is a no-go on Supabase (locks the table). Just let autovacuum reclaim.

---

## Scenario 7 — GitHub Pages serves stale content / PWA shows old version

This is a **service-worker cache** problem, not a Pages problem.

1. Verify the build is actually live: `curl -s https://<your-domain>/index.html | grep -c <something-from-the-new-version>` — if 0, Pages hasn't rebuilt yet, wait.
2. If the new build IS live but users see the old: their service worker cached it. You forgot to bump `CACHE_NAME` in `sw.js`.
3. **Right now:** bump `CACHE_NAME = 'wp-v<N+1>'` in `sw.js`, push. The new SW will fetch a new shell on next load and call `caches.delete('wp-v<N>')`.
4. **Tell users:** "Close the tab completely, reopen. Or on iOS: long-press the PWA icon → Delete → reinstall."

To prevent: the deploy checklist (item 6) reminds you to bump the cache name. Better: derive `CACHE_NAME` from the commit SHA via a CI step.

---

## Scenario 8 — Backup job failed (GitHub Actions red email)

1. Open the failed Actions run. Read the log.
2. Most likely:
   - **Supabase PAT expired / rotated.** Generate a new PAT in Supabase dashboard → Settings → Access Tokens. Add to repo secrets as `SUPABASE_PAT`.
   - **pg_dump version mismatch.** Pin to `postgresql-15-client` in the workflow's apt-install step.
   - **Backup repo out of space.** Repos cap at 5GB. Prune backups older than 90 days from `wedding-planner-backups`.
3. Re-run the job manually. If it goes green, you're done. If not, escalate to "manual dump tonight via `supabase db dump`" until fixed.

---

## Scenario 9 — Domain / HTTPS issue

1. **Site loads but "Not Secure" banner** → cert is missing. GitHub Pages → repo settings → Pages → tick "Enforce HTTPS". If unchecked or greyed out, the cert isn't issued yet — wait up to 24h after first DNS pointing.
2. **DNS broken** → `dig <domain>` returns nothing. Check your registrar. `A` records should be the four GitHub IPs:
   ```
   185.199.108.153
   185.199.109.153
   185.199.110.153
   185.199.111.153
   ```
   For apex, set all four A records. For `www`, set a CNAME to `aravindramesh2806.github.io`.
3. **Cert expired** → GH auto-renews via Let's Encrypt; this should never happen. If it does, untick + re-tick "Enforce HTTPS" to re-trigger.

---

## Scenario 10 — Spam signups / abuse

If someone is scripting `wp_signup` to create hundreds of fake weddings:

1. **Immediate:** revoke the publishable key in Supabase dashboard, generate a new one, paste into `index.html`, deploy. (This is disruptive — every open tab will get auth errors for ~1min. Do it anyway if the abuse is bad.)
2. Delete the spam rows: `delete from weddings where created_at > now() - interval '1 hour' and (data->'settings'->>'coupleName') is null or length(data->'settings'->>'coupleName') < 3;`
3. **Longer-term:** add a rate limit to `wp_signup` (e.g. ≤5/hour per IP — possible via a `signup_attempts` table keyed on `inet_client_addr()`). Add a hCaptcha to signup.

---

## Phone numbers / accounts you'll need at 2am

Put these in a password manager. Don't write them here.

- Supabase dashboard login
- GitHub login + 2FA recovery codes
- Domain registrar login
- UptimeRobot login (alert email config)
- Sentry login
- Healthchecks.io login

If you lose access to email on the laptop, you should still be able to log in from a phone. **Test that once before the wedding.**
