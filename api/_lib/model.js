// ─────────────────────────────────────────────────────────────────────────
// GROUNDED GENERATION (step 6) + CITATION VALIDATION (step 7).
//
// The model is optional and always fenced:
//   • It sees ONLY the retrieved records.
//   • Every factual sentence must carry a [S#] marker that exists in the set.
//   • We validate the output; if it invents citations or leaks dose numbers,
//     we DISCARD it and the caller falls back to the record's own explanation.
//
// Returns null on any of: disabled, no key, API error, invalid output. Null is
// a first-class "use the deterministic receipt" signal — never an exception.
// ─────────────────────────────────────────────────────────────────────────
import Anthropic from '@anthropic-ai/sdk';
import { scanForDoseLeak } from './safety.js';

const DEFAULT_MODEL = 'claude-sonnet-5';

export function modelEnabled() {
  if (String(process.env.ASK_MODEL_DISABLED).toLowerCase() === 'true') return false;
  return Boolean(process.env.ANTHROPIC_API_KEY);
}

const SYSTEM = `You are Aphrodite, an evidence assistant for peptide research claims.

You write ONLY from the RECORDS provided in the user message. Hard rules:
- Never invent studies, numbers, doses, populations, or citations.
- Never give dosing, protocols, administration, reconstitution, or sourcing.
- Keep human evidence separate from animal/preclinical evidence.
- Every factual sentence must end with a citation marker like [S1] that refers
  to a source id present in RECORDS. If you cannot support a sentence with a
  provided source, do not write that sentence.
- If the records do not answer the question, say so plainly.
- Neutral, professional, non-judgmental tone. No slang. Do not restate a verdict
  badge in full sentences — add explanation, not repetition.

Output STRICT JSON and nothing else:
{"direct_answer": "<2-4 sentences, plain language, each factual sentence ending in a [S#] marker>",
 "citations": ["S1", ...]}`;

function recordsBlock({ claim, sources }) {
  const lines = [];
  lines.push(`CLAIM UNDER REVIEW: ${claim.claim_text}`);
  lines.push(`VERDICT (fixed, do not change): ${claim.verdict}`);
  lines.push(`HUMAN EVIDENCE: ${claim.human_evidence_level}`);
  lines.push(`PRECLINICAL EVIDENCE: ${claim.preclinical_evidence_level}`);
  if (claim.critical_uncertainty) lines.push(`KEY UNCERTAINTY: ${claim.critical_uncertainty}`);
  lines.push('');
  lines.push('RECORDS:');
  for (const s of sources) {
    const meta = [s.title, s.authors, s.year].filter(Boolean).join(' · ');
    lines.push(`[${s.cite}] (${s.supports ? 'supports' : 'refutes'}) ${meta}`);
    if (s.sentence_ref) lines.push(`      basis: ${s.sentence_ref}`);
  }
  return lines.join('\n');
}

/**
 * @returns {Promise<{text:string, citations:string[]}|null>}
 */
export async function groundedAnswer({ claim, sources, query }) {
  if (!modelEnabled()) return null;
  if (!sources || sources.length === 0) return null;

  const validCites = new Set(sources.map((s) => s.cite));
  const client = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });
  const model = process.env.ANTHROPIC_MODEL || DEFAULT_MODEL;

  let raw;
  try {
    const resp = await client.messages.create({
      model,
      max_tokens: 500,
      system: SYSTEM,
      messages: [
        {
          role: 'user',
          content:
            `QUESTION: ${query}\n\n${recordsBlock({ claim, sources })}\n\n` +
            `Write the JSON now. Use only [S#] markers from RECORDS.`,
        },
      ],
    });
    raw = (resp.content || []).map((b) => (b.type === 'text' ? b.text : '')).join('').trim();
  } catch (e) {
    return null; // API/network error → deterministic fallback
  }

  // Parse strict JSON (tolerate code fences / stray prose around it).
  let parsed;
  try {
    const jsonStr = raw.slice(raw.indexOf('{'), raw.lastIndexOf('}') + 1);
    parsed = JSON.parse(jsonStr);
  } catch (e) {
    return null;
  }
  let text = typeof parsed.direct_answer === 'string' ? parsed.direct_answer.trim() : '';
  if (!text) return null;

  // Validate citations: strip any [S#] marker the model invented.
  const used = new Set();
  text = text.replace(/\[(S\d+)\]/g, (m, cite) => {
    if (validCites.has(cite)) {
      used.add(cite);
      return m;
    }
    return ''; // drop invented citation marker
  });
  text = text.replace(/\s{2,}/g, ' ').replace(/\s+([.,;])/g, '$1').trim();

  // If nothing valid remains, the answer is effectively uncited → fall back.
  if (used.size === 0) return null;

  // Post-filter: reject any dose-number leakage not present in a source record.
  const allowed = sources.flatMap((s) => (s.sentence_ref || '').match(/\b\d+(?:\.\d+)?\s?(?:mg|mcg|iu|units?)\b/gi) || []);
  if (scanForDoseLeak(text, allowed).leaked) return null;

  return { text, citations: Array.from(used) };
}
