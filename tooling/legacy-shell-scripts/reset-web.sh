#!/usr/bin/env bash
set -e

ROOT="/Users/eddie/baseframework/portal"
WEB="$ROOT/apps/web"
APP="$WEB/app"

echo "============================================================"
echo "     MAKERKIT LITE — ROUTE GROUP REPAIR (Next.js 15)"
echo "============================================================"

echo ""
echo "➡️  Step 1 — Create route group folders (if missing)..."

mkdir -p "$APP/(app)"
mkdir -p "$APP/(auth)"
mkdir -p "$APP/(marketing)"

echo "✔ Route groups ensured"
echo ""

echo "➡️  Step 2 — Move AUTH routes into (auth) group..."

if [ -d "$APP/auth" ]; then
  mv "$APP/auth" "$APP/(auth)/auth"
  echo "✔ Moved: app/auth → app/(auth)/auth"
else
  echo "✔ Auth routes already moved"
fi

echo ""
echo "➡️  Step 3 — Move ADMIN routes into (app) group..."

if [ -d "$APP/admin" ]; then
  mv "$APP/admin" "$APP/(app)/admin"
  echo "✔ Moved: app/admin → app/(app)/admin"
else
  echo "✔ Admin routes already moved"
fi

echo ""
echo "➡️  Step 4 — Move HOME (dashboard) routes into (app) group..."

if [ -d "$APP/home" ]; then
  mv "$APP/home" "$APP/(app)/home"
  echo "✔ Moved: app/home → app/(app)/home"
else
  echo "✔ Home already moved"
fi

echo ""
echo "➡️  Step 5 — Generate layout.tsx for (auth) and (app)..."

# (auth)/layout.tsx
AUTH_LAYOUT="$APP/(auth)/layout.tsx"
if [ ! -f "$AUTH_LAYOUT" ]; then
  cat > "$AUTH_LAYOUT" << 'EOF'
export default function AuthLayout({ children }: { children: React.ReactNode }) {
  return <>{children}</>;
}
EOF
  echo "✔ Created: (auth)/layout.tsx"
else
  echo "✔ (auth)/layout.tsx already exists"
fi

# (app)/layout.tsx
APP_LAYOUT="$APP/(app)/layout.tsx"
if [ ! -f "$APP_LAYOUT" ]; then
  cat > "$APP_LAYOUT" << 'EOF'
export default function AppLayout({ children }: { children: React.ReactNode }) {
  return <>{children}</>;
}
EOF
  echo "✔ Created: (app)/layout.tsx"
else
  echo "✔ (app)/layout.tsx already exists"
fi

echo ""
echo "➡️  Step 6 — Clean Next.js & Turbopack caches..."

rm -rf "$WEB/.next"
rm -rf "$WEB/node_modules"
rm -rf "$ROOT/node_modules"
rm -rf "$ROOT/.turbo"
rm -rf "$WEB/.turbo"
rm -rf ~/.cache/turbo

echo "✔ Caches removed"
echo ""

echo "➡️  Step 7 — Reinstall dependencies..."
cd "$ROOT"
pnpm install

echo ""
echo "============================================================"
echo "  ROUTE GROUP FIX COMPLETE — Starting pnpm dev..."
echo "============================================================"

pnpm dev &
