'use client';

import Link from 'next/link';
import { useMemo } from 'react';
import { usePathname } from 'next/navigation';

import { useClaims } from '~/components/useClaims';

type SectionKey = 'home' | 'premium' | 'enterprise' | 'admin' | 'settings' | 'general';

type SidebarItem = {
  label: string;
  href: string;
  match?: string[];
};

function tierRank(tier?: string | null): number {
  if (!tier) return 0;
  const normalized = tier.toLowerCase();
  if (normalized === 'enterprise') return 2;
  if (normalized === 'premium') return 1;
  return 0;
}

function deriveSection(pathname: string): SectionKey {
  if (pathname.startsWith('/admin')) return 'admin';
  if (pathname.startsWith('/settings')) return 'settings';
  if (pathname.startsWith('/analytics') || pathname.startsWith('/modules')) {
    return 'premium';
  }
  if (pathname.startsWith('/enterprise')) return 'enterprise';
  if (pathname.startsWith('/home')) return 'home';
  return 'general';
}

export default function Sidebar() {
  const pathname = usePathname() ?? '';
  const claims = useClaims();

  const roles = claims?.roles ?? [];
  const tier = claims?.tier ?? null;
  const permissions = claims?.permissions ?? [];
  const email = claims?.email ?? null;

  const isAdmin = roles.includes('admin') || roles.includes('super_admin');
  const isSuperAdmin = roles.includes('super_admin');
  const isPremium = tierRank(tier) >= 1;
  const isEnterprise = tierRank(tier) >= 2;

  const section = deriveSection(pathname);

  const items = useMemo<SidebarItem[]>(() => {
    if (section === 'admin') {
      if (!isAdmin) return [];
      const adminItems: SidebarItem[] = [
        { label: 'Users', href: '/admin/users' },
        { label: 'Tenant Members', href: '/admin/tenant-members' },
        { label: 'Roles', href: '/admin/roles' },
        { label: 'Permissions', href: '/admin/permissions' },
        { label: 'Attributes', href: '/admin/attributes' },
        { label: 'Modules', href: '/admin/modules' },
      ];

      if (isSuperAdmin) {
        adminItems.push({ label: 'System Settings', href: '/admin/system' });
      }

      return adminItems;
    }

    if (section === 'premium' && isPremium) {
      return [
        { label: 'Analytics', href: '/analytics' },
        { label: 'Modules', href: '/modules' },
      ];
    }

    if (section === 'enterprise' && isEnterprise) {
      return [
        { label: 'Enterprise Overview', href: '/enterprise' },
        { label: 'Tenant Members', href: '/admin/tenant-members', match: ['/admin/tenant-members'] },
      ];
    }

    if (section === 'settings') {
      return [
        { label: 'Settings Overview', href: '/settings' },
        { label: 'Profile', href: '/settings/profile' },
      ];
    }

    if (section === 'home') {
      return [
        { label: 'Overview', href: '/home' },
        { label: 'Profile Settings', href: '/settings/profile', match: ['/settings/profile'] },
      ];
    }

    return [];
  }, [section, isAdmin, isSuperAdmin, isPremium, isEnterprise]);

  const headingMap: Record<SectionKey, string> = {
    home: 'Home',
    premium: 'Premium',
    enterprise: 'Enterprise',
    admin: 'Admin',
    settings: 'Settings',
    general: 'Section',
  };

  return (
    <div className="flex h-full flex-col bg-white">
      <div className="flex-1 space-y-4 p-4">
        <div className="text-xs font-semibold uppercase tracking-wide text-gray-400">
          {headingMap[section]}
        </div>

        {!claims ? (
          <p className="text-sm text-gray-500">Loading navigation…</p>
        ) : items.length > 0 ? (
          <nav className="space-y-1">
            {items.map((item) => {
              const isActive =
                item.match?.some((prefix) => pathname.startsWith(prefix)) ??
                pathname.startsWith(item.href);

              return (
                <Link
                  key={item.label}
                  href={item.href}
                  className={[
                    'flex items-center justify-between rounded-md px-3 py-2 text-sm transition-colors',
                    isActive
                      ? 'bg-gray-900 text-white'
                      : 'text-gray-700 hover:bg-gray-100',
                  ].join(' ')}
                >
                  {item.label}
                </Link>
              );
            })}
          </nav>
        ) : (
          <p className="text-sm text-gray-500">
            No contextual links for this section yet.
          </p>
        )}
      </div>

      {claims && (
        <SidebarDebug
          email={email}
          roles={roles}
          tier={tier}
          permissions={permissions}
        />
      )}
    </div>
  );
}

function SidebarDebug({
  email,
  roles,
  tier,
  permissions,
}: {
  email: string | null;
  roles: string[];
  tier: string | null;
  permissions: string[];
}) {
  if (process.env.NEXT_PUBLIC_LOG_LEVEL !== 'debug') return null;

  return (
    <div className="space-y-1 border-t p-3 text-xs text-gray-600">
      <div className="font-semibold">Debug Info</div>
      <div>Email: {email || 'N/A'}</div>
      <div>Tier: {tier || 'N/A'}</div>
      <div>Roles: {roles.length ? roles.join(', ') : 'None'}</div>
      <div>Permissions: {permissions.length}</div>
    </div>
  );
}
