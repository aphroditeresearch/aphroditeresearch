# MEMBERSHIP BACKEND SPEC

*This document describes the system that turns the current static front-end into a
real membership product that takes payment and gates content. The account/sign-in
page references this spec. None of this is built yet — the pages you have are the
polished shell. This is the map for building the engine.*

---

## What exists now vs. what this spec covers

**Exists (static, deployed):** every page's design and content — the gate, homepage,
archive, compound dossiers, deep-dives, methodology, pricing, and the sign-in *design*.
Anyone can currently reach every page, including deep-dives. There is no real login,
no payment, and no gating.

**This spec covers:** accounts, secure login, subscription payment, and actually
restricting deep-dive/member content to paying members.

---

## Recommended stack

The current site is static HTML. To add membership you convert it into an application.
The lowest-friction path that fits what's already built:

- **Framework:** Next.js (React). Vercel is built for it, so deployment stays familiar.
  The existing HTML/CSS ports over as components with little visual change.
- **Auth:** Clerk or Supabase Auth. Handles sign-up, login, OAuth (Google/Apple),
  password resets, and sessions — so you don't build security-critical code yourself.
- **Payments:** Stripe, using Stripe Checkout + the customer billing portal and a
  webhook. Products: Initiate monthly ($4.99) and annual ($39).
- **Database:** Supabase (Postgres) or similar. Stores users and their subscription state.

## Data model (minimum)

```
users
  id, email, created_at, auth_provider
subscriptions
  user_id, stripe_customer_id, stripe_subscription_id,
  status (active | canceled | past_due), plan (monthly | annual),
  current_period_end
```

Content itself (compounds, dossiers) can stay as files/pages initially; only the
*gate* around member content needs the DB.

## Core flows

1. **Sign up / sign in** — Clerk/Supabase handles it; the existing `account.html`
   design becomes the styled auth screen.
2. **Subscribe** — "Become an Initiate" → Stripe Checkout → on success, Stripe fires a
   webhook → your server records an `active` subscription for that user.
3. **Gate content** — deep-dive pages check server-side: is the logged-in user's
   subscription `active`? If yes, render the full deep-dive. If no, render the
   locked preview (the design already exists) with the upgrade CTA.
4. **Manage / cancel** — link members to the Stripe billing portal; Stripe handles
   cancellation and card updates and keeps your DB in sync via webhooks.

## The gating rule (important)

Gating must happen **server-side**, not by hiding elements with CSS/JS. If the full
content is in the page and merely visually blurred, anyone can view source and read it.
The deep-dive content must not be sent to the browser at all unless the server has
confirmed an active subscription. The current blurred preview is a *design* of the
locked state — the real version renders the preview for non-members and never ships
them the full text.

## What must stay free (do not gate)

Per our own methodology and for trust + compliance, never paywall:
- Regulatory status and "not approved" flags
- Major safety warnings and Route Integrity notices
- The basic verdict, Evidence Score, and Claim Gap
- Whether meaningful human evidence exists

Members pay for depth and monitoring, never for basic safety information.

## Rough build order

1. Port the static pages into a Next.js app (visual parity — no redesign).
2. Add auth (Clerk/Supabase). Sign-in page works for real.
3. Add Stripe Checkout + webhook; record subscriptions in the DB.
4. Implement server-side gating on deep-dive routes.
5. Add the Stripe billing portal for self-serve cancel/manage.
6. Then build the retention features (Research Watch, watchlists, weekly digest),
   which also need the DB.

## Honest scope note

This is a real software project, not a settings toggle. It's very achievable with the
tools above, but it needs either time to learn the stack or a developer. The value is
that the entire design, content model, and compliance logic are already worked out —
which is the expensive, ambiguous part. A developer can build against this spec and the
existing pages directly.
