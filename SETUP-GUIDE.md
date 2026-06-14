# Wedding Planner — Shared setup (free, ~5 minutes)

This turns the planner into a real shared website: you and your partner each get a
private link that opens the same live plan on any phone or laptop. It costs $0 on
Supabase's free tier.

You do steps 1–3 (the cloud account). I'll do step 4 (wiring it in) once you send me
the two values from step 2.

---

## Step 1 — Create a free Supabase project (~3 min)

1. Go to **https://supabase.com** and click **Start your project** / sign in (a free
   account is fine — you can use GitHub or email).
2. Click **New project**.
   - **Name:** anything, e.g. `wedding`.
   - **Database password:** make one up and save it somewhere (you won't need it day to day).
   - **Region:** pick the one closest to you.
3. Click **Create new project** and wait ~2 minutes while it sets up.

## Step 2 — Copy your two values

1. In your project, open **Project Settings** (the gear, bottom-left) → **API**.
2. Copy these two things:
   - **Project URL** — looks like `https://abcdxyz.supabase.co`
   - **Project API key → `anon` `public`** — a long string starting with `eyJ...`

> The `anon` key is meant to be public/in the browser — that's expected and safe here,
> because the database is locked down and only the secure functions can touch the data.

## Step 3 — Create the database tables

1. In Supabase, open the **SQL Editor** (left sidebar) → **New query**.
2. Open the file **`supabase-setup.sql`** (in this same folder), copy everything, paste
   it into the editor, and click **Run**.
3. You should see "Success. No rows returned." That's it.

## Step 4 — Set your admin key

In `supabase-setup.sql` there's a line:

```
language sql immutable as $$ select 'CHANGE-ME-admin-2026'::text $$;
```

Change `CHANGE-ME-admin-2026` to your own secret before running the SQL (or re-run the
SQL after changing it). This key protects the master page that lists every couple.

## Step 5 — Send me the two values

Paste your **Project URL** and **anon public key** back to me in the chat. I'll drop them
into the app, confirm everything works, and (if you want) deploy it to a free URL.

---

## How the shared product works

- **Signup page** (the site's home): a couple enters the **bride's** and **groom's** names
  and (optionally) their wedding date, clicks **Create our planner**, and is sent to their
  own private URL like `yoursite.com/#w=ab12cd34…`.
- **Couple URL**: that link opens their private planner. Both partners use the *same* link,
  on any phone or laptop — edits sync within a few seconds. They should bookmark it and keep
  it private (anyone with the link can open the plan).
- **Master / admin page**: visit `yoursite.com/#admin=YOUR-ADMIN-KEY` to see a list of every
  couple that's signed up — names, wedding date, signup date, and guest count. Only someone
  with the admin key can see it.
