// ═══════════════════════════════════════════════════════════════════════════
// assets/aphrodite.js — shared browser client for the whole site.
//
//   • ask()      → POST /api/ask, returns a structured Evidence Receipt.
//   • auth       → Supabase Auth (email/password), session persisted.
//   • library    → save / follow claims + compounds (RLS: own rows only).
//
// No secrets here. The Supabase anon config is fetched from /api/public-config.
// If the backend isn't configured yet, everything degrades gracefully:
// ask() reports { degraded:true } so the caller can use its local fallback, and
// auth/library features announce that they need the backend.
// ═══════════════════════════════════════════════════════════════════════════

const SUPABASE_ESM = 'https://esm.sh/@supabase/supabase-js@2';

let _configPromise = null;
let _clientPromise = null;

export async function getConfig() {
  if (!_configPromise) {
    _configPromise = fetch('/api/public-config')
      .then((r) => (r.ok ? r.json() : { authEnabled: false }))
      .catch(() => ({ authEnabled: false }));
  }
  return _configPromise;
}

/** Lazily create the Supabase browser client, or null if unconfigured. */
export async function getClient() {
  if (_clientPromise) return _clientPromise;
  _clientPromise = (async () => {
    const cfg = await getConfig();
    if (!cfg || !cfg.authEnabled) return null;
    const { createClient } = await import(SUPABASE_ESM);
    return createClient(cfg.supabaseUrl, cfg.supabaseAnonKey);
  })();
  return _clientPromise;
}

// ── Auth ───────────────────────────────────────────────────────────────────
export async function currentUser() {
  const c = await getClient();
  if (!c) return null;
  const { data } = await c.auth.getUser();
  return data ? data.user : null;
}

export async function onAuthChange(cb) {
  const c = await getClient();
  if (!c) { cb(null); return () => {}; }
  const { data } = await c.auth.onAuthStateChange((_e, session) => cb(session ? session.user : null));
  const { data: u } = await c.auth.getUser();
  cb(u ? u.user : null);
  return () => data.subscription.unsubscribe();
}

export async function signUp(email, password, displayName) {
  const c = await getClient();
  if (!c) throw new Error('backend_unconfigured');
  return c.auth.signUp({
    email, password,
    options: { data: { display_name: displayName || email.split('@')[0] } },
  });
}
export async function signIn(email, password) {
  const c = await getClient();
  if (!c) throw new Error('backend_unconfigured');
  return c.auth.signInWithPassword({ email, password });
}
export async function signOut() {
  const c = await getClient();
  if (c) await c.auth.signOut();
}

// ── Ask (the product loop) ───────────────────────────────────────────────────
/**
 * @returns {Promise<{degraded:boolean, receipt?:object}>}
 * degraded=true means the backend is unavailable; caller should use its local
 * fallback library so the page still works.
 */
export async function ask(query) {
  let user = null;
  try { user = await currentUser(); } catch (_) {}
  try {
    const res = await fetch('/api/ask', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ query, user_id: user ? user.id : null }),
    });
    if (res.status === 503) return { degraded: true };
    if (!res.ok) return { degraded: true };
    const receipt = await res.json();
    return { degraded: false, receipt };
  } catch (_) {
    return { degraded: true };
  }
}

// ── Library: save / follow ───────────────────────────────────────────────────
const TABLE = {
  'save:claim': 'saved_claims',
  'follow:claim': 'followed_claims',
  'save:compound': 'saved_compounds',
  'follow:compound': 'followed_compounds',
};
const COL = { claim: 'claim_id', compound: 'compound_id' };

async function requireUser() {
  const c = await getClient();
  if (!c) throw new Error('backend_unconfigured');
  const user = await currentUser();
  if (!user) throw new Error('not_signed_in');
  return { c, user };
}

export async function isMarked(action, kind, id) {
  try {
    const { c, user } = await requireUser();
    const table = TABLE[`${action}:${kind}`];
    const col = COL[kind];
    const { data } = await c.from(table).select('id').eq('user_id', user.id).eq(col, id).limit(1);
    return Boolean(data && data.length);
  } catch (_) { return false; }
}

/** Toggle a save/follow. Returns the new boolean state. */
export async function toggleMark(action, kind, id) {
  const { c, user } = await requireUser();
  const table = TABLE[`${action}:${kind}`];
  const col = COL[kind];
  const { data: existing } = await c.from(table).select('id').eq('user_id', user.id).eq(col, id).limit(1);
  if (existing && existing.length) {
    await c.from(table).delete().eq('id', existing[0].id);
    return false;
  }
  await c.from(table).insert({ user_id: user.id, [col]: id });
  return true;
}

export async function listLibrary() {
  const { c, user } = await requireUser();
  const [sc, fc, sk, fk] = await Promise.all([
    c.from('saved_claims').select('created_at, claims(id, claim_text, verdict, review_status, compound_id, compounds(name, slug, dossier_url))').eq('user_id', user.id),
    c.from('followed_claims').select('created_at, claims(id, claim_text, verdict, review_status, compound_id, compounds(name, slug, dossier_url))').eq('user_id', user.id),
    c.from('saved_compounds').select('created_at, compounds(id, name, slug, class, dossier_url)').eq('user_id', user.id),
    c.from('followed_compounds').select('created_at, compounds(id, name, slug, class, dossier_url)').eq('user_id', user.id),
  ]);
  return {
    savedClaims: (sc.data || []).map((r) => r.claims).filter(Boolean),
    followedClaims: (fc.data || []).map((r) => r.claims).filter(Boolean),
    savedCompounds: (sk.data || []).map((r) => r.compounds).filter(Boolean),
    followedCompounds: (fk.data || []).map((r) => r.compounds).filter(Boolean),
  };
}
