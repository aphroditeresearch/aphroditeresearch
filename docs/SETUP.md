# Setup — local dev & deploy

Aphrodite is a static site **plus** a small serverless backend (`/api`) backed by
Supabase (Postgres + Auth + RLS) and Anthropic. The static pages work with **no backend**
(local fallback library); the backend turns the loop into the real, logged, account-aware
product.

---

## 0. Prerequisites
- Node 20+
- A [Supabase](https://supabase.com) project (free tier is fine)
- The [Supabase CLI](https://supabase.com/docs/guides/cli) (`npm i -g supabase`) — optional
  but the easiest way to run migrations + seed
- An [Anthropic API key](https://console.anthropic.com) (optional — see step 4)
- [Vercel](https://vercel.com) account for deploy

## 1. Install
```bash
npm install
cp .env.example .env.local   # fill in the values from steps 2–4
```

## 2. Create the Supabase project & run migrations
From the Supabase dashboard, create a project, then grab **Project Settings → API**:
`Project URL`, `anon` key, and `service_role` key.

Apply the schema, RLS, and seed:
```bash
# Option A — Supabase CLI (recommended)
supabase link --project-ref YOUR_REF
supabase db push          # runs supabase/migrations/*.sql
psql "$SUPABASE_DB_URL" -f supabase/seed.sql   # or paste seed.sql into the SQL editor

# Option B — dashboard
# Paste each file in supabase/migrations/*.sql (in order), then supabase/seed.sql,
# into the SQL editor and run them.
```
This creates the 14 tables, enables RLS, adds the profile-on-signup trigger, and seeds
**12 compounds + ~49 claims — all `review_status = 'unverified'`** (see the SEED HONESTY
note below).

## 3. Auth settings
In **Authentication → Providers**, enable **Email**. For local testing you can turn off
"Confirm email" so sign-ups are immediately usable; leave it on for production. The
`profiles` row is created automatically on sign-up by the `handle_new_user` trigger.

## 4. Anthropic (optional at first)
The full loop — safety gate, retrieval, receipt, logging — runs **without** a model key.
Set `ASK_MODEL_DISABLED=true` (or just leave `ANTHROPIC_API_KEY` empty) and `/api/ask`
returns a deterministic receipt straight from the DB records (`answer_source:"record"`).

When ready, set `ANTHROPIC_API_KEY` and `ASK_MODEL_DISABLED=false`. `ANTHROPIC_MODEL`
defaults to a current, capable Claude model; override if needed. The model only ever
rephrases retrieved records and every sentence is citation-validated server-side.

## 5. Run locally
```bash
npm run dev        # vercel dev — serves static pages + /api functions on one origin
```
Open http://localhost:3000/ask. The status pill reads **live · database** when the
backend answers, or **offline preview · local library** otherwise.

Smoke test:
- `"Does GHK-Cu regrow hair?"` → Evidence Receipt (verdict + sources + pending flag)
- `"How much BPC-157 should I take?"` → **Dosing request declined**
- `"where to buy retatrutide"` → **Sourcing request declined**
- `"is xyzabc proven?"` → **Not enough reviewed evidence yet**

## 6. Deploy (Vercel)
1. Import the repo into Vercel.
2. **Settings → Environment Variables** — add all keys from `.env.example`
   (`SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, `ANTHROPIC_API_KEY`,
   `ANTHROPIC_MODEL`, `ASK_MODEL_DISABLED`). Mark the service-role and Anthropic keys as
   **not** exposed to the browser (they're only read by `/api`).
3. Deploy. `vercel.json` keeps `cleanUrls`; `/api/*.js` deploy as Node functions.
4. In Supabase **Authentication → URL Configuration**, add your production domain to the
   allowed redirect/site URLs.

---

## SEED HONESTY (important)
Nothing is seeded as `reviewed`. Every seeded record is `unverified` (or `needs_sources`)
and the receipt visibly flags it **pending verification**. A record becomes `reviewed`
only after a human confirms its sources against the primary literature and sets
`review_status='reviewed'`, `reviewed_at`, and `reviewer`. Unverified records are still
retrieved — they're just labelled honestly.

## Phase 2 (stubbed, not wired)
`scripts/fetch-research-updates.mjs` documents the ClinicalTrials.gov / openFDA ingestion
into `research_updates`. It performs **no** network calls or writes yet — live ingestion is
a Phase-2 task and every update must pass human review before becoming a record.

## Security notes
- `SUPABASE_SERVICE_ROLE_KEY` and `ANTHROPIC_API_KEY` are **server-only**. They never
  appear in HTML or client JS. The browser gets the anon key via `/api/public-config`.
- RLS is enforced on all user tables (`profiles`, `saved_*`, `followed_*`, `query_logs`):
  a user can only read/write their own rows. Reference tables are world-read, service-role-write.
