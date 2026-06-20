# Product Strategy — Wedding Planner

Authored 2026-06-20 as a positioning, naming, pricing, and GTM doc. Separate from the roadmap (see PENDING.md) and the guest-portal spec (see GUEST-PORTAL-SPEC.md). The forcing function is Aravind's wedding on 2027-02-12; commercial launch follows.

---

## 1. Product name candidates

Criteria: short, memorable, pronounceable globally (works for both Indian and Western couples), not a corporate-sounding brand, ideally one word, ideally a domain you can plausibly buy without a five-figure broker fee. I haven't actually checked WHOIS — these are guesses based on how common the word is. Verify on Namecheap / Porkbun / get.dan.com before committing.

| # | Name | Rationale & vibe | Domain guess | Verdict |
|---|------|------------------|--------------|---------|
| 1 | **Plusone** | The single most universal wedding word ("are you bringing a plus one?"). Friendly, intimate, non-gendered, culture-neutral. Works for a 5-day Indian wedding or a 1-day City Hall ceremony. | `.com` almost certainly taken or parked at $$$$. `plusone.app` or `plusone.wedding` realistic. | Strong meaning, but expect a fight for the domain. Lead candidate if `plusone.app` is < $500. |
| 2 | **Tied** | "Tying the knot." Single syllable, declarative, feels like a verb couples opt into. Works in both cultures (knot-tying is in many Indian ceremonies too). | `tied.com` almost certainly parked. `tied.wedding` very likely available. `gettied.com` plausibly available cheap. | Probably taken for `.com`. `tied.wedding` is the play. |
| 3 | **Mehndi** | Owns the Indian wedding context, instantly meaningful, beautiful word. Risk: alienates Western couples who think it's only for South Asian weddings. | `.com` likely available or cheap — niche word. `mehndi.app` very likely free. | Skip unless he wants to wedge into Indian weddings first and expand. Too narrow for the stated dual market. |
| 4 | **Vow** | Tiny, declarative, present in every wedding tradition globally. Easy to say, easy to type. | `vow.com` definitely taken (Mary Kay / generic). `vow.app` likely premium. `vow.wedding` likely available. | Great name. Domain will hurt. `vow.wedding` is the realistic buy. |
| 5 | **Confetti** | Joyful, visual, post-ceremony imagery. Feels lightweight (matches the positioning). | `confetti.com` taken (events company). `confetti.app` likely premium-but-buyable. `confetti.wedding` very likely free. | Already used by a few event-tech brands — search for trademark conflict before buying. |
| 6 | **Petal** | Soft, floral, universal — flower petals show up in Hindu, Christian, Jewish, civil ceremonies. Two syllables. | `petal.com` definitely taken. `petal.app` likely premium. `petal.wedding` likely free. Also `petalapp.com`. | Backup option. Less directly evocative of "wedding" than Vow or Tied. |
| 7 | **Garland** | Garlands are central to Indian weddings (jaimala) and decorative in Western ones. Distinctive, not generic, but recognizable. | `garland.com` taken (city in Texas). `garland.app` plausibly free. `garland.wedding` very likely free. | Good story, slightly long. |
| 8 | **Toast** | "A toast to the couple." Warm, social, ceremony-neutral. | `toast.com` taken (the restaurant POS unicorn — trademark risk in adjacent categories). `toast.wedding` likely free. | **Skip.** Toast Inc. has aggressive trademark posture and overlaps in "events / hospitality SaaS." Legal headache. |
| 9 | **Rishta** | Hindi/Urdu for "relationship/match" — beautiful, owns the Indian wedding context, but pronounceable for Western users too. Risk: same as Mehndi (too Indian-coded). | `.com` likely available cheap. | Skip unless going Indian-first. |
| 10 | **Knotted** | Plays off "tied the knot," still verb-form, slightly more brandable than `Tied`. | `knotted.com` probably taken (food brand). `knotted.app` likely free or cheap. `knotted.wedding` likely free. | Decent backup. Watch trademark — "The Knot" is the dominant competitor and will scrutinize anything knot-adjacent. **Real risk of a C&D from The Knot.** |

**Top pick: `Plusone`** (fallback: `Tied`). Reasoning: "plus one" is the only wedding word a guest already knows and uses. Couples don't say "I'm tying the knot today" — they say "did you RSVP your plus one?" The name lives in the guest's vocabulary, which is the half of the product nobody else does well. Avoid Knotted/Toast for trademark reasons; avoid Mehndi/Rishta unless he's willing to lead Indian-first (which is a defensible strategy, but it's a different doc).

If `plusone.app` costs more than ~$500 and `plusone.wedding` is unavailable, go to `Tied` on `tied.wedding`. The `.wedding` TLD is a feature here, not a compromise — it tells the visitor what the product is in one character.

---

## 2. One-sentence positioning

Filling in the form: *"For [target couple], [name] is the [category] that [unique value], unlike [competitor] which [their flaw]."*

**Variant A — guest-experience wedge (recommended)**
> For couples who care more about their guests' day-of experience than their wedding website's parallax animation, **Plusone** is the wedding planner that gives every guest a phone-first portal with real-time alerts — unlike Joy, which buries the guest experience under template gallery upsells.

**Variant B — anti-bloat wedge**
> For couples who want to plan a wedding without learning a new SaaS app, **Plusone** is the wedding planner that does the five things you actually need — guests, events, budget, vendors, broadcasts — without the AI poem generator, unlike The Knot which has become a vendor-marketplace ad network with a planner attached.

**Variant C — multi-event / Indian-wedding wedge**
> For couples planning a multi-day wedding where every guest needs a different schedule, **Plusone** is the wedding planner built around per-event RSVPs and dress codes, unlike Zola which assumes one ceremony, one reception, one dress code, done.

Recommendation: lead with Variant A on the landing page. Variant C lives on a `/multi-day` SEO page for organic capture of Indian/South Asian / multi-day searches without making it the brand's center of gravity.

---

## 3. Pricing tiers

Wedding software is a one-shot purchase (couples don't renew next year, hopefully) and that breaks normal SaaS economics. ARPU and LTV are the same number. CAC has to come from organic / word of mouth, not paid acquisition, because the customer never re-pays.

### Option A — Pure free with limits (growth-first)

| Plan | Price | Included | Excluded |
|------|-------|----------|----------|
| **Plusone Free** | $0 | Up to 30 guests, 1 event, 5 vendors, basic guest portal, 1 theme, "Powered by Plusone" footer in guest portal | Multi-event, custom theme, custom domain, CSV import, push alerts, > 30 guests, branding removal |

**How he makes money:** he doesn't, directly. Monetization is one of:
- A `Remove "Powered by Plusone" footer` one-time unlock at $19.
- A vendor-marketplace cut later (The Knot's actual business — refer photographers, take a fee). This is a Phase 3 thing, not Phase 2.
- Donate / tip jar — emotional purchase, sometimes works for wedding products. Realistically <2% conversion.

**Verdict:** good for top-of-funnel and SEO ("free wedding planner"), terrible as a standalone strategy for a solo builder. The free tier exists, but not as the whole pricing model.

### Option B — Freemium (free below 30 guests, paid above) — RECOMMENDED

| Plan | Price | Included | Excluded |
|------|-------|----------|----------|
| **Free** | $0 | Up to 30 guests, 1 event, full guest portal (RSVP, schedule, alerts), default themes, Plusone footer | Multi-event, custom branding, CSV import, > 30 guests |
| **Plusone Pro** | **$79 one-time, per wedding** | Unlimited guests, unlimited events, all 8 themes, CSV import/export, custom subdomain (`yourname.plusone.app`), push alerts, branding removal, vendor manager | — |
| **Plusone Pro + Domain** | **$129 one-time** | Everything in Pro + connect your own domain (`smith-patel-wedding.com`) | — |

**Why these numbers work for the wedding industry:**
- The average US wedding is $30k+, the average Indian wedding (urban, upper-middle) is comparable or higher. $79 is a rounding error on the florist bill. The psychological frame is "is this less than one hour of my planner's time?" — yes.
- Joy charges $0–$15/mo (and pushes you toward $15). The Knot is "free" but monetizes via vendor ads polluting the planner. Zola pushes registry commissions. Riley & Grey charges $$$$ for the website alone ($300–$600). $79 sits between Joy's annualized $180ish and Zola's $0-but-with-ads, and undercuts Riley & Grey hard.
- One-time pricing matches the customer's mental model. Couples hate the idea of "another subscription," especially for something they'll use for 6–12 months and abandon. Selling a one-time unlock is honest and converts better than a subscription you have to remember to cancel.
- The 30-guest free tier is wide enough for elopements, courthouse weddings, and intimate dinner-only weddings to actually use the product — which builds the SEO and word-of-mouth flywheel — but narrow enough that any "real" wedding hits the paywall.

**Where the money actually comes from in year 1:** assume 200 couples sign up, 10% convert to Pro at $79 → $1,580. Realistic, not exciting. The freemium model is a flywheel, not a salary. Solo-builder side income for year one. Year 2 with SEO compounding could be 10x.

### Option C — One-time paid only ($X flat per wedding)

| Plan | Price | Included | Excluded |
|------|-------|----------|----------|
| **Plusone** | **$49 one-time, per wedding** | Everything. No tiers. | — |

**Why this could work:** simple, no decision fatigue, no "is this in my plan?" support tickets, no free-tier abuse. Wedding industry buyers respond well to "one price, all features." Compare to Wedding Wire / Wedding Spot's confusing tier sprawl.

**Why it might not:** no free tier means no SEO entry point ("free wedding planner" is a high-volume keyword and you can't rank for it if you have no free product), and zero growth without paid acquisition or virality. Solo founder with no marketing budget will struggle.

### Recommendation

Ship **Option B (freemium, $79 Pro)** at commercial launch. Concrete reasons:

1. The 30-guest free tier lets you rank for "free wedding planner" and capture word-of-mouth without the product feeling crippled.
2. $79 one-time is high enough to be a real revenue line, low enough that a couple doesn't shop competitors before buying.
3. One-time vs. subscription removes the cancellation-flow tax (solo founders waste weeks on Stripe subscription edge cases).
4. The custom-domain upsell ($129) catches the 10% of couples who care about brand and are willing to pay 60% more for one feature.
5. You can A/B test moving the free-tier guest limit (30 / 50 / 75) post-launch without touching the rest of the model.

Defer the vendor-marketplace cut and "Powered by" footer-removal microtransaction to Phase 3 once there's enough traffic to make either worth the build.

---

## 4. Top 3 differentiators (above the fold)

The landing page hero needs to answer "why not Joy / Zola / The Knot?" in five seconds. Pick three; here are the three:

### 1. "Your guests get a real app, not a website."
Joy and The Knot give guests a wedding *website* — basically a brochure. Plusone gives every guest a personal portal: their own RSVP per event, their own schedule with dress codes, real push alerts when the venue changes at 2pm Saturday. This is the differentiator. It's also what the user already built — the guest portal IS the product moat. Hero asset: a phone mockup, lock-screen push notification "Sangeet starts in 2 hours — Hyatt ballroom, parking on 4th floor."

### 2. "Built for one ceremony or seven."
Multi-event support is first-class, not bolted on. Indian weddings have 4–7 events, modern Western weddings often have rehearsal dinner + welcome drinks + ceremony + reception + brunch (4–5 events). Joy / Zola assume one ceremony and treat multi-event as an edit-fields-manually afterthought. Plusone treats every event as a first-class object with its own RSVPs, dress code, venue, parking. Hero asset: a per-guest schedule view where Aunt Priya is going to 5 events and Coworker Dan is only going to the reception.

### 3. "One $79 charge. No 'upgrade for that.'"
Wedding software pricing is genuinely confusing — Zola monetizes registry, The Knot monetizes vendor leads, Joy paywalls custom domains and push notifications. Plusone is one number, one purchase, every feature unlocked. Hero asset: a literal pricing table with two rows (Free / $79) instead of the 4-column SaaS matrix every competitor uses.

Why these three and not "custom themes" or "vendor manager" or "budget tracker": every competitor has those. They don't differentiate. Above the fold is for the things that make a couple actually switch.

---

## 5. Launch plan — first 30/60/90 days

Assume launch = the day after Aravind's wedding (Feb 13, 2027) — meaning the product is battle-tested on a real wedding with real guests by launch day, and you have authentic wedding photos + screenshots from your own use to put on the landing page.

### Days 0–30: testimonial harvest + private launch

**Goal:** convert Aravind's wedding into 5 unsolicited testimonials and 1 case study.

- Week 1: while your wedding is fresh, ask 10 guests for a one-paragraph testimonial about using the guest portal. Don't ask "did you like it" — ask "what was the moment you actually used it?" Specific quotes convert. Put the 5 best on the landing page with first name + photo (with permission).
- Week 2: write a public case study — "How we ran a 5-day, 200-guest wedding with one tool we built ourselves." Title is the SEO play. Publish on a `/case-study/our-wedding` URL with the real numbers (events, RSVPs, alerts sent, push-open rate).
- Week 3: open signups but don't announce broadly yet. Tell 20 people directly: friends getting married, friends-of-friends, anyone who saw your wedding portal as a guest. Ask them to use it and tell you what breaks.
- Week 4: post the case study to r/weddingplanning, r/IndianWeddings, r/weddingsunder10k. Cross-post the same week. *Do not pitch the product in the post.* Title: "We built our own wedding planner because [Joy / Zola] didn't do X — here's what we learned." Soft-mention the URL in a comment when asked. Don't astroturf — actually answer questions about the wedding.

**Channels to ignore in month 1:** Twitter/X (no wedding audience), TikTok (wrong content type for a solo founder, takes months to build), paid ads (waste).

### Days 31–60: SEO foundation + Reddit cadence

**Goal:** rank for 3 long-tail keywords by day 90; reach 30 signups.

- Pick 3 long-tail SEO keywords with low competition and clear intent. Examples: "multi-day wedding planner app," "guest portal for indian wedding," "wedding planner without subscription." Write one in-depth article per keyword (1500+ words, real examples, embedded screenshots of Plusone). Aim for one article per 2 weeks.
- Reddit cadence: post a substantive comment (not promo) in r/weddingplanning, r/IndianWeddings, r/weddingsunder10k 2x/week. When someone asks for tool recommendations, mention Plusone *with* one or two alternatives — don't be the guy who only ever recommends his own product. Track which posts drive signups via a UTM tag.
- Outreach: email 10 wedding bloggers / Instagram wedding planners with the case study link. No pitch. Just "thought you'd find this useful." 1–2 will write about it.
- Set up a "How was Plusone?" email 7 days post-wedding for every couple that uses the product. Use the replies as testimonials.

**Channels to ignore in month 2:** Product Hunt (wedding products don't perform there; audience is wrong), Hacker News (same), influencer partnerships (you can't afford them yet).

### Days 61–90: referral loop + first paid conversion push

**Goal:** 100 signups, 10 paying customers, 1 referral loop live.

- Build a "refer a friend, get a free domain" referral mechanic. Couples who refer another couple that signs up get their custom-domain upgrade ($129 tier) for free. Wedding people know other wedding people; the time-shifted virality is real.
- Email the 30 day 30 signups: "you're 3 weeks from your wedding — here's a checklist of what to send your guests." Soft CTA to upgrade to Pro for push alerts. Wedding urgency converts.
- Reach out to one wedding-industry adjacent newsletter (e.g., a wedding planner's substack, a wedding photographer's mailing list) and offer them a guest post — "5 tools that saved my couple's wedding." Plusone is one of them, alongside genuinely useful non-competing tools (florist apps, etc.).
- Publish a `/comparison/joy-vs-plusone` page. Honest table, includes things Joy does better. Honesty converts; competitive pages rank.

### What "success at day 90" looks like

- 100 signups total
- 10 Pro conversions ($790 revenue — not life-changing, but real)
- 1 article ranking in Google top 20 for a long-tail keyword
- 3 unsolicited DMs/emails from couples saying "this is better than Joy"
- A repeatable Reddit + blog motion that runs 2 hours/week

If the numbers are 10x lower, the problem is the product (or the wedge), not the marketing. If the numbers are 10x higher, hire help — solo doesn't scale past ~200 customers without burnout.

---

## 6. Risks and unknowns

Honest list. Some of these could kill the product; he should validate as many as possible *before* sinking another six months in.

### Risks that could kill it

1. **The one-shot purchase problem.** A wedding planner serves a customer for ~12 months then they're gone forever. There's no LTV expansion, no upsell-in-year-2. This means CAC has to be near zero. If organic doesn't work, the unit economics never close — there's no version of this business that survives paid acquisition. Validate before Phase 3: can he get 50 signups/month with zero ad spend by month 6? If no, this is a hobby, not a business.

2. **Joy / Zola can copy the guest portal in a quarter.** The moat is execution and mobile-first design, not technology. They have engineering teams. If Plusone shows traction, expect a "Joy Guest App" announcement within 6 months. Defense: ship faster, own a niche they won't (multi-day / Indian / multi-cultural weddings), build a brand that means something to a specific group.

3. **The "boyfriend builds wife a wedding app" perception.** Solo founder + wedding product + own-wedding case study has charm in indie circles, but to a stressed bride-to-be in Texas comparing 5 tools at 11pm, "built by a guy for his own wedding" may register as "hobby project, will it still work in 6 months?" Mitigate with social proof (testimonials, real case studies from other weddings), uptime page, response-time guarantees in the help section.

4. **Two-sided cultural fit is hard.** Indian weddings and Western weddings have genuinely different planning cultures. Aravind is Indian, the dogfooding wedding is Indian, the first 20 testimonials will be Indian. The product will pattern-match as "Indian wedding software" in the market's eyes, which is either a wedge (good) or a ceiling (bad). Decide explicitly which it is by month 3.

5. **Push notifications on iOS are flaky.** Web Push on iOS requires "Add to Home Screen" first — a step 80% of guests will not do. The "real-time alerts" pitch may not survive contact with reality. Validate at his own wedding: what % of iOS guests actually receive a push? If < 30%, demote alerts from a top-3 differentiator to a feature.

6. **Trademark fights.** "The Knot" lawyers will scrutinize any knot-adjacent name. If you pick Knotted or Tied, get a 30-minute trademark consult ($300) before sinking money into a domain.

7. **The dogfooding wedding underperforms.** If Aravind's own guests don't actively use the portal — RSVP rate <70%, push opt-in <20%, return visits <50% — the product hasn't proven its core thesis. Decide *now* what metrics from his own wedding would constitute "this didn't work" so the call is made cleanly, not emotionally, in March 2027.

### Unknowns worth validating before Phase 2 build

- **Will couples actually pay $79 one-time?** Run a fake-door test by mid-2026: a landing page with the pricing live, "join waitlist" → "pay $9 now to lock in $79 launch pricing." If 0 people pay $9, $79 won't sell either.
- **Do guests prefer a portal over WhatsApp/iMessage groups?** This is the *real* competitor, not Joy. Indian families especially run weddings on WhatsApp. Plusone has to be enough better that the bride is willing to fight her mom over which tool to use.
- **What's the channel that actually works?** Reddit, SEO, Instagram, wedding-planner referrals — assume one is 10x the others. Run all four in months 1–3 with UTMs, then cut the bottom three by month 4.
- **Custom domains: feature or distraction?** Connecting a custom domain is a support-load nightmare for a solo founder (DNS issues, SSL renewal). If <5% of paying customers buy the $129 tier, kill the feature, refund those few, save the support time.

### What he should NOT worry about yet

- Stripe complexity (one-time payments are easy; subscriptions are the hard part — and the recommended pricing avoids them)
- Multi-language i18n (English-only is fine for v1; Indian and Western anglophone weddings are the same English market)
- Mobile native apps (the PWA / mobile-web guest portal is the right call; native iOS/Android is 6 months of work for a marginal UX improvement)
- White-label / planner-reseller version (interesting Phase 3 idea — wedding planners pay $X to use Plusone as their client-facing tool. Park it.)

---

## Summary card

- **Name:** Plusone (fallback: Tied). Buy `.app` or `.wedding`; don't fight for `.com`.
- **Positioning:** Guest-experience-first wedding planner. Phone-first portal is the wedge.
- **Pricing:** Freemium. Free up to 30 guests / 1 event. Pro $79 one-time per wedding. Pro+Domain $129 one-time.
- **Above-the-fold trio:** (1) Guests get a real app. (2) Built for one ceremony or seven. (3) One price, no upgrades.
- **First 90 days:** Convert own-wedding into case study + testimonials → SEO + Reddit cadence → referral loop. Target 100 signups, 10 Pro at day 90.
- **Biggest risk:** one-shot purchase economics. If organic CAC doesn't trend toward zero by month 6, the business model doesn't exist. Validate before scaling.
