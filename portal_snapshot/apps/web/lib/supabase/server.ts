import { getSupabaseServerClient } from '@kit/supabase/server-client';

export function createServerClientWrapper() {
  return getSupabaseServerClient();
}
