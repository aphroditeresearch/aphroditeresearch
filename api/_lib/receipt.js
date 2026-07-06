// ─────────────────────────────────────────────────────────────────────────
// RECEIPT ASSEMBLY — turns DB records into the structured Evidence Receipt the
// frontend renders. The DB is the source of truth; the model may only rephrase
// `direct_answer`. Every other field comes verbatim from the records.
// ─────────────────────────────────────────────────────────────────────────

function flagsMatching(flags, re) {
  return (flags || []).filter((f) => re.test(f));
}
function titleCaseFlag(f) {
  // "ROUTE MISMATCH" -> "Route mismatch"
  return f.charAt(0) + f.slice(1).toLowerCase();
}

export function confidenceFor(claim) {
  const h = (claim.human_evidence_level || '').toLowerCase();
  if (/strong/.test(h)) return 'High';
  if (/moderate|early/.test(h)) return 'Moderate';
  if (/limited|insufficient|none/.test(h)) return 'Low';
  return 'Low';
}

/**
 * Assemble the receipt. `directAnswer` is the (possibly model-written) grounded
 * explanation; when the model is disabled/unavailable we pass the record's own
 * plain_language_explanation so the loop still works end to end.
 */
export function buildReceipt({ compound, claim, sources, directAnswer, source }) {
  const flags = claim.route_integrity || [];
  const routeFlag = flagsMatching(flags, /ROUTE|IDENTITY/)[0] || null;
  const popFlag = flagsMatching(flags, /POPULATION/)[0] || null;
  const safetyFlag = flagsMatching(flags, /SAFETY/)[0] || null;
  const pending = claim.review_status !== 'reviewed';

  return {
    compound: {
      name: compound.name,
      slug: compound.slug,
      class: compound.class,
      dossier_url: compound.dossier_url,
    },
    claim: {
      id: claim.id,
      text: claim.claim_text,
      outcome: claim.outcome,
      implied_route: claim.implied_route,
      implied_population: claim.implied_population,
    },
    verdict: claim.verdict || 'Not established',
    direct_answer: directAnswer || claim.plain_language_explanation || '',
    human_evidence: claim.human_evidence_level || 'Unknown',
    preclinical_evidence: claim.preclinical_evidence_level || 'Unknown',
    claim_gap: claim.claim_gap || null,
    integrity_flags: flags,
    route_warning: routeFlag ? titleCaseFlag(routeFlag) : null,
    population_warning: popFlag ? titleCaseFlag(popFlag) : null,
    safety_uncertainty: claim.critical_uncertainty || (safetyFlag ? titleCaseFlag(safetyFlag) : null),
    anecdotal_context: null, // not stored yet; never fabricated
    confidence: confidenceFor(claim),
    review_status: claim.review_status,
    pending_verification: pending,
    last_reviewed: claim.reviewed_at || null,
    reviewer: claim.reviewer || null,
    sources: sources.map((s) => ({
      cite: s.cite,
      type: s.type,
      title: s.title,
      authors: s.authors,
      year: s.year,
      url: s.url,
      registry_id: s.registry_id,
      quality_note: s.quality_note,
      supports: s.supports,
      sentence_ref: s.sentence_ref,
    })),
    answer_source: source, // 'model' | 'record'
    actions: [
      { type: 'follow_claim', claim_id: claim.id, label: 'Follow claim' },
      { type: 'save_claim', claim_id: claim.id, label: 'Save to Library' },
      compound.dossier_url
        ? { type: 'open_dossier', url: compound.dossier_url, label: 'Open ' + compound.name + ' dossier' }
        : null,
      { type: 'share', label: 'Share Evidence Receipt' },
    ].filter(Boolean),
  };
}

/** The honest "not enough reviewed evidence yet" receipt (no model call). */
export function insufficientReceipt(query, covered) {
  return {
    route: 'insufficient',
    query,
    verdict: 'Not enough reviewed evidence yet',
    direct_answer:
      "This isn't in Aphrodite's reviewed library yet, so we won't guess. " +
      'We only answer from compounds we have actually reviewed.',
    covered: covered.map((c) => ({ name: c.name, slug: c.slug })),
    sources: [],
    actions: [{ type: 'browse_archive', url: 'archive.html', label: 'Explore the Archive' }],
  };
}

/** The refuse-and-explain receipt for dosing / sourcing intent (no model call). */
export function refusalReceipt(category, compound) {
  const why =
    category === 'sourcing'
      ? "We don't point to vendors or sources. A site that brokers access becomes the thing it's meant to protect you from."
      : "We don't give doses, protocols, or personal-use guidance — for anyone, on any compound. Most of these compounds have little human safety data, so a “recommended dose” is guessing with someone's health.";
  const redirect = compound
    ? {
        type: 'open_dossier',
        url: compound.dossier_url || 'archive.html',
        label: 'Open ' + compound.name + ' dossier',
      }
    : { type: 'browse_archive', url: 'archive.html', label: 'Explore the Archive' };
  return {
    route: 'refuse',
    category,
    verdict: category === 'sourcing' ? 'Sourcing request declined' : 'Dosing request declined',
    direct_answer: why,
    study_context_note:
      'We can summarise amounts administered in a specific published study — as a record of the research, never as a recommendation — on the compound record.',
    sources: [],
    actions: [redirect],
  };
}
