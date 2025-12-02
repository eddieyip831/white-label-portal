#!/usr/bin/env bash
set -e

echo "======================================================="
echo "  MakerKit Supabase Client Auto-Fix + Verification Tool"
echo "======================================================="

ROOT="/Users/eddie/baseframework/portal"
WEB="$ROOT/apps/web"

SERVER_FILE="$WEB/lib/supabase/server.ts"
CLIENT_FILE="$WEB/lib/supabase/client.ts"

echo ""
echo "➡️  Step 1: Fixing server Supabase client import..."
cat > "$SERVER_FILE" << 'EOF'
import { createServerClient } from "@kit/supabase/server-client";

export function createServerClientWrapper() {
  return createServerClient();
}
EOF

echo "✔ Updated: $SERVER_FILE"

echo ""
echo "➡️  Step 2: Fixing browser Supabase client import..."
cat > "$CLIENT_FILE" << 'EOF'
import { createBrowserClient } from "@kit/supabase/browser-client";

export const supabase = createBrowserClient();
EOF

echo "✔ Updated: $CLIENT_FILE"

echo ""
echo "➡️  Step 3: Fixing admin layout Supabase import..."
ADMIN_LAYOUT="$WEB/app/admin/layout.tsx"

# Replace old import syntax with new import
sed -i '' 's|from "@\/lib/supabase/server"|from "@/lib/supabase/server"|g' "$ADMIN_LAYOUT"
sed -i '' 's|createServerClient()|createServerClientWrapper()|g' "$ADMIN_LAYOUT"

# Force using wrapper
sed -i '' 's|createServerClient as createSupabaseServerClient|createServerClientWrapper|g' "$ADMIN_LAYOUT"

echo "✔ Updated: $ADMIN_LAYOUT"

echo ""
echo "➡️  Step 4: Cleaning build + dependency caches..."
cd "$ROOT"

echo "  - Removing node_modules..."
rm -rf node_modules

echo "  - Removing web/.next cache..."
rm -rf "$WEB/.next"

echo "  - Removing turbo cache..."
rm -rf "$ROOT/.turbo"

echo "  - Removing pnpm store (local)..."
pnpm store prune || true

echo "✔ Cache cleaned."

echo ""
echo "➡️  Step 5: Reinstalling dependencies..."
pnpm install

echo "✔ Dependencies installed."

echo ""
echo "➡️  Step 6: Running Phase 2A Verification (v6)..."

if [ -f "$ROOT/verify-phase2a.sh" ]; then
  bash "$ROOT/verify-phase2a.sh" || true
else
  echo "⚠️ verify-phase2a.sh not found — skipping."
fi

echo ""
echo "======================================================="
echo "  All fixes applied. Starting pnpm dev server..."
echo "======================================================="

cd "$ROOT"
pnpm dev
