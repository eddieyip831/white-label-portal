// apps/web/app/api/auth/refresh-claims/route.ts
import { NextResponse } from 'next/server';

import { createClient } from '@/lib/supabase/server';

export async function POST() {
  const supabase = createClient();

  const {
    data: { user },
    error,
  } = await supabase.auth.getUser();

  if (error || !user) {
    return NextResponse.json(
      { ok: false, error: error?.message ?? 'No user' },
      { status: 401 },
    );
  }

  // Trick: ask Supabase to issue a fresh JWT using the existing app_metadata
  // (we aren't changing app_metadata here; we just want a new token)
  const { error: updateError } = await supabase.auth.updateUser({
    data: user.app_metadata ?? {},
  });

  if (updateError) {
    return NextResponse.json(
      { ok: false, error: updateError.message },
      { status: 500 },
    );
  }

  return NextResponse.json({ ok: true });
}
