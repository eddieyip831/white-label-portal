'use client';

import { useState } from 'react';

export default function AppHeader() {
  const [open, setOpen] = useState(false);

  return (
    <header className="flex w-full items-center justify-between border-b bg-white px-6 py-3">
      {/* Left section: burger + logo */}
      <div className="flex items-center space-x-4">
        {/* Burger menu */}
        <button
          onClick={() => setOpen(!open)}
          className="rounded-md border p-2 hover:bg-gray-100 lg:hidden"
        >
          ☰
        </button>

        {/* Logo - authenticated pages route to /dashboard */}
        <a href="/dashboard" className="flex items-center space-x-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-full bg-gray-300 font-bold text-gray-600">
            L
          </div>
          <span className="text-lg font-semibold">Portal Framework</span>
        </a>
      </div>

      {/* Right section: user avatar */}
      <div className="flex items-center space-x-3">
        <div className="h-9 w-9 rounded-full bg-gray-200"></div>
      </div>
    </header>
  );
}
