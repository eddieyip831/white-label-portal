import UsersList from '~/components/admin/users/users-list';
import { createServerClientWrapper } from '~/lib/supabase/server';

// We type only what we expect from user_profile
type UserRow = {
  id: string;
  full_name: string | null;
  tier_id: string | null;
  tenant_id: string;
  [key: string]: unknown;
};

export default async function UsersPage() {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const supabase = createServerClientWrapper() as any;

  const { data: users } = await supabase.from('user_profile').select(`
      id,
      full_name,
      tier_id,
      tenant_id,
      user_roles(role_id),
      user_attributes(attribute_key, attribute_value)
    `);

  return (
    <>
      <div className="mb-6 flex items-center justify-between">
        <h1 className="text-2xl font-semibold">Users</h1>

        <a
          href="/admin/users/create"
          className="rounded bg-blue-600 px-4 py-2 text-white"
        >
          + Add User
        </a>
      </div>

      <UsersList data={(users ?? []) as UserRow[]} />
    </>
  );
}
