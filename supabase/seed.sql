-- ═══════════════════════════════════════════════════════════════════════════
-- Aphrodite Research — seed
--
-- SEED HONESTY (non-negotiable): every record below is review_status
-- 'unverified' or 'needs_sources'. NOTHING is 'reviewed'. A record only
-- becomes 'reviewed' after a human confirms its sources against the primary
-- literature. These records may still be retrieved by /api/ask, but the
-- receipt visibly flags them as pending verification.
--
-- Content is derived from the existing site (lens.html LIBRARY, ask.html KB,
-- and the dossiers). Qualitative evidence levels only — no dosing, and no
-- numeric statistic appears without a backing source record.
--
-- Idempotent: safe to re-run (uses conflict guards on natural keys).
-- ═══════════════════════════════════════════════════════════════════════════

-- ─────────────────────────── COMPOUNDS ─────────────────────────────────────
insert into compounds (name, slug, class, summary, dossier_url) values
  ('BPC-157', 'bpc-157', 'Body-protective peptide',
   'A synthetic peptide studied extensively in animals for tissue and gut protection; robust controlled human evidence remains very limited.',
   'bpc-157.html'),
  ('GHK-Cu', 'ghk-cu', 'Copper peptide',
   'A copper-binding tripeptide with modest human research for topical skin appearance; systemic and injectable claims are largely unstudied.',
   'ghk-cu.html'),
  ('Retatrutide', 'retatrutide', 'Incretin — triple agonist',
   'An investigational GIP/GLP-1/glucagon receptor agonist with strong phase-2 weight-loss data; not yet approved.',
   'retatrutide.html'),
  ('Semaglutide', 'semaglutide', 'GLP-1 receptor agonist',
   'A GLP-1 receptor agonist approved for type-2 diabetes and weight management, supported by large randomized trials.',
   'compare.html'),
  ('Tirzepatide', 'tirzepatide', 'GIP/GLP-1 receptor agonist',
   'A dual GIP/GLP-1 receptor agonist approved for type-2 diabetes and weight management.',
   'compare.html'),
  ('TB-500', 'tb-500', 'Thymosin Beta-4 fragment',
   'A synthetic peptide fragment related to the natural protein Thymosin Beta-4; marketed for recovery with limited human evidence.',
   'archive.html'),
  ('MOTS-c', 'mots-c', 'Mitochondrial-derived peptide',
   'A mitochondrial-derived peptide studied in animals for metabolic and exercise-related effects; human evidence is very limited.',
   'archive.html'),
  ('Tesamorelin', 'tesamorelin', 'GHRH analog',
   'A growth-hormone-releasing-hormone analog approved to reduce excess visceral fat in HIV-associated lipodystrophy.',
   'archive.html'),
  ('Ipamorelin', 'ipamorelin', 'GH secretagogue',
   'A selective growth-hormone secretagogue studied mostly in preclinical models; not an approved therapy.',
   'archive.html'),
  ('CJC-1295', 'cjc-1295', 'GHRH analog',
   'A synthetic growth-hormone-releasing-hormone analog used in research; human clinical evidence for its marketed claims is limited.',
   'archive.html'),
  ('Bremelanotide', 'bremelanotide', 'Melanocortin receptor agonist',
   'A melanocortin-receptor agonist FDA-approved (Vyleesi) for hypoactive sexual desire disorder in premenopausal women. Also sold under the name PT-141.',
   'archive.html'),
  ('Melanotan II', 'melanotan-ii', 'Melanocortin receptor agonist',
   'An unapproved melanocortin agonist marketed for tanning and libido; sold without quality control and carrying notable safety concerns.',
   'archive.html')
on conflict (slug) do nothing;

-- ─────────────────────────── ALIASES ───────────────────────────────────────
insert into compound_aliases (compound_id, alias)
select c.id, a.alias from (values
  ('bpc-157','BPC157'), ('bpc-157','BPC 157'), ('bpc-157','body protection compound'),
  ('ghk-cu','GHK'), ('ghk-cu','GHK Cu'), ('ghk-cu','copper peptide'), ('ghk-cu','copper tripeptide'),
  ('retatrutide','reta'), ('retatrutide','LY3437943'), ('retatrutide','triple agonist'),
  ('semaglutide','ozempic'), ('semaglutide','wegovy'), ('semaglutide','sema'),
  ('tirzepatide','mounjaro'), ('tirzepatide','zepbound'), ('tirzepatide','tirz'),
  ('tb-500','TB500'), ('tb-500','TB 500'), ('tb-500','thymosin beta-4'), ('tb-500','thymosin beta 4'), ('tb-500','TB4'),
  ('mots-c','MOTSc'), ('mots-c','MOTS c'), ('mots-c','mitochondrial peptide'),
  ('tesamorelin','egrifta'),
  ('ipamorelin','ipam'),
  ('cjc-1295','CJC1295'), ('cjc-1295','CJC 1295'), ('cjc-1295','mod grf'),
  ('bremelanotide','PT-141'), ('bremelanotide','PT141'), ('bremelanotide','vyleesi'),
  ('melanotan-ii','MT-2'), ('melanotan-ii','MT2'), ('melanotan-ii','melanotan 2'), ('melanotan-ii','melanotan')
) as a(slug, alias)
join compounds c on c.slug = a.slug
on conflict do nothing;

-- ─────────────────────────── SOURCES ───────────────────────────────────────
-- (a) One internal review record per compound — the assessment basis for the
--     receipt's plain-language explanation. Clearly pending verification.
insert into sources (type, title, authors, year, url, quality_note)
select 'review',
       'Aphrodite internal review — ' || c.name,
       'Aphrodite Research', 2026, c.dossier_url,
       'Internal evidence review — pending primary-source verification.'
from compounds c
on conflict do nothing;

-- (b) A small set of genuinely real external sources for the well-evidenced
--     compounds. Still seeded as unlinked-until-reviewed provenance.
insert into sources (type, title, authors, year, url, registry_id, quality_note) values
  ('study',
   'Triple–Hormone-Receptor Agonist Retatrutide for Obesity — A Phase 2 Trial',
   'Jastreboff AM, et al. N Engl J Med', 2023,
   'https://www.nejm.org/doi/full/10.1056/NEJMoa2301972', 'NCT04881760',
   'Phase-2 RCT. Citation transcribed from public record; pending human verification.'),
  ('study',
   'Once-Weekly Semaglutide in Adults with Overweight or Obesity (STEP 1)',
   'Wilding JPH, et al. N Engl J Med', 2021,
   'https://www.nejm.org/doi/full/10.1056/NEJMoa2032183', 'NCT03548935',
   'Phase-3 RCT. Citation transcribed from public record; pending human verification.'),
  ('study',
   'Semaglutide and Cardiovascular Outcomes in Obesity without Diabetes (SELECT)',
   'Lincoff AM, et al. N Engl J Med', 2023,
   'https://www.nejm.org/doi/full/10.1056/NEJMoa2307563', 'NCT03574597',
   'Cardiovascular outcomes RCT. Citation transcribed from public record; pending verification.'),
  ('study',
   'Tirzepatide Once Weekly for the Treatment of Obesity (SURMOUNT-1)',
   'Jastreboff AM, et al. N Engl J Med', 2022,
   'https://www.nejm.org/doi/full/10.1056/NEJMoa2206038', 'NCT04184622',
   'Phase-3 RCT. Citation transcribed from public record; pending verification.'),
  ('label',
   'FDA approval — Vyleesi (bremelanotide) for HSDD in premenopausal women',
   'U.S. Food and Drug Administration', 2019,
   'https://www.accessdata.fda.gov/drugsatfda_docs/label/2019/210557s000lbl.pdf', null,
   'Regulatory approval record; pending verification.'),
  ('label',
   'FDA approval — Egrifta (tesamorelin) for HIV-associated lipodystrophy',
   'U.S. Food and Drug Administration', 2010,
   'https://www.accessdata.fda.gov/drugsatfda_docs/label/2014/022505s008lbl.pdf', null,
   'Regulatory approval record; pending verification.')
on conflict do nothing;

-- ─────────────────────────── STUDIES (structured) ──────────────────────────
insert into studies (source_id, design, population_n, is_human, notes)
select s.id, x.design, x.n, x.is_human, x.notes from (values
  ('Triple–Hormone-Receptor Agonist Retatrutide for Obesity — A Phase 2 Trial','Randomized controlled trial', 338, true, 'Phase 2, adults with obesity.'),
  ('Once-Weekly Semaglutide in Adults with Overweight or Obesity (STEP 1)','Randomized controlled trial', 1961, true, 'Phase 3, adults with overweight/obesity.'),
  ('Tirzepatide Once Weekly for the Treatment of Obesity (SURMOUNT-1)','Randomized controlled trial', 2539, true, 'Phase 3, adults with obesity.')
) as x(title, design, n, is_human, notes)
join sources s on s.title = x.title
on conflict do nothing;

insert into study_compounds (study_id, compound_id)
select st.id, c.id
from studies st
join sources s on s.id = st.source_id
join compounds c on (
  (s.title like '%Retatrutide%' and c.slug='retatrutide') or
  (s.title like '%Semaglutide%' and c.slug='semaglutide') or
  (s.title like '%Tirzepatide%' and c.slug='tirzepatide')
)
on conflict do nothing;

-- ─────────────────────────── CLAIMS ────────────────────────────────────────
-- Helper pattern: compound_id via slug subselect. All review_status default
-- 'unverified'. route_integrity uses the short token flags shown on the receipt.

-- BPC-157
insert into claims (compound_id, claim_text, outcome, implied_route, implied_population,
  human_evidence_level, preclinical_evidence_level, verdict, plain_language_explanation,
  critical_uncertainty, claim_gap, route_integrity) values
((select id from compounds where slug='bpc-157'),
 'BPC-157 rapidly heals tendon and soft-tissue injuries in humans.','tendon healing','injection','humans',
 'Very limited','Extensive','Not established in humans',
 'A large body of animal and cell research has explored BPC-157 in tissue repair, but robust controlled human trials showing it heals tendons are lacking.',
 'Nearly all evidence is animal or laboratory; route and formulation studied in animals may not translate to people.',
 'Extreme', array['ANIMAL-TO-HUMAN LEAP','LACK OF CONTROLLED HUMAN TRIALS','SAFETY DATA INSUFFICIENT']),
((select id from compounds where slug='bpc-157'),
 'BPC-157 heals the gut and reverses inflammatory bowel disease.','gut healing','oral','humans',
 'Very limited','Moderate','Preclinical only',
 'Gut-protective effects appear in animal models; controlled human evidence for treating IBD is not established.',
 'Animal gut-protection findings have not been confirmed in controlled human disease trials.',
 'High', array['ANIMAL-TO-HUMAN LEAP','LACK OF CONTROLLED HUMAN TRIALS']),
((select id from compounds where slug='bpc-157'),
 'BPC-157 is completely safe with no side effects.','safety','injection','humans',
 'Very limited','Moderate','Unsupported — safety not established',
 'Because there are almost no controlled human studies, long-term human safety simply has not been characterised.',
 'Absence of reported harm in small/animal studies is not evidence of safety.',
 'High', array['SAFETY DATA INSUFFICIENT']),
((select id from compounds where slug='bpc-157'),
 'Oral BPC-157 works as well as injected BPC-157.','route equivalence','oral','humans',
 'Very limited','Limited','Not established (route)',
 'Whether oral dosing reaches the same exposure as injection is not established in controlled human work.',
 'Route can change absorption and effect; the comparison is largely untested in humans.',
 'High', array['ROUTE UNCERTAINTY','LACK OF CONTROLLED HUMAN TRIALS']),
((select id from compounds where slug='bpc-157'),
 'BPC-157 is FDA-approved.','regulatory',null,'humans',
 'None','n/a','False',
 'BPC-157 is not FDA-approved for any indication and is prohibited in professional sport.',
 null,
 'Extreme', array['REGULATORY MISSTATEMENT']),
((select id from compounds where slug='bpc-157'),
 'BPC-157 protects the stomach against NSAID damage.','gastroprotection','oral','animals',
 'Very limited','Moderate','Preclinical signal',
 'Gastroprotective effects against NSAID injury are reported mainly in animal models, not confirmed in humans.',
 'Preclinical protection does not establish a human therapeutic effect.',
 'Moderate', array['ANIMAL-TO-HUMAN LEAP']);

-- GHK-Cu
insert into claims (compound_id, claim_text, outcome, implied_route, implied_population,
  human_evidence_level, preclinical_evidence_level, verdict, plain_language_explanation,
  critical_uncertainty, claim_gap, route_integrity) values
((select id from compounds where slug='ghk-cu'),
 'GHK-Cu regrows hair as well as or better than minoxidil.','hair growth','topical','humans',
 'Early','Moderate','Early, limited human evidence',
 'There is biological plausibility and a small amount of human research on copper-peptide effects on hair, but no strong head-to-head proof against established treatments.',
 'Only a handful of small trials exist; skin-appearance results do not automatically transfer to hair.',
 'High', array['SMALL-SAMPLE SIGNAL','NO INDEPENDENT REPLICATION','ROUTE / OUTCOME LEAP']),
((select id from compounds where slug='ghk-cu'),
 'Injectable GHK-Cu reverses aging throughout the body.','systemic anti-aging','injection','humans',
 'Insufficient','Moderate','Not established (route matters)',
 'Topical GHK-Cu has modest support for skin appearance, but there is essentially no rigorous controlled human evidence that injectable GHK-Cu produces full-body anti-aging.',
 'Topical evidence cannot be transferred to injection; systemic copper carries its own safety questions.',
 'Severe', array['ROUTE MISMATCH','ANIMAL-TO-HUMAN LEAP','SAFETY OVERSTATEMENT']),
((select id from compounds where slug='ghk-cu'),
 'Topical GHK-Cu improves skin appearance.','skin appearance','topical','humans',
 'Early','Moderate','Modestly supported (topical)',
 'Small human studies and mechanistic work support modest topical effects on skin appearance and collagen-related pathways.',
 'Effects are modest and the trials are small; marketing often overstates them.',
 'Low–Moderate', array['SMALL-SAMPLE SIGNAL']),
((select id from compounds where slug='ghk-cu'),
 'GHK-Cu heals wounds.','wound healing','topical','humans',
 'Early','Moderate','Preclinical / early human',
 'Wound-related activity is seen in laboratory and animal work with limited early human data.',
 'Most wound-healing evidence is preclinical; human confirmation is limited.',
 'Moderate', array['ANIMAL-TO-HUMAN LEAP']),
((select id from compounds where slug='ghk-cu'),
 'GHK-Cu boosts collagen production in skin.','collagen','topical','humans',
 'Early','Moderate','Early human / preclinical',
 'Copper-peptide effects on collagen-related pathways are described in lab studies and some early human work.',
 'Pathway activity does not guarantee a visible clinical outcome.',
 'Moderate', array['SURROGATE OUTCOME']),
((select id from compounds where slug='ghk-cu'),
 'GHK-Cu is a nootropic that improves brain function.','cognition','injection','humans',
 'None','Limited','Not established',
 'There is no reliable human evidence that GHK-Cu improves cognition.',
 'Cognitive claims run far ahead of any data.',
 'Severe', array['NO HUMAN EVIDENCE']);

-- Retatrutide
insert into claims (compound_id, claim_text, outcome, implied_route, implied_population,
  human_evidence_level, preclinical_evidence_level, verdict, plain_language_explanation,
  critical_uncertainty, claim_gap, route_integrity) values
((select id from compounds where slug='retatrutide'),
 'Retatrutide produces the strongest weight loss of any peptide.','weight loss','injection','humans',
 'Strong','Extensive','Supported by strong human trials',
 'Phase-2 trials in adults with obesity show large, consistent weight-loss effects — among the strongest reported for this drug class.',
 'It remains investigational and the long-term cardiovascular-safety program is not complete.',
 'Low–Moderate', array['INVESTIGATIONAL — NOT APPROVED','LONG-TERM SAFETY PENDING']),
((select id from compounds where slug='retatrutide'),
 'Retatrutide is approved and available.','regulatory','injection','humans',
 'Strong','Extensive','False — investigational',
 'Retatrutide is still in clinical development and is not an approved product.',
 null,
 'Moderate', array['REGULATORY MISSTATEMENT']),
((select id from compounds where slug='retatrutide'),
 'Retatrutide improves blood sugar in type-2 diabetes.','glycemic control','injection','humans',
 'Strong','Extensive','Supported by trial evidence',
 'Trial data show improvements in glucose control alongside weight loss.',
 'Still investigational; approval and long-term data pending.',
 'Low–Moderate', array['INVESTIGATIONAL — NOT APPROVED']),
((select id from compounds where slug='retatrutide'),
 'Retatrutide has no side effects.','safety','injection','humans',
 'Strong','Extensive','Unsupported',
 'Trials report gastrointestinal side effects and a dose-related heart-rate increase.',
 'Side-effect profile is real and dose-related.',
 'Moderate', array['SAFETY OVERSTATEMENT']),
((select id from compounds where slug='retatrutide'),
 'Retatrutide preserves muscle while losing fat.','body composition','injection','humans',
 'Limited','Moderate','Not established',
 'Body-composition preservation is not established as a distinct proven benefit in the current human evidence.',
 'Weight loss from incretins typically includes some lean mass; selective muscle sparing is unproven.',
 'High', array['SURROGATE OUTCOME']);

-- Semaglutide
insert into claims (compound_id, claim_text, outcome, implied_route, implied_population,
  human_evidence_level, preclinical_evidence_level, verdict, plain_language_explanation,
  critical_uncertainty, claim_gap, route_integrity) values
((select id from compounds where slug='semaglutide'),
 'Semaglutide causes major weight loss.','weight loss','injection','humans',
 'Strong','Extensive','Supported by strong human evidence',
 'Large randomized trials and real-world use show clinically meaningful weight loss, and it is approved for weight management.',
 'GI side effects are common and it is a prescription medicine, not a casual supplement.',
 'Moderate', array['PRESCRIPTION MEDICINE — NOT A SUPPLEMENT']),
((select id from compounds where slug='semaglutide'),
 'Weight stays off after stopping semaglutide.','weight maintenance','injection','humans',
 'Strong','Extensive','Not supported',
 'Trials show substantial weight regain is common after discontinuation.',
 'Durability without continued treatment is not established.',
 'High', array['DURABILITY CAVEAT']),
((select id from compounds where slug='semaglutide'),
 'Semaglutide reduces cardiovascular events.','cardiovascular outcomes','injection','humans',
 'Strong','Extensive','Supported (outcomes trial)',
 'A cardiovascular outcomes trial reported reduced major cardiovascular events in adults with overweight/obesity and established cardiovascular disease.',
 'Benefit was shown in a specific higher-risk population.',
 'Low', array['POPULATION-SPECIFIC']),
((select id from compounds where slug='semaglutide'),
 'Semaglutide treats type-2 diabetes.','glycemic control','injection','humans',
 'Strong','Extensive','Supported / approved',
 'Semaglutide is approved for type-2 diabetes with strong trial evidence for glucose control.',
 null,
 'Low', array[]::text[]),
((select id from compounds where slug='semaglutide'),
 'Semaglutide is a supplement you can take casually.','regulatory','injection','humans',
 'Strong','Extensive','False — prescription medicine',
 'Semaglutide is a prescription medicine requiring medical supervision, not an over-the-counter supplement.',
 null,
 'High', array['PRESCRIPTION MEDICINE — NOT A SUPPLEMENT']);

-- Tirzepatide
insert into claims (compound_id, claim_text, outcome, implied_route, implied_population,
  human_evidence_level, preclinical_evidence_level, verdict, plain_language_explanation,
  critical_uncertainty, claim_gap, route_integrity) values
((select id from compounds where slug='tirzepatide'),
 'Tirzepatide produces greater weight loss than semaglutide.','weight loss','injection','humans',
 'Strong','Extensive','Supported by trial evidence',
 'Head-to-head and program-level trial data indicate tirzepatide can produce greater average weight loss than semaglutide.',
 'Individual response varies; both are prescription medicines with GI side effects.',
 'Low–Moderate', array['PRESCRIPTION MEDICINE — NOT A SUPPLEMENT']),
((select id from compounds where slug='tirzepatide'),
 'Tirzepatide is approved for weight management.','regulatory','injection','humans',
 'Strong','Extensive','Supported / approved',
 'Tirzepatide is approved for weight management and type-2 diabetes.',
 null,
 'Low', array[]::text[]),
((select id from compounds where slug='tirzepatide'),
 'Tirzepatide cures diabetes.','glycemic control','injection','humans',
 'Strong','Extensive','Overstated',
 'Tirzepatide manages blood glucose but does not cure diabetes; effects depend on continued treatment.',
 'Framing a chronic-disease treatment as a cure is misleading.',
 'High', array['OVERSTATEMENT']),
((select id from compounds where slug='tirzepatide'),
 'Tirzepatide has no gastrointestinal side effects.','safety','injection','humans',
 'Strong','Extensive','Unsupported',
 'GI side effects such as nausea are commonly reported in tirzepatide trials.',
 null,
 'Moderate', array['SAFETY OVERSTATEMENT']);

-- TB-500
insert into claims (compound_id, claim_text, outcome, implied_route, implied_population,
  human_evidence_level, preclinical_evidence_level, verdict, plain_language_explanation,
  critical_uncertainty, claim_gap, route_integrity) values
((select id from compounds where slug='tb-500'),
 'TB-500 and Thymosin Beta-4 are the same thing.','identity','injection','humans',
 'Limited','Moderate','Partly true — an important distinction',
 'TB-500 is a synthetic fragment related to the natural protein Thymosin Beta-4, but it is typically a specific fragment, not the full protein.',
 'Research on the full protein does not automatically describe what is in a vial labelled TB-500, and product identity varies.',
 'High', array['IDENTITY MISMATCH (fragment vs. full protein)','LABEL / PURITY UNCERTAINTY']),
((select id from compounds where slug='tb-500'),
 'TB-500 speeds recovery from injury in humans.','recovery','injection','humans',
 'Limited','Moderate','Not established in humans',
 'Human clinical evidence for the marketed recovery claims is limited.',
 'Most support is preclinical; product purity is a real-world unknown.',
 'High', array['LACK OF CONTROLLED HUMAN TRIALS','LABEL / PURITY UNCERTAINTY']),
((select id from compounds where slug='tb-500'),
 'TB-500 is safe and well-studied.','safety','injection','humans',
 'Limited','Moderate','Unsupported',
 'Human safety data are limited and the identity/purity of marketed product is often uncertain.',
 null,
 'High', array['SAFETY DATA INSUFFICIENT','LABEL / PURITY UNCERTAINTY']),
((select id from compounds where slug='tb-500'),
 'TB-500 regrows hair.','hair growth','injection','humans',
 'None','Limited','Not established',
 'There is no reliable human evidence that TB-500 regrows hair.',
 null,
 'Severe', array['NO HUMAN EVIDENCE']);

-- MOTS-c
insert into claims (compound_id, claim_text, outcome, implied_route, implied_population,
  human_evidence_level, preclinical_evidence_level, verdict, plain_language_explanation,
  critical_uncertainty, claim_gap, route_integrity) values
((select id from compounds where slug='mots-c'),
 'MOTS-c is a proven exercise mimetic that boosts human metabolism.','metabolism','injection','humans',
 'Very limited','Moderate','Primarily preclinical',
 'MOTS-c is a genuinely interesting mitochondrial-derived peptide, but the compelling findings are largely from animal and lab studies; robust human evidence is very limited.',
 '"Exercise mimetic" is a research hypothesis, not a demonstrated human outcome.',
 'High', array['ANIMAL-TO-HUMAN LEAP','SURROGATE OUTCOME','LACK OF CONTROLLED HUMAN TRIALS']),
((select id from compounds where slug='mots-c'),
 'MOTS-c extends lifespan.','longevity','injection','humans',
 'None','Limited','Preclinical hypothesis only',
 'Longevity claims are not supported by human evidence.',
 null,
 'Severe', array['NO HUMAN EVIDENCE','ANIMAL-TO-HUMAN LEAP']),
((select id from compounds where slug='mots-c'),
 'MOTS-c improves insulin sensitivity in people.','metabolism','injection','humans',
 'Very limited','Moderate','Preclinical',
 'Metabolic effects are described in animal work; controlled human confirmation is limited.',
 null,
 'High', array['ANIMAL-TO-HUMAN LEAP']);

-- Tesamorelin
insert into claims (compound_id, claim_text, outcome, implied_route, implied_population,
  human_evidence_level, preclinical_evidence_level, verdict, plain_language_explanation,
  critical_uncertainty, claim_gap, route_integrity) values
((select id from compounds where slug='tesamorelin'),
 'Tesamorelin reduces excess visceral belly fat.','visceral fat','injection','HIV-associated lipodystrophy',
 'Strong','Moderate','Supported in its approved population',
 'Tesamorelin is approved to reduce excess visceral fat in HIV-associated lipodystrophy, backed by trial evidence in that population.',
 'Evidence is specific to the approved population.',
 'Low', array['POPULATION-SPECIFIC']),
((select id from compounds where slug='tesamorelin'),
 'Tesamorelin is a general anti-aging and bodybuilding drug.','anti-aging','injection','general adults',
 'Limited','Moderate','Not established outside approved use',
 'Benefits shown in the approved population do not establish general anti-aging or performance benefit.',
 'Extending an indication-specific result to healthy adults is unsupported.',
 'High', array['POPULATION MISMATCH']),
((select id from compounds where slug='tesamorelin'),
 'Tesamorelin builds muscle.','muscle','injection','general adults',
 'Limited','Moderate','Not established',
 'There is no strong human evidence that tesamorelin builds muscle in healthy adults.',
 null,
 'Moderate', array['POPULATION MISMATCH','SURROGATE OUTCOME']);

-- Ipamorelin
insert into claims (compound_id, claim_text, outcome, implied_route, implied_population,
  human_evidence_level, preclinical_evidence_level, verdict, plain_language_explanation,
  critical_uncertainty, claim_gap, route_integrity) values
((select id from compounds where slug='ipamorelin'),
 'Ipamorelin builds muscle and burns fat in humans.','body composition','injection','humans',
 'Very limited','Moderate','Not established in humans',
 'Ipamorelin raises growth-hormone signalling in models, but controlled human body-composition benefits are not established.',
 'Raising a hormone level is not the same as a proven physique outcome.',
 'High', array['SURROGATE OUTCOME','LACK OF CONTROLLED HUMAN TRIALS']),
((select id from compounds where slug='ipamorelin'),
 'Ipamorelin is a safe way to raise growth hormone.','safety','injection','humans',
 'Very limited','Moderate','Unsupported',
 'Human safety data are limited; it is not an approved therapy.',
 null,
 'High', array['SAFETY DATA INSUFFICIENT']),
((select id from compounds where slug='ipamorelin'),
 'Ipamorelin is selective and does not raise cortisol or hunger.','selectivity','injection','humans',
 'Very limited','Moderate','Partly supported (preclinical)',
 'Preclinical work suggests relative selectivity, but human confirmation is limited.',
 null,
 'Moderate', array['ANIMAL-TO-HUMAN LEAP']);

-- CJC-1295
insert into claims (compound_id, claim_text, outcome, implied_route, implied_population,
  human_evidence_level, preclinical_evidence_level, verdict, plain_language_explanation,
  critical_uncertainty, claim_gap, route_integrity) values
((select id from compounds where slug='cjc-1295'),
 'CJC-1295 dramatically increases growth hormone and reverses aging.','anti-aging','injection','humans',
 'Limited','Moderate','Overstated',
 'CJC-1295 can raise growth-hormone markers, but controlled human evidence for anti-aging outcomes is limited.',
 'Hormone-marker changes do not establish clinical anti-aging benefit.',
 'High', array['SURROGATE OUTCOME','LACK OF CONTROLLED HUMAN TRIALS']),
((select id from compounds where slug='cjc-1295'),
 'CJC-1295 improves recovery and sleep.','recovery','injection','humans',
 'Very limited','Limited','Not established',
 'Recovery and sleep benefits are not established in controlled human trials.',
 null,
 'Moderate', array['LACK OF CONTROLLED HUMAN TRIALS']),
((select id from compounds where slug='cjc-1295'),
 'CJC-1295 with DAC lasts for days from a single dose.','pharmacokinetics','injection','humans',
 'Limited','Moderate','Pharmacology plausible; clinical benefit unproven',
 'The DAC modification extends half-life, but a longer half-life does not by itself prove a clinical benefit.',
 'Extended exposure is a pharmacology point, not an outcome.',
 'Moderate', array['SURROGATE OUTCOME']);

-- Bremelanotide / PT-141
insert into claims (compound_id, claim_text, outcome, implied_route, implied_population,
  human_evidence_level, preclinical_evidence_level, verdict, plain_language_explanation,
  critical_uncertainty, claim_gap, route_integrity) values
((select id from compounds where slug='bremelanotide'),
 'PT-141 (bremelanotide) improves sexual desire in women.','sexual desire','injection','premenopausal women with HSDD',
 'Strong','Moderate','Supported in approved use',
 'Bremelanotide is FDA-approved (Vyleesi) for hypoactive sexual desire disorder in premenopausal women, supported by trial evidence.',
 'Approval and evidence are specific to that population.',
 'Low', array['POPULATION-SPECIFIC']),
((select id from compounds where slug='bremelanotide'),
 'PT-141 works as a general libido booster for everyone.','libido','injection','general adults',
 'Limited','Moderate','Not established beyond approved population',
 'Evidence supports a specific approved population; general use is not established.',
 'Extending the approved indication to all users is unsupported.',
 'Moderate', array['POPULATION MISMATCH']),
((select id from compounds where slug='bremelanotide'),
 'PT-141 has no side effects.','safety','injection','humans',
 'Strong','Moderate','Unsupported',
 'Reported effects include nausea, flushing and transient blood-pressure changes.',
 null,
 'Moderate', array['SAFETY OVERSTATEMENT']);

-- Melanotan II
insert into claims (compound_id, claim_text, outcome, implied_route, implied_population,
  human_evidence_level, preclinical_evidence_level, verdict, plain_language_explanation,
  critical_uncertainty, claim_gap, route_integrity) values
((select id from compounds where slug='melanotan-ii'),
 'Melanotan II gives a safe protective tan.','tanning','injection','humans',
 'Very limited','Limited','Not established as safe',
 'Melanotan II is unapproved and sold without quality control; a "safe protective tan" is not established, and moles/skin changes and other effects are reported.',
 'Unregulated product identity and safety are serious unknowns.',
 'Severe', array['SAFETY OVERSTATEMENT','UNREGULATED PRODUCT']),
((select id from compounds where slug='melanotan-ii'),
 'Melanotan II is a proven aphrodisiac.','libido','injection','humans',
 'Very limited','Moderate','Preclinical / early — unapproved',
 'Melanocortin pathways affect sexual function, but Melanotan II itself is unapproved with limited human evidence.',
 null,
 'High', array['UNREGULATED PRODUCT','LACK OF CONTROLLED HUMAN TRIALS']),
((select id from compounds where slug='melanotan-ii'),
 'Melanotan II is regulated and quality-controlled.','regulatory','injection','humans',
 'None','n/a','False',
 'Melanotan II is sold unapproved; product purity and identity are not quality-controlled.',
 null,
 'Extreme', array['REGULATORY MISSTATEMENT','UNREGULATED PRODUCT']),
((select id from compounds where slug='melanotan-ii'),
 'Melanotan II clears acne and boosts mood.','skin / mood','injection','humans',
 'None','Limited','Unsupported',
 'There is no reliable human evidence for these benefits.',
 null,
 'Severe', array['NO HUMAN EVIDENCE','UNREGULATED PRODUCT']);

-- ─────────────────────────── CLAIM ↔ SOURCE LINKS ──────────────────────────
-- (a) Every claim is grounded in its compound's internal review record. The
--     sentence_ref is the receipt's plain-language explanation. This enforces
--     "no factual sentence without a source record" structurally, while the
--     source's own quality_note keeps the provenance honest (pending review).
insert into claim_sources (claim_id, source_id, supports, sentence_ref)
select cl.id, s.id, true, left(cl.plain_language_explanation, 240)
from claims cl
join compounds c on c.id = cl.compound_id
join sources s on s.type = 'review' and s.title = 'Aphrodite internal review — ' || c.name
on conflict do nothing;

-- (b) Attach the real external trial/label records to the specific supported claims.
insert into claim_sources (claim_id, source_id, supports, sentence_ref)
select cl.id, s.id, true, left(cl.plain_language_explanation, 240)
from claims cl
join sources s on (
  (cl.claim_text = 'Retatrutide produces the strongest weight loss of any peptide.'
     and s.registry_id = 'NCT04881760') or
  (cl.claim_text = 'Semaglutide causes major weight loss.'
     and s.registry_id = 'NCT03548935') or
  (cl.claim_text = 'Semaglutide reduces cardiovascular events.'
     and s.registry_id = 'NCT03574597') or
  (cl.claim_text = 'Tirzepatide produces greater weight loss than semaglutide.'
     and s.registry_id = 'NCT04184622') or
  (cl.claim_text = 'PT-141 (bremelanotide) improves sexual desire in women.'
     and s.title like 'FDA approval — Vyleesi%') or
  (cl.claim_text = 'Tesamorelin reduces excess visceral belly fat.'
     and s.title like 'FDA approval — Egrifta%')
)
on conflict do nothing;

-- ─────────────────────────── VERDICT HISTORY (seed) ────────────────────────
-- One initial verdict row per claim, so the history table is populated from day one.
insert into claim_verdicts (claim_id, verdict, rationale, effective_from)
select cl.id, cl.verdict, 'Initial seed verdict — unverified, pending human source review.', now()
from claims cl
on conflict do nothing;

-- ─────────────────────────── RESEARCH UPDATES ──────────────────────────────
-- Intentionally left EMPTY at seed time. Populated in Phase 2 by the stubbed
-- ClinicalTrials.gov / openFDA fetcher (scripts/fetch-research-updates.mjs),
-- and only after a human approves each update into a record.
