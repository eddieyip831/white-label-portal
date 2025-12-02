-- 2025120202_update_on_auth_user_created_first_last.sql
-- Purpose:
-- - Make on_auth_user_created() read first_name / last_name from auth.users.raw_user_meta_data
-- - Keep a fallback to full_name for backward compatibility

BEGIN;

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

  -- Prefer discrete first_name / last_name; fall back to full_name if present
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

  return new;
end;
$$;

COMMIT;
