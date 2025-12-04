'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';

import UserMenu from '~/components/layout/UserMenu';

function getPageTitle(pathname: string): string {
  if (pathname === '/home') return 'Home';
  if (pathname.startsWith('/admin/users')) return 'Users';
  if (pathname.startsWith('/admin/roles')) return 'Roles';
  if (pathname.startsWith('/admin/permissions')) return 'Permissions';
  if (pathname.startsWith('/admin/attributes')) return 'Attributes';
  if (pathname.startsWith('/admin/modules')) return 'Modules';
  return '';
}

export default function AppHeaderAuth() {
  const pathname = usePathname();
  const pageTitle = getPageTitle(pathname);

  if (process.env.NEXT_PUBLIC_LOG_LEVEL === 'debug') {
    console.log('[AppHeaderAuth]', { pathname, pageTitle });
  }

  return (
    <div className="flex items-center justify-between border-b px-4 py-2">
      <div className="flex items-baseline gap-2">
        <Link href="/home" className="text-lg font-semibold text-gray-900">
          Portal
        </Link>
        {pageTitle && (
          <span className="text-sm text-gray-500">{pageTitle}</span>
        )}
      </div>

      {/* 🔥 Claims-based menu */}
      <UserMenu />

      {/* Temp sign out*/}
      <Link
        href="/auth/signout"
        className="text-sm text-gray-600 hover:text-gray-900"
      >
        Sign out
      </Link>
    </div>
  );
}
