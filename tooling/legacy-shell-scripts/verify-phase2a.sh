#!/usr/bin/env bash
set -e

echo ""
echo "============================================================"
echo "   Phase 2A Verification (v6) — MakerKit + Supabase + Next"
echo "============================================================"

ROOT="/Users/eddie/baseframework/portal"
WEB="$ROOT/apps/web"

echo ""
echo "ROOT: $ROOT"
echo "WEB:  $WEB"
echo ""

# 1) ADMIN FOLDER
echo "1) Checking admin folder structure..."
[ -d "$WEB/app/admin" ] && echo "✔ Admin folder exists" || echo "✘ Missing admin folder"
[ -f "$WEB/app/admin/layout.tsx" ] && echo "✔ layout.tsx found" || echo "✘ layout.tsx missing"
[ -f "$WEB/app/admin/sidebar.tsx" ] && echo "✔ sidebar.tsx found" || echo "✘ sidebar.tsx missing"

echo ""

# 2) SUPABASE HELPERS
echo "2) Checking Supabase helpers..."
[ -f "$WEB/lib/supabase/server.ts" ] && echo "✔ server.ts found" || echo "✘ server.ts missing"
[ -f "$WEB/lib/supabase/client.ts" ] && echo "✔ client.ts found" || echo "✘ client.ts missing"

echo ""

# 3) PATH ALIASES
echo "3) Checking TypeScript alias '~/*' ..."
TSCONFIGS=$(find "$ROOT" -maxdepth 3 -name "tsconfig.json")
HAS_ALIAS=false

for FILE in $TSCONFIGS; do
  if grep -F '"~/*"' "$FILE" >/dev/null; then
    echo "✔ Alias '~/*' found in: $FILE"
    HAS_ALIAS=true
  else
    echo "- No alias in $FILE"
  fi
done

[ "$HAS_ALIAS" = false ] && echo "✘ Alias '~/*' missing in all tsconfig files"

echo ""

# 4) ADMIN LAYOUT LOGIC
echo "4) Validating admin layout..."
LAYOUT="$WEB/app/admin/layout.tsx"

grep -q "auth.getUser" "$LAYOUT" && echo "✔ Supabase user check OK" || echo "✘ Missing getUser check"
grep -q "user_has_permission" "$LAYOUT" && echo "✔ RPC OK" || echo "✘ Missing RPC"
grep -q "redirect" "$LAYOUT" && echo "✔ redirect OK" || echo "✘ Missing redirect"
grep -q "{ children }" "$LAYOUT" && echo "✔ children props OK" || echo "✘ children props not typed"

echo ""

# 5) ENV FILES
echo "5) Checking env files..."
ENV_WEB="$WEB/.env.local"
ENV_ROOT="$ROOT/.env.local"

[ -f "$ENV_WEB" ] && echo "✔ apps/web .env.local exists: $ENV_WEB" || echo "✘ apps/web .env.local missing"
[ -f "$ENV_ROOT" ] && echo "✔ root .env.local exists: $ENV_ROOT"

echo ""

# 6) DEP VERSIONS
echo "6) Checking Next & Tailwind versions..."
NEXT=$(grep '"next":' "$WEB/package.json" | sed 's/[^0-9.]*//g')
TAILWIND=$(grep '"tailwindcss":' "$WEB/package.json" | sed 's/[^0-9.]*//g')

echo "Next.js: $NEXT"
echo "Tailwind: $TAILWIND"

[[ "$NEXT" == 15* ]] && echo "✔ Next OK" || echo "✘ Next must be 15.x"
[[ "$TAILWIND" == 4* ]] && echo "✔ Tailwind OK" || echo "✘ Tailwind must be 4.x"

echo ""

# 7) LIGHTNINGCSS
echo "7) Checking LightningCSS arch..."
LCS=$(find "$ROOT/node_modules" -name "lightningcss.*.node" | head -n1)

if [ -z "$LCS" ]; then
  echo "✘ No LightningCSS native module"
else
  echo "Found: $LCS"
  file "$LCS" | grep -q "arm64" && echo "✔ ARM64 OK" || echo "✘ LightningCSS is x64"
fi

echo ""

# 8) RPC CHECK
echo "8) Checking RPC user_has_permission..."
grep -R "user_has_permission" "$ROOT" >/dev/null && echo "✔ RPC exists" || echo "✘ RPC not found"

echo ""
echo "============================================================"
echo "     Phase 2A Verification — v6 Complete"
echo "============================================================"
echo ""
