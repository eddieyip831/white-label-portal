'use client';

import { useState } from 'react';

import { createClient } from '@supabase/supabase-js';

import PublicHeader from '@/components/public/PublicHeader';

export default function ForgotPassword() {
  const [email, setEmail] = useState('');
  const [sent, setSent] = useState(false);
  const [errorMsg, setErrorMsg] = useState('');

  const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
  );

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();

    const { error } = await supabase.auth.resetPasswordForEmail(email, {
      redirectTo: `${process.env.NEXT_PUBLIC_SITE_URL}/update-password`,
    });

    if (error) {
      setErrorMsg(error.message);
      return;
    }

    setSent(true);
  }

  return (
    <>
      <PublicHeader />

      <main className="flex min-h-screen items-center justify-center bg-gray-50 px-4">
        <div className="w-full max-w-md rounded-xl border bg-white p-8 shadow">
          <h1 className="mb-6 text-center text-xl font-semibold">
            Reset Your Password
          </h1>

          {sent ? (
            <p className="text-center text-green-600">
              A reset email has been sent.
            </p>
          ) : (
            <form onSubmit={handleSubmit} className="space-y-4">
              <input
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="you@example.com"
                className="w-full rounded-lg border px-3 py-2"
              />

              {errorMsg && <p className="text-red-600">{errorMsg}</p>}

              <button
                type="submit"
                className="w-full rounded-lg bg-blue-600 py-2.5 text-white hover:bg-blue-700"
              >
                Send Reset Link
              </button>
            </form>
          )}

          <div className="mt-4 text-center">
            <a href="/" className="text-sm text-blue-600 hover:underline">
              Back to Login
            </a>
          </div>
        </div>
      </main>
    </>
  );
}
