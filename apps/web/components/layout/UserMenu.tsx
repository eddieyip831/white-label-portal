'use client';

import { useState } from 'react';

import Link from 'next/link';
import { useRouter } from 'next/navigation';

import { useClaims } from '~/components/useClaims';

export interface Claims {
  email: string | null;
  name: string | null;
  tier: string | null;
  roles: string[] | null;
  permissions?: string[];
  tenantId: string | null;
  rawMeta?: Record<string, any>;
  rawClaims?: Record<string, any>;
}

function deriveDisplayName(c: Claims): string {
  if (c.name) return c.name.trim();
  if (c.email) return c.email.split('@')[0]!;
  return 'User';
}

function getInitials(name: string): string {
  const parts = name.trim().split(/\s+/).filter(Boolean);
  if (parts.length === 0) return 'US';
  if (parts.length === 1) return parts[0]!.slice(0, 2).toUpperCase();
  return `${parts[0]![0]}${parts[parts.length - 1]![0]}`.toUpperCase();
}

export default function UserMenu() {
  const router = useRouter();
  const [pending, setPending] = useState(false);

  const claims = useClaims();
  if (!claims) return null;

  // -----------------------------
  // ⭐ MERGE CLAIMS SAFELY
  // -----------------------------
  const merged: Claims = {
    email: claims.email ?? claims.rawMeta?.email ?? null,
    name: claims.name ?? claims.rawMeta?.name ?? null,

    tier: claims.tier ?? claims.rawMeta?.tier ?? 'free',

    roles:
      claims.roles && claims.roles.length > 0
        ? claims.roles
        : (claims.rawMeta?.roles ?? []),

    permissions:
      claims.permissions && claims.permissions.length > 0
        ? claims.permissions
        : (claims.rawMeta?.permissions ?? []),

    tenantId: claims.tenantId ?? null,
    rawMeta: claims.rawMeta,
    rawClaims: claims.rawClaims,
  };

  console.debug('[UserMenu] FINAL merged claims:', merged);

  const name = deriveDisplayName(merged);
  const initials = getInitials(name);

  const showDebug =
    typeof process !== 'undefined' &&
    process.env.NEXT_PUBLIC_LOG_LEVEL === 'debug';

  async function handleLogout() {
    setPending(true);
    try {
      await fetch('/auth/signout', { method: 'GET' });
    } finally {
      router.push('/');
      setPending(false);
    }
  }

  return (
    <div className="flex items-center gap-4 pr-4">
      <div className="hidden text-right sm:block">
        <div className="text-xs text-gray-400 uppercase">Signed in as</div>

        <div className="text-sm font-medium text-gray-900">{name}</div>
        <div className="text-xs text-gray-500">{merged.email}</div>

        <div className="mt-1 text-xs font-semibold text-blue-600">
          Tier: {merged.tier}
        </div>

        {showDebug && (
          <div className="mt-2 space-y-1 text-[10px] text-gray-400">
            <div>Roles: {merged.roles?.join(', ') || 'None'}</div>
            <div>Perms: {merged.permissions?.length ?? 0}</div>
            <div>Tenant: {merged.tenantId ?? 'N/A'}</div>
          </div>
        )}
      </div>

      {/* Avatar */}
      <div className="flex h-10 w-10 items-center justify-center rounded-full bg-gray-200 text-sm font-semibold text-gray-700">
        {initials}
      </div>

      {/* Profile link */}
      <Link
        href="/settings/profile"
        className="hidden rounded-full border px-3 py-1 text-xs text-gray-700 hover:bg-gray-100 sm:inline-block"
      >
        Profile
      </Link>

      {/* Logout */}
      <button
        onClick={handleLogout}
        disabled={pending}
        className="rounded-full bg-gray-900 px-3 py-1 text-xs text-white hover:bg-gray-800 disabled:opacity-50"
      >
        {pending ? 'Logging out…' : 'Logout'}
      </button>
    </div>
  );
}
