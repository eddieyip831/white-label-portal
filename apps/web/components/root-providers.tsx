'use client';

import { usePathname } from 'next/navigation';

import { AuthProvider } from './auth-provider';
import { ReactQueryProvider } from './react-query-provider';

export function RootProviders({
  lang,
  theme,
  children,
}: {
  lang: string;
  theme: string;
  children: React.ReactNode;
}) {
  const pathname = usePathname();

  /**
   * Protected Routes
   */
  const isProtected =
    pathname?.startsWith('/home') || pathname?.startsWith('/admin');

  return (
    <ReactQueryProvider>
      {isProtected ? <AuthProvider>{children}</AuthProvider> : children}
    </ReactQueryProvider>
  );
}
