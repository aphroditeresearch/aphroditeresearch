// GET /api/stats — minimal, aggregate-only analytics (no PII).
// Counts asks (by route), saves, and follows. Used by an internal dashboard;
// returns only totals, never individual queries or user rows.
import { serviceClient } from './_lib/supabase.js';

async function count(supabase, table, filter) {
  let q = supabase.from(table).select('*', { count: 'exact', head: true });
  if (filter) q = filter(q);
  const { count: n, error } = await q;
  if (error) return null;
  return n ?? 0;
}

export default async function handler(req, res) {
  const supabase = serviceClient();
  if (!supabase) return res.status(503).json({ error: 'backend_unconfigured' });
  try {
    const [asks, answered, refused, insufficient, savedC, savedK, follC, follK] = await Promise.all([
      count(supabase, 'query_logs'),
      count(supabase, 'query_logs', (q) => q.eq('route_taken', 'answer')),
      count(supabase, 'query_logs', (q) => q.eq('route_taken', 'refuse')),
      count(supabase, 'query_logs', (q) => q.eq('route_taken', 'insufficient')),
      count(supabase, 'saved_claims'),
      count(supabase, 'saved_compounds'),
      count(supabase, 'followed_claims'),
      count(supabase, 'followed_compounds'),
    ]);
    res.setHeader('Cache-Control', 'no-store');
    return res.status(200).json({
      asks: { total: asks, answered, refused, insufficient },
      saves: { claims: savedC, compounds: savedK },
      follows: { claims: follC, compounds: follK },
    });
  } catch (err) {
    return res.status(500).json({ error: 'server_error' });
  }
}
