// apps/web/lib/auth/claims.ts
import { createServerClientWrapper } from '~/lib/supabase/server';

type AnyJson = Record<string, any>;

export interface ServerClaims {
  email: string | null;
  name: string | null;
  tier: string | null;
  roles: string[];
  tenantId: string | null;
  // keep loose for now
  [key: string]: unknown;
}

/**
 * Normalise the various shapes we might get from Supabase:
 *
 * - auth.users.app_metadata.claims = { tenant_id, tier, roles, permissions, ... }
 * - auth.users.app_metadata may also have top-level tier/roles in some earlier migrations
 */
function deriveClaimsFromMetadata(
  meta: AnyJson,
  user: AnyJson | null,
): ServerClaims {
  const claims = (meta.claims ?? {}) as AnyJson;

  // email / name from user
  const email = (user?.email ?? null) as string | null;

  const rawName =
    (user?.user_metadata?.full_name as string | undefined) ??
    (user?.user_metadata?.name as string | undefined) ??
    null;

  const name = rawName && rawName.trim().length > 0 ? rawName : null;

  // roles can live under claims.roles (current) or app_metadata.roles (older)
  const roles =
    (claims.roles as string[] | undefined) ??
    (meta.roles as string[] | undefined) ??
    [];

  // tier can live under claims.tier (current) or app_metadata.tier (older)
  const tier =
    (claims.tier as string | undefined) ??
    (meta.tier as string | undefined) ??
    null;

  // tenant_id only in claims in the current design
  const tenantId =
    (claims.tenant_id as string | undefined) ??
    (meta.tenant_id as string | undefined) ??
    null;

  return {
    email,
    name,
    tier,
    roles,
    tenantId,
    // expose raw structures for debugging if needed
    rawClaims: claims,
    rawMeta: meta,
  };
}

/**
 * Server-side helper used by (app)/layout to fetch the current user's claims.
 *
 * It reads the JWT / user from Supabase and normalises it into the shape:
 *   { email, name, tier, roles, tenantId, ... }
 */
export async function getClaims(): Promise<ServerClaims | null> {
  const supabase = createServerClientWrapper();

  const { data, error } = await supabase.auth.getUser();

  if (error || !data?.user) {
    if (process.env.NEXT_PUBLIC_LOG_LEVEL === 'debug') {
      console.log('[getClaims] no user or error', error);
    }
    return null;
  }

  const user = data.user as AnyJson;
  const meta = (user.app_metadata ?? {}) as AnyJson;

  const normalised = deriveClaimsFromMetadata(meta, user);

  if (process.env.NEXT_PUBLIC_LOG_LEVEL === 'debug') {
    console.log('[getClaims] normalised claims =', normalised);
  }

  return normalised;
}
