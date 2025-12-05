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

export function useClaims(): Claims | null {
  const { supabase } = useSupabase();
  const [claims, setClaims] = useState<Claims | null>(null);

  useEffect(() => {
    let mounted = true;

    async function load() {
      try {
        const { data } = await supabase.auth.getUser();
        if (!mounted) return;

        const user = data.user;
        const meta =
          (user?.app_metadata as Record<string, unknown> | undefined) ??
          ((user as unknown as { raw_app_meta_data?: Record<string, unknown> })
            ?.raw_app_meta_data ?? {});

        setClaims({
          email: user?.email ?? null,
          name:
            ((user?.user_metadata as Record<string, unknown> | undefined)
              ?.full_name as string | undefined) ?? null,
          roles: Array.isArray(meta.roles) ? (meta.roles as string[]) : [],
          tier: typeof meta.tier === 'string' ? (meta.tier as string) : null,
          permissions: Array.isArray(meta.permissions)
            ? (meta.permissions as string[])
            : [],
        });
      } catch (error) {
        if (process.env.NEXT_PUBLIC_LOG_LEVEL === 'debug') {
          console.error('[useClaims] failed to load claims', error);
        }
        if (mounted) {
          setClaims(null);
        }
      }
    }

    load();

    return () => {
      mounted = false;
    };
  }, [supabase]);

  return claims;
}

/**
 * @deprecated Prefer `useClaims` directly. This is kept for existing imports.
 */
export const useClaimsClient = useClaims;
