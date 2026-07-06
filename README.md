# Aphrodite Research

An educational evidence archive for peptides and research compounds. Dark, editorial,
mystique-forward design; clarity-first content. Translates the published research into
what people can actually understand — what's proven, what's promising, what's hype.

**Positioning:** *Peptide science, decoded.* Human evidence separated from animal data,
every claim traced to its source, evidence broken out by outcome and route.

## The product loop
**Paste a claim → receive a cited Evidence Receipt → save/follow it → return when it changes.**
`ask.html` ("Ask Aphrodite") is the single surface for this loop — a terminal-style
Evidence Receipt powered by `/api/ask`. Everything else (dossiers, Hype Gap, Compare,
Archive) is a *destination reached from a receipt*.

## Pages
| File | Purpose |
|---|---|
| `index.html` | The Gate — atmospheric entrance (cipher-rain, "Enter the Archive") |
| `home.html` | Homepage — one primary action ("Paste a peptide claim"), demoted secondary entries |
| `ask.html` | **Ask Aphrodite** — paste a claim → cited Evidence Receipt (terminal console). Calls `/api/ask` |
| `lens.html` | Redirect → `ask.html` (the Lens was merged into Ask Aphrodite) |
| `library.html` | Your Library — saved & followed claims/compounds (Supabase Auth) |
| `archive.html` | The Archive — compound library, upgrade card |
| `retatrutide.html` | Compound dossier — Evidence Score, badges, internet-vs-research |
| `ghk-cu.html` | Compound dossier — evidence-by-outcome, Claim Gap, Route Integrity (the model) |
| `deepdive.html` | Paid deep-dive — full synthesis, comparison table, ledger, timeline |
| `methodology.html` | Evidence Methodology — how the Evidence Score works |
| `pricing.html` | Membership — Visitor (free) vs Initiate ($4.99/mo · $39/yr) |
| `account.html` | Access — Supabase Auth (sign in / create account) |
| `legal-*.html` | Disclaimer, Terms, Acceptable Use |

## Backend (`/api` + Supabase)
| Path | Purpose |
|---|---|
| `api/ask.js` | The loop: validate → safety gate → retrieve → insufficient gate → grounded model → citation validation → log |
| `api/public-config.js` | Browser-safe Supabase config (anon key; RLS enforces access) |
| `api/stats.js` | Aggregate-only analytics (asks/saves/follows) |
| `api/_lib/*` | supabase client · safety gate · retrieval · receipt assembly · model |
| `supabase/migrations/*` | 14-table schema + RLS + profile trigger |
| `supabase/seed.sql` | 12 compounds + ~49 claims, **all `unverified`** |
| `assets/aphrodite.js` | Shared browser client: ask() · auth · save/follow · library |

- **The database is the source of truth.** The model may only phrase what records contain;
  every factual sentence is citation-validated server-side, and no dose ever leaks.
- Secrets (`SUPABASE_SERVICE_ROLE_KEY`, `ANTHROPIC_API_KEY`) live only in `/api`.
- The static site works with **no backend** via a labelled local fallback library.

## Assets & docs
- `docs/API.md` — the `/api/ask` contract, routes, and honesty guarantees
- `docs/SETUP.md` — local dev + Supabase + deploy, step by step
- `docs/ASK-APHRODITE-SPEC.md` — the RAG + safety-gate design this build implements
- `docs/intake-template.md` — fill one per compound to produce a full entry
- `docs/MEMBERSHIP-SPEC.md` — spec for the payment/paywall backend (separate from Ask)
- `.env.example` — required environment variables
- `legal/*.md` — source markdown for the legal pages

## Flow
`index (gate)` → `home` → **`ask` (paste a claim → receipt)** → `retatrutide` / `ghk-cu`
dossiers · `library`; `archive`, `hype-gap`, `compare`, `methodology`, `pricing`,
`account`, legal pages all linked.

## Deploy
Static pages + Vercel serverless `/api`. Push to GitHub, import into Vercel, set env vars,
deploy. See `docs/SETUP.md` and `DEPLOY-CHECKLIST.md`.

## Status — read this
The front-end is complete and the **Phase-1 evidence loop is built**: `/api/ask`, the
Supabase schema + RLS, seed data, auth, save/follow, and the Library all exist as code.
To go live you must **provision Supabase + set env vars** (see `docs/SETUP.md`); until
then the site runs read-only on its local fallback library.

The paywall/membership remains a **visual demonstration** (separate backend —
`docs/MEMBERSHIP-SPEC.md`). All seeded evidence is `unverified` and flagged **pending
verification** — figures need human confirmation against the primary literature before
any record is marked `reviewed`.

**Educational resource. Not for human or veterinary use. No compounds are sold, and no
dosing or sourcing information is provided.**
