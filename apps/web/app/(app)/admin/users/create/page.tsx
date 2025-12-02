import UserForm, { UserFormValues } from '~/components/admin/users/user-form';
import AdminShell from '~/components/layout/AdminShell';
import { createServerClientWrapper } from '~/lib/supabase/server';

type Role = { id: string; name: string };
type Tier = { id: string; name: string };

export default async function CreateUserPage() {
  // Supabase client is typed only for "accounts". Treat as any here.
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const supabase = createServerClientWrapper() as any;

  const { data: roles } = await supabase.from('roles').select('id, name');
  const { data: tiers } = await supabase.from('tiers').select('id, name');

  async function handleCreate(values: UserFormValues) {
    'use server';

    await fetch('/api/admin-api/users', {
      method: 'POST',
      body: JSON.stringify(values),
      headers: {
        'Content-Type': 'application/json',
      },
    });
  }

  return (
    <AdminShell isAdmin={true}>
      <h1 className="mb-4 text-2xl font-semibold">Create User</h1>

      <UserForm
        roles={(roles ?? []) as Role[]}
        tiers={(tiers ?? []) as Tier[]}
        onSubmit={handleCreate}
      />
    </AdminShell>
  );
}
