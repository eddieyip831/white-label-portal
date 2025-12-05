'use client';

import Link from 'next/link';
import UserMenu from '~/components/layout/UserMenu';
import MainNav from '~/components/layout/main-nav';
import { useClaims } from '~/components/useClaims';

export default function AppHeaderAuth() {
  const claims = useClaims();

  return (
    <header className="flex items-center justify-between border-b px-4 py-2">
      <div className="flex flex-1 items-center gap-6">
        <Link
          href="/home"
          className="text-lg font-semibold text-gray-900 hover:text-gray-700"
        >
          Portal
        </Link>
        <MainNav claims={claims} />
      </div>

      <UserMenu claims={claims} />
    </header>
  );
}
