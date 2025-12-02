#!/usr/bin/env bash
set -e

ROOT="$HOME/baseframework/portal"
WEB="$ROOT/apps/web"
CONFIG_FILE="$ROOT/.supabase/config.toml"
TYPES_OUT="$ROOT/types/supabase.ts"

echo ""
echo "============================================================"
echo "     Phase 3 — Enterprise RBAC Bootstrap (MakerKit 2025)"
echo "============================================================"
echo ""

### 1. Ensure Supabase is linked
echo "➡️  Checking Supabase link..."

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "✘ No Supabase config.toml found at:"
  echo "  $CONFIG_FILE"
  echo ""
  echo "Run this first:"
  echo "  supabase link --project-ref <PROJECT_REF>"
  exit 1
fi

### 1. Extract Supabase project ref (SUPABASE 2024/2025 format compatible)
echo "➡️  Extracting Supabase project ref..."

# Try pattern 1: project_ref = "xxxxxx"
PROJECT_REF=$(grep -oE 'project_ref[[:space:]]*=[[:space:]]*"[a-z0-9]+"' "$CONFIG_FILE" \
  | sed 's/.*="//; s/"//')

# Try pattern 2: api.url = "https://xxxx.supabase.co"
if [[ -z "$PROJECT_REF" ]]; then
  PROJECT_REF=$(grep -oE 'https://([a-z0-9]+)\.supabase\.co' "$CONFIG_FILE" \
    | sed 's#https://##; s/.supabase.co//')
fi

# Validate
if [[ -z "$PROJECT_REF" || ${#PROJECT_REF} -ne 20 ]]; then
  echo "✘ Could not extract a valid Supabase project ref."
  echo "  Extracted: '$PROJECT_REF'"
  echo ""
  echo "Please manually enter your project ref (20 characters):"
  read -r PROJECT_REF
fi

if [[ ${#PROJECT_REF} -ne 20 ]]; then
  echo "✘ Invalid project ref length: '$PROJECT_REF'"
  exit 1
fi

echo "✔ Supabase linked: project_ref=$PROJECT_REF"
echo ""

### 2. Generate fresh Supabase types
echo "➡️  Generating Supabase types..."

supabase gen types typescript \
  --project-id "$PROJECT_REF" \
  --schema public \
  > "$TYPES_OUT"

echo "✔ Supabase types written to $TYPES_OUT"
echo ""

### 3. Ensure RBAC admin folders exist
echo "➡️  Ensuring admin RBAC folder structure..."

mkdir -p "$WEB/app/(app)/admin/roles"
mkdir -p "$WEB/app/(app)/admin/permissions"
mkdir -p "$WEB/app/(app)/admin/attributes"
mkdir -p "$WEB/app/(app)/admin/modules"

echo "✔ RBAC folders ready"
echo ""

### 4. Generate CRUD pages
echo "➡️  Creating RBAC CRUD pages..."

cat > "$WEB/app/(app)/admin/roles/page.tsx" << 'EOF'
import RolesList from "~/components/admin/roles/roles-list";
export default function RolesPage() {
  return <RolesList />;
}
EOF

cat > "$WEB/app/(app)/admin/permissions/page.tsx" << 'EOF'
import PermissionsList from "~/components/admin/permissions/permissions-list";
export default function PermissionsPage() {
  return <PermissionsList />;
}
EOF

cat > "$WEB/app/(app)/admin/attributes/page.tsx" << 'EOF'
import AttributesList from "~/components/admin/attributes/attributes-list";
export default function AttributesPage() {
  return <AttributesList />;
}
EOF

cat > "$WEB/app/(app)/admin/modules/page.tsx" << 'EOF'
import ModulesList from "~/components/admin/modules/modules-list";
export default function ModulesPage() {
  return <ModulesList />;
}
EOF

echo "✔ CRUD pages generated"
echo ""

### 5. Create server admin API stubs
echo "➡️  Creating server admin API handlers..."

mkdir -p "$WEB/app/api/admin/roles"
mkdir -p "$WEB/app/api/admin/permissions"
mkdir -p "$WEB/app/api/admin/attributes"
mkdir -p "$WEB/app/api/admin/modules"

for section in roles permissions attributes modules; do
  cat > "$WEB/app/api/admin/$section/route.ts" << 'EOF'
import { NextResponse } from "next/server";

export async function GET() {
  return NextResponse.json({ ok: true });
}

export async function POST() {
  return NextResponse.json({ ok: true });
}
EOF
done

echo "✔ API handlers created"
echo ""

### 6. Validate Service Role Key availability
echo "➡️  Checking SUPABASE_SERVICE_ROLE_KEY..."

if [[ -z "$SUPABASE_SERVICE_ROLE_KEY" ]]; then
  echo "⚠ WARNING: SUPABASE_SERVICE_ROLE_KEY is NOT set in current environment."
  echo "  Admin functions (roles/users/permissions) may fail until configured."
else
  echo "✔ Service role key detected"
fi

echo ""

### 7. Clear Next.js / Turbopack caches
echo "➡️  Clearing Next.js caches..."

find "$WEB/.next" -maxdepth 4 -type d -exec rm -rf {} + 2>/dev/null || true
rm -rf "$WEB/.turbo" 2>/dev/null || true

echo "✔ Caches cleared"
echo ""

echo "============================================================"
echo "         Phase 3 RBAC Bootstrap Complete"
echo "============================================================"
echo ""
echo "Start your dev server:"
echo "    pnpm dev"
echo ""
echo "Then visit:"
echo "    http://localhost:3000/admin/roles"
echo "    http://localhost:3000/admin/permissions"
echo "    http://localhost:3000/admin/attributes"
echo "    http://localhost:3000/admin/modules"
echo ""
echo "============================================================"
