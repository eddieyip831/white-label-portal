#!/usr/bin/env bash

# ============================================================
# Scaffold Portal Framework Structure (Option B)
# ============================================================
# Creates a clean baseline folder + file structure under apps/web
# without overwriting existing files.
# ============================================================

if [ -n "$ZSH_VERSION" ]; then
  echo "❌ ERROR: Run this script with bash, not zsh"
  echo "Usage: bash scaffold-framework-structure.sh"
  exit 1
fi

if [ ! -d "apps/web" ]; then
  echo "❌ ERROR: Cannot find apps/web. Run this script from the project root."
  exit 1
fi

WEB_ROOT="apps/web"

echo "➡ Creating base directories..."

mkdir -p "$WEB_ROOT/app/auth/login"
mkdir -p "$WEB_ROOT/app/auth/register"
mkdir -p "$WEB_ROOT/app/admin"
mkdir -p "$WEB_ROOT/app/dashboard"
mkdir -p "$WEB_ROOT/app/settings"
mkdir -p "$WEB_ROOT/app/api/health"

mkdir -p "$WEB_ROOT/components/ui"
mkdir -p "$WEB_ROOT/components/layout"
mkdir -p "$WEB_ROOT/lib/supabase"
mkdir -p "$WEB_ROOT/modules/users/pages/list"

# ------------------------------------------------------------
# Helper: create file only if it does NOT exist
# ------------------------------------------------------------
create_if_missing() {
  local path="$1"
  local label="$2"

  if [ -f "$path" ]; then
    echo "⏩ Skipping existing $label: $path"
  else
    echo "🆕 Creating $label: $path"
    cat > "$path"
  fi
}

# ------------------------------------------------------------
# app/admin/layout.tsx
# ------------------------------------------------------------
create_if_missing "$WEB_ROOT/app/admin/layout.tsx" "admin layout" << 'EOF'
import AppShell from "~/components/layout/AppShell";

export default function AdminLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return <AppShell section="admin">{children}</AppShell>;
}
EOF

# ------------------------------------------------------------
# app/admin/page.tsx
# ------------------------------------------------------------
create_if_missing "$WEB_ROOT/app/admin/page.tsx" "admin root page" << 'EOF'
export default function AdminHomePage() {
  return (
    <div>
      <h1>Admin Console</h1>
      <p>This will host the generic admin console for the portal framework.</p>
    </div>
  );
}
EOF

# ------------------------------------------------------------
# app/auth/login/page.tsx
# ------------------------------------------------------------
create_if_missing "$WEB_ROOT/app/auth/login/page.tsx" "auth login page" << 'EOF'
export default function LoginPage() {
  return (
    <div>
      <h1>Login</h1>
      <p>Hook this into Supabase Auth (email/password, OAuth, magic links).</p>
    </div>
  );
}
EOF

# ------------------------------------------------------------
# app/auth/register/page.tsx
# ------------------------------------------------------------
create_if_missing "$WEB_ROOT/app/auth/register/page.tsx" "auth register page" << 'EOF'
export default function RegisterPage() {
  return (
    <div>
      <h1>Register</h1>
      <p>Generic user registration form for the portal framework.</p>
    </div>
  );
}
EOF

# ------------------------------------------------------------
# app/dashboard/page.tsx
# ------------------------------------------------------------
create_if_missing "$WEB_ROOT/app/dashboard/page.tsx" "dashboard page" << 'EOF'
export default function DashboardPage() {
  return (
    <div>
      <h1>Dashboard</h1>
      <p>Portal home/dashboard. Future modules can plug widgets here.</p>
    </div>
  );
}
EOF

# ------------------------------------------------------------
# app/settings/page.tsx
# ------------------------------------------------------------
create_if_missing "$WEB_ROOT/app/settings/page.tsx" "settings page" << 'EOF'
export default function SettingsPage() {
  return (
    <div>
      <h1>Settings</h1>
      <p>User/account settings placeholder for the portal framework.</p>
    </div>
  );
}
EOF

# ------------------------------------------------------------
# app/api/health/route.ts
# ------------------------------------------------------------
create_if_missing "$WEB_ROOT/app/api/health/route.ts" "health check route" << 'EOF'
import { NextResponse } from "next/server";

export const dynamic = "force-dynamic";

export async function GET() {
  return NextResponse.json({ status: "ok" });
}
EOF

# ------------------------------------------------------------
# components/layout/AppShell.tsx
# ------------------------------------------------------------
create_if_missing "$WEB_ROOT/components/layout/AppShell.tsx" "AppShell layout component" << 'EOF'
"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

type AppShellProps = {
  children: React.ReactNode;
  section?: "admin" | "user" | "public";
};

const navItems = [
  { href: "/dashboard", label: "Dashboard" },
  { href: "/settings", label: "Settings" },
  { href: "/admin", label: "Admin" },
];

export default function AppShell({ children }: AppShellProps) {
  const pathname = usePathname();

  return (
    <div className="min-h-screen flex flex-col">
      <header className="border-b px-4 py-3 flex items-center justify-between">
        <div className="font-semibold">Portal Framework</div>
        <nav className="flex gap-4">
          {navItems.map((item) => (
            <Link
              key={item.href}
              href={item.href}
              className={
                pathname?.startsWith(item.href)
                  ? "font-semibold underline"
                  : "text-gray-600"
              }
            >
              {item.label}
            </Link>
          ))}
        </nav>
      </header>

      <main className="flex-1 px-4 py-6">{children}</main>
    </div>
  );
}
EOF

# ------------------------------------------------------------
# components/ui/Button.tsx
# ------------------------------------------------------------
create_if_missing "$WEB_ROOT/components/ui/Button.tsx" "Button component" << 'EOF'
"use client";

import type { ButtonHTMLAttributes } from "react";

type ButtonProps = ButtonHTMLAttributes<HTMLButtonElement> & {
  variant?: "primary" | "secondary";
};

export function Button({ variant = "primary", className = "", ...props }: ButtonProps) {
  const base =
    "inline-flex items-center justify-center rounded-md px-4 py-2 text-sm font-medium border";

  const styles =
    variant === "primary"
      ? "bg-black text-white border-black"
      : "bg-white text-black border-gray-300";

  return <button className={`${base} ${styles} ${className}`} {...props} />;
}
EOF

# ------------------------------------------------------------
# lib/supabase/client.ts
# ------------------------------------------------------------
create_if_missing "$WEB_ROOT/lib/supabase/client.ts" "Supabase client helper" << 'EOF'
import { createBrowserClient } from "@supabase/ssr";

export function createSupabaseBrowserClient() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const anonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

  if (!url || !anonKey) {
    throw new Error("Supabase env vars are missing");
  }

  return createBrowserClient(url, anonKey);
}
EOF

# ------------------------------------------------------------
# lib/supabase/server.ts (only if missing)
# ------------------------------------------------------------
create_if_missing "$WEB_ROOT/lib/supabase/server.ts" "Supabase server helper" << 'EOF'
import { cookies } from "next/headers";
import { createServerClient } from "@supabase/ssr";

export function createSupabaseServerClient() {
  const cookieStore = cookies();
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const anonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

  if (!url || !anonKey) {
    throw new Error("Supabase env vars are missing");
  }

  return createServerClient(url, anonKey, {
    cookies: {
      get(name: string) {
        return cookieStore.get(name)?.value;
      },
    },
  });
}
EOF

# ------------------------------------------------------------
# modules/users/pages/list/page.tsx
# ------------------------------------------------------------
create_if_missing "$WEB_ROOT/modules/users/pages/list/page.tsx" "users list page placeholder" << 'EOF'
export default function UsersListPage() {
  return (
    <div>
      <h1>Users</h1>
      <p>
        This is a placeholder for the Users module list page. In the framework,
        this will be driven by configuration (columns, filters, actions).
      </p>
    </div>
  );
}
EOF

echo "✅ Scaffold complete. Base framework structure is in place."
