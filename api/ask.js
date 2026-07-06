// ═══════════════════════════════════════════════════════════════════════════
// POST /api/ask  — the one product loop, server-side.
//
//   1. Validate + sanitize input.
//   2. SAFETY GATE (pre-filter): dosing / sourcing → refuse-and-explain. No model.
//   3. Retrieve matching reviewed records from the DB.
//   4. INSUFFICIENT-EVIDENCE GATE: nothing matched → honest "not yet" receipt.
//   5. Grounded generation (Anthropic, server key) — optional, always fenced.
//   6. Citation validation happens inside the model layer; on failure we serve
//      the deterministic record-based receipt instead of anything uncited.
//   7. Return structured JSON. Log to query_logs.
//
// Secrets (service-role, Anthropic) never leave this function.
// ═══════════════════════════════════════════════════════════════════════════
import { serviceClient, isConfigured } from './_lib/supabase.js';
import { classifyUnsafe } from './_lib/safety.js';
import { retrieve } from './_lib/retrieve.js';
import { groundedAnswer, modelEnabled } from './_lib/model.js';
import { buildReceipt, insufficientReceipt, refusalReceipt } from './_lib/receipt.js';

const MAX_LEN = 600;

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST');
    return res.status(405).json({ error: 'method_not_allowed' });
  }

  // 1. Validate + sanitize -------------------------------------------------
  let body = req.body;
  if (typeof body === 'string') {
    try { body = JSON.parse(body); } catch { body = {}; }
  }
  const rawQuery = (body && typeof body.query === 'string' ? body.query : '').trim();
  const userId = body && typeof body.user_id === 'string' && body.user_id ? body.user_id : null;

  if (!rawQuery) return res.status(400).json({ error: 'empty_query' });
  const query = rawQuery.slice(0, MAX_LEN);

  // Lightweight health check used by the frontend status pill — no DB, no log.
  if (query === '__ping__') return res.status(200).json({ ok: true, route: 'ping' });

  const supabase = serviceClient();
  if (!supabase) {
    // Backend not configured yet — tell the client to use its local fallback.
    return res.status(503).json({ error: 'backend_unconfigured' });
  }

  const log = async (route, compoundId, claimId) => {
    try {
      await supabase.from('query_logs').insert({
        user_id: userId,
        raw_query: query,
        matched_compound_id: compoundId || null,
        matched_claim_id: claimId || null,
        route_taken: route,
      });
    } catch (_) { /* logging must never break the response */ }
  };

  try {
    // 2. SAFETY GATE (pre-filter) -----------------------------------------
    const unsafe = classifyUnsafe(query);
    if (unsafe.blocked) {
      // Try to name the compound so we can offer its record as a redirect.
      let compound = null;
      try {
        const r = await retrieve(supabase, query);
        compound = r.compound;
      } catch (_) { /* non-fatal */ }
      await log('refuse', compound && compound.id, null);
      return res.status(200).json({ ok: true, ...refusalReceipt(unsafe.category, compound) });
    }

    // 3. Retrieve ----------------------------------------------------------
    const { compound, claim, sources, covered } = await retrieve(supabase, query);

    // 4. INSUFFICIENT-EVIDENCE GATE ---------------------------------------
    if (!compound || !claim) {
      await log('insufficient', null, null);
      return res.status(200).json({ ok: true, ...insufficientReceipt(query, covered) });
    }

    // 5 + 6. Grounded generation with validation (or deterministic) --------
    let directAnswer = claim.plain_language_explanation || '';
    let answerSource = 'record';
    const model = await groundedAnswer({ claim, sources, query });
    if (model && model.text) {
      directAnswer = model.text;
      answerSource = 'model';
    }

    const receipt = buildReceipt({ compound, claim, sources, directAnswer, source: answerSource });
    receipt.route = 'answer';
    receipt.ok = true;

    // 7. Log + return ------------------------------------------------------
    await log('answer', compound.id, claim.id);
    return res.status(200).json(receipt);
  } catch (err) {
    console.error('[/api/ask] error:', err && err.message);
    await log('error', null, null);
    return res.status(500).json({ error: 'server_error' });
  }
}

// Small helper other endpoints can import to report readiness.
export function backendReady() {
  return isConfigured();
}
export const usesModel = modelEnabled;
