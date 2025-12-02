import { getSupabaseServerClient } from '@kit/supabase/server-client';

import type { Database } from '~/lib/supabase/database.types';

// This wrapper forces MakerKit to use your database schema.
// MakerKit handles cookies, headers, and SSR; we only override typing here.
export function createServerClientWrapper() {
  return getSupabaseServerClient<Database>();
}
