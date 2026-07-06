# Ask Aphrodite — API

Server-side endpoints (Vercel serverless functions in `/api`). Secrets
(`SUPABASE_SERVICE_ROLE_KEY`, `ANTHROPIC_API_KEY`) live only here and are never
exposed to the browser.

---

## `POST /api/ask`

The one product loop: **paste a claim → cited Evidence Receipt.**

### Request
```json
{ "query": "BPC-157 heals tendon injuries in humans.", "user_id": "uuid-or-null" }
```
- `query` (required) — the pasted claim / question. Trimmed, capped at 600 chars.
- `user_id` (optional) — Supabase auth user id, for attributing `query_logs`.

`query: "__ping__"` is a health check → `200 {ok:true, route:"ping"}` (no DB, no log).

### Pipeline (server-side)
1. **Validate + sanitize** input.
2. **Safety gate (pre-filter)** — dosing / administration / sourcing / vendor intent →
   `route:"refuse"`. No model call. Logged.
3. **Retrieve** the best-matching compound + claim + sources from the DB.
4. **Insufficient-evidence gate** — nothing matched → `route:"insufficient"`. No model call.
5. **Grounded generation** (Anthropic, optional) — writes `direct_answer` using ONLY the
   retrieved records, each factual sentence carrying a `[S#]` citation marker.
6. **Citation validation** — invented `[S#]` markers are stripped; dose-number leakage is
   rejected; if no valid citation survives, we fall back to the record's own explanation
   (`answer_source:"record"`) rather than return anything uncited.
7. **Log** to `query_logs` and return structured JSON.

### Response — `route: "answer"` (the Evidence Receipt)
```json
{
  "ok": true,
  "route": "answer",
  "compound": { "name": "GHK-Cu", "slug": "ghk-cu", "class": "Copper peptide", "dossier_url": "ghk-cu.html" },
  "claim": { "id": "uuid", "text": "...", "outcome": "hair growth", "implied_route": "topical", "implied_population": "humans" },
  "verdict": "Early, limited human evidence",
  "direct_answer": "There is biological plausibility ... [S1]",
  "human_evidence": "Early",
  "preclinical_evidence": "Moderate",
  "claim_gap": "High",
  "integrity_flags": ["SMALL-SAMPLE SIGNAL", "..."],
  "route_warning": null,
  "population_warning": null,
  "safety_uncertainty": "Only a handful of small trials exist...",
  "anecdotal_context": null,
  "confidence": "Low",
  "review_status": "unverified",
  "pending_verification": true,
  "last_reviewed": null,
  "reviewer": null,
  "sources": [
    { "cite": "S1", "type": "review", "title": "...", "authors": "...", "year": 2026,
      "url": "...", "registry_id": null, "quality_note": "...pending verification.",
      "supports": true, "sentence_ref": "..." }
  ],
  "answer_source": "record",
  "actions": [
    { "type": "follow_claim", "claim_id": "uuid", "label": "Follow claim" },
    { "type": "save_claim", "claim_id": "uuid", "label": "Save to Library" },
    { "type": "open_dossier", "url": "ghk-cu.html", "label": "Open GHK-Cu dossier" },
    { "type": "share", "label": "Share Evidence Receipt" }
  ]
}
```

### Other routes
| `route` | When | Key fields |
|---|---|---|
| `refuse` | dosing / sourcing intent | `category` (`dosing`\|`sourcing`), `verdict`, `direct_answer`, `study_context_note` |
| `insufficient` | no reviewed record matched | `verdict`, `direct_answer`, `covered[]` (what IS in the library) |

### Status codes
| Code | Meaning |
|---|---|
| `200` | receipt returned (any route) |
| `400` | `empty_query` |
| `405` | not POST |
| `503` | `backend_unconfigured` — Supabase env not set. The frontend falls back to its local library. |
| `500` | `server_error` (also logged as `route:"error"`) |

### Honesty guarantees
- **The DB is the source of truth.** The model may only phrase what records contain.
- **No factual sentence without a source.** Uncited model text is discarded.
- **`pending_verification: true`** whenever `review_status !== 'reviewed'` — surfaced in the UI.
- **No dose ever leaks.** Two-layer safety (pre-filter intent + post-filter number scan).

---

## `GET /api/public-config`
Browser-safe Supabase config for the frontend (anon key is public; RLS enforces access).
```json
{ "supabaseUrl": "https://...", "supabaseAnonKey": "...", "authEnabled": true }
```
`authEnabled:false` when env isn't set → the site runs read-only with local fallback.

## `GET /api/stats`
Aggregate-only analytics (no PII, no individual rows).
```json
{ "asks": { "total": 0, "answered": 0, "refused": 0, "insufficient": 0 },
  "saves": { "claims": 0, "compounds": 0 },
  "follows": { "claims": 0, "compounds": 0 } }
```

---

## Save / Follow (client-side, RLS-guarded)
Save/follow are done directly from the browser via `@supabase/supabase-js` using the
signed-in user's JWT — RLS ensures a user can only read/write their own rows. See
`assets/aphrodite.js` (`toggleMark`, `isMarked`, `listLibrary`). No server endpoint needed.

## Environment
See `.env.example`. Server-only: `SUPABASE_SERVICE_ROLE_KEY`, `ANTHROPIC_API_KEY`.
`ASK_MODEL_DISABLED=true` runs the whole loop deterministically from the DB with no
Anthropic call — useful before you have a model key.
