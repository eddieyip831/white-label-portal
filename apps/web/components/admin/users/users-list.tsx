'use client';

import { useMemo } from 'react';
import type { ColumnDef } from '@tanstack/react-table';

import { DataTable } from '@kit/ui/data-table';

type TableRow = Record<string, unknown>;

function formatValue(value: unknown): string {
  if (value === null || value === undefined || value === '') {
    return '—';
  }

  if (typeof value === 'string' || typeof value === 'number') {
    return String(value);
  }

  if (typeof value === 'boolean') {
    return value ? 'Yes' : 'No';
  }

  if (Array.isArray(value)) {
    if (value.length === 0) return '—';

    return value
      .map((item) => {
        if (typeof item === 'string' || typeof item === 'number') {
          return String(item);
        }

        if (item && typeof item === 'object') {
          return Object.entries(item)
            .map(([key, nestedValue]) => `${key}: ${nestedValue ?? '—'}`)
            .join(', ');
        }

        return JSON.stringify(item);
      })
      .join('; ');
  }

  if (typeof value === 'object') {
    return Object.entries(value as Record<string, unknown>)
      .map(([key, nestedValue]) => `${key}: ${nestedValue ?? '—'}`)
      .join(', ');
  }

  return String(value);
}

function humanizeKey(key: string): string {
  return key.replace(/_/g, ' ').replace(/\b\w/g, (char) => char.toUpperCase());
}

export default function UsersList({ data }: { data: TableRow[] }) {
  const columns = useMemo<ColumnDef<TableRow>[]>(() => {
    const keys = Array.from(
      data.reduce((acc, row) => {
        Object.keys(row ?? {}).forEach((key) => acc.add(key));
        return acc;
      }, new Set<string>()),
    );

    if (keys.length === 0) {
      return [
        {
          accessorKey: '__placeholder__',
          header: 'Users',
          cell: () => '—',
        },
      ];
    }

    return keys.map((key) => ({
      accessorKey: key,
      header: humanizeKey(key),
      cell: ({ row }) => formatValue(row.original[key]),
    }));
  }, [data]);

  return <DataTable columns={columns} data={data} />;
}
