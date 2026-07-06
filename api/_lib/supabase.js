// Server-side Supabase clients. The SERVICE ROLE key bypasses RLS and MUST
// never be sent to the browser — it lives only in these serverless functions.
import { createClient } from '@supabase/supabase-js';

let _service = null;

/**
 * Service-role client: reads the reference tables and writes query_logs.
 * Returns null if env is not configured, so callers can degrade gracefully.
 */
export function serviceClient() {
  if (_service) return _service;
  const url = process.env.SUPABASE_URL;
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!url || !key) return null;
  _service = createClient(url, key, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  return _service;
}

export function isConfigured() {
  return Boolean(process.env.SUPABASE_URL && process.env.SUPABASE_SERVICE_ROLE_KEY);
}
