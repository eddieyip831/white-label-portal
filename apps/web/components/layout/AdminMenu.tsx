'use client';

import { useState } from 'react';

import Link from 'next/link';

export default function AdminMenu() {
  const [open, setOpen] = useState(false);

  return (
    <div className="relative">
      <button
        onClick={() => setOpen((o) => !o)}
        className="rounded-md px-3 py-2 hover:bg-gray-100"
      >
        Admin ▾
      </button>

      {open && (
        <div className="absolute right-0 z-20 mt-2 w-48 rounded-md border bg-white shadow-lg">
          <Link
            href="/admin/tenant-members"
            className="block px-4 py-2 hover:bg-gray-100"
          >
            Tenant Members
          </Link>
        </div>
      )}
    </div>
  );
}
