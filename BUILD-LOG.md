# APHRODITE RESEARCH — BUILD LOG

*The complete project record: what's built, the decisions behind it, what's next.*

## CONCEPT
Educational evidence archive for peptides and research compounds. Translates published
research into plain language — what's proven, promising, and hype. Model: Examine.com
(evidence-adjudicator, not promoter). Aesthetic: dark obsidian + antique gold, Greek
mythological mystique, "you've found something" entrance. Revenue: subscription
($4.99/mo, $39/yr). One platform, different depths — TikTok-curious to serious researcher.

## COMPLIANCE SPINE (non-negotiable)
Curate the PUBLIC, published record; report what research found. Never sell compounds,
give dosing, or provide sourcing. Mystique lives in the AESTHETIC, never in claims of
"secret/hidden data." Risks get equal-or-greater prominence than effects. Human vs.
animal evidence always separated. The translation/hype-vs-evidence angle is legally
SAFER (tempers claims). Route Integrity + Claim Gap reinforce this. Legal pages need
real attorney review before launch. Don't publicly claim "first ever" (Peptipedia, THPdb
exist) — use "the up-to-date, consumer-friendly one."

## WHAT'S BUILT (12 pages, all verified, logo on every page)
- **index.html** — the Gate: cipher-rain, new AR monogram, threshold-crossing animation
- **home.html** — homepage: "Peptide science, decoded" hero, search, 8 interest categories,
  trending cards (evidence badges + claim-gap meters), reality check, membership CTA
- **archive.html** — compound library grid, "Become an Initiate" upgrade card (desktop-fixed)
- **retatrutide.html** — dossier: Evidence Score (6 categories + verdict), research-stage
  badges, internet-vs-research block, real PubMed data (NEJM/Lancet/Nature Med, phase 3 TRIUMPH)
- **ghk-cu.html** — THE MODEL: evidence-by-outcome matrix (5 outcomes × route), per-outcome
  Claim Gap panels, Route Integrity warning, 10-second verdict, real GHK-Cu literature
- **deepdive.html** — paid experience: head-to-head table, study synthesis, human/animal
  ledger, safety timeline, open questions, citation ledger, sticky TOC
- **methodology.html** — how the Evidence Score works: 6 categories, 5 bands, process, limitations
- **pricing.html** — Visitor (free) vs Initiate tiers, honest positioning, FAQ
- **account.html** — sign-in design with explicit "needs backend" notice
- **legal-disclaimer / legal-terms / legal-acceptable-use.html** — styled from legal/*.md

## SIGNATURE FEATURES
- **Aphrodite Evidence Score** — 6 categories, plain-language verdict, on compound pages
- **Evidence-by-outcome** — evidence broken out by outcome AND route (not one global score)
- **Claim Gap** — hype vs. evidence, per claim, shareable
- **Route Integrity** — topical evidence ≠ injectable evidence warning
- **Research-stage badges** — instant evidence-status read
- **Internet-vs-research / Reality Check** — most shareable, harm-reduction

## LOGO
New AR monogram (`assets/monogram.svg`): sunburst crest, interlocked A·R ligature,
diamond flourishes top and bottom, gold gradient. Inlined as SVG on every page (nav-mark
in navs, ar-mark on the gate, cmark in the crossing animation, logo on the account card).
Note: rendered structurally-verified; eyeball the ligature curve and request a tweak if wanted.

## DESIGN SYSTEM (locked)
Colors: obsidian #08080b, gold #c9a35b / #e6c684, rose #c88a7d (risk), teal #8fc4b8
(evidence/positive), marble #efe9dc. Type: Cormorant (display), Jost (UI), Spectral (body).
Signatures: cipher-rain gate, gold ticker, ghosted numerals, grain overlay, sheen button.

## CONTENT PIPELINE
`docs/intake-template.md` — fill one per compound → full entry. Now includes evidence-by-
outcome, Claim Gap, and Route Integrity so every future compound inherits the model.
Rule: AI drafts, a HUMAN verifies every figure vs. the primary source before publishing.

### Launch cohort (depth over breadth, ~8–12 strong to start)
Retatrutide ✅ · GHK-Cu ✅ · then BPC-157 (extreme claim gap), Tesamorelin, PT-141,
Thymosin Beta-4/TB-500, CJC-1295/Ipamorelin, MOTS-c, Kisspeptin, Semax/Selank,
plus Semaglutide/Tirzepatide/Cagrilintide for breadth.

## NEXT BUILDS (priority)
1. **Deploy this fresh repo** (DEPLOY-CHECKLIST.md)
2. **Membership/payment backend** — the thing that makes money (docs/MEMBERSHIP-SPEC.md):
   Next.js + Clerk/Supabase auth + Stripe + DB + server-side gating
3. **More compound entries** — BPC-157 next, then the cohort, via the intake template
4. **Comparison tool** — side-by-side peptides (two real compounds now exist to compare)
5. **Research Watch / change alerts, watchlists, weekly digest** — retention (need backend)
6. **Ask Aphrodite** — curated-DB Q&A ("what did researchers study," never "what to take")
7. **Discord community** — big retention/growth, but biggest compliance risk: needs heavy
   moderation + acceptable-use enforcement FIRST (sourcing/dosing talk would undo compliance)

## HONEST STANDING NOTES
- Paywall is a VISUAL DEMO — no login/payment/gating yet. Don't collect money until backend exists.
- Evidence figures + paper counts are reasoned but need human verification vs. sources.
- Methodology page makes scoring a PROMISE — real scores must follow those criteria.
- Keep risks ≥ effects; keep human/animal + route splits explicit; no "secret" language.
- Attorney review of legal pages before real launch.
