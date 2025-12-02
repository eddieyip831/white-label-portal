// apps/web/app/layout.tsx
import RootLayoutContent from '~/components/RootLayoutContent';

import '../styles/globals.css';

// IMPORTANT: RootLayout must NOT be async
export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return <RootLayoutContent>{children}</RootLayoutContent>;
}

export { generateRootMetadata as generateMetadata } from '~/lib/root-metdata';
