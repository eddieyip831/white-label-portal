'use client';

import { DataTable } from '@kit/ui/data-table';

type UserListRow = {
  id: string;
  full_name: string | null;
  tier_id: string | null;
  tenant_id: string;
  user_roles?: { role_id: string }[];
  user_attributes?: { attribute_key: string; attribute_value: string }[];
};

export default function UsersList({ data }: { data: UserListRow[] }) {
  return (
    <DataTable
      data={data}
      columns={Object.keys(data[0] || {}).map((k) => ({
        accessorKey: k,
        header: k.replace(/_/g, ' ').toUpperCase(),
      }))}
    />
  );
}
