'use client';

import Link from 'next/link';
import { useMemo } from 'react';
import { usePathname } from 'next/navigation';

import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuTrigger,
} from '@kit/ui/dropdown-menu';

import type { Claims } from '~/components/useClaims';

function tierRank(tier?: string | null): number {
  if (!tier) return 0;
  const normalized = tier.toLowerCase();
  if (normalized === 'enterprise') return 2;
  if (normalized === 'premium') return 1;
  return 0;
}

function hasTier(claims: Claims, minimum: 'premium' | 'enterprise') {
  const requiredRank = minimum === 'enterprise' ? 2 : 1;
  return tierRank(claims.tier) >= requiredRank;
}

function hasRole(claims: Claims, role: 'admin' | 'super_admin') {
  return claims.roles?.includes(role) ?? false;
}

type NavItem = {
  key: string;
  label: string;
  href: string;
  match?: string[];
  visible: boolean;
};

type MainNavProps = {
  claims: Claims | null;
};

const SUPER_ADMIN_LINKS = [
  { label: 'Users', href: '/admin/super-admin/users' },
  { label: 'Roles', href: '/admin/super-admin/roles' },
  { label: 'Tiers', href: '/admin/super-admin/tiers' },
  { label: 'Permissions', href: '/admin/super-admin/permissions' },
  { label: 'Tier Permissions', href: '/admin/super-admin/tier-permissions' },
];

export default function MainNav({ claims }: MainNavProps) {
  const pathname = usePathname() ?? '';

  const items = useMemo<NavItem[]>(() => {
    if (!claims) {
      if (process.env.NEXT_PUBLIC_LOG_LEVEL === 'debug') {
        console.log('[MainNav] claims not available yet');
      }
      return [];
    }

    const isAdmin = hasRole(claims, 'admin') || hasRole(claims, 'super_admin');
    const isSuperAdmin = hasRole(claims, 'super_admin');

    return [
      {
        key: 'home',
        label: 'Home',
        href: '/home',
        match: ['/home'],
        visible: true,
      },
      {
        key: 'premium',
        label: 'Premium',
        href: '/premium',
        match: ['/premium', '/analytics', '/modules'],
        visible: hasTier(claims, 'premium'),
      },
      {
        key: 'enterprise',
        label: 'Enterprise',
        href: '/enterprise',
        match: ['/enterprise'],
        visible: hasTier(claims, 'enterprise'),
      },
      {
        key: 'admin',
        label: 'Admin',
        href: '/admin/users',
        match: ['/admin'],
        visible: isAdmin,
      },
      {
        key: 'super-admin',
        label: 'Super Admin',
        href: SUPER_ADMIN_LINKS[0]?.href ?? '/admin/super-admin',
        match: ['/admin/super-admin', ...SUPER_ADMIN_LINKS.map((link) => link.href)],
        visible: isSuperAdmin,
      },
    ].filter((item) => item.visible);
  }, [claims]);

  if (!items.length) return null;

  return (
    <nav className="flex items-center gap-2 text-sm font-medium text-gray-600">
      {items.map((item) => {
        const isActive =
          item.match?.some((prefix) => pathname.startsWith(prefix)) ??
          pathname.startsWith(item.href);

        if (item.key === 'super-admin') {
          return (
            <DropdownMenu key={item.key}>
              <DropdownMenuTrigger asChild>
                <button
                  type="button"
                  className={[
                    'flex items-center gap-2 rounded-md px-3 py-1 text-sm transition-colors',
                    isActive
                      ? 'bg-gray-900 text-white'
                      : 'text-gray-600 hover:bg-gray-100 hover:text-gray-900',
                  ].join(' ')}
                >
                  {item.label}
                  <span className="text-xs">▾</span>
                </button>
              </DropdownMenuTrigger>
              <DropdownMenuContent align="start" sideOffset={8} className="w-56">
                <DropdownMenuLabel className="text-[10px] font-semibold uppercase text-gray-500">
                  Console
                </DropdownMenuLabel>
                {SUPER_ADMIN_LINKS.map((link) => (
                  <DropdownMenuItem asChild key={link.href}>
                    <Link href={link.href}>{link.label}</Link>
                  </DropdownMenuItem>
                ))}
              </DropdownMenuContent>
            </DropdownMenu>
          );
        }

        return (
          <Link
            key={item.key}
            href={item.href}
            className={[
              'rounded-md px-3 py-1 transition-colors',
              isActive
                ? 'bg-gray-900 text-white'
                : 'text-gray-600 hover:bg-gray-100 hover:text-gray-900',
            ].join(' ')}
          >
            {item.label}
          </Link>
        );
      })}
    </nav>
  );
}
