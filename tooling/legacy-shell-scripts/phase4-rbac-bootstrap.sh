#!/usr/bin/env bash
set -e

echo "============================================================"
echo "   Phase 4 — COMPLETE RBAC Bootstrap Patch (MakerKit 2025)"
echo "============================================================"
ROOT="$(pwd)"
WEB="$ROOT/apps/web"
APP="$WEB/app"
ADMIN="$APP/(app)/admin"

echo
echo "➡ 1) Cleaning invalid admin folders..."
if [ -d "$APP/admin" ]; then
  echo "⚠ Removing legacy: $APP/admin"
  rm -rf "$APP/admin"
fi
if [ -d "$WEB/.next/server/app/admin" ]; then
  echo "⚠ Removing stale Next.js build: .next/server/app/admin"
  rm -rf "$WEB/.next/server/app/admin"
fi
echo "✔ Admin folder cleanup done"

echo
echo "➡ 2) Ensuring correct admin folder structure..."
mkdir -p "$ADMIN/users/[id]"
mkdir -p "$ADMIN/roles"
mkdir -p "$ADMIN/permissions"
mkdir -p "$ADMIN/attributes"
mkdir -p "$ADMIN/modules"
mkdir -p "$APP/api/admin"
echo "✔ Folder ensured"

echo
echo "➡ 3) Installing corrected RBAC server utilities..."
mkdir -p "$WEB/lib/rbac"

cat > "$WEB/lib/rbac/permissions.ts" <<'EOF'
// SAFE SERVER RBAC — permissions.ts
import "server-only";
import { getSupabaseServerAdminClient } from "@kit/supabase/server-admin-client";

export async function listPermissions() {
  const admin = getSupabaseServerAdminClient();
  const { data, error } = await admin
    .from("permissions")
    .select("*")
    .order("name");

  if (error) throw error;
  return data ?? [];
}
EOF

cat > "$WEB/lib/rbac/roles.ts" <<'EOF'
// SAFE SERVER RBAC — roles.ts
import "server-only";
import { getSupabaseServerAdminClient } from "@kit/supabase/server-admin-client";

export async function listRoles() {
  const admin = getSupabaseServerAdminClient();
  const { data, error } = await admin.from("roles").select("*").order("name");
  if (error) throw error;
  return data ?? [];
}
EOF

cat > "$WEB/lib/rbac/attributes.ts" <<'EOF'
// SAFE SERVER RBAC — attributes.ts
import "server-only";
import { getSupabaseServerAdminClient } from "@kit/supabase/server-admin-client";

export async function listAttributes() {
  const admin = getSupabaseServerAdminClient();
  const { data, error } = await admin
    .from("user_attribute_definitions")
    .select("*")
    .order("key");

  if (error) throw error;
  return data ?? [];
}
EOF

echo "✔ RBAC server utilities patched"

echo
echo "➡ 4) Installing updated server admin user list..."
mkdir -p "$WEB/lib/admin"
cat > "$WEB/lib/admin/users.ts" <<'EOF'
// SAFE ADMIN USERS — users.ts
import "server-only";
import { getSupabaseServerAdminClient } from "@kit/supabase/server-admin-client";

export async function listAdminUsers() {
  const admin = getSupabaseServerAdminClient();
  const { data, error } = await admin.auth.admin.listUsers({ page: 1, perPage: 50 });
  if (error) throw error;

  return (data?.users ?? []).map(u => ({
    id: u.id,
    email: u.email ?? null,
    created_at: u.created_at
  }));
}
EOF
echo "✔ Admin users API patched"

echo
echo "➡ 5) Installing corrected Admin UI components..."
mkdir -p "$WEB/components/admin"

# ROLES UI
mkdir -p "$WEB/components/admin/roles"
cat > "$WEB/components/admin/roles/roles-list.tsx" <<'EOF'
"use client";

import React from "react";
import { DataTable } from "@kit/ui/data-table";
import { listRoles } from "~/lib/rbac/roles";

export default async function RolesList() {
  const roles = await listRoles();
  return (
    <DataTable
      columns={[{ accessorKey: "name", header: "Role" }]}
      data={roles}
    />
  );
}
EOF

# PERMISSIONS UI
mkdir -p "$WEB/components/admin/permissions"
cat > "$WEB/components/admin/permissions/permissions-list.tsx" <<'EOF'
"use client";

import { DataTable } from "@kit/ui/data-table";
import { listPermissions } from "~/lib/rbac/permissions";

export default async function PermissionsList() {
  const permissions = await listPermissions();
  return (
    <DataTable
      columns={[
        { accessorKey: "name", header: "Permission" },
        { accessorKey: "module", header: "Module" }
      ]}
      data={permissions}
    />
  );
}
EOF

# ATTRIBUTES UI
mkdir -p "$WEB/components/admin/attributes"
cat > "$WEB/components/admin/attributes/attributes-list.tsx" <<'EOF'
"use client";

import { DataTable } from "@kit/ui/data-table";
import { listAttributes } from "~/lib/rbac/attributes";

export default async function AttributesList() {
  const attributes = await listAttributes();
  return (
    <DataTable
      columns={[
        { accessorKey: "key", header: "Key" },
        { accessorKey: "label", header: "Label" },
        { accessorKey: "data_type", header: "Type" }
      ]}
      data={attributes}
    />
  );
}
EOF

echo "✔ Admin UI components installed"

echo
echo "➡ 6) Rewriting all admin page.tsx files..."
cat > "$ADMIN/roles/page.tsx" <<'EOF'
import RolesList from "~/components/admin/roles/roles-list";
export default function Page() { return <RolesList />; }
EOF

cat > "$ADMIN/permissions/page.tsx" <<'EOF'
import PermissionsList from "~/components/admin/permissions/permissions-list";
export default function Page() { return <PermissionsList />; }
EOF

cat > "$ADMIN/attributes/page.tsx" <<'EOF'
import AttributesList from "~/components/admin/attributes/attributes-list";
export default function Page() { return <AttributesList />; }
EOF

cat > "$ADMIN/modules/page.tsx" <<'EOF'
export default function Page() { return <>Modules coming soon…</>; }
EOF

echo "✔ Admin page.tsx regenerated"

echo
echo "➡ 7) Regenerating Supabase types..."
supabase gen types typescript --linked > "$WEB/types/supabase.ts" || true
echo "✔ types regenerated (or skipped if CLI not available)"

echo
echo "➡ 8) Cleaning Next.js build cache..."
rm -rf "$WEB/.next"
echo "✔ Cache removed"

echo
echo "➡ 9) Final route scan..."
find "$APP" -maxdepth 3 -type d -name "admin" -print

echo
echo "============================================================"
echo "   Phase 4 RBAC Bootstrap Patch Installed Successfully"
echo "============================================================"
echo "Run:  pnpm dev"
echo "Then visit:  http://localhost:3000/admin"
echo "============================================================"
