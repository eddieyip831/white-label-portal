"use client";

import { DataTable } from "@kit/ui/data-table";

export default function RolesList({ data }) {
  return (
    <DataTable
      data={data}
      columns={Object.keys(data[0] || {}).map((k) => ({
        accessorKey: k,
        header: k.replace(/_/g, " ").toUpperCase(),
      }))}
    />
  );
}
