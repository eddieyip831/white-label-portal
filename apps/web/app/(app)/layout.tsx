// apps/web/app/(app)/layout.tsx
import type { ReactNode } from 'react';

import { redirect } from 'next/navigation';

import AppShell from '~/components/layout/AppShell';
import { getClaims } from '~/lib/auth/claims';
import { logDebug } from '~/lib/log';

export default async function AppLayout({ children }: { children: ReactNode }) {
  const claims = await getClaims();

  logDebug('auth', 'claims in (app)/layout', claims);

  // In production, enforce auth
  if (process.env.NODE_ENV === 'production' && !claims) {
    redirect('/');
  }

  // In dev, allow access even if claims are null so we can debug
  return <AppShell user={claims as any}>{children}</AppShell>;
}
