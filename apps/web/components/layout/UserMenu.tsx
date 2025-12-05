'use client';

import { useEffect, useRef, useState } from 'react';

import Link from 'next/link';
import { useRouter } from 'next/navigation';

import type { Claims } from '~/components/useClaims';
import { useClaims } from '~/components/useClaims';
import { supabase } from '~/lib/supabase/client';

function deriveDisplayName(c: Claims): string {
  const name = c.name?.trim();
  if (name) return name;

  const email = c.email?.trim();
  if (email) {
    const [localPart] = email.split('@');
    return localPart && localPart.trim() ? localPart.trim() : 'User';
  }

  return 'User';
}

function getInitials(name: string): string {
  const parts = name.trim().split(/\s+/).filter(Boolean);

  if (parts.length === 0) return 'US';

  const first = parts[0] ?? '';

  if (parts.length === 1) {
    const initials = first.slice(0, 2);
    return initials ? initials.toUpperCase() : 'US';
  }

  const last = parts[parts.length - 1] ?? first;
  const initials = `${first.charAt(0)}${last.charAt(0)}`.trim();

  return initials ? initials.toUpperCase() : 'US';
}

type UserMenuProps = {
  claims?: Claims | null;
};

export default function UserMenu({ claims: injectedClaims }: UserMenuProps = {}) {
  const router = useRouter();
  const fallbackClaims = useClaims();
  const claims = injectedClaims ?? fallbackClaims;

  const [pending, setPending] = useState(false);
  const [open, setOpen] = useState(false);
  const menuRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    function handlePointer(event: MouseEvent) {
      if (!menuRef.current?.contains(event.target as Node)) {
        setOpen(false);
      }
    }

    function handleKey(event: KeyboardEvent) {
      if (event.key === 'Escape') {
        setOpen(false);
      }
    }

    document.addEventListener('mousedown', handlePointer);
    document.addEventListener('keydown', handleKey);

    return () => {
      document.removeEventListener('mousedown', handlePointer);
      document.removeEventListener('keydown', handleKey);
    };
  }, []);

  if (!claims) {
    return (
      <div className="flex items-center gap-3">
        <span className="h-6 w-16 animate-pulse rounded-full bg-gray-200" />
        <span className="h-10 w-10 animate-pulse rounded-full bg-gray-200" />
      </div>
    );
  }

  const tierLabel = (claims.tier ?? 'free').toLowerCase();
  const displayName = deriveDisplayName(claims);
  const initials = getInitials(displayName);

  async function handleLogout() {
    setPending(true);
    try {
      await supabase.auth.signOut();
      setOpen(false);
      router.push('/');
    } catch (error) {
      console.error('[UserMenu] logout failed', error);
    } finally {
      setPending(false);
    }
  }

  const menuItems = [
    {
      key: 'profile',
      label: 'Profile',
      node: (
        <Link
          href="/settings/profile"
          onClick={() => setOpen(false)}
          className="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-50"
        >
          Profile
        </Link>
      ),
    },
    {
      key: 'logout',
      label: 'Logout',
      node: (
        <button
          type="button"
          onClick={handleLogout}
          disabled={pending}
          className="block w-full px-4 py-2 text-left text-sm text-red-600 hover:bg-red-50 disabled:opacity-60"
        >
          {pending ? 'Logging out…' : 'Logout'}
        </button>
      ),
    },
  ];

  return (
    <div className="relative flex items-center gap-3" ref={menuRef}>
      <span className="rounded-full bg-gray-100 px-2 py-0.5 text-xs font-semibold capitalize text-gray-700">
        {tierLabel}
      </span>

      <button
        type="button"
        className="flex h-10 w-10 items-center justify-center rounded-full bg-gray-900 text-sm font-semibold uppercase text-white focus:outline-none focus:ring-2 focus:ring-gray-400"
        aria-haspopup="menu"
        aria-expanded={open}
        onClick={() => setOpen((prev) => !prev)}
      >
        {initials}
      </button>

      {open && (
        <div className="absolute right-0 top-full z-20 mt-3 w-56 overflow-hidden rounded-md border bg-white shadow-xl">
          <div className="border-b px-4 py-3">
            <p className="text-sm font-semibold text-gray-900">{displayName}</p>
            <p className="text-xs text-gray-500">{claims.email ?? 'No email'}</p>
          </div>

          <div className="flex flex-col py-1">
            {menuItems.map((item) => (
              <div key={item.key}>{item.node}</div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
