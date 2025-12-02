#!/usr/bin/env bash

# Ensure bash
if [ -n "$ZSH_VERSION" ]; then
  echo "❌ Please run with bash, not zsh"
  exit 1
fi

ROOT="apps/web/app"

echo "============================================"
echo "🔍 Verifying Next.js App Structure"
echo "============================================"

check_dir() {
  if [ -d "$1" ]; then
    echo "✔ Directory exists: $1"
  else
    echo "❌ Missing directory: $1"
  fi
}

check_file() {
  if [ -f "$1" ]; then
    echo "✔ File exists: $1"
  else
    echo "❌ Missing file: $1"
  fi
}

echo "➡ Public pages"
check_file "$ROOT/page.tsx"
check_file "$ROOT/sitemap.xml/route.ts"
check_file "$ROOT/robots.ts"

echo "➡ Auth pages"
check_file "$ROOT/auth/login/page.tsx"
check_file "$ROOT/auth/register/page.tsx"
check_file "$ROOT/auth/forgot-password/page.tsx"
check_file "$ROOT/auth/reset-password/page.tsx"

echo "➡ User portal pages"
check_file "$ROOT/dashboard/page.tsx"
check_file "$ROOT/settings/page.tsx"

echo "➡ Admin console"
check_file "$ROOT/admin/layout.tsx"
check_file "$ROOT/admin/page.tsx"

echo "➡ API routes"
check_file "$ROOT/api/health/route.ts"

echo "➡ Error boundaries"
check_file "$ROOT/error.tsx"
check_file "$ROOT/global-error.tsx"
check_file "$ROOT/not-found.tsx"

echo "============================================"
echo "Done. Review missing items above."
