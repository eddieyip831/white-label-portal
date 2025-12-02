// apps/web/components/RootLayoutContent.tsx
import { cookies } from 'next/headers';

import { Toaster } from '@kit/ui/sonner';
import { cn } from '@kit/ui/utils';

import { RootProviders } from '~/components/root-providers';
import { heading, sans } from '~/lib/fonts';
import { createI18nServerInstance } from '~/lib/i18n/i18n.server';

export default async function RootLayoutContent({
  children,
}: {
  children: React.ReactNode;
}) {
  // These async operations MUST NOT run in the root layout directly
  const { language } = await createI18nServerInstance();

  const cookieStore = await cookies();
  const theme = (cookieStore.get('theme')?.value || 'light') as
    | 'light'
    | 'dark';

  const className = cn(
    'bg-background min-h-screen antialiased',
    heading.variable,
    sans.variable,
    {
      dark: theme === 'dark',
      light: theme !== 'dark',
    },
  );

  return (
    <html lang={language} className={className}>
      <body>
        {/* Providers must remain client-safe */}
        <RootProviders theme={theme} lang={language}>
          {children}
        </RootProviders>

        {/* Toast notifications */}
        <Toaster richColors={true} theme={theme} position="top-center" />
      </body>
    </html>
  );
}
