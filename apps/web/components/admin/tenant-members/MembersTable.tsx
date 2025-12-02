'use client';

import { useTransition } from 'react';

import Link from 'next/link';

import { deleteMember } from '~/app/admin/tenant-members/actions';

export default function MembersTable({ rows }) {
  const [isPending, startTransition] = useTransition();

  return (
    <table className="min-w-full text-sm">
      <thead>
        <tr className="border-b">
          <th className="py-2 text-left">User</th>
          <th className="py-2 text-left">Tenant</th>
          <th className="py-2 text-left">Role</th>
          <th className="py-2 text-left">Tier</th>
          <th className="py-2 text-left">Created</th>
          <th className="py-2 text-left">Actions</th>
        </tr>
      </thead>

      <tbody>
        {rows.map((m) => (
          <tr
            key={`${m.tenant_id}-${m.user_id}`}
            className="border-b last:border-0"
          >
            <td className="py-2">{m.user_email}</td>
            <td className="py-2">{m.tenant_name}</td>
            <td className="py-2">{m.role_name ?? '—'}</td>
            <td className="py-2">{m.tier_name ?? '—'}</td>
            <td className="py-2">
              {m.created_at ? new Date(m.created_at).toLocaleDateString() : '—'}
            </td>

            <td className="py-2">
              <div className="flex gap-2">
                <Link
                  href={`/admin/tenant-members/${m.tenant_id}/${m.user_id}/edit`}
                  className="text-blue-600 underline"
                >
                  Edit
                </Link>

                <button
                  disabled={isPending}
                  className="text-red-600 underline disabled:opacity-50"
                  onClick={() =>
                    startTransition(() =>
                      deleteMember({
                        tenant_id: m.tenant_id,
                        user_id: m.user_id,
                      }),
                    )
                  }
                >
                  Delete
                </button>
              </div>
            </td>
          </tr>
        ))}

        {rows.length === 0 && (
          <tr>
            <td className="py-4 text-center" colSpan={6}>
              No tenant members found
            </td>
          </tr>
        )}
      </tbody>
    </table>
  );
}
