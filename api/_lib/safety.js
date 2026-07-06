// ─────────────────────────────────────────────────────────────────────────
// SAFETY GATE — enforced server-side, never only in the UI.
//
// Two layers (per ASK-APHRODITE-SPEC):
//   pre-filter  : intent classifier. Dosing / personal-use / sourcing / vendor
//                 requests never reach the model — they get refuse-and-explain.
//   post-filter : scan generated text for dose-like leakage before returning.
//
// Design note: we match personal-use *intent*, not mere vocabulary. The bare
// words "injectable" / "injection" appear in legitimate evidence claims
// ("Injectable GHK-Cu reverses aging"), so those alone must NOT refuse. We look
// for how-to / how-much / where-to-buy phrasing and numeric dose patterns.
// ─────────────────────────────────────────────────────────────────────────

// Sourcing / vendor intent → refuse (category: sourcing)
const SOURCING = [
  'where to buy', 'where can i buy', 'where do i buy', 'where to get',
  'where can i get', 'where do i get', 'best place to buy', 'legit source',
  'legit vendor', 'trusted source', 'trusted vendor', 'good vendor',
  'which vendor', 'what vendor', 'recommend a source', 'recommend a vendor',
  'buy online', 'order online', 'coupon', 'discount code',
];

// Dosing / administration / protocol intent → refuse (category: dosing)
const DOSING = [
  'how much', 'how many mg', 'how many mcg', 'what dose', 'what dosage',
  'recommended dose', 'recommended dosage', 'correct dose', 'right dose',
  'starting dose', 'my dose', 'dose for', 'dosage for', 'dosing for',
  'dosing protocol', 'dosing schedule', 'how do i take', 'how should i take',
  'how to take', 'how do i use', 'how should i use', 'how to use',
  'how often should i', 'how often do i', 'how frequently',
  'how do i inject', 'how to inject', 'how do i mix', 'how to mix',
  'reconstitut', 'draw up', 'titrat', 'my protocol', 'a protocol',
  'protocol for', 'what cycle', 'cycle length', 'stack with', 'stacking',
  'best stack', 'how to cycle', 'pin ', 'pinning',
];

// Numeric dose patterns, e.g. "5mg", "250 mcg", "10 iu", "2 units", "0.25 mg/kg"
const DOSE_NUM = /\b\d+(?:\.\d+)?\s?(?:mg|mcg|µg|ug|iu|units?|cc|ml)\b/i;
const PER_TIME = /\b(?:per|a|each|every)\s+(?:day|week|month|dose|injection|cycle)\b/i;

function normalize(q) {
  return (q || '').toLowerCase().replace(/\s+/g, ' ').trim();
}

/**
 * Pre-filter. Returns { blocked, category } — category is 'sourcing' | 'dosing'
 * when blocked, else null.
 */
export function classifyUnsafe(query) {
  const q = normalize(query);
  if (SOURCING.some((t) => q.includes(t))) return { blocked: true, category: 'sourcing' };
  if (DOSING.some((t) => q.includes(t))) return { blocked: true, category: 'dosing' };
  // A number + unit combined with a personal verb reads as a dosing question.
  if (DOSE_NUM.test(q) && /\b(i|me|my|should|take|inject|use|run|dose)\b/.test(q)) {
    return { blocked: true, category: 'dosing' };
  }
  return { blocked: false, category: null };
}

/**
 * Post-filter. Scans model output for dose-like leakage. `allowedNumbers` are
 * the exact dose strings that appear in a cited study record (study context is
 * permitted when clearly labelled). Anything else trips the filter.
 */
export function scanForDoseLeak(text, allowedNumbers = []) {
  if (!text) return { leaked: false };
  const allowed = new Set(allowedNumbers.map((s) => String(s).toLowerCase()));
  const matches = text.match(new RegExp(DOSE_NUM, 'gi')) || [];
  const offending = matches
    .map((m) => m.toLowerCase().replace(/\s+/g, ''))
    .filter((m) => !allowed.has(m));
  const titration = PER_TIME.test(text) && matches.length > 0;
  return { leaked: offending.length > 0 || titration, offending };
}
