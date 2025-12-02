import Link from 'next/link';

import MembersTable from '~/components/admin/tenant-members/MembersTable';
import { createServerClientWrapper } from '~/lib/supabase/server';

export default async function TenantMembersPage() {
  const supabase = createServerClientWrapper();

  // Load admin view
  const { data, error } = await supabase
    .from('tenant_members_admin')
    .select('*')
    .order('created_at', { ascending: false });

  if (error) {
    console.error('Failed loading tenant members:', error);
    throw error;
  }

  return (
    <div className="space-y-4 p-6">
      <div className="flex items-center justify-between">
        <h1 className="text-xl font-semibold">Tenant Members</h1>

        <Link
          href="/admin/tenant-members/new"
          className="rounded bg-blue-600 px-4 py-2 text-white"
        >
          Add Member
        </Link>
      </div>

      <MembersTable rows={data ?? []} />
    </div>
  );
}
