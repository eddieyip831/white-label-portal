'use client';

import React from 'react';

import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

import AppHeaderAuth from './AppHeaderAuth';

export default function AppShell({ children }: { children: React.ReactNode }) {
  const [queryClient] = React.useState(() => new QueryClient());

  return (
    <QueryClientProvider client={queryClient}>
      <div className="flex min-h-screen flex-col">
        <AppHeaderAuth />
        <main className="flex-1 bg-gray-50 p-6">{children}</main>
      </div>
    </QueryClientProvider>
  );
}
