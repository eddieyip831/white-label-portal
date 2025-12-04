import type { ReactNode } from 'react';

import { redirect } from 'next/navigation';

import AppShell from '~/components/layout/AppShell';
import { SupabaseProvider } from '~/components/providers/supabase-provider';
import { getClaims } from '~/lib/auth/claims';
import { logDebug } from '~/lib/log';

export default async function AppLayout({ children }: { children: ReactNode }) {
  const claims = await getClaims();

  logDebug('auth', 'claims in (app)/layout', claims);

  if (process.env.NODE_ENV === 'production' && !claims) {
    redirect('/');
  }

  const normalizedClaims = claims
    ? {
        email: claims.email ?? null,
        roles: Array.isArray(claims.roles) ? claims.roles : [],
        permissions: Array.isArray(claims.permissions)
          ? claims.permissions
          : [],
        tier: claims.tier ?? 'free',
        tenantId: claims.tenantId ?? null,
      }
    : null;

  return (
    <SupabaseProvider>
      <AppShell claims={normalizedClaims}>{children}</AppShell>
    </SupabaseProvider>
  );
}
