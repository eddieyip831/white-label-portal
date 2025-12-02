import { getClaims } from './claims';

export async function requireAuth() {
  const claims = await getClaims();
  if (!claims) throw new Error('Unauthorized');
}

export async function requireRole(role: string) {
  const claims = await getClaims();
  if (!claims?.roles?.includes(role)) {
    throw new Error('Forbidden');
  }
}

export async function requirePermission(permission: string) {
  const claims = await getClaims();
  if (!claims?.permissions?.includes(permission)) {
    throw new Error('Forbidden');
  }
}

export async function requireModule(moduleKey: string) {
  const claims = await getClaims();
  if (!claims?.permissions?.includes(`${moduleKey}.access`)) {
    throw new Error('Forbidden');
  }
}

// apps/web/lib/auth/guards.ts

export async function requireAdminOrTenantAdmin(supabase) {
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) throw new Error('Unauthorized');

  const claims = user.app_metadata?.claims ?? {};

  return {
    user,
    isSuperAdmin: claims.roles?.includes('super_admin'),
    tenantId: claims.tenant_id,
  };
}
