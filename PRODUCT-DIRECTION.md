# Wedding Planner — Product Direction

## North Star
Build this into a commercial product. Aravind's own wedding (Feb 12, 2027) is the
forcing-function deadline: make it good enough that *his guests* actively use it.
If guests don't use it, customers won't either.

## Decision rule
Every feature/UX choice must be justified from a **customer / user experience**
standpoint. Two users:
- **Couple** — planning a wedding, stressed, time-poor, wants control
- **Guest** — invited, on phone, wants answers fast (when/where/what to wear)

When evaluating a feature, answer:
1. Which user does this serve, and is it their top-3 unmet need right now?
2. Does it make them say "wow" or "finally"?
3. Would they pay for it (couple) / recommend it to the couple (guest)?
4. What's the minimum version that proves the value? Ship that first.

## Competitive landscape
Joy (joy.so), Zola, The Knot, Minted, Withjoy, Riley & Grey.
- Most have heavy bloat (registry, vendor marketplace, etc.)
- Most are not mobile-first for guests
- Most don't have real-time alerts
- Most lock the good stuff behind a paywall

Our wedge: **lightweight, instant, guest-first**.
Their wedding planner + a portal guests actually *want* to open.

## Phases

### Phase 1 — Aravind's wedding (NOW → Feb 2027)
Goal: 80%+ of Aravind's invited guests actively use the portal at least once.
- Bulletproof guest sign-in (sign-up → approval → in)
- Auto-approve flow for pre-added guests works flawlessly
- Personal invite links (sent via WhatsApp/SMS) reach 100% of guests
- Alerts feature is genuinely useful (Web Push for lock-screen pings)
- Every guest can answer: when? where? what to wear? what's next?
- Zero crashes, zero confusion. Test with non-tech-savvy relatives.

### Phase 2 — Commercial-ready
- Multi-tenant onboarding (new couple signup flow that doesn't suck)
- Customizable guest portal (couple's branding/photos/story)
- Pricing tiers (free for small weddings, paid for >50 guests or premium features)
- Payment integration (Stripe)
- Domain alias (couple's own domain or branded subdomain)
- Couple support docs / "getting started" tour

### Phase 3 — Growth
- SEO content (wedding planning guides → product)
- Referral mechanics (guests who see it want it for their wedding)
- Partner integrations (photographers, planners)
- Mobile app wrapper (PWA → installable)

## How Claude should work going forward
For every feature request or design decision:
1. Frame it from the user's POV first ("a couple would want to do this because...")
2. Flag if it's a "couple feature" or "guest feature"
3. Surface trade-offs (cost, complexity, time-to-test)
4. Suggest the MVP that proves the value
5. Flag when a request is more about Aravind's personal preference vs.
   what would work for 1000 other couples
6. Push back when a feature would bloat the product

Periodically (every ~5 features), do a "business check" — review the roadmap,
flag scope creep, suggest what to cut, what's still missing for Phase 1 success.

## Open strategic questions (decide before Phase 2)
- Free tier limits (guest count? events? alerts/month?)
- Paid tier price ($50 one-time? $20/mo for 6 months?)
- Bring-your-own-domain or `weddings.app/your-name` only?
- Vendor side as separate product or out of scope?
- Photo gallery — host yourself or integrate Cloudinary/Imgix?

