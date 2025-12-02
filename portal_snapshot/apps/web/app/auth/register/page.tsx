'use client';

import { useState } from 'react';

import { createClient } from '@supabase/supabase-js';

import PublicHeader from '@/components/public/PublicHeader';

import PasswordStrength from '~/components/auth/PasswordStrength';

export default function RegisterPage() {
  const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
  );

  const [fullName, setFullName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');

  const [acceptTerms, setAcceptTerms] = useState(false);
  const [marketingOptOut, setMarketingOptOut] = useState(false);

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);

  async function handleRegister(e: React.FormEvent) {
    e.preventDefault();
    setError(null);

    if (!acceptTerms) {
      return setError('You must accept the privacy policy and terms.');
    }

    if (password !== confirmPassword) {
      return setError('Passwords do not match.');
    }

    setLoading(true);

    const { error: signupError } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: {
          full_name: fullName,
          marketing_opt_out: marketingOptOut,
        },
      },
    });

    setLoading(false);

    if (signupError) {
      setError(signupError.message);
    } else {
      setSuccess(true);
    }
  }

  return (
    <>
      <PublicHeader />

      <main className="flex min-h-screen items-center justify-center bg-gray-50 px-4">
        <div className="w-full max-w-md rounded-xl bg-white p-8 shadow">
          <h1 className="mb-4 text-2xl font-semibold">Create an Account</h1>
          <p className="mb-6 text-gray-600">
            Enter your details below to register.
          </p>

          {error && (
            <p className="mb-4 text-center text-sm text-red-600">{error}</p>
          )}

          {success ? (
            <p className="text-center text-green-600">
              Registration successful! Please check your email to confirm your
              account.
            </p>
          ) : (
            <form onSubmit={handleRegister} className="space-y-4">
              {/* Full Name */}
              <div>
                <label className="block text-sm font-medium text-gray-700">
                  Full Name
                </label>
                <input
                  type="text"
                  required
                  value={fullName}
                  onChange={(e) => setFullName(e.target.value)}
                  className="mt-1 w-full rounded-lg border px-3 py-2"
                  placeholder="John Doe"
                />
              </div>

              {/* Email */}
              <div>
                <label className="block text-sm font-medium text-gray-700">
                  Email Address
                </label>
                <input
                  type="email"
                  required
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="mt-1 w-full rounded-lg border px-3 py-2"
                  placeholder="you@example.com"
                />
              </div>

              {/* Password */}
              <div>
                <label className="block text-sm font-medium text-gray-700">
                  Password
                </label>
                <input
                  type="password"
                  required
                  minLength={8}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="mt-1 w-full rounded-lg border px-3 py-2"
                  placeholder="••••••••"
                />

                {/* Password Strength Meter */}
                <PasswordStrength password={password} />
              </div>

              {/* Confirm Password */}
              <div>
                <label className="block text-sm font-medium text-gray-700">
                  Confirm Password
                </label>
                <input
                  type="password"
                  required
                  minLength={8}
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                  className="mt-1 w-full rounded-lg border px-3 py-2"
                  placeholder="••••••••"
                />

                {confirmPassword && password !== confirmPassword && (
                  <p className="text-sm text-red-600">Passwords do not match</p>
                )}
              </div>

              {/* Terms & Conditions */}
              <div className="flex items-center space-x-2">
                <input
                  type="checkbox"
                  checked={acceptTerms}
                  onChange={(e) => setAcceptTerms(e.target.checked)}
                  className="h-4 w-4"
                />
                <label className="text-sm text-gray-700">
                  I agree to the{' '}
                  <a
                    href="/legal/privacy"
                    className="text-blue-600 hover:underline"
                  >
                    Privacy Policy
                  </a>{' '}
                  and{' '}
                  <a
                    href="/legal/terms"
                    className="text-blue-600 hover:underline"
                  >
                    Terms of Use
                  </a>
                </label>
              </div>

              {/* Marketing Opt-Out */}
              <div className="flex items-center space-x-2">
                <input
                  type="checkbox"
                  checked={marketingOptOut}
                  onChange={(e) => setMarketingOptOut(e.target.checked)}
                  className="h-4 w-4"
                />
                <label className="text-sm text-gray-700">
                  I prefer not to receive marketing updates.
                </label>
              </div>

              {/* Submit Button */}
              <button
                type="submit"
                disabled={loading}
                className="w-full rounded-lg bg-blue-600 px-4 py-2 font-medium text-white hover:bg-blue-700"
              >
                {loading ? 'Creating account...' : 'Register'}
              </button>
            </form>
          )}

          <div className="mt-4 text-center">
            <a href="/" className="text-sm text-blue-600 hover:underline">
              Already have an account? Sign in
            </a>
          </div>
        </div>
      </main>
    </>
  );
}
