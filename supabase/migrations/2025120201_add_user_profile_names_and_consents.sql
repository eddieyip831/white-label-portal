-- 2025120201_add_user_profile_names_and_consents.sql
-- Purpose:
-- - Replace user_profile.full_name with first_name / last_name
-- - Introduce legal_documents and user_consents for consent tracking
-- - Update on_auth_user_created() to use first_name / last_name

BEGIN;

----------------------------------------------------------------------
-- 1. user_profile: add first_name / last_name, drop full_name
----------------------------------------------------------------------

ALTER TABLE public.user_profile
  ADD COLUMN first_name text;

ALTER TABLE public.user_profile
  ADD COLUMN last_name text;

-- Optional: best-effort backfill.
-- Since we're early stage, this is mainly defensive in case there is data.
UPDATE public.user_profile
SET
  first_name = COALESCE(first_name, full_name)
WHERE
  full_name IS NOT NULL
  AND first_name IS NULL;

-- Now we can safely drop full_name.
ALTER TABLE public.user_profile
  DROP COLUMN full_name;

----------------------------------------------------------------------
-- 2. legal_documents
----------------------------------------------------------------------

CREATE TABLE public.legal_documents (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code         text NOT NULL,  -- 'privacy_policy', 'terms_of_service', 'marketing_opt_in', etc.
  version      text NOT NULL,  -- e.g. '2025-01', 'v1.2'
  title        text NOT NULL,
  url          text NOT NULL,  -- where the full text is hosted
  published_at timestamptz NOT NULL DEFAULT now(),
  is_active    boolean NOT NULL DEFAULT true
);

-- Ensure (code, version) uniqueness.
CREATE UNIQUE INDEX legal_documents_code_version_key
  ON public.legal_documents (code, version);

----------------------------------------------------------------------
-- 3. user_consents
----------------------------------------------------------------------

CREATE TABLE public.user_consents (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      uuid NOT NULL,
  tenant_id    uuid,            -- optional, usually NULL for global docs
  document_id  uuid NOT NULL,
  version      text NOT NULL,   -- snapshot from legal_documents.version
  consented_at timestamptz NOT NULL DEFAULT now(),
  revoked_at   timestamptz
);

-- FKs
ALTER TABLE public.user_consents
  ADD CONSTRAINT user_consents_user_id_fkey
  FOREIGN KEY (user_id)
  REFERENCES auth.users (id)
  ON DELETE CASCADE;

ALTER TABLE public.user_consents
  ADD CONSTRAINT user_consents_document_id_fkey
  FOREIGN KEY (document_id)
  REFERENCES public.legal_documents (id)
  ON DELETE RESTRICT;

ALTER TABLE public.user_consents
  ADD CONSTRAINT user_consents_tenant_id_fkey
  FOREIGN KEY (tenant_id)
  REFERENCES public.tenants (id)
  ON DELETE SET NULL;

-- Indexes for lookups
CREATE INDEX idx_user_consents_user_id
  ON public.user_consents (user_id);

CREATE INDEX idx_user_consents_document_id
  ON public.user_consents (document_id);

CREATE INDEX idx_user_consents_tenant_id
  ON public.user_consents (tenant_id);

----------------------------------------------------------------------
-- 4. Update on_auth_user_created() to use first_name / last_name
----------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.on_auth_user_created()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
declare
  v_user_id uuid;
  v_tenant_id uuid;
  v_free_tier uuid;
  v_member_role uuid;
begin
  v_user_id := new.id;

  -- Unassigned Tenant
  select id into v_tenant_id
  from public.tenants
  where name ilike 'unassigned%';

  -- FREE tier
  select id into v_free_tier
  from public.tiers
  where code = 'free';

  -- MEMBER role
  select id into v_member_role
  from public.roles
  where name = 'member';

  -- Insert user profile
  insert into public.user_profile (id, first_name, last_name, tenant_id, tier_id)
  values (v_user_id, new.raw_user_meta_data->>'full_name', NULL, v_tenant_id, v_free_tier)
  on conflict (id) do nothing;

  -- Assign FREE tier
  insert into public.user_tiers (user_id, tier_id)
  values (v_user_id, v_free_tier)
  on conflict do nothing;

  -- Assign MEMBER role
  insert into public.user_roles (user_id, role_id, tenant_id)
  values (v_user_id, v_member_role, v_tenant_id)
  on conflict do nothing;

  return new;
end;
$$;

COMMIT;
