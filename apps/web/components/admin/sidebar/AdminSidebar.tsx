'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';

import { adminNav } from '../nav/admin-nav';

export default function AdminSidebar() {
  const pathname = usePathname();

  return (
    <aside className="flex h-full w-64 flex-col bg-gray-900 text-white">
      <div className="border-b border-gray-700 p-4 text-lg font-bold">
        Admin Console
      </div>

      <nav className="flex-1 space-y-4 overflow-y-auto p-2">
        {adminNav.map((item) => (
          <div key={item.label}>
            <div className="px-2 py-1 text-sm font-semibold text-gray-400 uppercase">
              {item.label}
            </div>

            {item.children?.map((child) => {
              const active = pathname === child.route;

              return (
                <Link
                  key={child.route}
                  href={child.route}
                  className={`block rounded-md px-4 py-2 text-sm ${
                    active
                      ? 'bg-white font-semibold text-black'
                      : 'text-gray-300 hover:bg-gray-700'
                  }`}
                >
                  {child.label}
                </Link>
              );
            })}
          </div>
        ))}
      </nav>
    </aside>
  );
}
