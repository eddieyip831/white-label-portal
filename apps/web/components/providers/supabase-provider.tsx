'use client';

import { createContext, useContext, useState } from 'react';

import type { SupabaseClient } from '@supabase/supabase-js';

import { createBrowserClient } from '@supabase/auth-helpers-nextjs';

interface SupabaseContextType {
  supabase: SupabaseClient;
}

const SupabaseContext = createContext<SupabaseContextType | undefined>(
  undefined,
);

export function SupabaseProvider({ children }: { children: React.ReactNode }) {
  const [supabase] = useState(() =>
    createBrowserClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    ),
  );

  return (
    <SupabaseContext.Provider value={{ supabase }}>
      {children}
    </SupabaseContext.Provider>
  );
}

export function useSupabase() {
  const ctx = useContext(SupabaseContext);
  if (!ctx) {
    throw new Error('useSupabase must be used inside <SupabaseProvider>');
  }
  return ctx;
}
