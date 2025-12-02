import type { ReactNode } from 'react';

import { redirect } from 'next/navigation';

import AppShell from '~/components/layout/AppShell';
import { getClaims } from '~/lib/auth/claims';

export default async function AppLayout({ children }: { children: ReactNode }) {
  // Require authentication
  const claims = await getClaims();
  if (!claims) redirect('/login');

  return <AppShell user={claims}>{children}</AppShell>;
}
