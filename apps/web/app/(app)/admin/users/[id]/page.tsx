import UserForm, { UserFormValues } from '~/components/admin/users/user-form';
import AdminShell from '~/components/layout/AdminShell';
import { createServerClientWrapper } from '~/lib/supabase/server';

type Role = { id: string; name: string };
type Tier = { id: string; name: string };
type UserRow = {
  id: string;
  full_name: string | null;
  tier_id: string | null;
  tenant_id: string;
};
type UserRoleRow = { role_id: string };

export default async function EditUserPage({
  params,
}: {
  params: { id: string };
}) {
  const { id } = params;

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const supabase = createServerClientWrapper() as any;

  const { data: user } = await supabase
    .from('user_profile')
    .select('id, full_name, tier_id, tenant_id')
    .eq('id', id)
    .single();

  const { data: roles } = await supabase.from('roles').select('id, name');
  const { data: tiers } = await supabase.from('tiers').select('id, name');

  const { data: userRoles } = await supabase
    .from('user_roles')
    .select('role_id')
    .eq('user_id', id);

  const initial: UserFormValues = {
    email: undefined, // you can load from auth.users later if needed
    full_name: (user as UserRow | null)?.full_name ?? '',
    tier_id: (user as UserRow | null)?.tier_id ?? undefined,
    role_ids: ((userRoles ?? []) as UserRoleRow[]).map((r) => r.role_id),
  };

  async function handleUpdate(values: UserFormValues) {
    'use server';

    await fetch(`/api/admin-api/users/${id}`, {
      method: 'PATCH',
      body: JSON.stringify(values),
      headers: {
        'Content-Type': 'application/json',
      },
    });
  }

  return (
    <AdminShell>
      <h1 className="mb-4 text-2xl font-semibold">Edit User</h1>

      <UserForm
        initial={initial}
        roles={(roles ?? []) as Role[]}
        tiers={(tiers ?? []) as Tier[]}
        onSubmit={handleUpdate}
      />
    </AdminShell>
  );
}
