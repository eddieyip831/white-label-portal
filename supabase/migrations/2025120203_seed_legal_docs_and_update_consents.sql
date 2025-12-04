-- 2025120203_seed_legal_docs_and_update_consents.sql
-- Purpose:
-- - Seed default legal_documents for privacy, terms, marketing
-- - Extend on_auth_user_created() to write user_consents

BEGIN;

----------------------------------------------------------------------
-- 1. Seed default legal documents (idempotent)
----------------------------------------------------------------------

INSERT INTO public.legal_documents (code, version, title, url)
VALUES
  ('privacy_policy', 'v1', 'Default Privacy Policy', '/legal/privacy'),
  ('terms_of_service', 'v1', 'Default Terms of Use', '/legal/terms'),
  ('marketing_communications', 'v1', 'Default Marketing Communications Consent', '/legal/marketing')
ON CONFLICT (code, version) DO NOTHING;

----------------------------------------------------------------------
-- 2. Update on_auth_user_created() to handle consents
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

  v_first_name text;
  v_last_name text;

  v_accept_terms_and_privacy boolean;
  v_marketing_opt_out boolean;

  v_privacy_doc_id uuid;
  v_privacy_version text;

  v_terms_doc_id uuid;
  v_terms_version text;

  v_marketing_doc_id uuid;
  v_marketing_version text;
begin
  v_user_id := new.id;

  -- Unassigned Tenant
  select id into v_tenant_id
  from public.tenants
  where name ilike 'unassigned%'
  limit 1;

  -- FREE tier
  select id into v_free_tier
  from public.tiers
  where code = 'free'
  limit 1;

  -- MEMBER role
  select id into v_member_role
  from public.roles
  where name = 'member'
  limit 1;

  -- Names: prefer discrete first_name/last_name, fall back to full_name if present
  v_first_name := coalesce(
    new.raw_user_meta_data->>'first_name',
    new.raw_user_meta_data->>'full_name'
  );
  v_last_name := new.raw_user_meta_data->>'last_name';

  -- Insert user profile
  insert into public.user_profile (id, first_name, last_name, tenant_id, tier_id)
  values (v_user_id, v_first_name, v_last_name, v_tenant_id, v_free_tier)
  on conflict (id) do nothing;

  -- Assign FREE tier
  insert into public.user_tiers (user_id, tier_id)
  values (v_user_id, v_free_tier)
  on conflict do nothing;

  -- Assign MEMBER role
  insert into public.user_roles (user_id, role_id, tenant_id)
  values (v_user_id, v_member_role, v_tenant_id)
  on conflict do nothing;

  --------------------------------------------------------------------
  -- Consents: privacy, terms, marketing
  --------------------------------------------------------------------

  v_accept_terms_and_privacy :=
    coalesce((new.raw_user_meta_data->>'accepted_terms_and_privacy')::boolean, false);

  v_marketing_opt_out :=
    coalesce((new.raw_user_meta_data->>'marketing_opt_out')::boolean, false);

  -- Privacy Policy & Terms of Service (only if user accepted)
  if v_accept_terms_and_privacy then
    -- Privacy Policy
    select id, version
    into v_privacy_doc_id, v_privacy_version
    from public.legal_documents
    where code = 'privacy_policy'
      and is_active
    order by published_at desc
    limit 1;

    if v_privacy_doc_id is not null then
      insert into public.user_consents (user_id, tenant_id, document_id, version)
      values (v_user_id, v_tenant_id, v_privacy_doc_id, v_privacy_version);
    end if;

    -- Terms of Service
    select id, version
    into v_terms_doc_id, v_terms_version
    from public.legal_documents
    where code = 'terms_of_service'
      and is_active
    order by published_at desc
    limit 1;

    if v_terms_doc_id is not null then
      insert into public.user_consents (user_id, tenant_id, document_id, version)
      values (v_user_id, v_tenant_id, v_terms_doc_id, v_terms_version);
    end if;
  end if;

  -- Marketing communications: only record consent if user did NOT opt out
  if not v_marketing_opt_out then
    select id, version
    into v_marketing_doc_id, v_marketing_version
    from public.legal_documents
    where code = 'marketing_communications'
      and is_active
    order by published_at desc
    limit 1;

    if v_marketing_doc_id is not null then
      insert into public.user_consents (user_id, tenant_id, document_id, version)
      values (v_user_id, v_tenant_id, v_marketing_doc_id, v_marketing_version);
    end if;
  end if;

  return new;
end;
$$;

COMMIT;
