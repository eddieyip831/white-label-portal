import { NextResponse } from 'next/server';

import { requireAdminOrTenantAdmin } from '~/lib/auth/guards';
import { createServerSupabaseClient } from '~/lib/supabase/server';

// GET /api/admin-api/users
export async function GET() {
  const supabase = createServerSupabaseClient();
  const { isSuperAdmin, tenantId } = await requireAdminOrTenantAdmin(supabase);

  let query = supabase.from('user_profile').select(`
    id,
    full_name,
    tenant_id,
    tier_id,
    user_roles(role_id),
    user_attributes(attribute_key, attribute_value)
  `);

  if (!isSuperAdmin) {
    query = query.eq('tenant_id', tenantId);
  }

  const { data, error } = await query;

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 400 });
  }

  return NextResponse.json(data);
}

// POST /api/admin-api/users
export async function POST(request: Request) {
  const body = await request.json();
  const { email, password, full_name, role_ids, tier_id } = body;

  const supabase = createServerSupabaseClient();
  const { isSuperAdmin, tenantId } = await requireAdminOrTenantAdmin(supabase);

  const effectiveTenantId = isSuperAdmin ? body.tenant_id : tenantId;

  const { data, error } = await supabase.functions.invoke('admin_create_user', {
    body: {
      email,
      password,
      full_name,
      role_ids,
      tier_id,
      tenant_id: effectiveTenantId,
    },
  });

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 400 });
  }

  return NextResponse.json({ user_id: data.user_id });
}
