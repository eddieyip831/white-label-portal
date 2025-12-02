import { cookies } from 'next/headers';

import { createServerClient } from '@supabase/ssr';

import type { Database } from '~/lib/supabase/database.types';

export type Claims = {
  email: string | null;
  roles: string[];
  tier: string | null;
  tenantId: string | null;
};

export async function getClaims(): Promise<Claims | null> {
  const cookieStore = await cookies();

  const supabase = createServerClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        get(name: string) {
          return cookieStore.get(name)?.value;
        },
      },
    },
  );

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) return null;

  const roles = user.app_metadata?.roles || user.user_metadata?.roles || [];

  const tier = user.user_metadata?.tier || null;

  return {
    email: user.email,
    roles,
    tier,
    tenantId: user.user_metadata?.tenant_id || null,
  };
}
