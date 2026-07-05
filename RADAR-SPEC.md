# APHRODITE RADAR — Automation Spec

*How Dispatches gets fed automatically. Radar is the engine; Dispatches (in the Archive)
is the window it publishes into. This is the blueprint for the "always fresh, minimal
work from you" system — built the honest way that keeps Aphrodite's credibility intact.*

---

## The one rule that makes or breaks this

**Automation finds changes. A human approves conclusions.**

Aphrodite's entire value is cutting the BS that unsupervised AI and hype merchants
spread. An AI that auto-publishes evidence verdicts with nobody checking them will
eventually hallucinate a fake trial, misread an animal study as human, or invent a
citation — and the first time someone catches it, the credibility that is your *only*
moat is gone. So Radar automates the 90% that's safe (watching, drafting, flagging) and
puts a human gate on the 10% that isn't (publishing a conclusion). That gate can be ~15
minutes a week. It cannot be zero.

This isn't a limitation on the ambition — it's the thing that lets Aphrodite *be*
ambitious. Fully-automatic peptide sites already exist by the hundred; they're the slop
you're beating.

---

## What Radar watches (the data sources — all free, all real)

| Source | API | What it catches |
|---|---|---|
| **PubMed / NCBI** | E-utilities (esearch/efetch) | New papers, reviews, retractions on tracked compounds |
| **ClinicalTrials.gov** | Data API v2 | New trials, status changes, posted results |
| **openFDA** | drug/label + drug/event | Label changes, adverse-event reports, warning letters |
| **FDA advisory calendars** | scrape/RSS | Compounding committee meetings (e.g. the Jul 2026 BPC-157/TB-500 review) |
| **UniProt / ChEBI** | REST | Canonical compound identity, aliases, "is X the same as Y" |

Each tracked compound (BPC-157, GHK-Cu, Retatrutide, etc.) has a watch profile: its
names/aliases, relevant MeSH terms, and trial IDs. Radar polls on a schedule (daily for
trials/FDA, weekly for literature).

## The pipeline

```
1. WATCH      Poll each source for changes since last run (per compound)
        ↓
2. DEDUPE     Drop anything already seen; keep genuinely new items
        ↓
3. DRAFT      AI writes a plain-language Dispatch draft in the Aphrodite voice:
              — what changed (headline)
              — the one-line evidence read (what it means)
              — category tag + date + source link
              — FLAGS: "may change the [compound] verdict" if relevant
        ↓
4. QUEUE      Draft lands in an admin review queue (not public)
        ↓
5. APPROVE    Human reviews: accurate? correctly framed? human-vs-animal right?
              — Approve  → publishes into Dispatches (+ Radar alert to watchers)
              — Edit     → fix wording, then publish
              — Reject   → discard
        ↓
6. PUBLISH    Appears in the Archive's Dispatches list and (later) triggers
              watchlist alerts + the weekly Intelligence Brief
```

## What auto-updates vs. what you rubber-stamp

**Fully automatic (no human):**
- Detecting new papers/trials/FDA changes
- Drafting the summary
- Flagging which existing verdict *might* be affected
- Sorting the queue by importance

**Human gate (you or a reviewer, ~15 min/week):**
- Approving any Dispatch before it goes public
- Approving any change to a compound's Evidence Score or verdict
- Anything touching safety

Never let step 5 be skipped. A wrong auto-published verdict costs more than a hundred
missed updates.

## How it connects to what's already built

- **Dispatches** (Archive sidebar) — the publish target. Already styled; Radar fills it.
- **Evidence Passports** (compound pages) — when Radar flags "verdict may change," an
  approved update revises the page + adds a Change Log entry (trust signal).
- **Hype Gap Index** — Radar can nudge the evidence score as data matures, closing a gap.
- **Aphrodite Lens** — new reviewed items expand the claim library the Lens answers from.
- **Weekly Intelligence Brief** — the approved Dispatches of the week, compiled.

## Build requirements (this is the backend phase)

Radar cannot run from static HTML. It needs:
- A server/cron layer (Next.js API routes + a scheduler, or serverless cron on Vercel)
- A database (Supabase/Postgres) for: tracked compounds, seen-items log, draft queue,
  published dispatches, change log
- An AI drafting call (any LLM API) constrained to *summarize the retrieved source only* —
  never to answer from general knowledge
- An admin review UI (the approval queue)
- API keys + polite rate-limit handling for each source

Rough order: (1) DB + watch profiles, (2) one source end-to-end (ClinicalTrials.gov is
cleanest), (3) AI draft + review queue, (4) publish-to-Dispatches, (5) add remaining
sources, (6) watchlist alerts + weekly brief.

## Honest scope

This is a real backend project, not a toggle — but it's very buildable, and the front-end
it feeds (Dispatches, Passports, Lens, Hype Gap) already exists. That's the expensive,
ambiguous part done. A developer can build Radar against this spec and wire it straight
into the current pages. The result is the thing you asked for: fresh, always-updated,
minimal work from you — done the way that keeps people trusting it.
