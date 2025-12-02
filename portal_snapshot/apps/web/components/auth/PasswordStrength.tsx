'use client';

import { validatePassword } from '~/lib/validators/password';

export default function PasswordStrength({ password }: { password: string }) {
  const result = validatePassword(password);

  const colors = [
    'bg-red-500',
    'bg-orange-500',
    'bg-yellow-500',
    'bg-green-400',
    'bg-green-600',
  ];

  const activeColor = colors[result.score] ?? 'bg-gray-300';

  const bars = [0, 1, 2, 3].map((i) => (
    <div
      key={i}
      className={`h-2 w-full rounded transition-all ${
        i <= result.score - 1 ? activeColor : 'bg-gray-200'
      }`}
    ></div>
  ));

  return (
    <div className="mt-2 space-y-3">
      {/* Strength Bar */}
      <div className="grid grid-cols-4 gap-1">{bars}</div>

      {/* Requirements */}
      <ul className="space-y-1 text-sm">
        <Req ok={result.length} label="At least 8 characters" />
        <Req ok={result.uppercase} label="At least one uppercase letter" />
        <Req ok={result.lowercase} label="At least one lowercase letter" />
        <Req ok={result.number} label="At least one number" />
        <Req ok={result.symbol} label="At least one symbol" />
      </ul>
    </div>
  );
}

function Req({ ok, label }: { ok: boolean; label: string }) {
  return (
    <li
      className={`flex items-center ${ok ? 'text-green-600' : 'text-gray-500'}`}
    >
      {ok ? <span className="mr-2">✔</span> : <span className="mr-2">✕</span>}
      {label}
    </li>
  );
}
