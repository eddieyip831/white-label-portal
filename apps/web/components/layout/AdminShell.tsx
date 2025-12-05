'use client';

import type { ReactNode } from 'react';

import AppHeader from './AppHeader';

export default function AdminShell({ children }: { children: ReactNode }) {
  return (
    <div className="flex min-h-screen">
      <div className="flex flex-1 flex-col">
        <AppHeader />
        <main className="bg-gray-50 p-6">{children}</main>
      </div>
    </div>
  );
}
