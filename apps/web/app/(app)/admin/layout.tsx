import { redirect } from 'next/navigation';

import AdminShell from '~/components/layout/AdminShell';
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

  // AdminShell handles rendering top nav and page scaffold
  return <AdminShell>{children}</AdminShell>;
}
