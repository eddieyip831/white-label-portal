'use server';

import { redirect } from 'next/navigation';

import type { Database } from '~/lib/supabase/database.types';
import { createServerClientWrapper } from '~/lib/supabase/server';

// Helpers
type UserRolesInsert = Database['public']['Tables']['user_roles']['Insert'];
type UserProfileUpsert = Database['public']['Tables']['user_profile']['Insert'];

//
// CREATE MEMBER
//
export async function createMember(formData: FormData) {
  const supabase = createServerClientWrapper();

  const tenant_id = formData.get('tenant_id') as string;
  const user_id = formData.get('user_id') as string;
  const role_id = formData.get('role_id') as string;
  const tier_id = formData.get('tier_id')
    ? (formData.get('tier_id') as string)
    : null;

  // 1️⃣ Insert into user_roles
  const newRole: UserRolesInsert = {
    tenant_id,
    user_id,
    role_id,
  };

  const { error: roleErr } = await supabase.from('user_roles').insert(newRole);

  if (roleErr) throw roleErr;

  // 2️⃣ Upsert into user_profile (for tier settings)
  if (tier_id) {
    const profileUpsert: UserProfileUpsert = {
      id: user_id,
      tenant_id,
      tier_id,
    };

    const { error: profileErr } = await supabase
      .from('user_profile')
      .upsert(profileUpsert);

    if (profileErr) throw profileErr;
  }

  redirect('/admin/tenant-members');
}

//
// UPDATE MEMBER
//
export async function updateMember(formData: FormData) {
  const supabase = createServerClientWrapper();

  const tenant_id = formData.get('tenant_id') as string;
  const user_id = formData.get('user_id') as string;
  const role_id = formData.get('role_id') as string;
  const tier_id = formData.get('tier_id')
    ? (formData.get('tier_id') as string)
    : null;

  // 1️⃣ Update user_roles
  const { error: roleErr } = await supabase
    .from('user_roles')
    .update({ role_id })
    .eq('tenant_id', tenant_id)
    .eq('user_id', user_id);

  if (roleErr) throw roleErr;

  // 2️⃣ Upsert user_profile for tier
  const profileUpsert: UserProfileUpsert = {
    id: user_id,
    tenant_id,
    tier_id,
  };

  const { error: profileErr } = await supabase
    .from('user_profile')
    .upsert(profileUpsert);

  if (profileErr) throw profileErr;

  redirect('/admin/tenant-members');
}

//
// DELETE MEMBER
//
export async function deleteMember(opts: {
  tenant_id: string;
  user_id: string;
}) {
  const supabase = createServerClientWrapper();

  const { tenant_id, user_id } = opts;

  // 1️⃣ Remove membership
  const { error } = await supabase
    .from('user_roles')
    .delete()
    .eq('tenant_id', tenant_id)
    .eq('user_id', user_id);

  if (error) throw error;

  redirect('/admin/tenant-members');
}
