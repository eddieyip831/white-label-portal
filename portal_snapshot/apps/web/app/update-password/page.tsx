'use client';

import { useEffect, useState } from 'react';

import dynamic from 'next/dynamic';

import { createClient } from '@supabase/supabase-js';

// Import your existing password strength meter
import PasswordStrength from '~/components/auth/PasswordStrength';

// adjust path if needed

// PublicHeader must be client-loaded to avoid hydration mismatch
const PublicHeader = dynamic(() => import('~/components/public/PublicHeader'), {
  ssr: false,
});

export default function UpdatePasswordPage() {
  const [error, setError] = useState<string | null>(null);
  const [token, setToken] = useState<string | null>(null);
  const [validating, setValidating] = useState(true);

  const [password, setPassword] = useState('');
  const [confirm, setConfirm] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [success, setSuccess] = useState(false);

  // Initialize Supabase client
  const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
  );

  /**
   * Parse Supabase hash fragment
   */
  useEffect(() => {
    const hash = window.location.hash;

    // Error from Supabase callback
    if (hash.includes('error')) {
      const params = new URLSearchParams(hash.replace('#', ''));
      const message =
        params.get('error_description') ||
        'The password reset link is invalid or has expired.';
      setError(message);
      setValidating(false);
      return;
    }

    // Extract access_token
    if (hash.includes('access_token')) {
      const params = new URLSearchParams(hash.replace('#', ''));
      const accessToken = params.get('access_token');

      if (!accessToken) {
        setError('Invalid password reset token.');
        setValidating(false);
        return;
      }

      setToken(accessToken);
      setValidating(false);
      return;
    }

    setError('Invalid reset link.');
    setValidating(false);
  }, []);

  /**
   * Submit handler
   */
  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setSubmitting(true);
    setError(null);

    if (!token) {
      setError('Missing or invalid password reset token.');
      setSubmitting(false);
      return;
    }

    if (password !== confirm) {
      setError('Passwords do not match.');
      setSubmitting(false);
      return;
    }

    // Update user password
    const { error: updateError } = await supabase.auth.updateUser(
      { password },
      { accessToken: token },
    );

    if (updateError) {
      setError(updateError.message);
      setSubmitting(false);
      return;
    }

    setSuccess(true);

    // Auto redirect
    setTimeout(() => {
      window.location.href = '/';
    }, 2200);
  }

  // ------------------------------
  // UI STATES
  // ------------------------------

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

  if (error && !success) {
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

  if (success) {
    return (
      <div className="min-h-screen bg-gray-50">
        <PublicHeader />
        <main className="flex min-h-[80vh] items-center justify-center px-4">
          <div className="max-w-lg rounded-xl bg-white p-10 text-center shadow">
            <h1 className="text-2xl font-semibold text-green-600">
              Password Updated!
            </h1>
            <p className="mt-4 text-gray-700">Redirecting…</p>
          </div>
        </main>
      </div>
    );
  }

  // ------------------------------
  // MAIN FORM
  // ------------------------------

  return (
    <div className="min-h-screen bg-gray-50">
      <PublicHeader />

      <main className="flex min-h-[80vh] items-center justify-center px-4">
        <div className="max-w-lg rounded-xl bg-white p-10 shadow">
          <h1 className="text-2xl font-semibold">Set a New Password</h1>
          <p className="mt-2 text-gray-600">
            Your link is valid. Set a strong new password below.
          </p>

          <form onSubmit={handleSubmit} className="mt-8 space-y-6">
            <div>
              <label className="block text-sm font-medium">New Password</label>
              <input
                type="password"
                className="mt-1 w-full rounded border px-3 py-2"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="Enter a strong password"
              />
              {/* Your actual strength meter */}
              <PasswordStrength password={password} />
            </div>

            <div>
              <label className="block text-sm font-medium">
                Confirm Password
              </label>
              <input
                type="password"
                className="mt-1 w-full rounded border px-3 py-2"
                value={confirm}
                onChange={(e) => setConfirm(e.target.value)}
                placeholder="Re-enter password"
              />
            </div>

            {error && <p className="text-sm text-red-600">{error}</p>}

            <button
              type="submit"
              disabled={submitting}
              className="w-full rounded bg-blue-600 px-6 py-2 font-medium text-white"
            >
              {submitting ? 'Updating...' : 'Update Password'}
            </button>
          </form>
        </div>
      </main>
    </div>
  );
}
