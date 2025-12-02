


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE SCHEMA IF NOT EXISTS "public";


ALTER SCHEMA "public" OWNER TO "pg_database_owner";


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE OR REPLACE FUNCTION "public"."apply_claims_to_role_users"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    v_role_id uuid;
    v_user_id uuid;
BEGIN
    v_role_id := COALESCE(NEW.role_id, OLD.role_id);

    FOR v_user_id IN
        SELECT user_id
        FROM public.user_roles
        WHERE role_id = v_role_id
    LOOP
        PERFORM public.apply_claims_to_user(v_user_id);
    END LOOP;

    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."apply_claims_to_role_users"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."apply_claims_to_user"("p_user_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    v_claims jsonb;
BEGIN
    v_claims := public.build_claims(p_user_id);

    UPDATE auth.users
    SET raw_app_meta_data = jsonb_set(
        COALESCE(raw_app_meta_data, '{}'::jsonb),
        '{claims}',
        v_claims
    )
    WHERE id = p_user_id;
END;
$$;


ALTER FUNCTION "public"."apply_claims_to_user"("p_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."build_claims"("p_user_id" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_tenant uuid;
    v_tier text;
    v_roles text[];
    v_permissions text[];
BEGIN
    -- Tenant
    SELECT tenant_id 
    INTO v_tenant
    FROM public.user_profile
    WHERE id = p_user_id;

    -- Tier
    SELECT t.name
    INTO v_tier
    FROM public.tiers t
    JOIN public.user_profile up ON up.tier_id = t.id
    WHERE up.id = p_user_id;

    -- Roles
    SELECT array_agg(r.name)::text[]
    INTO v_roles
    FROM public.user_roles ur
    JOIN public.roles r ON r.id = ur.role_id
    WHERE ur.user_id = p_user_id;

    -- Permissions
    SELECT array_agg(DISTINCT p.name)::text[]
    INTO v_permissions
    FROM public.user_roles ur
    JOIN public.role_permissions rp ON rp.role_id = ur.role_id
    JOIN public.permissions p ON p.id = rp.permission_id
    WHERE ur.user_id = p_user_id;

    RETURN jsonb_build_object(
        'tenant_id', v_tenant,
        'tier', COALESCE(v_tier, 'free'),
        'roles', COALESCE(v_roles, ARRAY[]::text[]),
        'permissions', COALESCE(v_permissions, ARRAY[]::text[])
    );
END;
$$;


ALTER FUNCTION "public"."build_claims"("p_user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_role_permissions"("role_id" "uuid") RETURNS TABLE("permission" "text")
    LANGUAGE "sql" SECURITY DEFINER
    AS $$
  select p.name
  from role_permissions rp
  join permissions p on p.id = rp.permission_id
  where rp.role_id = role_id;
$$;


ALTER FUNCTION "public"."get_role_permissions"("role_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_user_permissions"("user_id" "uuid") RETURNS TABLE("permission" "text")
    LANGUAGE "sql" SECURITY DEFINER
    AS $$
  select p.name
  from user_roles ur
  join role_permissions rp on rp.role_id = ur.role_id
  join permissions p on p.id = rp.permission_id
  where ur.user_id = user_id;
$$;


ALTER FUNCTION "public"."get_user_permissions"("user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."on_auth_user_created"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_user_id uuid := NEW.id;

  v_tenant_id    uuid;
  v_free_tier    uuid;
  v_member_role  uuid;

  v_first_name text;
  v_last_name  text;

  v_accept_terms_and_privacy boolean;
  v_marketing_opt_out        boolean;

  v_privacy_doc_id    uuid;
  v_privacy_version   text;

  v_terms_doc_id      uuid;
  v_terms_version     text;

  v_marketing_doc_id  uuid;
  v_marketing_version text;
BEGIN
  --------------------------------------------------------------------
  -- 1) Resolve tenant / tier / role from existing tables
  --------------------------------------------------------------------
  SELECT id
  INTO v_tenant_id
  FROM public.tenants
  WHERE name ILIKE 'unassigned%'
  LIMIT 1;

  SELECT id
  INTO v_free_tier
  FROM public.tiers
  WHERE code = 'free'
  LIMIT 1;

  SELECT id
  INTO v_member_role
  FROM public.roles
  WHERE name = 'member'
  LIMIT 1;

  -- If any core config is missing, don't block auth
  IF v_tenant_id IS NULL OR v_free_tier IS NULL OR v_member_role IS NULL THEN
    RAISE LOG 'on_auth_user_created: missing tenant/tier/role config for user % (tenant %, tier %, role %)',
      v_user_id, v_tenant_id, v_free_tier, v_member_role;
    RETURN NEW;
  END IF;

  --------------------------------------------------------------------
  -- 2) Names + consent flags from raw_user_meta_data
  --------------------------------------------------------------------
  v_first_name := COALESCE(
    NEW.raw_user_meta_data->>'first_name',
    NEW.raw_user_meta_data->>'full_name'
  );
  v_last_name := COALESCE(NEW.raw_user_meta_data->>'last_name', '');

  v_accept_terms_and_privacy :=
    COALESCE((NEW.raw_user_meta_data->>'accepted_terms_and_privacy')::boolean, false);

  v_marketing_opt_out :=
    COALESCE((NEW.raw_user_meta_data->>'marketing_opt_out')::boolean, false);

  --------------------------------------------------------------------
  -- 3) user_profile (upsert, never throw)
  --------------------------------------------------------------------
  BEGIN
    INSERT INTO public.user_profile (id, first_name, last_name, tenant_id, tier_id)
    VALUES (v_user_id, v_first_name, v_last_name, v_tenant_id, v_free_tier)
    ON CONFLICT (id) DO UPDATE
      SET first_name = EXCLUDED.first_name,
          last_name  = EXCLUDED.last_name,
          tenant_id  = COALESCE(public.user_profile.tenant_id, EXCLUDED.tenant_id),
          tier_id    = COALESCE(public.user_profile.tier_id, EXCLUDED.tier_id);
  EXCEPTION WHEN OTHERS THEN
    RAISE LOG 'on_auth_user_created: user_profile upsert failed for %: %',
      v_user_id, SQLERRM;
  END;

  --------------------------------------------------------------------
  -- 4) user_tiers
  --------------------------------------------------------------------
  -- BEGIN
  --   INSERT INTO public.user_tiers (user_id, tier_id)
  --   VALUES (v_user_id, v_free_tier)
  --   ON CONFLICT DO NOTHING;
  -- EXCEPTION WHEN OTHERS THEN
  --   RAISE LOG 'on_auth_user_created: user_tiers insert failed for %: %',
  --     v_user_id, SQLERRM;
  -- END;

  --------------------------------------------------------------------
  -- 5) user_roles
  --------------------------------------------------------------------
  BEGIN
    INSERT INTO public.user_roles (user_id, role_id, tenant_id)
    VALUES (v_user_id, v_member_role, v_tenant_id)
    ON CONFLICT DO NOTHING;
  EXCEPTION WHEN OTHERS THEN
    RAISE LOG 'on_auth_user_created: user_roles insert failed for %: %',
      v_user_id, SQLERRM;
  END;

  --------------------------------------------------------------------
  -- 6) Consents: privacy + terms if accepted
  --------------------------------------------------------------------
  IF v_accept_terms_and_privacy THEN
    BEGIN
      -- Privacy Policy
      SELECT id, version
      INTO v_privacy_doc_id, v_privacy_version
      FROM public.legal_documents
      WHERE code = 'privacy_policy'
        AND is_active
      ORDER BY published_at DESC
      LIMIT 1;

      IF v_privacy_doc_id IS NOT NULL THEN
        INSERT INTO public.user_consents (user_id, tenant_id, document_id, version)
        VALUES (v_user_id, v_tenant_id, v_privacy_doc_id, v_privacy_version);
      END IF;

      -- Terms of Service
      SELECT id, version
      INTO v_terms_doc_id, v_terms_version
      FROM public.legal_documents
      WHERE code = 'terms_of_service'
        AND is_active
      ORDER BY published_at DESC
      LIMIT 1;

      IF v_terms_doc_id IS NOT NULL THEN
        INSERT INTO public.user_consents (user_id, tenant_id, document_id, version)
        VALUES (v_user_id, v_tenant_id, v_terms_doc_id, v_terms_version);
      END IF;
    EXCEPTION WHEN OTHERS THEN
      RAISE LOG 'on_auth_user_created: privacy/terms consents failed for %: %',
        v_user_id, SQLERRM;
    END;
  END IF;

  --------------------------------------------------------------------
  -- 7) Marketing consent – only if user did NOT opt out
  --------------------------------------------------------------------
  IF NOT v_marketing_opt_out THEN
    BEGIN
      SELECT id, version
      INTO v_marketing_doc_id, v_marketing_version
      FROM public.legal_documents
      WHERE code = 'marketing_communications'
        AND is_active
      ORDER BY published_at DESC
      LIMIT 1;

      IF v_marketing_doc_id IS NOT NULL THEN
        INSERT INTO public.user_consents (user_id, tenant_id, document_id, version)
        VALUES (v_user_id, v_tenant_id, v_marketing_doc_id, v_marketing_version);
      END IF;
    EXCEPTION WHEN OTHERS THEN
      RAISE LOG 'on_auth_user_created: marketing consent failed for %: %',
        v_user_id, SQLERRM;
    END;
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."on_auth_user_created"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."user_has_permission"("user_id" "uuid", "permission_name" "text") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
begin
  return exists (
    select 1
    from user_roles ur
    join role_permissions rp on rp.role_id = ur.role_id
    join permissions p on p.id = rp.permission_id
    where ur.user_id = user_id
    and p.name = permission_name
  );
end;
$$;


ALTER FUNCTION "public"."user_has_permission"("user_id" "uuid", "permission_name" "text") OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."function_groups" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "slug" "text" NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "sort_order" integer DEFAULT 1,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."function_groups" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."functions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "label" "text" NOT NULL,
    "description" "text",
    "route" "text" NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "slug" "text",
    "group_id" "uuid",
    "sort_order" integer DEFAULT 1,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."functions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."legal_documents" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "code" "text" NOT NULL,
    "version" "text" NOT NULL,
    "title" "text" NOT NULL,
    "url" "text" NOT NULL,
    "published_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL
);


ALTER TABLE "public"."legal_documents" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."modules" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "key" "text" NOT NULL,
    "label" "text" NOT NULL,
    "description" "text",
    "enabled" boolean DEFAULT false,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "tenant_id" "uuid"
);


ALTER TABLE "public"."modules" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."permissions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "module" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "tenant_id" "uuid"
);


ALTER TABLE "public"."permissions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."role_permissions" (
    "role_id" "uuid" NOT NULL,
    "permission_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "tenant_id" "uuid" NOT NULL
);


ALTER TABLE "public"."role_permissions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."roles" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "tenant_id" "uuid"
);


ALTER TABLE "public"."roles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."tenant_members" (
    "tenant_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "role" "text" DEFAULT 'member'::"text" NOT NULL,
    "status" "text" DEFAULT 'active'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."tenant_members" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."tenants" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "slug" "text",
    "tier_id" "uuid"
);


ALTER TABLE "public"."tenants" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."tiers" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "tenant_id" "uuid",
    "name" "text" NOT NULL,
    "description" "text",
    "code" "text",
    "sort_order" integer DEFAULT 1 NOT NULL
);


ALTER TABLE "public"."tiers" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_profile" (
    "id" "uuid" NOT NULL,
    "tenant_id" "uuid",
    "attributes" "jsonb" DEFAULT '{}'::"jsonb",
    "tier_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "first_name" "text",
    "last_name" "text"
);


ALTER TABLE "public"."user_profile" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_roles" (
    "user_id" "uuid" NOT NULL,
    "role_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "tenant_id" "uuid" NOT NULL
);


ALTER TABLE "public"."user_roles" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."tenant_members_admin" AS
 SELECT "ur"."tenant_id",
    "t"."name" AS "tenant_name",
    "ur"."user_id",
    "u"."email" AS "user_email",
    "ur"."role_id",
    "r"."name" AS "role_name",
    "up"."tier_id",
    "tr"."name" AS "tier_name",
    "ur"."created_at"
   FROM ((((("public"."user_roles" "ur"
     JOIN "public"."tenants" "t" ON (("t"."id" = "ur"."tenant_id")))
     JOIN "auth"."users" "u" ON (("u"."id" = "ur"."user_id")))
     LEFT JOIN "public"."roles" "r" ON (("r"."id" = "ur"."role_id")))
     LEFT JOIN "public"."user_profile" "up" ON (("up"."id" = "ur"."user_id")))
     LEFT JOIN "public"."tiers" "tr" ON (("tr"."id" = "up"."tier_id")));


ALTER VIEW "public"."tenant_members_admin" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."tier_functions" (
    "tier_id" "uuid" NOT NULL,
    "function_id" "uuid" NOT NULL
);


ALTER TABLE "public"."tier_functions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."tier_permissions" (
    "tier_id" "uuid" NOT NULL,
    "permission_id" "uuid" NOT NULL,
    "tenant_id" "uuid" NOT NULL
);


ALTER TABLE "public"."tier_permissions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_attribute_definitions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "key" "text" NOT NULL,
    "label" "text" NOT NULL,
    "data_type" "text" NOT NULL,
    "required" boolean DEFAULT false,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "tenant_id" "uuid"
);


ALTER TABLE "public"."user_attribute_definitions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_attributes" (
    "user_id" "uuid" NOT NULL,
    "attribute_key" "text" NOT NULL,
    "value" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "tenant_id" "uuid" NOT NULL
);


ALTER TABLE "public"."user_attributes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_consents" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "tenant_id" "uuid",
    "document_id" "uuid" NOT NULL,
    "version" "text" NOT NULL,
    "consented_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "revoked_at" timestamp with time zone
);


ALTER TABLE "public"."user_consents" OWNER TO "postgres";


ALTER TABLE ONLY "public"."function_groups"
    ADD CONSTRAINT "function_groups_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."function_groups"
    ADD CONSTRAINT "function_groups_slug_key" UNIQUE ("slug");



ALTER TABLE ONLY "public"."functions"
    ADD CONSTRAINT "functions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."functions"
    ADD CONSTRAINT "functions_slug_key" UNIQUE ("slug");



ALTER TABLE ONLY "public"."legal_documents"
    ADD CONSTRAINT "legal_documents_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."modules"
    ADD CONSTRAINT "modules_key_key" UNIQUE ("key");



ALTER TABLE ONLY "public"."modules"
    ADD CONSTRAINT "modules_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."permissions"
    ADD CONSTRAINT "permissions_name_key" UNIQUE ("name");



ALTER TABLE ONLY "public"."permissions"
    ADD CONSTRAINT "permissions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."role_permissions"
    ADD CONSTRAINT "role_permissions_pkey" PRIMARY KEY ("role_id", "permission_id");



ALTER TABLE ONLY "public"."roles"
    ADD CONSTRAINT "roles_name_key" UNIQUE ("name");



ALTER TABLE ONLY "public"."roles"
    ADD CONSTRAINT "roles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."tenant_members"
    ADD CONSTRAINT "tenant_members_pkey" PRIMARY KEY ("tenant_id", "user_id");



ALTER TABLE ONLY "public"."tenants"
    ADD CONSTRAINT "tenants_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."tenants"
    ADD CONSTRAINT "tenants_slug_key" UNIQUE ("slug");



ALTER TABLE ONLY "public"."tier_functions"
    ADD CONSTRAINT "tier_functions_pkey" PRIMARY KEY ("tier_id", "function_id");



ALTER TABLE ONLY "public"."tier_permissions"
    ADD CONSTRAINT "tier_permissions_pkey" PRIMARY KEY ("tier_id", "permission_id");



ALTER TABLE ONLY "public"."tiers"
    ADD CONSTRAINT "tiers_code_key" UNIQUE ("code");



ALTER TABLE ONLY "public"."tiers"
    ADD CONSTRAINT "tiers_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."tiers"
    ADD CONSTRAINT "tiers_tenant_id_name_key" UNIQUE ("tenant_id", "name");



ALTER TABLE ONLY "public"."user_attribute_definitions"
    ADD CONSTRAINT "user_attribute_definitions_key_key" UNIQUE ("key");



ALTER TABLE ONLY "public"."user_attribute_definitions"
    ADD CONSTRAINT "user_attribute_definitions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_attributes"
    ADD CONSTRAINT "user_attributes_pkey" PRIMARY KEY ("user_id", "attribute_key");



ALTER TABLE ONLY "public"."user_consents"
    ADD CONSTRAINT "user_consents_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_profile"
    ADD CONSTRAINT "user_profile_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_roles"
    ADD CONSTRAINT "user_roles_pkey" PRIMARY KEY ("user_id", "role_id");



CREATE INDEX "idx_user_consents_document_id" ON "public"."user_consents" USING "btree" ("document_id");



CREATE INDEX "idx_user_consents_tenant_id" ON "public"."user_consents" USING "btree" ("tenant_id");



CREATE INDEX "idx_user_consents_user_id" ON "public"."user_consents" USING "btree" ("user_id");



CREATE UNIQUE INDEX "legal_documents_code_version_key" ON "public"."legal_documents" USING "btree" ("code", "version");



ALTER TABLE ONLY "public"."functions"
    ADD CONSTRAINT "functions_group_id_fkey" FOREIGN KEY ("group_id") REFERENCES "public"."function_groups"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."modules"
    ADD CONSTRAINT "modules_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id");



ALTER TABLE ONLY "public"."permissions"
    ADD CONSTRAINT "permissions_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id");



ALTER TABLE ONLY "public"."role_permissions"
    ADD CONSTRAINT "role_permissions_permission_id_fkey" FOREIGN KEY ("permission_id") REFERENCES "public"."permissions"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."role_permissions"
    ADD CONSTRAINT "role_permissions_role_id_fkey" FOREIGN KEY ("role_id") REFERENCES "public"."roles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."roles"
    ADD CONSTRAINT "roles_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id");



ALTER TABLE ONLY "public"."role_permissions"
    ADD CONSTRAINT "rp_tenant_fk" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."tenant_members"
    ADD CONSTRAINT "tenant_members_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."tenant_members"
    ADD CONSTRAINT "tenant_members_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."tenants"
    ADD CONSTRAINT "tenants_tier_id_fkey" FOREIGN KEY ("tier_id") REFERENCES "public"."tiers"("id");



ALTER TABLE ONLY "public"."tier_functions"
    ADD CONSTRAINT "tier_functions_function_id_fkey" FOREIGN KEY ("function_id") REFERENCES "public"."functions"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."tier_functions"
    ADD CONSTRAINT "tier_functions_tier_id_fkey" FOREIGN KEY ("tier_id") REFERENCES "public"."tiers"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."tier_permissions"
    ADD CONSTRAINT "tier_permissions_permission_id_fkey" FOREIGN KEY ("permission_id") REFERENCES "public"."permissions"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."tier_permissions"
    ADD CONSTRAINT "tier_permissions_tier_id_fkey" FOREIGN KEY ("tier_id") REFERENCES "public"."tiers"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."tiers"
    ADD CONSTRAINT "tiers_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."tier_permissions"
    ADD CONSTRAINT "tp_tenant_fk" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_attributes"
    ADD CONSTRAINT "ua_tenant_fk" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_attribute_definitions"
    ADD CONSTRAINT "uad_tenant_fk" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_roles"
    ADD CONSTRAINT "ur_tenant_fk" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_attributes"
    ADD CONSTRAINT "user_attributes_attribute_key_fkey" FOREIGN KEY ("attribute_key") REFERENCES "public"."user_attribute_definitions"("key");



ALTER TABLE ONLY "public"."user_attributes"
    ADD CONSTRAINT "user_attributes_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_consents"
    ADD CONSTRAINT "user_consents_document_id_fkey" FOREIGN KEY ("document_id") REFERENCES "public"."legal_documents"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."user_consents"
    ADD CONSTRAINT "user_consents_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."user_consents"
    ADD CONSTRAINT "user_consents_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_profile"
    ADD CONSTRAINT "user_profile_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_profile"
    ADD CONSTRAINT "user_profile_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id");



ALTER TABLE ONLY "public"."user_profile"
    ADD CONSTRAINT "user_profile_tier_id_fkey" FOREIGN KEY ("tier_id") REFERENCES "public"."tiers"("id");



ALTER TABLE ONLY "public"."user_roles"
    ADD CONSTRAINT "user_roles_role_id_fkey" FOREIGN KEY ("role_id") REFERENCES "public"."roles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_roles"
    ADD CONSTRAINT "user_roles_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



CREATE POLICY "Admin can manage modules" ON "public"."modules" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM ("public"."user_roles" "ur"
     JOIN "public"."roles" "r" ON (("r"."id" = "ur"."role_id")))
  WHERE (("ur"."user_id" = "auth"."uid"()) AND ("r"."name" = 'admin'::"text")))));



CREATE POLICY "Admin can modify RBAC tables" ON "public"."roles" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM ("public"."user_roles"
     JOIN "public"."roles" "r" ON (("user_roles"."role_id" = "r"."id")))
  WHERE (("user_roles"."user_id" = "auth"."uid"()) AND ("r"."name" = 'admin'::"text")))));



CREATE POLICY "Admin can modify permissions" ON "public"."permissions" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM ("public"."user_roles"
     JOIN "public"."roles" "r" ON (("r"."id" = "user_roles"."role_id")))
  WHERE (("user_roles"."user_id" = "auth"."uid"()) AND ("r"."name" = 'admin'::"text")))));



CREATE POLICY "Allow read for authenticated" ON "public"."permissions" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Allow read for authenticated" ON "public"."role_permissions" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Allow read for authenticated" ON "public"."roles" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Read enabled modules" ON "public"."modules" FOR SELECT TO "authenticated" USING (("enabled" = true));



CREATE POLICY "Service role full access" ON "public"."permissions" USING (("auth"."role"() = 'service_role'::"text"));



CREATE POLICY "Service role full access" ON "public"."role_permissions" USING (("auth"."role"() = 'service_role'::"text"));



CREATE POLICY "Service role full access" ON "public"."roles" USING (("auth"."role"() = 'service_role'::"text"));



CREATE POLICY "Service role full access" ON "public"."user_roles" USING (("auth"."role"() = 'service_role'::"text"));



CREATE POLICY "Users may read their own attributes" ON "public"."user_attributes" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users may update their own attributes" ON "public"."user_attributes" FOR UPDATE TO "authenticated" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "deny all select" ON "public"."permissions" FOR SELECT USING (false);



CREATE POLICY "deny all select" ON "public"."role_permissions" FOR SELECT USING (false);



CREATE POLICY "deny all select" ON "public"."roles" FOR SELECT USING (false);



CREATE POLICY "deny all select" ON "public"."user_roles" FOR SELECT USING (false);



ALTER TABLE "public"."modules" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."permissions" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "read_own_profile" ON "public"."user_profile" FOR SELECT USING (("id" = "auth"."uid"()));



ALTER TABLE "public"."role_permissions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."roles" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "service role full access" ON "public"."permissions" TO "service_role" USING (true) WITH CHECK (true);



CREATE POLICY "service role full access" ON "public"."role_permissions" TO "service_role" USING (true) WITH CHECK (true);



CREATE POLICY "service role full access" ON "public"."roles" TO "service_role" USING (true) WITH CHECK (true);



CREATE POLICY "service role full access" ON "public"."user_roles" TO "service_role" USING (true) WITH CHECK (true);



CREATE POLICY "tenant_delete_modules" ON "public"."modules" FOR DELETE USING (("auth"."role"() = 'super_admin'::"text"));



CREATE POLICY "tenant_delete_permissions" ON "public"."permissions" FOR DELETE USING (("auth"."role"() = 'super_admin'::"text"));



CREATE POLICY "tenant_insert_modules" ON "public"."modules" FOR INSERT WITH CHECK ((("auth"."role"() = 'super_admin'::"text") OR ("tenant_id" = (("auth"."jwt"() ->> 'tenant_id'::"text"))::"uuid")));



CREATE POLICY "tenant_insert_permissions" ON "public"."permissions" FOR INSERT WITH CHECK ((("auth"."role"() = 'super_admin'::"text") OR ("tenant_id" = (("auth"."jwt"() ->> 'tenant_id'::"text"))::"uuid")));



CREATE POLICY "tenant_isolation_modules" ON "public"."modules" FOR SELECT USING (("tenant_id" = (("auth"."jwt"() ->> 'tenant_id'::"text"))::"uuid"));



CREATE POLICY "tenant_isolation_permissions" ON "public"."permissions" FOR SELECT USING (("tenant_id" = (("auth"."jwt"() ->> 'tenant_id'::"text"))::"uuid"));



CREATE POLICY "tenant_isolation_role_permissions" ON "public"."role_permissions" FOR SELECT USING (("permission_id" IN ( SELECT "permissions"."id"
   FROM "public"."permissions"
  WHERE ("permissions"."tenant_id" = (("auth"."jwt"() ->> 'tenant_id'::"text"))::"uuid"))));



CREATE POLICY "tenant_isolation_roles" ON "public"."roles" FOR SELECT USING (("tenant_id" = (("auth"."jwt"() ->> 'tenant_id'::"text"))::"uuid"));



CREATE POLICY "tenant_isolation_tier_permissions" ON "public"."tier_permissions" FOR SELECT USING (("tier_id" IN ( SELECT "tiers"."id"
   FROM "public"."tiers"
  WHERE ("tiers"."tenant_id" = (("auth"."jwt"() ->> 'tenant_id'::"text"))::"uuid"))));



CREATE POLICY "tenant_isolation_tiers" ON "public"."tiers" FOR SELECT USING (("tenant_id" = (("auth"."jwt"() ->> 'tenant_id'::"text"))::"uuid"));



CREATE POLICY "tenant_isolation_user_attribute_definitions" ON "public"."user_attribute_definitions" FOR SELECT USING (true);



CREATE POLICY "tenant_isolation_user_attributes" ON "public"."user_attributes" FOR SELECT USING (("user_id" IN ( SELECT "user_profile"."id"
   FROM "public"."user_profile"
  WHERE ("user_profile"."tenant_id" = (("auth"."jwt"() ->> 'tenant_id'::"text"))::"uuid"))));



CREATE POLICY "tenant_isolation_user_profile" ON "public"."user_profile" FOR SELECT USING (("tenant_id" = (("auth"."jwt"() ->> 'tenant_id'::"text"))::"uuid"));



CREATE POLICY "tenant_isolation_user_roles" ON "public"."user_roles" FOR SELECT USING (("role_id" IN ( SELECT "roles"."id"
   FROM "public"."roles"
  WHERE ("roles"."tenant_id" = (("auth"."jwt"() ->> 'tenant_id'::"text"))::"uuid"))));



CREATE POLICY "tenant_modify_user_roles" ON "public"."user_roles" USING ((("auth"."role"() = 'super_admin'::"text") OR ("tenant_id" = (("auth"."jwt"() ->> 'tenant_id'::"text"))::"uuid"))) WITH CHECK ((("auth"."role"() = 'super_admin'::"text") OR ("tenant_id" = (("auth"."jwt"() ->> 'tenant_id'::"text"))::"uuid")));



CREATE POLICY "tenant_select_modules" ON "public"."modules" FOR SELECT USING ((("auth"."role"() = 'super_admin'::"text") OR ("tenant_id" = (("auth"."jwt"() ->> 'tenant_id'::"text"))::"uuid")));



CREATE POLICY "tenant_select_permissions" ON "public"."permissions" FOR SELECT USING ((("auth"."role"() = 'super_admin'::"text") OR ("tenant_id" = (("auth"."jwt"() ->> 'tenant_id'::"text"))::"uuid")));



CREATE POLICY "tenant_select_user_roles" ON "public"."user_roles" FOR SELECT USING ((("auth"."role"() = 'super_admin'::"text") OR ("tenant_id" = (("auth"."jwt"() ->> 'tenant_id'::"text"))::"uuid")));



CREATE POLICY "tenant_update_modules" ON "public"."modules" FOR UPDATE USING ((("auth"."role"() = 'super_admin'::"text") OR ("tenant_id" = (("auth"."jwt"() ->> 'tenant_id'::"text"))::"uuid"))) WITH CHECK ((("auth"."role"() = 'super_admin'::"text") OR ("tenant_id" = (("auth"."jwt"() ->> 'tenant_id'::"text"))::"uuid")));



CREATE POLICY "tenant_update_permissions" ON "public"."permissions" FOR UPDATE USING ((("auth"."role"() = 'super_admin'::"text") OR ("tenant_id" = (("auth"."jwt"() ->> 'tenant_id'::"text"))::"uuid"))) WITH CHECK ((("auth"."role"() = 'super_admin'::"text") OR ("tenant_id" = (("auth"."jwt"() ->> 'tenant_id'::"text"))::"uuid")));



ALTER TABLE "public"."tenants" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "tenants_super_admin_modify" ON "public"."tenants" USING (("auth"."role"() = 'super_admin'::"text")) WITH CHECK (("auth"."role"() = 'super_admin'::"text"));



CREATE POLICY "tenants_super_admin_select" ON "public"."tenants" FOR SELECT USING (("auth"."role"() = 'super_admin'::"text"));



ALTER TABLE "public"."tier_permissions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."tiers" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_attribute_definitions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_attributes" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_profile" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "user_profile_admin_update" ON "public"."user_profile" FOR UPDATE USING ((("auth"."role"() = 'super_admin'::"text") OR ("tenant_id" = (("auth"."jwt"() ->> 'tenant_id'::"text"))::"uuid"))) WITH CHECK ((("auth"."role"() = 'super_admin'::"text") OR ("tenant_id" = (("auth"."jwt"() ->> 'tenant_id'::"text"))::"uuid")));



CREATE POLICY "user_profile_delete" ON "public"."user_profile" FOR DELETE USING (("auth"."role"() = 'super_admin'::"text"));



CREATE POLICY "user_profile_self_select" ON "public"."user_profile" FOR SELECT USING ((("id" = "auth"."uid"()) OR ("auth"."role"() = 'super_admin'::"text") OR ("tenant_id" = (("auth"."jwt"() ->> 'tenant_id'::"text"))::"uuid")));



CREATE POLICY "user_profile_self_update" ON "public"."user_profile" FOR UPDATE USING (("id" = "auth"."uid"())) WITH CHECK (("id" = "auth"."uid"()));



ALTER TABLE "public"."user_roles" ENABLE ROW LEVEL SECURITY;


GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";



GRANT ALL ON FUNCTION "public"."apply_claims_to_role_users"() TO "anon";
GRANT ALL ON FUNCTION "public"."apply_claims_to_role_users"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."apply_claims_to_role_users"() TO "service_role";



GRANT ALL ON FUNCTION "public"."apply_claims_to_user"("p_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."apply_claims_to_user"("p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."apply_claims_to_user"("p_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."build_claims"("p_user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."build_claims"("p_user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."build_claims"("p_user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_role_permissions"("role_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_role_permissions"("role_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_role_permissions"("role_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_user_permissions"("user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_user_permissions"("user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_user_permissions"("user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."on_auth_user_created"() TO "anon";
GRANT ALL ON FUNCTION "public"."on_auth_user_created"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."on_auth_user_created"() TO "service_role";



GRANT ALL ON FUNCTION "public"."user_has_permission"("user_id" "uuid", "permission_name" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."user_has_permission"("user_id" "uuid", "permission_name" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."user_has_permission"("user_id" "uuid", "permission_name" "text") TO "service_role";



GRANT ALL ON TABLE "public"."function_groups" TO "anon";
GRANT ALL ON TABLE "public"."function_groups" TO "authenticated";
GRANT ALL ON TABLE "public"."function_groups" TO "service_role";



GRANT ALL ON TABLE "public"."functions" TO "anon";
GRANT ALL ON TABLE "public"."functions" TO "authenticated";
GRANT ALL ON TABLE "public"."functions" TO "service_role";



GRANT ALL ON TABLE "public"."legal_documents" TO "anon";
GRANT ALL ON TABLE "public"."legal_documents" TO "authenticated";
GRANT ALL ON TABLE "public"."legal_documents" TO "service_role";



GRANT ALL ON TABLE "public"."modules" TO "anon";
GRANT ALL ON TABLE "public"."modules" TO "authenticated";
GRANT ALL ON TABLE "public"."modules" TO "service_role";



GRANT ALL ON TABLE "public"."permissions" TO "anon";
GRANT ALL ON TABLE "public"."permissions" TO "authenticated";
GRANT ALL ON TABLE "public"."permissions" TO "service_role";



GRANT ALL ON TABLE "public"."role_permissions" TO "anon";
GRANT ALL ON TABLE "public"."role_permissions" TO "authenticated";
GRANT ALL ON TABLE "public"."role_permissions" TO "service_role";



GRANT ALL ON TABLE "public"."roles" TO "anon";
GRANT ALL ON TABLE "public"."roles" TO "authenticated";
GRANT ALL ON TABLE "public"."roles" TO "service_role";



GRANT ALL ON TABLE "public"."tenant_members" TO "anon";
GRANT ALL ON TABLE "public"."tenant_members" TO "authenticated";
GRANT ALL ON TABLE "public"."tenant_members" TO "service_role";



GRANT ALL ON TABLE "public"."tenants" TO "anon";
GRANT ALL ON TABLE "public"."tenants" TO "authenticated";
GRANT ALL ON TABLE "public"."tenants" TO "service_role";



GRANT ALL ON TABLE "public"."tiers" TO "anon";
GRANT ALL ON TABLE "public"."tiers" TO "authenticated";
GRANT ALL ON TABLE "public"."tiers" TO "service_role";



GRANT ALL ON TABLE "public"."user_profile" TO "anon";
GRANT ALL ON TABLE "public"."user_profile" TO "authenticated";
GRANT ALL ON TABLE "public"."user_profile" TO "service_role";



GRANT ALL ON TABLE "public"."user_roles" TO "anon";
GRANT ALL ON TABLE "public"."user_roles" TO "authenticated";
GRANT ALL ON TABLE "public"."user_roles" TO "service_role";



GRANT ALL ON TABLE "public"."tenant_members_admin" TO "anon";
GRANT ALL ON TABLE "public"."tenant_members_admin" TO "authenticated";
GRANT ALL ON TABLE "public"."tenant_members_admin" TO "service_role";



GRANT ALL ON TABLE "public"."tier_functions" TO "anon";
GRANT ALL ON TABLE "public"."tier_functions" TO "authenticated";
GRANT ALL ON TABLE "public"."tier_functions" TO "service_role";



GRANT ALL ON TABLE "public"."tier_permissions" TO "anon";
GRANT ALL ON TABLE "public"."tier_permissions" TO "authenticated";
GRANT ALL ON TABLE "public"."tier_permissions" TO "service_role";



GRANT ALL ON TABLE "public"."user_attribute_definitions" TO "anon";
GRANT ALL ON TABLE "public"."user_attribute_definitions" TO "authenticated";
GRANT ALL ON TABLE "public"."user_attribute_definitions" TO "service_role";



GRANT ALL ON TABLE "public"."user_attributes" TO "anon";
GRANT ALL ON TABLE "public"."user_attributes" TO "authenticated";
GRANT ALL ON TABLE "public"."user_attributes" TO "service_role";



GRANT ALL ON TABLE "public"."user_consents" TO "anon";
GRANT ALL ON TABLE "public"."user_consents" TO "authenticated";
GRANT ALL ON TABLE "public"."user_consents" TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";







