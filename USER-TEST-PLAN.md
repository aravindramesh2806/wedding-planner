# Wedding Planner — User Test Plan (Phase 1)

**Goal:** Find out what real guests actually do (and where they get stuck) before
we build more features. We're testing the guest portal end-to-end.

**Test couple:** Aanya & Vihaan (already populated with realistic data).
**Test URL to share:** https://aravindramesh2806.github.io/wedding-planner/#guestlogin-aanya-vihaan

---

## Part A — You (Aravind), on your phone

**Time:** 15 minutes. **Device:** Your iPhone, NOT desktop. Open in Safari.

Pretend you're "Priya Sharma" — first name `Priya`, phone last 4 digits `3210`.
She's already in Aanya & Vihaan's guest list.

Walk through these scenarios. **At every step, write down the seconds it took
and any moment you paused, second-guessed, or felt friction.**

1. **Tap the URL** — does it open cleanly? Anything confusing?
2. **Sign up** — what do you fill in? Any field unclear? Did it accept you?
3. **Land in the portal** — first impression, 3 seconds. What do you see?
   Where do your eyes go first?
4. **Find the wedding date** — how long does it take?
5. **Find where the ceremony is** — the venue is hidden until Nov 15. Does the
   message make sense? Frustrating or fine?
6. **RSVP yes to Mehndi with 1 plus-one** — how many taps? Anything weird?
7. **Tap "Add to calendar" on Sangeet** — does it work? What happens?
8. **Open Maps for the Reception venue** — easy to find?
9. **Read the "Know" tab** — useful content? Or empty?
10. **Send yourself out** — find the sign-out. Was it obvious or hidden?

---

## Part B — 3 friends, 10 min each

**Pick three:**
- 1 tech-savvy (your benchmark — they should breeze through)
- 1 medium (a friend who uses WhatsApp daily, nothing more)
- 1 your parents' generation (a relative who finds tech annoying)

**For each:**

1. **WhatsApp them:** *"Hey, can you help me test something for 10 min? Open this
   link and pretend you're invited to a wedding. Just go through whatever you'd
   normally do. Don't tell me what you're doing — I'll watch."*
2. **The URL:** https://aravindramesh2806.github.io/wedding-planner/#guestlogin-aanya-vihaan
3. **Give them a fake identity:**
   - Tech friend: first name `Vikram`, phone `+91 99988 11122` (auto-approves)
   - Medium friend: first name `Anjali`, phone `+91 99876 54321` (auto-approves)
   - Older relative: first name `Karthik`, phone `+91 66666 44444` (auto-approves)
4. **Either screen-share or just watch them.** Don't help. Don't explain.
   When they get stuck, just say "what are you trying to do?"
5. **After 10 min, ask:**
   - What was confusing?
   - Did anything feel slow or broken?
   - Would you actually use this if a friend sent you this link?
   - What did you expect to see that wasn't there?
   - On a scale of 1-10, how likely are you to recommend this to a couple
     planning their wedding?

---

## Part C — Capture findings

For each test, fill in this template:

```
Tester: [name / role]
Device: [iPhone 14 Safari / Android Chrome / etc]
Total time on portal: __ min

🔴 Broken — things that didn't work:
-

🟡 Friction — things they paused or second-guessed:
-

🟢 Worked well — things they used without thinking:
-

💡 Asked-for — things they expected that weren't there:
-

Final rating (1-10):
Would they recommend to a couple? Y/N
```

---

## Part D — After all 4 tests, prioritize

Group findings into:

1. **🔴 Must fix before Aravind's wedding** — anything that broke or majorly confused
2. **🟡 Should fix for Phase 2 (commercial)** — friction that's tolerable for known users
   but would lose customers
3. **💡 Net new features people asked for** — add to roadmap, decide priority

Pick the top 3 from category 1 → that's our next sprint.

---

## What I (Claude) will do with the findings

Paste each tester's filled-in template into the next chat. I'll:
- Bucket the findings
- Flag any pattern that came up >1 time (those are real signals)
- Suggest fixes ranked by impact / effort
- Update PRODUCT-DIRECTION.md with what we learned

