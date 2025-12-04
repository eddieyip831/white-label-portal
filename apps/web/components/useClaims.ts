'use client';

import { useEffect, useState } from 'react';

import { useSupabase } from '~/components/providers/supabase-provider';

export interface Claims {
  email: string | null;
  name: string | null;
  roles: string[];
  tier: string | null;
  permissions: string[];
}

export function useClaims(): Claims {
  const { supabase } = useSupabase();
  const [claims, setClaims] = useState<Claims>({
    email: null,
    name: null,
    roles: [],
    tier: null,
    permissions: [],
  });

  useEffect(() => {
    async function load() {
      const { data } = await supabase.auth.getUser();
      const user = data.user;

      const meta = (user?.raw_app_meta_data as any) || {};

      setClaims({
        email: user?.email ?? null,
        name: (user?.user_metadata as any)?.full_name ?? null,
        roles: meta.roles ?? [],
        tier: meta.tier ?? null,
        permissions: meta.permissions ?? [],
      });
    }

    load();
  }, [supabase]);

  return claims;
}

/**
 * @deprecated Prefer `useClaims` directly. This is kept for existing imports.
 */
export const useClaimsClient = useClaims;
