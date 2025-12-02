'use client';

import { useEffect, useState } from 'react';

export function useClaims() {
  const [claims, setClaims] = useState<any>(null);

  useEffect(() => {
    const token = document.cookie
      .split('; ')
      .find((c) => c.startsWith('sb-access-token='))
      ?.split('=')[1];

    if (!token) return;

    try {
      const payload = JSON.parse(atob(token.split('.')[1]));
      setClaims(payload?.app_metadata?.claims ?? null);
    } catch {}
  }, []);

  return claims;
}

export function useRole(role: string) {
  const claims = useClaims();
  return claims?.roles?.includes(role) ?? false;
}

export function usePermission(perm: string) {
  const claims = useClaims();
  return claims?.permissions?.includes(perm) ?? false;
}

export function useModule(moduleKey: string) {
  const claims = useClaims();
  return claims?.permissions?.includes(`${moduleKey}.access`) ?? false;
}
