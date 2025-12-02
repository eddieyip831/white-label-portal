'use client';

import Link from 'next/link';

const adminLinks = [
  { href: '/admin/users', label: 'Users' },
  { href: '/admin/roles', label: 'Roles' },
  { href: '/admin/permissions', label: 'Permissions' },
  { href: '/admin/attributes', label: 'Attributes' },
  { href: '/admin/modules', label: 'Modules' },
];

export default function Sidebar() {
  return (
    <aside className="p-4">
      <ul className="space-y-2">
        {adminLinks.map((l) => (
          <li key={l.href}>
            <Link href={l.href} className="text-blue-600 hover:underline">
              {l.label}
            </Link>
          </li>
        ))}
      </ul>
    </aside>
  );
}
