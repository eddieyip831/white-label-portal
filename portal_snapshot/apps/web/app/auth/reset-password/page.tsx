'use client';

import { useEffect, useState } from 'react';

import PublicHeader from '~/components/public/PublicHeader';

export default function UpdatePasswordPage() {
  const [error, setError] = useState<string | null>(null);
  const [validating, setValidating] = useState(true);

  useEffect(() => {
    // Check for hash errors from Supabase
    const hash = window.location.hash;
    if (hash.includes('error')) {
      const params = new URLSearchParams(hash.replace('#', ''));
      const message =
        params.get('error_description') ||
        'The password reset link is invalid or has expired.';
      setError(message);
      setValidating(false);
      return;
    }

    // No hash errors → OK to show reset form
    setValidating(false);
  }, []);

  if (validating) {
    return (
      <div className="min-h-screen bg-gray-50">
        <PublicHeader />
        <main className="flex min-h-[80vh] items-center justify-center px-4">
          <div className="max-w-lg rounded-xl bg-white p-10 shadow">
            <h1 className="text-2xl font-semibold">Set a New Password</h1>
            <p className="mt-2 text-gray-600">Validating reset link…</p>
          </div>
        </main>
      </div>
    );
  }

  if (error) {
    return (
      <div className="min-h-screen bg-gray-50">
        <PublicHeader />
        <main className="flex min-h-[80vh] items-center justify-center px-4">
          <div className="max-w-lg rounded-xl bg-white p-10 text-center shadow">
            <h1 className="text-2xl font-semibold text-red-600">
              Password Reset Failed
            </h1>
            <p className="mt-4 text-gray-700">{error}</p>

            <a
              href="/auth/forgot-password"
              className="mt-6 inline-block rounded bg-blue-600 px-6 py-2 text-white"
            >
              Request a New Reset Link
            </a>
          </div>
        </main>
      </div>
    );
  }

  // TODO: Add the actual new-password form
  return (
    <div className="min-h-screen bg-gray-50">
      <PublicHeader />
      <main className="flex min-h-[80vh] items-center justify-center px-4">
        <div className="max-w-lg rounded-xl bg-white p-10 shadow">
          <h1 className="text-2xl font-semibold">Set a New Password</h1>

          <p className="mt-4 text-gray-600">
            Your link is valid! (Form UI goes here.)
          </p>
        </div>
      </main>
    </div>
  );
}
