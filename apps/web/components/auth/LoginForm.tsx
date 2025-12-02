// apps/web/components/auth/LoginForm.tsx
'use client';

import { FormEvent, useState } from 'react';

import { useRouter } from 'next/navigation';

import { supabase } from '~/lib/supabase/client';

// apps/web/components/auth/LoginForm.tsx

export default function LoginForm() {
  const router = useRouter();
  const [pending, setPending] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleSubmit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setError(null);
    setPending(true);

    const formData = new FormData(e.currentTarget);
    const email = String(formData.get('email') || '').trim();
    const password = String(formData.get('password') || '');

    if (!email || !password) {
      setError('Please enter email and password.');
      setPending(false);
      return;
    }

    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });

    console.log('login result', { data, error });

    setPending(false);

    if (error) {
      setError(error.message || 'Login failed');
      return;
    }

    if (!data.session) {
      setError('No session returned from Supabase.');
      return;
    }

    // At this point, MakerKit's browser client should have a session.
    router.push('/home');
  }

  return (
    <form
      onSubmit={handleSubmit}
      className="w-full max-w-md space-y-4 rounded-lg bg-white p-6 shadow"
    >
      <h1 className="text-xl font-semibold">Sign in</h1>

      {error && (
        <p className="rounded bg-red-50 px-3 py-2 text-sm text-red-700">
          {error}
        </p>
      )}

      <div className="space-y-1">
        <label htmlFor="email" className="text-sm font-medium text-gray-700">
          Email
        </label>
        <input
          id="email"
          name="email"
          type="email"
          className="w-full rounded border px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-blue-500"
          autoComplete="email"
          disabled={pending}
          required
        />
      </div>

      <div className="space-y-1">
        <label htmlFor="password" className="text-sm font-medium text-gray-700">
          Password
        </label>
        <input
          id="password"
          name="password"
          type="password"
          className="w-full rounded border px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-blue-500"
          autoComplete="current-password"
          disabled={pending}
          required
        />
      </div>

      <button
        type="submit"
        disabled={pending}
        className="flex w-full items-center justify-center rounded bg-blue-600 px-4 py-2 text-sm font-medium text-white disabled:opacity-60"
      >
        {pending ? 'Signing in…' : 'Sign in'}
      </button>
    </form>
  );
}
