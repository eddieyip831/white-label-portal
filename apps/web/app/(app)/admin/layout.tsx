import { redirect } from 'next/navigation';

import AdminShell from '~/components/layout/AdminShell';
import { getClaims } from '~/lib/auth/claims';
import { requireRole } from '~/lib/auth/guards';

export default async function AdminLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  // Strong server-side admin guard
  try {
    await requireRole('admin');
  } catch {
    redirect('/home');
  }

  // Fetch JWT claims once, server-side
  const claims = await getClaims();
  const isAdmin = claims?.roles?.includes('admin') ?? false;

  // AdminShell handles rendering full sidebar + top nav
  return <AdminShell isAdmin={isAdmin}>{children}</AdminShell>;
}
