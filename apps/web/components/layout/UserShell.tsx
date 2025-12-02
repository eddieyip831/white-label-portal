'use client';

import AppHeader from './AppHeader';

export default function UserShell({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex min-h-screen flex-col">
      <AppHeader />
      <main className="flex-1 bg-gray-50 p-6">{children}</main>
    </div>
  );
}
