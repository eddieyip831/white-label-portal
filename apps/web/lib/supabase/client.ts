// apps/web/lib/supabase/client.ts
// MakerKit exposes a helper to get a browser-side Supabase client that is
// already configured using NEXT_PUBLIC_SUPABASE_URL + NEXT_PUBLIC_SUPABASE_ANON_KEY.
//
// The older name `createBrowserClient` does *not* exist in this package.
// The correct export is `getSupabaseBrowserClient`.
import { getSupabaseBrowserClient } from '@kit/supabase/browser-client';

/**
 * Canonical browser Supabase client.
 *
 * Use this in *client components* (LoginForm, UserMenu, etc).
 */
export const supabaseBrowserClient = getSupabaseBrowserClient();

/**
 * Backwards-compatible alias.
 *
 * Some code may still import `{ supabase }` from this file. Instead of
 * changing all those call sites, we alias `supabase` to the browser client.
 *
 * There is no functional difference between `supabase` and
 * `supabaseBrowserClient` — they are the same instance. The alias just
 * makes it easier to migrate old code gradually.
 */
export const supabase = supabaseBrowserClient;
