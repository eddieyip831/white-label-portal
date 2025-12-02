'use client';

import Sidebar from '../admin/sidebar';
import AppHeader from './AppHeader';

export default function AppShell({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex min-h-screen">
      {/* Left sidebar (desktop only) */}
      <aside className="hidden w-64 border-r bg-white lg:block">
        <Sidebar />
      </aside>

      {/* Right side */}
      <div className="flex flex-1 flex-col">
        {/* Top Header */}
        <AppHeader />

        {/* Main content */}
        <main className="flex-1 bg-gray-50 p-6">{children}</main>
      </div>
    </div>
  );
}
