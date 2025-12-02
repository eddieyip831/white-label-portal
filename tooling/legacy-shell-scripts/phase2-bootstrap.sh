#!/usr/bin/env bash

# ====================================================================
# Phase 2 - Admin Console + RBAC UI + User Management
# Bash-only version (safe for zsh users)
# ====================================================================

# Detect and block zsh or sh
if [ -n "$ZSH_VERSION" ]; then
  echo "ERROR: This script must be run with bash, not zsh."
  echo "Run:  bash phase2-bootstrap.sh"
  exit 1
fi

if [ -n "$SH_VERSION" ]; then
  echo "ERROR: This script must be run with bash, not sh."
  echo "Run:  bash phase2-bootstrap.sh"
  exit 1
fi

ROOT_DIR="$HOME/baseframework/portal"
WEB_DIR="$ROOT_DIR/apps/web/app"
API_DIR="$ROOT_DIR/apps/web/app/api"
ADMIN_DIR="$WEB_DIR/admin"

echo "==============================="
echo " Phase 2: Admin Console Setup "
echo "==============================="

# -------------------------------
# Validate project structure
# -------------------------------

if [ ! -d "$ROOT_DIR" ]; then
  echo "ERROR: Missing project at $ROOT_DIR"
  exit 1
fi

if [ ! -d "$ROOT_DIR/apps/web" ]; then
  echo "ERROR: MakerKit Lite missing or corrupted (apps/web not found)"
  exit 1
fi

# -------------------------------
# Supabase Linking Check
# -------------------------------

if [ ! -f "$ROOT_DIR/.supabase/config.toml" ]; then
  echo "Supabase is not linked."
  echo "Run this first (replace PROJECT_REF):"
  echo "supabase link --project-ref PROJECT_REF"
  exit 1
fi

echo "Supabase is linked."

# -------------------------------
# Generate TypeScript Types
# -------------------------------

mkdir -p "$ROOT_DIR/types"

echo "Generating Supabase types..."
supabase gen types typescript \
  --linked \
  --schema public \
  --schema auth \
  --schema storage \
  > "$ROOT_DIR/types/supabase.ts"

echo "Types generated at types/supabase.ts"

# -------------------------------
# Create Admin Directory Structure
# -------------------------------

echo "Creating admin route structure..."
mkdir -p "$ADMIN_DIR"
mkdir -p "$ADMIN_DIR/users/[id]"
mkdir -p "$ADMIN_DIR/roles"
mkdir -p "$ADMIN_DIR/permissions"
mkdir -p "$ADMIN_DIR/attributes"
mkdir -p "$ADMIN_DIR/modules"

# -------------------------------
# Admin Layout
# -------------------------------

cat << 'EOF' > "$ADMIN_DIR/layout.tsx"
import { redirect } from "next/navigation";
import Sidebar from "./sidebar";
import { createServerClient } from "@/lib/supabase/server";

export default async function AdminLayout({ children }) {
  const supabase = createServerClient();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) redirect("/login");

  const { data: allowed } = await supabase.rpc("user_has_permission", {
    user_id: user.id,
    permission_name: "rbac.manage"
  });

  if (!allowed) redirect("/");

  return (
    <div className="flex min-h-screen">
      <Sidebar />
      <main className="flex-1 p-6">{children}</main>
    </div>
  );
}
EOF

# -------------------------------
# Sidebar
# -------------------------------

cat << 'EOF' > "$ADMIN_DIR/sidebar.tsx"
import Link from "next/link";

export default function Sidebar() {
  return (
    <aside className="w-64 p-4 border-r bg-gray-100">
      <h2 className="font-bold mb-4 text-lg">Admin Console</h2>
      <nav className="flex flex-col gap-2">
        <Link href="/admin/users">Users</Link>
        <Link href="/admin/roles">Roles</Link>
        <Link href="/admin/permissions">Permissions</Link>
        <Link href="/admin/attributes">Attributes</Link>
        <Link href="/admin/modules">Modules</Link>
      </nav>
    </aside>
  );
}
EOF

# -------------------------------
# Users List Page
# -------------------------------

cat << 'EOF' > "$ADMIN_DIR/users/page.tsx"
import { createServerClient } from "@/lib/supabase/server";
import Link from "next/link";

export default async function UsersPage() {
  const supabase = createServerClient();
  const { data: users } = await supabase.from("auth.users").select("*");

  return (
    <div>
      <h1 className="text-2xl font-bold mb-4">Users</h1>
      <table className="w-full text-sm border">
        <thead>
          <tr className="border-b">
            <th>Email</th>
            <th>Roles</th>
          </tr>
        </thead>
        <tbody>
          {users?.map((u) => (
            <tr key={u.id} className="border-b">
              <td>{u.email}</td>
              <td>
                <Link href={`/admin/users/${u.id}`}>Manage</Link>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
EOF

# -------------------------------
# User Detail + Assign Roles
# -------------------------------

cat << 'EOF' > "$ADMIN_DIR/users/[id]/page.tsx"
import { createServerClient } from "@/lib/supabase/server";
import AssignRoles from "./assign-roles";

export default async function UserDetail({ params }) {
  const supabase = createServerClient();
  const { id } = params;

  const { data: user } = await supabase
    .from("auth.users")
    .select("*")
    .eq("id", id)
    .single();

  const { data: roles } = await supabase.from("roles").select("*");

  const { data: userRoles } = await supabase
    .from("user_roles")
    .select("role_id")
    .eq("user_id", id);

  const assigned = userRoles?.map((ur) => ur.role_id) ?? [];

  return (
    <div>
      <h1 className="text-xl mb-4 font-bold">{user.email}</h1>
      <AssignRoles userId={id} roles={roles} assigned={assigned} />
    </div>
  );
}
EOF

cat << 'EOF' > "$ADMIN_DIR/users/[id]/assign-roles.tsx"
"use client";
import { useState } from "react";

export default function AssignRoles({ userId, roles, assigned }) {
  const [selected, setSelected] = useState(new Set(assigned));

  const toggle = (roleId) => {
    const next = new Set(selected);
    next.has(roleId) ? next.delete(roleId) : next.add(roleId);
    setSelected(next);
  };

  const save = async () => {
    await fetch("/api/admin/assign-roles", {
      method: "POST",
      body: JSON.stringify({
        userId,
        roleIds: [...selected]
      })
    });
    alert("Updated");
  };

  return (
    <div>
      <h2 className="font-semibold mb-2">Assign Roles</h2>
      {roles.map((role) => (
        <label key={role.id} className="flex gap-2 items-center">
          <input
            type="checkbox"
            checked={selected.has(role.id)}
            onChange={() => toggle(role.id)}
          />
          {role.name}
        </label>
      ))}
      <button className="px-4 py-2 bg-black text-white mt-4" onClick={save}>
        Save
      </button>
    </div>
  );
}
EOF

# -------------------------------
# API Route
# -------------------------------

mkdir -p "$API_DIR/admin/assign-roles"

cat << 'EOF' > "$API_DIR/admin/assign-roles/route.ts"
import { createRouteHandler } from "@/lib/supabase/server";

export async function POST(req: Request) {
  const supabase = createRouteHandler();
  const { userId, roleIds } = await req.json();

  await supabase.from("user_roles").delete().eq("user_id", userId);

  for (const roleId of roleIds) {
    await supabase.from("user_roles").insert({ user_id: userId, role_id: roleId });
  }

  return new Response("OK");
}
EOF

echo "==============================="
echo " Admin Console generated."
echo " Visit: http://localhost:3000/admin"
echo "==============================="
