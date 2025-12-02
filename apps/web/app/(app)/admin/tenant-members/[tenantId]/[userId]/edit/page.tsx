import { createServerClientWrapper } from '~/lib/supabase/server';

import { updateMember } from '../../../actions';

export default async function EditTenantMemberPage({ params }) {
  const supabase = createServerClientWrapper();

  const { data: member, error } = await supabase
    .from('tenant_members_admin')
    .select('*')
    .eq('tenant_id', params.tenantId)
    .eq('user_id', params.userId)
    .single();

  if (error || !member) {
    console.error('Failed loading tenant member:', error);
    throw new Error('Tenant member not found');
  }

  const [{ data: roles }, { data: tiers }] = await Promise.all([
    supabase.from('roles').select('id, name').order('name'),
    supabase.from('tiers').select('id, name').order('name'),
  ]);

  return (
    <form action={updateMember} className="max-w-lg space-y-4 p-6">
      <input type="hidden" name="tenant_id" value={params.tenantId} />
      <input type="hidden" name="user_id" value={params.userId} />

      <h1 className="text-xl font-semibold">Edit Tenant Member</h1>

      <p className="text-sm text-gray-600">
        User: {member.user_email} <br />
        Tenant: {member.tenant_name}
      </p>

      <div>
        <label className="mb-1 block text-sm">Role</label>
        <select
          name="role_id"
          defaultValue={member.role_id ?? ''}
          className="w-full rounded border p-2"
        >
          {roles?.map((r) => (
            <option key={r.id} value={r.id}>
              {r.name}
            </option>
          ))}
        </select>
      </div>

      <div>
        <label className="mb-1 block text-sm">Tier</label>
        <select
          name="tier_id"
          defaultValue={member.tier_id ?? ''}
          className="w-full rounded border p-2"
        >
          <option value="">(none)</option>
          {tiers?.map((t) => (
            <option key={t.id} value={t.id}>
              {t.name}
            </option>
          ))}
        </select>
      </div>

      <button className="rounded bg-blue-600 px-4 py-2 text-white">
        Save Changes
      </button>
    </form>
  );
}
