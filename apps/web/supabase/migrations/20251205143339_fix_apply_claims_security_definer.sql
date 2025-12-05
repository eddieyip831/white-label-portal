-- Fix: Add SECURITY DEFINER to apply_claims_to_user function
-- This allows the function to update auth.users when triggered by user_profile updates
-- Without this, the trigger fails with "permission denied for table users"

CREATE OR REPLACE FUNCTION public.apply_claims_to_user(p_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_claims       jsonb;
  v_roles        jsonb;
  v_permissions  jsonb;
  v_tier         text;
  v_tenant_id    text;
BEGIN
  -- Build claims from our helper (tenant/tier/roles/permissions)
  v_claims := public.build_claims(p_user_id);

  -- Extract individual pieces, with safe defaults
  v_roles       := COALESCE(v_claims->'roles', '[]'::jsonb);
  v_permissions := COALESCE(v_claims->'permissions', '[]'::jsonb);
  v_tier        := COALESCE(v_claims->>'tier', 'free');
  v_tenant_id   := v_claims->>'tenant_id';

  -- Flatten into top-level app_metadata keys.
  -- IMPORTANT:
  --  - Remove legacy nested "claims" (if it exists) with "- 'claims'"
  --  - Then merge new flat keys so Supabase includes them in the JWT.
  UPDATE auth.users
  SET raw_app_meta_data =
        COALESCE(raw_app_meta_data, '{}'::jsonb)
        - 'claims'
        || jsonb_build_object(
             'roles',       v_roles,
             'permissions', v_permissions,
             'tier',        v_tier
           )
        || CASE
             WHEN v_tenant_id IS NULL THEN '{}'::jsonb
             ELSE jsonb_build_object('tenant_id', v_tenant_id)
           END
  WHERE id = p_user_id;
END;
$$;

-- Revoke direct execution from public to prevent misuse
-- The function will still work when called via triggers
REVOKE ALL ON FUNCTION public.apply_claims_to_user(uuid) FROM PUBLIC;
