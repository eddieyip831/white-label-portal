#!/usr/bin/env bash
set -e

ROOT="$HOME/baseframework/portal"
ADMIN_SIDEBAR="$ROOT/apps/web/app/(app)/admin/sidebar.tsx"

echo "============================================================"
echo "       Fixing Admin Sidebar URL Paths (Precise Version)"
echo "============================================================"

if [ ! -f "$ADMIN_SIDEBAR" ]; then
  echo "❌ Admin sidebar not found at:"
  echo "   $ADMIN_SIDEBAR"
  exit 1
fi

echo "➡️  Patching: $ADMIN_SIDEBAR"

# Fix any "/(app)/admin" → "/admin"
sed -i '' 's|/(app)/admin|/admin|g' "$ADMIN_SIDEBAR"

# Fix any "(app)/admin" → "admin"
sed -i '' 's|(app)/admin|admin|g' "$ADMIN_SIDEBAR"

# Normalize to canonical relative paths if any weirdness exists
sed -i '' 's|"\/admin|"/admin|g' "$ADMIN_SIDEBAR"
sed -i '' "s|'\/admin|'/admin|g" "$ADMIN_SIDEBAR"

echo "✔ Done updating Admin sidebar."

echo
echo "============================================================"
echo " Now restart your dev server:"
echo "   pnpm dev"
echo " Then click Users in Admin menu"
echo "============================================================"
