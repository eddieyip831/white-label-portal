'use client';

import Link from 'next/link';

import { useClaimsClient } from '~/components/useClaims';

export default function Sidebar() {
  const { email, roles, tier, permissions } = useClaimsClient();

  const isAdmin = roles.includes('admin') || roles.includes('super_admin');
  const isSuperAdmin = roles.includes('super_admin');

  return (
    <div className="flex h-full flex-col space-y-6 border-r bg-white p-4">
      {/* Branding */}
      <div className="text-xl font-semibold">Portal</div>

      {/* MAIN NAV */}
      <nav className="flex-1 space-y-2">
        <SidebarLink href="/home" label="Home" />

        {/* ADMIN MODULES */}
        {isAdmin && (
          <Section title="Admin">
            <SidebarLink href="/admin/users" label="Users" />
            <SidebarLink href="/admin/tenant-members" label="Tenant Members" />
            <SidebarLink href="/admin/roles" label="Roles & Permissions" />
          </Section>
        )}

        {/* SUPER ADMIN ONLY */}
        {isSuperAdmin && (
          <Section title="Super Admin Tools">
            <SidebarLink href="/admin/system" label="System Settings" />
          </Section>
        )}

        {/* PAID MODULES EXAMPLE */}
        {tier !== 'free' && (
          <Section title="Premium">
            <SidebarLink href="/analytics" label="Analytics" />
            <SidebarLink href="/modules" label="Modules" />
          </Section>
        )}
      </nav>

      {/* DEBUG SECTION */}
      <SidebarDebug
        email={email}
        roles={roles}
        tier={tier}
        permissions={permissions}
      />
    </div>
  );
}

function SidebarLink({ href, label }: { href: string; label: string }) {
  return (
    <Link href={href} className="block rounded px-2 py-1 hover:bg-gray-100">
      {label}
    </Link>
  );
}

function Section({
  title,
  children,
}: {
  title: string;
  children: React.ReactNode;
}) {
  return (
    <div>
      <div className="mb-1 text-sm font-medium text-gray-500">{title}</div>
      <div className="space-y-1">{children}</div>
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
    <div className="mt-6 space-y-1 border-t p-3 text-xs text-gray-600">
      <div className="font-semibold">Debug Info</div>
      <div>Email: {email || 'N/A'}</div>
      <div>Tier: {tier || 'N/A'}</div>
      <div>Roles: {roles.length ? roles.join(', ') : 'None'}</div>
      <div>Permissions: {permissions.length}</div>
    </div>
  );
}
