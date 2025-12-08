'use client';

import type { ReactNode } from 'react';

import AppHeader from './AppHeader';

export default function AdminShell({ children }: { children: ReactNode }) {
  return (
    <div className="flex min-h-screen flex-col">
      <AppHeader />
      <main className="flex-1 bg-gray-50 p-6">{children}</main>
    </div>
  );
}
