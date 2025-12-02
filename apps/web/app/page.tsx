'use client';

import { useState } from 'react';

import { createClient } from '@supabase/supabase-js';

import PublicHeader from '~/components/public/PublicHeader';

export default function Home() {
  const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
  );

  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [errorMsg, setErrorMsg] = useState('');

  async function handleLogin(e: React.FormEvent) {
    e.preventDefault();
    setErrorMsg('');

    const { error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });

    if (error) {
      setErrorMsg(error.message);
      return;
    }

    window.location.href = '/home';
  }

  return (
    <>
      <PublicHeader />

      <main className="flex min-h-screen items-center justify-center bg-gray-50 px-4">
        <div className="w-full max-w-md rounded-xl border bg-white p-8 shadow-lg">
          <h1 className="mb-6 text-center text-2xl font-semibold">
            Welcome Back
          </h1>

          <form onSubmit={handleLogin} className="space-y-4">
            {/* Email */}
            <input
              type="email"
              required
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full rounded-lg border px-3 py-2"
              placeholder="Email"
            />

            {/* Password */}
            <input
              type="password"
              required
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full rounded-lg border px-3 py-2"
              placeholder="Password"
            />

            {errorMsg && <p className="text-red-600">{errorMsg}</p>}

            <button
              type="submit"
              className="w-full rounded-lg bg-blue-600 py-2 text-white"
            >
              Sign In
            </button>
          </form>

          <div className="mt-4 text-center">
            <a
              href="/auth/forgot-password"
              className="text-sm text-gray-600 hover:underline"
            >
              Forgot password?
            </a>
          </div>

          <div className="mt-4 text-center">
            <a
              href="/auth/register"
              className="text-sm text-blue-600 hover:underline"
            >
              Create a new account
            </a>
          </div>
        </div>
      </main>
    </>
  );
}
