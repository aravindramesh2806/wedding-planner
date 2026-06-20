# DevOps Plan

**Status:** audit at 2026-06-20 by SRE review. Owner: Aravind (solo). Deadline: Jan 2027 (one month before wedding Feb 12, 2027).

This is sized for **one technical-but-not-ops-focused person** running a paid product on free-tier infra. Every recommendation is justified against: (a) does it prevent a real failure that would hit a paying couple? (b) how much ongoing toil does it add? Anything that doesn't pass both is in the "don't do this yet" bucket at the end.

---

## TL;DR — top 3 things to do this week

1. **Stand up a nightly Supabase backup to a private GitHub repo (GitHub Action + `pg_dump`).** 90 minutes one-time, zero ongoing toil. This is non-negotiable before a single dollar changes hands. See section 2.
2. **Wire UptimeRobot + Sentry, both free tiers.** 30 minutes total. Without these you have no way to know if the site is down or if guests are hitting JS errors — and right now, guests text you, which doesn't scale and won't catch silent breakage. See sections 3 + 6.
3. **Add a 20-line GitHub Action that does `node --check` on the inline JS on every push.** 15 minutes. Would have caught at least 2 of the 4 date/time bugs from last week before they hit production. See section 4.

If you do nothing else this week, do those three.

---

## Risks I'd address before any paying customer

Severity = (likelihood × blast radius), gut-calibrated for solo-builder context.

### 🚨 P0 — fix before charging anyone

| # | Risk | What happens | How to fix | Cost | Time |
|---|------|--------------|------------|------|------|
| R1 | **No backups.** A buggy `wp_save`, a stray `delete from weddings`, or a corrupt JSON write wipes a couple's data permanently. Couples spend weeks building guest lists. | Couple loses everything. Refund + reputational damage + possibly legal. **You are not in business after this happens once.** | Nightly `pg_dump` → private GH repo via GitHub Action. See §2. | $0 | 90 min |
| R2 | **No staging.** Every push is to production. The 4 date/time bugs that shipped last week were live for hours before you noticed. | Bad UX, lost trust. Eventually a deploy will corrupt data live. | Branch-based preview deploys (§5). Bare-minimum: a second Supabase project for staging. | $0 | 2 hr |
| R3 | **No rollback procedure.** Frontend `git revert` is easy but you've never tested it. SQL migrations are *not* reversible at all. | A bad deploy stays bad while you scramble. | Document rollback in runbook (done). Practice it once on staging. Enforce idempotent SQL via checklist. | $0 | 30 min |
| R4 | **PWA service worker can pin guests to an old, broken build for days.** You only bump `CACHE_NAME` by hand. Last week's date bug fix wouldn't have reached guests who'd already installed the PWA. | Guests see "fixed" bugs persist. They blame you, not their cache. | Auto-bump `CACHE_NAME` from commit SHA in CI. Add cache-busting `?v=<sha>` to script tag. | $0 | 30 min |

### ⚠ P1 — fix before commercial launch (Phase 2)

| # | Risk | What happens | How to fix | Cost | Time |
|---|------|--------------|------------|------|------|
| R5 | **Supabase free tier auto-pauses after 7 days idle.** If no one hits the DB for a week, your site goes 503 with no warning. | New visitor lands on broken site. Lost signup. | Healthchecks.io 6-hourly ping to `wp_load`. See §3. | $0 | 15 min |
| R6 | **No error tracking.** JS errors on a guest's iPhone 8 die in the void. You learn about them from a text message, if at all. | Silent breakage at scale. | Sentry free tier (5k events/mo is plenty). See §6. | $0 | 30 min |
| R7 | **No uptime monitoring.** First time prod is down for 4 hours, you'll find out from a customer. | Lost trust. | UptimeRobot free, 5-min interval, email + SMS. See §3. | $0 | 15 min |
| R8 | **No CI gate.** You hand-run `node --check` *if you remember*. The Pending doc says "do this!" which means it doesn't always happen. | Syntax errors ship to prod. Already happened. | GitHub Action: `node --check` + a Playwright smoke test that loads the live site post-deploy. See §4. | $0 | 1 hr |
| R9 | **Unsellable URL.** No one is paying $99 to host their wedding on `aravindramesh2806.github.io/wedding-planner/#w=abc123`. | Pricing power is zero. | Buy a domain (~$12/yr), point at Pages. See §8. | $12/yr | 30 min |
| R10 | **No analytics.** You have no idea what the conversion funnel looks like. You're optimizing in the dark. | Wrong features get built. | Plausible (cheap) or Umami (free, self-host) or PostHog (free tier). See §7. | $0–$9/mo | 1 hr |

### 🟨 P2 — nice to have but not blocking

| # | Risk | What happens | How to fix | Cost | Time |
|---|------|--------------|------------|------|------|
| R11 | **Supabase publishable key + admin key both visible in `index.html`.** The admin key gates `wp_admin_list`/`wp_admin_delete`. | If someone scrapes the page, they can delete every couple. | Move admin functions behind a separate auth (Supabase Auth + role check) or behind a Cloudflare Workers proxy with IP allowlist. | $0 | 4 hr |
| R12 | **`wp_save` is "last write wins" with a 7s polling loop.** Two devices editing the same wedding will silently overwrite each other. | Lost edits. | Add an `updated_at` optimistic-lock check in `wp_save`. Reject save if server is newer than client baseline. | $0 | 2 hr |
| R13 | **No DB-size monitoring.** You'll hit the 500MB free limit one day with no warning. | Sudden write failures. | Add Supabase usage to nightly backup job; alert if >80%. | $0 | 30 min |

---

## Phased rollout

### Week 1 (NOW — before friend tests)
Cheapest, highest-leverage work. Total: ~4 hours.
- [ ] **Day 1:** R1 — nightly backup GitHub Action. Verify it runs.
- [ ] **Day 1:** R7 — UptimeRobot on `https://<your-current-url>/`.
- [ ] **Day 1:** R5 — Healthchecks.io cron pinging `wp_load`.
- [ ] **Day 2:** R8 — CI: `node --check` on push.
- [ ] **Day 2:** R6 — Sentry SDK in `index.html`.
- [ ] **Day 3:** R3 — practice a frontend rollback on staging. Test backup restore on a throwaway Supabase project.
- [ ] **Day 3:** Adopt `DEPLOY-CHECKLIST.md` (this folder) — actually use it on the next push.

### Month 1 (before commercial launch — Phase 2)
Adds the polish that lets you charge money. Total: ~12 hours over ~4 weeks, async.
- [ ] R9 — buy domain, point at Pages, get HTTPS.
- [ ] R2 — proper staging: branch `staging` → second Supabase project → preview URL.
- [ ] R10 — Plausible or PostHog wired up; funnel events for signup → planner-loaded → first-task-added → invite-sent.
- [ ] R4 — auto-cache-bust in CI.
- [ ] R13 — Supabase usage alert in nightly job.
- [ ] R12 — optimistic locking on `wp_save`.
- [ ] Document Stripe + refund flow (out of scope for this doc).

### Pre-wedding freeze (Jan 2027)
**No feature ships in January 2027.** Production goes into "boring is beautiful" mode.
- [ ] **Jan 1:** Code freeze for new features. Bug fixes only.
- [ ] **Jan 5:** Run a full backup restore drill end-to-end. Time it.
- [ ] **Jan 10:** Verify all alerts (UptimeRobot SMS, Sentry email) actually reach your phone — not just your inbox. Test by intentionally breaking the site for 30 seconds.
- [ ] **Jan 15:** Print this runbook. Yes, on paper. Put it in a folder. You will not have laptop access during the wedding weekend.
- [ ] **Jan 20:** Identify a backup-human (sibling, friend who's technical) who can follow the runbook if you're, say, getting married.
- [ ] **Jan 25:** Final go/no-go. If anything is yellow, descope hard.
- [ ] **Feb 1–12:** **Zero pushes to prod for two weeks pre-wedding** unless there's an active P0.

---

## Detailed recommendations by area

### 1. Reliability risks — current state

Ranked by `severity = (likelihood this quarter) × (blast radius if it happens)`.

#### Severity 10/10 — Data loss
- **No backups.** `pg_dump` runs zero times currently. Single point of failure: any logic bug in `wp_save`, any errant SQL in a migration, any data corruption in Postgres = irrecoverable.
- **Detection:** none. You find out when a couple emails you.
- **Mitigation:** §2. Do this week.

#### Severity 9/10 — Silent prod breakage
- **No uptime monitoring.** Site can be down for hours and you wouldn't know until someone texts you.
- **No JS error tracking.** A button might be broken on Safari for 6 months and you'd never know.
- **No staging.** Every commit IS the staging environment.
- **Detection:** Twitter / text messages / your own dogfooding.
- **Mitigation:** §3, §6, §5.

#### Severity 8/10 — Supabase free-tier walls
- **Auto-pause after 7 days idle.** Real risk: in early days when you have low traffic, the project will pause regularly. New signups land on a dead site.
- **500MB DB cap.** Each couple's `data` JSON is probably 10–50KB. You're fine until ~5k couples or until someone uploads photo data URLs into settings.
- **5GB egress/mo.** The 7-second poll is your enemy here. 10 active couples × 2 tabs × 12 polls/min × 50KB × 24h × 30d = ~52GB/mo. **You will blow this cap quickly with even modest engagement.** Fix the poll cadence (30s minimum, or move to Realtime) before launch.
- **50k auth MAU.** N/A (we don't use Supabase Auth for couples).
- **Detection:** none today.
- **Mitigation:** §3 (Healthchecks for pause), §13 (usage monitoring), and **change the poll from 7s → 30s + only when tab is visible** as a code change before launch.

#### Severity 7/10 — PWA stale-cache trap
- Service worker (`sw.js`) caches the shell. You bump `CACHE_NAME` by hand and have already forgotten before.
- Worst case: a guest installed the PWA in October 2026. Wedding's in February. They open the app the morning of the wedding and see a 4-month-old version with broken alerts.
- **Mitigation:** auto-derive `CACHE_NAME` from commit SHA via CI. Add `<link rel="manifest">` with `?v=<sha>`.

#### Severity 6/10 — Buggy deploy with no rollback path
- Frontend rollback is `git revert && push`, ~60s. Untested though.
- SQL rollback **does not exist** — your migrations don't have down-migrations. A bad `alter table` ships and stays shipped.
- **Mitigation:** enforce idempotent migrations (DEPLOY-CHECKLIST item 2), and write down-migrations for any change that's not trivially reversible.

#### Severity 5/10 — Single-writer race condition
- Two devices on the same wedding overwrite each other's edits. Not strictly a "reliability" issue but it's an unowned data-loss path. Address in Phase 2 (R12).

### 2. Backups

**Decision:** nightly `pg_dump` via GitHub Action → private GitHub repo `wedding-planner-backups` (separate from the public repo). Free, retains forever, restorable in 5 min, zero ongoing toil.

**Why not Supabase's own backups?** Supabase free tier offers point-in-time recovery only on paid plans. The dashboard "Database Backups" tab is paid-only. You need to roll your own on free tier.

**Why not S3 / R2?** Adds another account, another credential to rotate, another bill. A private GH repo is 5GB free and git diffs the dumps cleanly (so storage stays small even with daily snapshots).

**Setup (90 min one-time):**

1. Create a new private repo: `aravindramesh2806/wedding-planner-backups`.
2. In Supabase dashboard → Settings → Database, copy the **connection string** (`postgresql://postgres.<ref>:...@aws-...supabase.com:5432/postgres`).
3. In the main `wedding-planner` repo, add three GitHub Actions secrets (Settings → Secrets):
   - `SUPABASE_DB_URL` — the connection string
   - `BACKUP_REPO_TOKEN` — a GH personal access token scoped to the backup repo only (use a fine-grained PAT)
4. Add `.github/workflows/nightly-backup.yml`:

```yaml
name: Nightly Supabase Backup
on:
  schedule:
    - cron: '17 9 * * *'   # 09:17 UTC ≈ 02:17 PT. Off-peak.
  workflow_dispatch:        # manual trigger button
jobs:
  backup:
    runs-on: ubuntu-latest
    steps:
      - name: Install pg_dump 15
        run: |
          sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
          wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
          sudo apt-get update
          sudo apt-get install -y postgresql-client-15

      - name: Dump
        env:
          PGPASSWORD: ${{ secrets.SUPABASE_DB_PASSWORD }}
        run: |
          DATE=$(date -u +%Y-%m-%d)
          pg_dump "${{ secrets.SUPABASE_DB_URL }}" \
            --no-owner --no-acl \
            --schema=public \
            -f backup-$DATE.sql
          gzip backup-$DATE.sql
          ls -lh backup-$DATE.sql.gz

      - name: Push to backup repo
        env:
          GH_TOKEN: ${{ secrets.BACKUP_REPO_TOKEN }}
        run: |
          git clone https://x-access-token:$GH_TOKEN@github.com/aravindramesh2806/wedding-planner-backups.git
          cd wedding-planner-backups
          mkdir -p $(date -u +%Y/%m)
          mv ../backup-*.sql.gz $(date -u +%Y/%m)/
          # prune anything older than 90 days
          find . -name 'backup-*.sql.gz' -mtime +90 -delete
          git config user.email "backups@wedding-planner.local"
          git config user.name  "Backup Bot"
          git add -A
          git commit -m "backup $(date -u +%Y-%m-%d)" || echo "no changes"
          git push

      - name: Notify on failure
        if: failure()
        run: echo "Backup failed — check Actions tab" && exit 1
```

5. Hook GitHub's built-in workflow-failure email (Settings → Notifications → Actions → email on failure).
6. **Restore drill (mandatory):** spin up a throwaway Supabase project, `psql <new-project-url> < latest-backup.sql`, verify a couple's data comes back. Time how long it takes. Write it in the runbook.

**Per-couple snapshot bonus:** add a "Download my data" button in the planner UI that POSTs a JSON dump of `S` for download. Costs nothing. Couples love it. Gives you legal coverage too.

### 3. Monitoring + alerting

Three layers, all free tier:

**Uptime: UptimeRobot.** Free tier = 50 monitors, 5-min interval, email + SMS alerts.

Setup:
1. Sign up at uptimerobot.com with aravindramesh98@gmail.com.
2. Add monitor: HTTPS GET `https://<your-domain>/healthcheck.html` — interval 5min — alert via email + SMS.
3. Create `healthcheck.html` in the repo root with one line: `<!doctype html><body>ok</body>`. Don't use `index.html` — it's big and a slow load doesn't mean it's down.
4. Add monitor: HTTPS GET `https://vjncnjalnxdkyzbdrxck.supabase.co/rest/v1/` with header `apikey: <publishable-key>` — interval 5min — alerts to email only (Supabase blips are normal, don't SMS you).
5. SMS only on `<your-domain>` going down. Email everything else.

**Keep-alive (free-tier pause prevention): Healthchecks.io.** Cron monitoring SaaS. Free tier = 20 checks. Inverted from UptimeRobot — *you* ping *it*. Won't help here; we want the other way around.

For pause prevention, use a second GitHub Action cron that calls `wp_load` every 6 hours:

```yaml
name: Keep Supabase Warm
on:
  schedule:
    - cron: '0 */6 * * *'
jobs:
  ping:
    runs-on: ubuntu-latest
    steps:
      - name: Hit a read RPC
        run: |
          curl -fsS -X POST \
            "https://vjncnjalnxdkyzbdrxck.supabase.co/rest/v1/rpc/wp_load" \
            -H "apikey: ${{ secrets.SUPABASE_PUBLISHABLE_KEY }}" \
            -H "Content-Type: application/json" \
            -d '{"p_token":"ping-no-such-token"}'
          # Returning 200 with {"error":"not_found"} is fine — we just need the DB awake.
```

**Usage tracking:** add a step in the nightly backup workflow that hits Supabase Management API for project usage, and `exit 1` if DB size > 80% of 500MB or egress > 80% of 5GB. Failure email is your alert.

```bash
# add to nightly workflow:
curl -fsS https://api.supabase.com/v1/projects/$REF/usage \
  -H "Authorization: Bearer ${{ secrets.SUPABASE_PAT }}" \
  | jq '.db_size_bytes, .egress_bytes'
```

(The exact endpoint shape changes; check Supabase Management API docs when you build this.)

### 4. CI / pre-deploy gates

**Decision:** GitHub Actions on push to main. Don't move to PR-based flow yet — you're solo and the friction would slow you down. The gate runs *after* push but fails loudly if broken, and pairs with the checklist for pre-push discipline.

`.github/workflows/ci.yml`:

```yaml
name: CI
on:
  push:
    branches: [main, staging]
  pull_request:
jobs:
  syntax-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20' }
      - name: Extract inline JS and node --check it
        run: |
          node -e "
            const fs = require('fs');
            const html = fs.readFileSync('index.html','utf8');
            const re = /<script(?![^>]*\bsrc=)[^>]*>([\s\S]*?)<\/script>/g;
            let m, i=0, fails=0;
            while ((m = re.exec(html))) {
              i++;
              const code = m[1];
              if (!code.trim()) continue;
              fs.writeFileSync('/tmp/chunk.js', code);
              const { spawnSync } = require('child_process');
              const r = spawnSync('node', ['--check', '/tmp/chunk.js']);
              if (r.status !== 0) {
                console.error('Script block #'+i+' failed:');
                console.error(r.stderr.toString());
                fails++;
              }
            }
            if (fails) process.exit(1);
            console.log('All '+i+' inline scripts parse cleanly.');
          "

  html-validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npx -y html-validate index.html || true   # advisory only; HTML5 validation is noisy

  sql-lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Check migrations are idempotent
        run: |
          # naive but effective: every migration must contain "if not exists" or "or replace"
          # OR be explicitly tagged as one-shot in a header comment
          for f in migrations/pending/*.sql 2>/dev/null; do
            if ! grep -qE "(if not exists|or replace|-- one-shot)" "$f"; then
              echo "FAIL: $f appears not idempotent. Add 'if not exists' / 'or replace' or '-- one-shot' header."
              exit 1
            fi
          done

  smoke-test:
    needs: [syntax-check]
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - name: Wait for Pages to rebuild
        run: sleep 90
      - name: Smoke test
        run: |
          URL="${{ secrets.LIVE_URL }}"  # e.g. https://your-domain.com/
          set -e
          curl -fsS "$URL" > /tmp/page.html
          # Must include the signup form heading and a Supabase URL — otherwise build is broken
          grep -q "vjncnjalnxdkyzbdrxck" /tmp/page.html
          grep -qi "wedding" /tmp/page.html
          # Service worker must be registered
          grep -q "serviceWorker" /tmp/page.html
          echo "Smoke test passed."
```

Failures email you (default GH behavior). Don't add Playwright yet — overkill for a single-file SPA. Add it in Phase 2 when guest flows get complex.

### 5. Staging environment

**Decision:** two Supabase projects (prod + staging) + branch-based GitHub Pages preview. Free.

Setup:
1. Create a new free Supabase project `wedding-planner-staging`. Run all migrations against it.
2. In the repo, create a `staging` branch.
3. Configure GH Pages to publish *both* `main` and `staging`. There are a few ways:
   - **Easiest:** the `staging` branch keeps the same `index.html` but uses a build-time replace to swap the Supabase ref. Use a `<meta>` tag or an env-substituted constant. Push to `gh-pages-staging` branch via a workflow.
   - **Even easier:** publish the staging branch to a separate gh-pages site (`wedding-planner-staging` repo).
4. Workflow on push to `staging`: copy `index.html`, sed-replace the prod Supabase URL/key with the staging values, push to the staging gh-pages.
5. Bookmark `https://<staging-url>/` in your phone home screen for testing.

**Use this for:** any change that touches SQL, any change to sign-in flow, any change to save/load logic. Direct-to-main is fine for copy tweaks and CSS.

**Skip-level option (don't do this yet):** Vercel/Netlify give you per-PR preview URLs for free. But it'd mean moving off GH Pages, which doesn't pay for itself until you're doing real teamwork. Stay on Pages.

### 6. Error tracking

**Recommendation: Sentry.** Free tier = 5k errors/mo, 1 user, source maps supported. Battle-tested for a one-person team.

Why not the alternatives:
- **PostHog** — great product analytics, but its error tracking is a younger feature. You'll want PostHog OR Plausible for analytics anyway, but use Sentry for errors.
- **Roll-your-own (`window.onerror` → Supabase table)** — tempting because of the existing stack, but it puts more load on your already-quota-bound DB, you build a UI for it yourself, and you'll skip on stack trace symbolication. Not worth saving the SaaS account.

Setup (15 min):
1. Sentry → New project → Browser JavaScript → name `wedding-planner-prod`.
2. Paste the loader snippet in `<head>` of `index.html` *above* your inline `<script>`:
   ```html
   <script src="https://js.sentry-cdn.com/<your-public-key>.min.js" crossorigin="anonymous"></script>
   ```
3. Configure: `Sentry.init({ tracesSampleRate: 0, replaysSessionSampleRate: 0, environment: 'prod' })` to keep within the free tier (no perf monitoring, no session replay — both burn quota fast).
4. Wrap your RPC fetches with a try/catch that calls `Sentry.captureException(e, { tags: { rpc: 'wp_save' } })`.
5. Set up an Issue Alert: "send me an email when an error happens > 5 times in 1 hour" — don't email on every error or you'll go numb.
6. Create a second project `wedding-planner-staging` and only enable Sentry on staging when `location.host` matches the staging URL.

### 7. Analytics

**Recommendation: PostHog free tier**, with a fallback option of Plausible Cloud ($9/mo) if you want it dead simple.

Reasoning:
- **PostHog free** = 1M events/mo, free product analytics + feature flags + session replay (sample at 1%). Self-host option exists if you ever care. The funnels and cohorts are great for a SaaS launch.
- **Plausible** = privacy-respecting, cookie-less, $9/mo. Cleaner dashboards, much shallower than PostHog. Worth it if you want zero setup time.
- **Umami self-hosted** = free + cookie-less, but you have to host it. Adds toil. Skip.
- **Google Analytics** — no. Privacy-hostile for a wedding product, terrible DX, slow loader, won't survive ad-blockers.

Funnel events to instrument (regardless of tool):
- `landed_signup` — anyone hits the marketing page
- `signup_completed` — couple created
- `planner_first_load` — couple opens their `#w=…` URL the first time
- `first_task_added` / `first_event_added` / `first_guest_added` — activation
- `invite_link_copied` — major activation event
- `guest_landed_invite` — guest opens their `#rsvp=…`
- `guest_signin_completed` — guest is "in"
- `guest_rsvp_submitted` — major value moment
- `couple_upgraded_to_paid` — money event

Watch:
- **Signup → first_task** conversion (activation): goal >60%
- **invite_link_copied → guest_landed_invite** (real usage): goal >80% (this is the Phase 1 dogfooding gate)
- **guest_landed → guest_rsvp** conversion: goal >70%
- **Time-to-first-action** (signup → first edit): goal <5 min

Don't instrument everything. The 8 events above are enough to run the business.

### 8. Custom domain + HTTPS

**Yes, do this in Month 1.** The current URL is fine for friend tests; it is not fine for paying customers. $12/yr is trivially worth it.

Suggested domain pattern (not picking the name — that's the product strategist's job): something short, .com or .so or .app, that works in plain speech ("go to ____ dot com").

**Step-by-step (30 min):**

1. Buy domain via Cloudflare Registrar (sells at cost, no markup) or Namecheap. Cloudflare gives you free DNS + DDoS protection at the same time.
2. In Cloudflare DNS (or your registrar's DNS console), add:
   - Apex (`yourdomain.com`): four A records pointing to GH Pages IPs:
     ```
     185.199.108.153
     185.199.109.153
     185.199.110.153
     185.199.111.153
     ```
   - `www` → CNAME to `aravindramesh2806.github.io`
3. In the repo root, create a file named `CNAME` (no extension) containing only `yourdomain.com`.
4. GitHub repo Settings → Pages → Custom domain → enter `yourdomain.com`. GH will verify DNS (~1–5 min).
5. Once verified, **tick "Enforce HTTPS"**. GH provisions a Let's Encrypt cert in 5–60 min.
6. Verify: `curl -I https://yourdomain.com/` returns `200`. Visit in incognito.
7. Update Supabase publishable-key URL allowlist if you've set one (Settings → API).
8. Update `index.html` invite-link templates to use the new domain.
9. **Old URL keeps working** — GH Pages serves both. Don't redirect the old one for a few weeks (broken bookmarks).

**Cloudflare bonus (10 min extra):** turn on "Always Use HTTPS" + "Auto Minify" + cache rules for static assets. Free. Improves load time by 200–500ms in Asia.

### 9. Pre-deploy checklist

See `DEPLOY-CHECKLIST.md` (this folder). 15 items, ~5 min to run through. Specifically designed to catch the four classes of bug that have shipped historically: date/time, blob-shape regressions, secrets, and stale cache.

### 10. Operations runbook

See `RUNBOOK.md` (this folder). Ten scenarios covering: site down, Supabase paused, quota hit, buggy deploy, data loss, DB filling, stale PWA cache, backup failure, DNS/HTTPS, spam.

Re-read it once a month. Rehearse the data-loss scenario at least once before the wedding.

---

## Don't do this yet

A list of things that sound like good ops hygiene but are not worth your time **for a solo, pre-revenue, single-file app**:

- **Kubernetes / containers / Docker** — you have zero servers.
- **Terraform / IaC** — you have two SaaS dashboards. Click them.
- **Datadog / New Relic / paid APM** — Sentry covers errors, UptimeRobot covers uptime. Save the $200/mo.
- **PagerDuty** — you'd be the only one on call and the only thing it'd do is wake you up. Use UptimeRobot SMS.
- **Multi-region** — Supabase free has one region. You're optimizing for "exists" not "fast in Singapore". Revisit at 1k MRR.
- **Blue/green / canary deploys** — overkill for a static HTML file. Branch-based preview gives you 80% of the value.
- **End-to-end Playwright suite** — start with the one-line smoke test in CI. Build E2E when guest-flow regressions become a real pattern, not before.
- **Penetration test / security audit** — get to 50 paying customers first. Then do it. Until then: rotate the leaked `sb_secret` key (already in your PENDING housekeeping list) and keep an eye on the Sentry feed for `403`/`401` spikes.
- **Custom auth (move off the token-in-URL model)** — material work, breaks all existing invite links, customers won't notice the difference. Phase 3 problem.
- **CDN beyond Cloudflare** — Pages + CF is plenty for <100k pageviews/mo.

---

## Pre-deploy checklist (also saved separately as DEPLOY-CHECKLIST.md)

See `DEPLOY-CHECKLIST.md` in this folder — it's the source of truth; the duplicate here would drift. Summary: 10 sections, ~15 items, ~5 minutes per deploy. Covers code sanity, migration sanity, blob shape, **date/time** (the bug-prone area), manual smoke, cache-bust, backup confirmation, comms, wedding-day empathy, and rollback readiness.

## Runbook (also saved separately as RUNBOOK.md)

See `RUNBOOK.md` in this folder. Ten scenarios with concrete commands and SQL. Designed to be readable on a phone at 2am.

---

## Appendix — open questions for you

These need decisions before/during Month 1. Flagging now so you can think on them:

1. **Domain name** — out of scope for this doc, but blocks §8. Decide by Week 2.
2. **Free vs paid tier limits for couples** — already in PRODUCT-DIRECTION open questions. Affects analytics events (need a `couple_hit_free_limit` event).
3. **GDPR / data-deletion** — when a couple says "delete my account", you need a flow. Today there's `wp_admin_delete`; not user-facing. Add a "Delete my wedding" button + 7-day grace period before Month 1.
4. **Stripe webhook handling** — when payments come in, where do they go? A Supabase Edge Function is the cleanest fit. Separate doc.
5. **Backup of `wedding-planner-backups` repo itself** — what if GitHub locks your account? Once a quarter, run `git clone --mirror` of the backup repo to an external drive. Low frequency, high insurance value.
