'use client';

import Link from 'next/link';

import { useUser } from '@kit/supabase/hooks/use-user';

import AdminMenu from '~/components/layout/AdminMenu';

export default function AppHeaderAuth() {
  // MakerKit user query (returns UseQueryResult<JwtPayload | null>)
  const userQuery = useUser();
  const user = userQuery.data;

  if (!user) {
    return null;
  }

  // role lives inside JWT payload (app_metadata.role)
  const role = user.app_metadata?.role;
  const isSuperAdmin = role === 'super_admin';

  return (
    <header className="flex items-center justify-between border-b bg-white px-6 py-4">
      <Link href="/home" className="text-xl font-semibold">
        Portal
      </Link>

      <nav className="flex items-center gap-6">
        <Link href="/home">Home</Link>
        {isSuperAdmin && <AdminMenu />}
      </nav>
    </header>
  );
}
