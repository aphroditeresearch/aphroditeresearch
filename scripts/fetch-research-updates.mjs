// ═══════════════════════════════════════════════════════════════════════════
// Phase-2 STUB — research updates ingestion (NOT wired to live data yet).
//
// The intent (Phase 2): poll ClinicalTrials.gov and openFDA for new studies /
// adverse-event signals on the compounds we cover, stage them, and let a human
// approve each into a `research_updates` row (and, where relevant, a new/updated
// `claims` record). Nothing here runs automatically and nothing is inserted
// until a reviewer approves it — same "reviewed knowledge only" contract as the
// rest of the system.
//
// This file deliberately performs NO network calls and NO writes. It documents
// the shape and returns mock candidates so the pipeline can be built and tested
// later without turning on live ingestion.
// ═══════════════════════════════════════════════════════════════════════════

// ClinicalTrials.gov v2 API (reference; not called here):
//   https://clinicaltrials.gov/api/v2/studies?query.term=<compound>&fields=...
// openFDA drug event API (reference; not called here):
//   https://api.fda.gov/drug/event.json?search=patient.drug.medicinalproduct:<name>

/** @returns {Promise<Array<{compound_slug:string, source:'clinicaltrials'|'openfda', headline:string, body:string, url:string, registry_id?:string}>>} */
export async function fetchCandidateUpdates(/* { compounds } */) {
  // STUB: return an empty list. Wire real fetchers in Phase 2.
  return [];
}

/**
 * Would map a candidate to a staged research_updates row for human review.
 * Not inserted anywhere in Phase 1.
 */
export function toStagedUpdate(candidate) {
  return {
    compound_slug: candidate.compound_slug,
    headline: candidate.headline,
    body: candidate.body,
    source_url: candidate.url,
    registry_id: candidate.registry_id || null,
    status: 'pending_human_review',
  };
}

if (import.meta.url === `file://${process.argv[1]}`) {
  fetchCandidateUpdates().then((c) =>
    console.log(`[stub] ${c.length} candidate updates — live ingestion is a Phase-2 task.`)
  );
}
