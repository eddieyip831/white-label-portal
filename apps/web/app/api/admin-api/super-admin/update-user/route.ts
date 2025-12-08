import { NextResponse } from 'next/server';

import { getSupabaseServerAdminClient } from '@kit/supabase/server-admin-client';
import { z } from 'zod';

import type { Database } from '~/lib/supabase/database.types';
import { requireRole } from '~/lib/auth/guards';

const PayloadSchema = z.object({
  user_id: z.string().uuid(),
  roles: z.array(z.string().uuid()).default([]),
  tier_id: z.string().uuid().nullable().optional(),
});

export async function POST(request: Request) {
  await requireRole('super_admin');

  const raw = await request.json();
  const parsed = PayloadSchema.safeParse(raw);

  if (!parsed.success) {
    return NextResponse.json(
      { error: 'Invalid payload', details: parsed.error.flatten() },
      { status: 400 },
    );
  }

  const { user_id, roles, tier_id } = parsed.data;
  const supabase = getSupabaseServerAdminClient<Database>();

  const { data: profile, error: profileError } = await supabase
    .from('user_profile')
    .select('tenant_id')
    .eq('id', user_id)
    .maybeSingle();

  if (profileError) {
    return NextResponse.json(
      { error: 'Failed to load profile', details: profileError.message },
      { status: 400 },
    );
  }

  const tenantId = profile?.tenant_id ?? null;

  const { error: deleteError } = await supabase
    .from('user_roles')
    .delete()
    .eq('user_id', user_id);

  if (deleteError) {
    return NextResponse.json(
      { error: 'Failed to clear roles', details: deleteError.message },
      { status: 400 },
    );
  }

  if (roles.length) {
    const rows = Array.from(new Set(roles)).map((roleId) => ({
      user_id,
      role_id: roleId,
      tenant_id: tenantId,
    }));

    const { error: insertError } = await supabase
      .from('user_roles')
      .insert(rows);

    if (insertError) {
      return NextResponse.json(
        { error: 'Failed to assign roles', details: insertError.message },
        { status: 400 },
      );
    }
  }

  const { error: profileUpdateError } = await supabase
    .from('user_profile')
    .update({
      tier_id: tier_id ?? null,
    })
    .eq('id', user_id);

  if (profileUpdateError) {
    return NextResponse.json(
      { error: 'Failed to update tier', details: profileUpdateError.message },
      { status: 400 },
    );
  }

  const { error: claimsError } = await supabase.rpc('apply_claims_to_user', {
    p_user_id: user_id,
  });

  if (claimsError) {
    return NextResponse.json(
      { error: 'Failed to refresh claims', details: claimsError.message },
      { status: 400 },
    );
  }

  return NextResponse.json({ ok: true });
}
