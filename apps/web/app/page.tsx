// apps/web/app/page.tsx
'use client';

import LoginForm from '~/components/auth/LoginForm';
import PublicHeader from '~/components/public/PublicHeader';

// apps/web/app/page.tsx

export default function Home() {
  return (
    <>
      <PublicHeader />

      <main className="flex min-h-screen items-center justify-center bg-gray-50 px-4">
        <LoginForm />
      </main>
    </>
  );
}
