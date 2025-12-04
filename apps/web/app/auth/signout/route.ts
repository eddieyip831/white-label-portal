import { NextResponse } from 'next/server';

import { createServerClientWrapper } from '~/lib/supabase/server';

export async function GET() {
  // Create SSR Supabase client
  const supabase = createServerClientWrapper();

  // Sign out – clears Supabase auth cookies
  await supabase.auth.signOut();

  // Redirect back to home
  return NextResponse.redirect(new URL('/', process.env.NEXT_PUBLIC_SITE_URL));
}
