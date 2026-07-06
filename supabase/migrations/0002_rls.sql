-- ═══════════════════════════════════════════════════════════════════════════
-- Aphrodite Research — 0002 Row-Level Security
--
-- Reference tables : world-READABLE, writes restricted to the service role
--                    (the service-role key bypasses RLS; no write policy is
--                    granted to anon/authenticated, so the browser can never
--                    mutate the evidence base).
-- User tables      : a user may only read/write their OWN rows.
-- ═══════════════════════════════════════════════════════════════════════════

-- ── Reference tables: enable RLS, grant SELECT to everyone ──────────────────
do $$
declare t text;
begin
  foreach t in array array[
    'compounds','compound_aliases','sources','claims','claim_verdicts',
    'claim_revisions','claim_sources','studies','study_compounds','research_updates'
  ] loop
    execute format('alter table %I enable row level security;', t);
    execute format('drop policy if exists %I on %I;', t||'_read', t);
    execute format(
      'create policy %I on %I for select to anon, authenticated using (true);',
      t||'_read', t
    );
  end loop;
end $$;

-- ── profiles ────────────────────────────────────────────────────────────────
alter table profiles enable row level security;

drop policy if exists profiles_select_own on profiles;
create policy profiles_select_own on profiles
  for select to authenticated using (id = auth.uid());

drop policy if exists profiles_insert_own on profiles;
create policy profiles_insert_own on profiles
  for insert to authenticated with check (id = auth.uid());

drop policy if exists profiles_update_own on profiles;
create policy profiles_update_own on profiles
  for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

-- ── saved_* / followed_* : own rows only ────────────────────────────────────
do $$
declare t text;
begin
  foreach t in array array[
    'saved_claims','followed_claims','saved_compounds','followed_compounds'
  ] loop
    execute format('alter table %I enable row level security;', t);

    execute format('drop policy if exists %I on %I;', t||'_select_own', t);
    execute format(
      'create policy %I on %I for select to authenticated using (user_id = auth.uid());',
      t||'_select_own', t
    );

    execute format('drop policy if exists %I on %I;', t||'_insert_own', t);
    execute format(
      'create policy %I on %I for insert to authenticated with check (user_id = auth.uid());',
      t||'_insert_own', t
    );

    execute format('drop policy if exists %I on %I;', t||'_delete_own', t);
    execute format(
      'create policy %I on %I for delete to authenticated using (user_id = auth.uid());',
      t||'_delete_own', t
    );
  end loop;
end $$;

-- ── query_logs : a user reads only their own; inserts come from the server ──
-- (service role bypasses RLS, so /api/ask can log anonymous + authenticated
--  queries; the browser can only ever read back its own rows).
alter table query_logs enable row level security;

drop policy if exists query_logs_select_own on query_logs;
create policy query_logs_select_own on query_logs
  for select to authenticated using (user_id = auth.uid());
