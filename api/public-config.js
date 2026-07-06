// GET /api/public-config — the browser-safe Supabase config.
//
// The anon key is designed to be public (RLS enforces every access), but we
// serve it from an endpoint rather than hard-coding it so the static site
// carries no keys and rotating them is a dashboard change, not a code change.
export default function handler(req, res) {
  const url = process.env.SUPABASE_URL || null;
  const anonKey = process.env.SUPABASE_ANON_KEY || null;
  res.setHeader('Cache-Control', 'public, max-age=300');
  return res.status(200).json({
    supabaseUrl: url,
    supabaseAnonKey: anonKey,
    authEnabled: Boolean(url && anonKey),
  });
}
