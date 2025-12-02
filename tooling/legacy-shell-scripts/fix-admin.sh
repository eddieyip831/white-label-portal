#!/usr/bin/env bash
set -e

echo "========================================================="
echo "   FIX ADMIN LAYOUT & SUPABASE SERVER CLIENT (MakerKit)"
echo "========================================================="

ROOT="/Users/eddie/baseframework/portal"
WEB="$ROOT/apps/web"

LAYOUT="$WEB/app/admin/layout.tsx"
SERVER_TS="$WEB/lib/supabase/server.ts"

echo ""
echo "➡️ Fixing server.ts (createServerClientWrapper)..."
cat > "$SERVER_TS" << 'EOF'
import { createServerClient } from "@kit/supabase/server-client";

export function createServerClientWrapper() {
  return createServerClient();
}
EOF

echo "✔ Updated: $SERVER_TS"

echo ""
echo "➡️ Fixing Admin Layout import + usage..."

# Remove ANY old incorrect imports
sed -i '' '/createServerClient/d' "$LAYOUT"
sed -i '' '/createSupabaseServerClient/d' "$LAYOUT"

# Insert correct import at top (after first import block)
awk '
  NR==1 { print; next }
  NR==2 { print "import { createServerClientWrapper } from \"~/lib/supabase/server\";"; next }
  { print }
' "$LAYOUT" > "$LAYOUT.tmp" && mv "$LAYOUT.tmp" "$LAYOUT"

# Replace ANY old usage patterns with correct function
sed -i '' 's/createServerClientWrapper()/createServerClientWrapper()/g' "$LAYOUT"
sed -i '' 's/createServerClient()/createServerClientWrapper()/g' "$LAYOUT"
sed -i '' 's/createSupabaseServerClient()/createServerClientWrapper()/g' "$LAYOUT"

echo "✔ Updated: $LAYOUT"

echo ""
echo "➡️ Cleaning Next.js cache..."
rm -rf "$WEB/.next"

echo "✔ Next.js cache cleaned"

echo ""
echo "========================================================="
echo "  All fixes applied. Starting pnpm dev..."
echo "========================================================="

cd "$ROOT"
pnpm dev &
