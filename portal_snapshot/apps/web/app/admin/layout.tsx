import { redirect } from 'next/navigation';

import AdminShell from '~/components/layout/AdminShell';
import { getClaims } from '~/lib/auth/claims';
import { requireRole } from '~/lib/auth/guards';

export default async function AdminLayout({ children }) {
  // Ensure only admins can access
  try {
    await requireRole('admin');
  } catch {
    redirect('/dashboard');
  }

  // Fetch claims server-side
  const claims = await getClaims();
  const isAdmin = claims?.roles?.includes('admin');

  return <AdminShell isAdmin={isAdmin}>{children}</AdminShell>;
}
