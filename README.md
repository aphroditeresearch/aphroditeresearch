# Aphrodite Research

An educational evidence archive for peptides and research compounds. Dark, editorial,
mystique-forward design; clarity-first content. Translates the published research into
what people can actually understand — what's proven, what's promising, what's hype.

**Positioning:** *Peptide science, decoded.* Human evidence separated from animal data,
every claim traced to its source, evidence broken out by outcome and route.

## Pages
| File | Purpose |
|---|---|
| `index.html` | The Gate — atmospheric entrance (cipher-rain, "Enter the Archive") |
| `home.html` | Homepage — hero, search, browse by interest, trending cards, reality check |
| `archive.html` | The Archive — compound library, upgrade card |
| `retatrutide.html` | Compound dossier — Evidence Score, badges, internet-vs-research |
| `ghk-cu.html` | Compound dossier — evidence-by-outcome, Claim Gap, Route Integrity (the model) |
| `deepdive.html` | Paid deep-dive — full synthesis, comparison table, ledger, timeline |
| `methodology.html` | Evidence Methodology — how the Evidence Score works |
| `pricing.html` | Membership — Visitor (free) vs Initiate ($4.99/mo · $39/yr) |
| `account.html` | Sign-in design (needs backend — see docs/MEMBERSHIP-SPEC.md) |
| `legal-*.html` | Disclaimer, Terms, Acceptable Use |

## Assets & docs
- `assets/monogram.svg` — the AR monogram logo (crest + interlocked A·R + diamonds)
- `docs/intake-template.md` — fill one per compound to produce a full entry
- `docs/MEMBERSHIP-SPEC.md` — spec for the auth + Stripe + DB backend
- `legal/*.md` — source markdown for the legal pages

## Flow
`index (gate)` → `home` → `archive` → `retatrutide` / `ghk-cu` → `deepdive`;
`methodology`, `pricing` → `account`, legal pages all linked. All 12 pages verified.

## Deploy
Static site. Push to GitHub, import into Vercel, deploy. See `DEPLOY-CHECKLIST.md`.

## Status — read this
The site is a complete, polished **front-end**. The paywall is a **visual demonstration**:
there is no login, no payment, and no real gating yet — anyone can reach the deep-dives.
Making it take money is a separate backend build documented in `docs/MEMBERSHIP-SPEC.md`.
Content figures (evidence levels, paper counts) are reasoned from real sources but need
final human verification against the primary literature before launch.

**Educational resource. Not for human or veterinary use. No compounds are sold, and no
dosing or sourcing information is provided.**
