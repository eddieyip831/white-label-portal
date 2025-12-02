// apps/web/components/admin/nav/admin-nav.ts

export type AdminNavItem = {
  label: string;
  route: string;
  icon?: string; // optional icon support
  children?: AdminNavItem[];
};

export const adminNav: AdminNavItem[] = [
  {
    label: 'Dashboard',
    route: '/admin',
  },
  {
    label: 'Tenant Management',
    route: '',
    children: [
      { label: 'Tenants', route: '/admin/tenants' },
      { label: 'Tenant Members', route: '/admin/tenant-members' },
    ],
  },
  {
    label: 'User & Access Control',
    route: '',
    children: [
      { label: 'Roles', route: '/admin/roles' },
      { label: 'Tier Management', route: '/admin/tiers' },
      { label: 'Tier → Function', route: '/admin/tier-functions' },
    ],
  },
  {
    label: 'System Functions',
    route: '',
    children: [
      { label: 'Function Groups', route: '/admin/function-groups' },
      { label: 'Functions', route: '/admin/functions' },
    ],
  },
  {
    label: 'System Logs & Tools',
    route: '',
    children: [{ label: 'Audit Logs', route: '/admin/audit-logs' }],
  },
];
