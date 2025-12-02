import Link from 'next/link';

import { useUser } from '@kit/supabase/hooks/use-user';

import AdminMenu from './AdminMenu';

// or MakerKit equivalent

export default function MainNav() {
  const userQuery = useUser();
  const user = userQuery.data;
  const role = user?.app_metadata?.role;
  const isSuperAdmin = role === 'super_admin';

  return (
    <nav className="flex items-center gap-6">
      <Link href="/">Home</Link>
      <Link href="/modules">Modules</Link>

      {isSuperAdmin && <AdminMenu />}
    </nav>
  );
}
