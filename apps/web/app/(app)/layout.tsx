import type { ReactNode } from 'react';

import { redirect } from 'next/navigation';

import AppShell from '~/components/layout/AppShell';
import { SupabaseProvider } from '~/components/providers/supabase-provider';
import { getClaims } from '~/lib/auth/claims';
import { logDebug } from '~/lib/log';

export default async function AppLayout({ children }: { children: ReactNode }) {
  const claims = await getClaims();

  logDebug('auth', 'claims in (app)/layout', claims);

  if (!claims) {
    redirect('/');
  }

  return (
    <SupabaseProvider>
      <AppShell>{children}</AppShell>
    </SupabaseProvider>
  );
}
