import { createServerClientWrapper } from '~/lib/supabase/server';

import { createMember } from '../actions';

export default async function NewTenantMemberPage() {
  const supabase = createClient();

  const [{ data: tenants }, { data: users }, { data: roles }, { data: tiers }] =
    await Promise.all([
      supabase.from('tenants').select('id, name').order('name'),
      supabase.schema('auth').from('users').select('id, email').order('email'),
      supabase.from('roles').select('id, name').order('name'),
      supabase.from('tiers').select('id, name').order('name'),
    ]);

  return (
    <form action={createMember} className="max-w-lg space-y-4 p-6">
      <h1 className="text-xl font-semibold">Add Tenant Member</h1>

      <div>
        <label className="mb-1 block text-sm">User</label>
        <select name="user_id" className="w-full rounded border p-2">
          {users?.map((u) => (
            <option key={u.id} value={u.id}>
              {u.email}
            </option>
          ))}
        </select>
      </div>

      <div>
        <label className="mb-1 block text-sm">Tenant</label>
        <select name="tenant_id" className="w-full rounded border p-2">
          {tenants?.map((t) => (
            <option key={t.id} value={t.id}>
              {t.name}
            </option>
          ))}
        </select>
      </div>

      <div>
        <label className="mb-1 block text-sm">Role</label>
        <select name="role_id" className="w-full rounded border p-2">
          {roles?.map((r) => (
            <option key={r.id} value={r.id}>
              {r.name}
            </option>
          ))}
        </select>
      </div>

      <div>
        <label className="mb-1 block text-sm">Tier (optional)</label>
        <select name="tier_id" className="w-full rounded border p-2">
          <option value="">(none)</option>
          {tiers?.map((t) => (
            <option key={t.id} value={t.id}>
              {t.name}
            </option>
          ))}
        </select>
      </div>

      <button className="rounded bg-blue-600 px-4 py-2 text-white">
        Create
      </button>
    </form>
  );
}
