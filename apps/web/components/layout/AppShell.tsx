'use client';

import React from 'react';

// ⭐ NEW: React Query imports
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

import Sidebar from '../admin/sidebar';
import AppHeaderAuth from './AppHeaderAuth';

// Create QueryClient (once)
const queryClient = new QueryClient();

export default function AppShell({ children }: { children: React.ReactNode }) {
  return (
    <QueryClientProvider client={queryClient}>
      <div className="flex min-h-screen">
        <aside className="hidden w-64 border-r bg-white lg:block">
          <Sidebar />
        </aside>

        <div className="flex flex-1 flex-col">
          <AppHeaderAuth />

          <main className="flex-1 bg-gray-50 p-6">{children}</main>
        </div>
      </div>
    </QueryClientProvider>
  );
}
