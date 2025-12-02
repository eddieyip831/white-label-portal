'use client';

import type { ReactNode } from 'react';

import Sidebar from '~/components/admin/sidebar';

import AppHeader from './AppHeader';

export default function AdminShell({
  children,
  isAdmin,
}: {
  children: ReactNode;
  isAdmin: boolean;
}) {
  return (
    <div className="flex min-h-screen">
      {/* Sidebar only visible for admins */}
      {isAdmin && (
        <aside className="hidden w-64 border-r bg-white lg:block">
          <Sidebar />
        </aside>
      )}

      <div className="flex flex-1 flex-col">
        <AppHeader />
        <main className="bg-gray-50 p-6">{children}</main>
      </div>
    </div>
  );
}
