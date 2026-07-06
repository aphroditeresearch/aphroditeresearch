// ─────────────────────────────────────────────────────────────────────────
// RETRIEVAL — the model only ever sees records that come out of here.
//
// No embeddings in Phase 1: the reference set is small (a dozen compounds), so
// we score by alias/keyword overlap in JS — the same approach the client
// prototype used, moved server-side against the real DB. This is the single
// place that decides "what does Aphrodite actually know about this query."
// ─────────────────────────────────────────────────────────────────────────

const STOP = new Set([
  'the', 'a', 'an', 'is', 'are', 'was', 'were', 'be', 'been', 'do', 'does',
  'did', 'for', 'of', 'to', 'in', 'on', 'and', 'or', 'it', 'that', 'this',
  'with', 'as', 'at', 'by', 'from', 'about', 'can', 'you', 'i', 'me', 'my',
  'what', 'which', 'how', 'have', 'has', 'any', 'really', 'work', 'works',
]);

function tokens(text) {
  return (text || '')
    .toLowerCase()
    .replace(/[^a-z0-9\s-]/g, ' ')
    .split(/\s+/)
    .filter((t) => t.length > 2 && !STOP.has(t));
}

/**
 * Retrieve the best-matching compound and claim for a query.
 *
 * @returns {Promise<{
 *   compound: object|null,
 *   claim: object|null,
 *   otherClaims: object[],
 *   sources: object[],
 *   covered: {name:string, slug:string}[]
 * }>}
 */
export async function retrieve(supabase, query) {
  const covered = [];
  // 1) Load compounds + aliases (small table) and score against the query.
  const { data: compounds, error: cErr } = await supabase
    .from('compounds')
    .select('id, name, slug, class, summary, dossier_url, compound_aliases(alias)');
  if (cErr) throw cErr;

  for (const c of compounds || []) covered.push({ name: c.name, slug: c.slug });

  const q = ' ' + (query || '').toLowerCase() + ' ';
  let best = null;
  let bestHits = 0;
  for (const c of compounds || []) {
    const needles = [c.name, c.slug.replace(/-/g, ' '), c.slug]
      .concat((c.compound_aliases || []).map((a) => a.alias))
      .map((s) => String(s).toLowerCase())
      .filter(Boolean);
    let hits = 0;
    for (const n of needles) {
      if (n.length >= 2 && q.includes(' ' + n + ' ')) hits += 2; // whole-token
      else if (n.length >= 3 && q.includes(n)) hits += 1; // substring
    }
    if (hits > bestHits) {
      bestHits = hits;
      best = c;
    }
  }

  if (!best || bestHits < 1) {
    return { compound: null, claim: null, otherClaims: [], sources: [], covered };
  }

  // 2) Load that compound's claims + their sources.
  const { data: claims, error: clErr } = await supabase
    .from('claims')
    .select(
      `id, claim_text, outcome, implied_route, implied_population,
       human_evidence_level, preclinical_evidence_level, verdict,
       plain_language_explanation, critical_uncertainty, claim_gap,
       route_integrity, review_status, reviewed_at, reviewer,
       claim_sources ( supports, sentence_ref,
         sources ( id, type, title, authors, year, url, registry_id, quality_note ) )`
    )
    .eq('compound_id', best.id);
  if (clErr) throw clErr;

  // 3) Pick the best claim by keyword overlap with claim_text + outcome + flags.
  const qTokens = new Set(tokens(query));
  let bestClaim = null;
  let bestScore = -1;
  for (const cl of claims || []) {
    const hay = tokens(
      [cl.claim_text, cl.outcome, cl.implied_route, (cl.route_integrity || []).join(' ')].join(' ')
    );
    let score = 0;
    for (const t of hay) if (qTokens.has(t)) score += 1;
    // Small nudge toward claims whose outcome word is explicitly present.
    if (cl.outcome && q.includes(cl.outcome.toLowerCase())) score += 2;
    if (score > bestScore) {
      bestScore = score;
      bestClaim = cl;
    }
  }

  // If nothing overlapped, fall back to the compound's headline claim (first).
  if (!bestClaim && claims && claims.length) bestClaim = claims[0];

  const otherClaims = (claims || []).filter((c) => c.id !== (bestClaim && bestClaim.id));
  const sources = collectSources(bestClaim);

  return { compound: best, claim: bestClaim, otherClaims, sources, covered };
}

function collectSources(claim) {
  if (!claim || !claim.claim_sources) return [];
  const out = [];
  const seen = new Set();
  claim.claim_sources.forEach((cs, i) => {
    const s = cs.sources;
    if (!s || seen.has(s.id)) return;
    seen.add(s.id);
    out.push({
      cite: 'S' + (out.length + 1), // stable citation token for this receipt
      id: s.id,
      type: s.type,
      title: s.title,
      authors: s.authors,
      year: s.year,
      url: s.url,
      registry_id: s.registry_id,
      quality_note: s.quality_note,
      supports: cs.supports,
      sentence_ref: cs.sentence_ref,
    });
  });
  return out;
}
