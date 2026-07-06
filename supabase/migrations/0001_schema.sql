-- ═══════════════════════════════════════════════════════════════════════════
-- Aphrodite Research — 0001 schema
-- The database is the source of truth. The model may only phrase what these
-- records already contain. Reference tables are world-readable; user tables are
-- locked to their owner via RLS (see 0002_rls.sql).
-- ═══════════════════════════════════════════════════════════════════════════

create extension if not exists pgcrypto;   -- gen_random_uuid()

-- shared updated_at trigger ---------------------------------------------------
create or replace function set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

-- ── review status: honesty is enforced at the type level ────────────────────
-- A record is 'reviewed' ONLY after a human confirms its sources. Seeded
-- records are 'unverified' or 'needs_sources' — never 'reviewed' by default.
do $$ begin
  create type review_status as enum ('unverified', 'needs_sources', 'reviewed');
exception when duplicate_object then null; end $$;

-- ═══════════════════════════ REFERENCE TABLES ═══════════════════════════════

create table if not exists compounds (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  slug        text not null unique,
  class       text,
  summary     text,
  dossier_url text,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create trigger compounds_updated before update on compounds
  for each row execute function set_updated_at();

create table if not exists compound_aliases (
  id          uuid primary key default gen_random_uuid(),
  compound_id uuid not null references compounds(id) on delete cascade,
  alias       text not null
);
create index if not exists compound_aliases_compound_idx on compound_aliases(compound_id);
create index if not exists compound_aliases_alias_idx on compound_aliases(lower(alias));

create table if not exists sources (
  id           uuid primary key default gen_random_uuid(),
  type         text not null default 'study',   -- study | review | registry | label | guideline
  title        text not null,
  authors      text,
  year         int,
  url          text,
  registry_id  text,                             -- e.g. NCT number
  quality_note text,
  created_at   timestamptz not null default now()
);

create table if not exists claims (
  id                        uuid primary key default gen_random_uuid(),
  compound_id               uuid not null references compounds(id) on delete cascade,
  claim_text                text not null,
  outcome                   text,               -- e.g. "tendon healing", "weight loss"
  implied_route             text,               -- e.g. "injection", "topical", "oral"
  implied_population        text,               -- e.g. "humans", "athletes"
  human_evidence_level      text,               -- e.g. "None","Very limited","Early","Moderate","Strong"
  preclinical_evidence_level text,              -- e.g. "None","Limited","Moderate","Extensive"
  verdict                   text,               -- current verdict label
  plain_language_explanation text,
  critical_uncertainty      text,
  claim_gap                 text,               -- "Low","Low–Moderate","Moderate","High","Severe","Extreme"
  route_integrity           text[] default '{}',-- flags: {"ROUTE MISMATCH","ANIMAL-TO-HUMAN LEAP"}
  reviewed_at               timestamptz,
  review_status             review_status not null default 'unverified',
  reviewer                  text,
  created_at                timestamptz not null default now(),
  updated_at                timestamptz not null default now()
);
create index if not exists claims_compound_idx on claims(compound_id);
create index if not exists claims_review_status_idx on claims(review_status);
create trigger claims_updated before update on claims
  for each row execute function set_updated_at();

-- verdict history — every verdict a claim has ever held
create table if not exists claim_verdicts (
  id             uuid primary key default gen_random_uuid(),
  claim_id       uuid not null references claims(id) on delete cascade,
  verdict        text not null,
  rationale      text,
  effective_from timestamptz not null default now()
);
create index if not exists claim_verdicts_claim_idx on claim_verdicts(claim_id);

-- field-level audit of edits to a claim
create table if not exists claim_revisions (
  id         uuid primary key default gen_random_uuid(),
  claim_id   uuid not null references claims(id) on delete cascade,
  field      text not null,
  old_value  text,
  new_value  text,
  changed_at timestamptz not null default now(),
  changed_by text
);
create index if not exists claim_revisions_claim_idx on claim_revisions(claim_id);

-- links a claim to its supporting/refuting sources, at sentence granularity
create table if not exists claim_sources (
  id           uuid primary key default gen_random_uuid(),
  claim_id     uuid not null references claims(id) on delete cascade,
  source_id    uuid not null references sources(id) on delete cascade,
  supports     boolean not null default true,
  sentence_ref text,                            -- the exact sentence this source backs
  unique (claim_id, source_id, sentence_ref)
);
create index if not exists claim_sources_claim_idx on claim_sources(claim_id);
create index if not exists claim_sources_source_idx on claim_sources(source_id);

create table if not exists studies (
  id           uuid primary key default gen_random_uuid(),
  source_id    uuid not null references sources(id) on delete cascade,
  design       text,                            -- "RCT", "systematic review", "animal", ...
  population_n int,
  is_human     boolean not null default false,
  notes        text
);
create index if not exists studies_source_idx on studies(source_id);

create table if not exists study_compounds (
  id          uuid primary key default gen_random_uuid(),
  study_id    uuid not null references studies(id) on delete cascade,
  compound_id uuid not null references compounds(id) on delete cascade,
  unique (study_id, compound_id)
);

-- Phase 2 target: populated by the stubbed ClinicalTrials.gov / openFDA fetcher.
create table if not exists research_updates (
  id           uuid primary key default gen_random_uuid(),
  compound_id  uuid references compounds(id) on delete cascade,
  claim_id     uuid references claims(id) on delete set null,
  headline     text not null,
  body         text,
  source_id    uuid references sources(id) on delete set null,
  published_at timestamptz not null default now()
);
create index if not exists research_updates_compound_idx on research_updates(compound_id);
create index if not exists research_updates_published_idx on research_updates(published_at desc);

-- ═══════════════════════════ USER TABLES ════════════════════════════════════

create table if not exists profiles (
  id           uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  created_at   timestamptz not null default now()
);

create table if not exists saved_claims (
  id        uuid primary key default gen_random_uuid(),
  user_id   uuid not null references auth.users(id) on delete cascade,
  claim_id  uuid not null references claims(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, claim_id)
);

create table if not exists followed_claims (
  id        uuid primary key default gen_random_uuid(),
  user_id   uuid not null references auth.users(id) on delete cascade,
  claim_id  uuid not null references claims(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, claim_id)
);

create table if not exists saved_compounds (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  compound_id uuid not null references compounds(id) on delete cascade,
  created_at  timestamptz not null default now(),
  unique (user_id, compound_id)
);

create table if not exists followed_compounds (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  compound_id uuid not null references compounds(id) on delete cascade,
  created_at  timestamptz not null default now(),
  unique (user_id, compound_id)
);

create table if not exists query_logs (
  id                  uuid primary key default gen_random_uuid(),
  user_id             uuid references auth.users(id) on delete set null,
  raw_query           text not null,
  matched_compound_id uuid references compounds(id) on delete set null,
  matched_claim_id    uuid references claims(id) on delete set null,
  route_taken         text not null,   -- 'answer' | 'refuse' | 'insufficient' | 'error'
  created_at          timestamptz not null default now()
);
create index if not exists query_logs_user_idx on query_logs(user_id);
create index if not exists query_logs_created_idx on query_logs(created_at desc);
create index if not exists query_logs_route_idx on query_logs(route_taken);
