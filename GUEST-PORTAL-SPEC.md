# Guest Portal — v1 Spec

Lean MVP module for the Wedding Planner app. Lets each couple invite guests, lets guests sign in and see event info, and gives the couple a single dashboard to manage everything.

---

## 1. Goals

- Guests can self-serve answers to: When? Where? What do I wear? What's happening?
- Couple can broadcast last-minute changes without group-texting everyone.
- Couple keeps approval control — no random people get into the portal.
- Couple sees **everything** about every guest from one page in their existing admin/dashboard view.

## 2. Non-goals (v1)

Meal preferences, song requests, photo upload, guestbook, hotel/travel info, seating chart, SMS, multi-language, post-wedding photo gallery. All deferred to v2.

---

## 3. Guest sign-in

Three methods on the same sign-in screen:

1. **Continue with Google** — Supabase Auth Google OAuth provider. Fastest path for most guests.
2. **Name + phone (last 4 digits)** — for relatives without Google. Matches an entry in the couple's pre-uploaded guest list.
3. **Sign up with email** — for guests who have the link but weren't pre-added.

### Approval flow

- Pre-added guests matched on name+phone or pre-added email → **auto-approved**.
- New self-signups (Google or email, no match in couple's list) → **pending**.
- Couple gets an in-app notification + browser push: *"New guest wants to join — Approve / Reject"*.
- Pending guests see a "Waiting for couple's approval" screen until approved.

---

## 4. Pages the guest sees

| Page | Content |
|------|---------|
| **Home** | Personalized welcome, countdown, next upcoming event card, latest alerts. |
| **Schedule** | All events with date, time, dress code, "Add to Calendar" (.ics) button. |
| **Venues** | Per-event address, "Open in Maps" link (Google + Apple), parking notes. |
| **Know before you go** | Couple-authored notes — general + per-event. |
| **My RSVP** | Per-event attendance toggle, plus-one count. |
| **Alerts** | In-app feed of broadcasts from couple. Push opt-in prompt on first visit. |

Mobile-first layout. Reuses the app's existing 8 color themes.

---

## 5. What the couple sees (admin / dashboard)

A new **Guests** tab in the existing couple dashboard. Single source of truth — no separate screens.

**Per-guest row shows:**
- Name, contact (email, phone), sign-in method (Google / phone / email)
- Status: pending / approved / rejected
- RSVP status per event (✓ Attending / ✗ Declined / — No response)
- Plus-one count
- Last seen, alerts opened, push-enabled (yes/no)
- Actions: Approve, Reject, Edit, Remove, View as guest (preview their portal)

**Aggregate widgets at top:**
- Total invited / approved / pending / declined
- RSVP completion % per event
- Push opt-in rate

**Couple actions on the page:**
- Upload pre-approved guest list (CSV: name, phone, email)
- Approve / reject pending signups (inbox)
- Compose alert → pick audience (all / per-event attendees / specific guests) → send
- Edit "Know before you go" notes (general + per-event)
- Edit per-event details (dress code, venue, parking, map link)

---

## 6. Alerts

**Channels (v1):** in-app banner + browser push (Web Push API, free).

**Lifecycle:**
1. Couple composes alert → picks audience → sends.
2. Alert lands in every targeted guest's `Alerts` feed.
3. If guest opted into push, service worker fires a notification.
4. Alert marked "read" when guest opens it.

**Auto-alerts (system-generated):**
- T-7 days, T-1 day, T-2 hours before each event (per RSVP'd guest).
- Welcome alert on first approved sign-in.

---

## 7. Data model (new tables in Supabase)

```
guests
  id, couple_id, name, email, phone, phone_last4,
  auth_user_id (nullable), signin_method (google|phone|email),
  status (pending|approved|rejected),
  created_at, approved_at, last_seen_at, push_subscription (jsonb)

guest_rsvps
  id, guest_id, event_id, attending (bool), plus_ones (int), updated_at

guest_alerts
  id, couple_id, title, body, audience (jsonb — all|event_id|guest_ids),
  created_at, sent_by

alert_reads
  alert_id, guest_id, read_at  (composite PK)
```

Existing `events` table extended with: `dress_code`, `parking_notes`, `map_link`, `know_before_notes`.

## 8. RPCs (SECURITY DEFINER, same pattern as existing `wp_*`)

- `wp_guest_signup(couple_token, method, name, email, phone, google_id)` → returns guest_id + status
- `wp_guest_load(guest_id)` → guest's events, venues, notes, RSVPs, alerts
- `wp_guest_rsvp(guest_id, event_id, attending, plus_ones)`
- `wp_guest_register_push(guest_id, subscription_json)`
- `wp_admin_list_guests(couple_token)` → full guest table for couple's dashboard
- `wp_admin_approve_guest(couple_token, guest_id, decision)`
- `wp_admin_upload_guests(couple_token, csv_rows)` → bulk add pre-approved
- `wp_admin_send_alert(couple_token, title, body, audience)`
- `wp_admin_edit_event_guest_info(couple_token, event_id, fields)`

RLS stays on; guests only ever hit guest-scoped RPCs, couple hits admin RPCs.

---

## 9. URLs & routing

Same single-page app, hash-based routing:

- `#g` — guest sign-in / portal (auto-detects logged-in session)
- `#g=<invite_token>` — pre-personalized invite link sent by couple
- Existing `#w=<couple_token>` — couple's dashboard (now includes Guests tab)
- Existing `#admin=<admin_key>` — master admin (unchanged)

---

## 10. Setup steps (one-time, before build)

1. Supabase → Authentication → Providers → enable **Google**.
2. Google Cloud Console → create OAuth client → add `https://aravindramesh2806.github.io` as authorized origin + redirect.
3. Generate VAPID keys for Web Push (`npx web-push generate-vapid-keys`); store public key in app, private in Supabase env.
4. Run new SQL migration (tables + RPCs) on Supabase project `vjncnjalnxdkyzbdrxck`.

---

## 11. Build order

1. SQL migration: tables + RPCs.
2. Guest sign-in screen (Google + phone + email).
3. Approval inbox in couple's dashboard.
4. Guest home + schedule + venues + know-before pages (read-only).
5. RSVP per event.
6. Guests tab in couple dashboard (table + actions + aggregates).
7. Alerts: couple compose + guest feed (in-app only).
8. Web Push service worker + opt-in prompt + auto-alerts.

Each step deployable independently.

---

## 12. Open questions to resolve before coding

- CSV format for guest upload — settle exact columns.
- Approval notification: real-time (Supabase Realtime) or polling like existing app? Probably polling for consistency.
- Should rejected guests be told they're rejected, or just see "pending" forever? Recommend: silent — they stay on "pending" screen.
- Push notifications on iOS Safari work only if guest "adds to home screen" first. Surface this hint in the opt-in prompt.
