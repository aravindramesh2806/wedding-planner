# Wedding Planner

A free, multi-tenant wedding-planning web app.

- **Live site (signup):** https://aravindramesh2806.github.io/wedding-planner/
- **Admin console:** add `#admin` to the URL and sign in with the admin key
- **Stack:** single-file `index.html` (no build step) + Supabase (Postgres) + GitHub Pages

## Files
- `index.html` — the entire app (UI + cloud sync logic)
- `supabase-setup.sql` — database schema + secure functions (run in Supabase SQL editor)
- `SETUP-GUIDE.md` — how to set up the Supabase backend

## How it works
Couples sign up and get a private link (`#w=<token>`) that opens the same plan on any
device. Guests RSVP via a public link (`#rsvp=<token>`). All data lives in Supabase,
locked down so only the secure functions can read/write it.
