import { NextResponse } from 'next/server';

import { requireAdminOrTenantAdmin } from '~/lib/auth/guards';
import { createServerSupabaseClient } from '~/lib/supabase/server';

export async function PATCH(
  req: Request,
  context: { params: { user_id: string } },
) {
  const { user_id } = context.params;

  const supabase = createServerSupabaseClient();
  const { isSuperAdmin, tenantId } = await requireAdminOrTenantAdmin(supabase);

  const updates: {
    full_name?: string;
    tier_id?: string;
    role_ids?: string[];
    tenant_id?: string;
  } = await req.json();

  // Ensure tenant admin stays inside their tenant
  if (!isSuperAdmin) {
    const { data: profile, error: profileErr } = await supabase
      .from('user_profile')
      .select('tenant_id')
      .eq('id', user_id)
      .single();

    if (profileErr || !profile) {
      return NextResponse.json({ error: 'User not found' }, { status: 404 });
    }

    if (profile.tenant_id !== tenantId) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 });
    }
  }

  // Update profile
  if (updates.full_name || updates.tier_id) {
    const { error } = await supabase
      .from('user_profile')
      .update({
        full_name: updates.full_name,
        tier_id: updates.tier_id,
      })
      .eq('id', user_id);

    if (error) {
      return NextResponse.json(
        { error: 'Failed to update profile: ' + error.message },
        { status: 400 },
      );
    }
  }

  // Update user roles
  if (Array.isArray(updates.role_ids)) {
    await supabase.from('user_roles').delete().eq('user_id', user_id);

    const effectiveTenantId = isSuperAdmin ? updates.tenant_id : tenantId;

    const rows = updates.role_ids.map((role_id) => ({
      user_id,
      role_id,
      tenant_id: effectiveTenantId,
    }));

    const { error } = await supabase.from('user_roles').insert(rows);

    if (error) {
      return NextResponse.json(
        { error: 'Failed to update roles: ' + error.message },
        { status: 400 },
      );
    }
  }

  // Refresh claims
  await supabase.rpc('apply_claims_to_user', { p_user_id: user_id });

  return NextResponse.json({ ok: true });
}
