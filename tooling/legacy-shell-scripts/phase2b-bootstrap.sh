#!/usr/bin/env bash
set -e

ROOT="$(pwd)"
WEB="${ROOT}/apps/web"
ADMIN="${WEB}/app/(app)/admin"

echo "============================================================"
echo "        Phase 2B – Admin Console Bootstrap (2025)"
echo "============================================================"
echo

# -------------------------------------------------------------
# 1. Check Supabase link
# -------------------------------------------------------------
echo "1) Checking Supabase link..."

if [ -f "${ROOT}/.supabase/config.toml" ]; then
  echo "✔ Supabase project is linked."
else
  echo "✘ Supabase NOT linked."
  echo "Run:"
  echo "   supabase link --project-ref <PROJECT_REF>"
  exit 1
fi

# -------------------------------------------------------------
# 2. Fetch latest DB types
# -------------------------------------------------------------
echo
echo "2) Generating up-to-date Supabase types..."

mkdir -p "${ROOT}/types"

supabase gen types typescript \
  --linked \
  --schema public \
  > "${ROOT}/types/supabase.ts"

echo "✔ Supabase types written to types/supabase.ts"

# -------------------------------------------------------------
# 3. Ensure admin folder exists
# -------------------------------------------------------------
echo
echo "3) Ensuring admin folder structure..."

mkdir -p "${ADMIN}"
mkdir -p "${ADMIN}/users/[id]"
mkdir -p "${ADMIN}/roles"
mkdir -p "${ADMIN}/permissions"
mkdir -p "${ADMIN}/attributes"
mkdir -p "${ADMIN}/modules"

echo "✔ Admin folders ready"

# -------------------------------------------------------------
# 4. Create Admin Layout if missing
# -------------------------------------------------------------
echo
echo "4) Injecting admin layout..."

ADMIN_LAYOUT="${ADMIN}/layout.tsx"

cat > "$ADMIN_LAYOUT" << 'EOF'
import { redirect } from "next/navigation";
import Sidebar from "./sidebar";
import { createServerClientWrapper } from "~/lib/supabase/server";

export default async function AdminLayout({ children }: { children: React.ReactNode }) {
  const supabase = createServerClientWrapper();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    redirect("/auth/sign-in");
  }

  const { data: allowed } = await supabase.rpc("user_has_permission", {
    user_id: user.id,
    permission_name: "rbac.manage",
  });

  if (!allowed) {
    redirect("/");
  }

  return (
    <div className="flex min-h-screen">
      <Sidebar />
      <main className="flex-1 p-6">{children}</main>
    </div>
  );
}
EOF

echo "✔ Admin layout created / updated"

# -------------------------------------------------------------
# 5. Generate sidebar
# -------------------------------------------------------------
echo
echo "5) Creating sidebar..."

cat > "${ADMIN}/sidebar.tsx" << 'EOF'
import Link from "next/link";

const links = [
  { href: "/(app)/admin/users", label: "Users" },
  { href: "/(app)/admin/roles", label: "Roles" },
  { href: "/(app)/admin/permissions", label: "Permissions" },
  { href: "/(app)/admin/attributes", label: "Attributes" },
  { href: "/(app)/admin/modules", label: "Modules" },
];

export default function Sidebar() {
  return (
    <aside className="w-64 border-r p-4 space-y-2">
      {links.map((link) => (
        <Link
          key={link.href}
          href={link.href}
          className="block px-3 py-2 rounded hover:bg-gray-100"
        >
          {link.label}
        </Link>
      ))}
    </aside>
  );
}
EOF

echo "✔ Sidebar created"

# -------------------------------------------------------------
# 6. Create CRUD pages
# -------------------------------------------------------------
echo
echo "6) Creating CRUD pages..."

# USERS
cat > "${ADMIN}/users/page.tsx" << 'EOF'
import UsersList from "~/components/admin/users/users-list";

export default function UsersPage() {
  return <UsersList />;
}
EOF

# USER DETAILS
cat > "${ADMIN}/users/[id]/page.tsx" << 'EOF'
import UserDetail from "~/components/admin/users/user-detail";

export default function UserDetailPage({ params }: { params: { id: string }}) {
  return <UserDetail userId={params.id} />;
}
EOF

# ROLES
cat > "${ADMIN}/roles/page.tsx" << 'EOF'
import RolesList from "~/components/admin/roles/roles-list";

export default function RolesPage() {
  return <RolesList />;
}
EOF

# PERMISSIONS
cat > "${ADMIN}/permissions/page.tsx" << 'EOF'
import PermissionsList from "~/components/admin/permissions/permissions-list";

export default function PermissionsPage() {
  return <PermissionsList />;
}
EOF

# ATTRIBUTES
cat > "${ADMIN}/attributes/page.tsx" << 'EOF'
import AttributesList from "~/components/admin/attributes/attributes-list";

export default function AttributesPage() {
  return <AttributesList />;
}
EOF

# MODULES
cat > "${ADMIN}/modules/page.tsx" << 'EOF'
import ModulesList from "~/components/admin/modules/modules-list";

export default function ModulesPage() {
  return <ModulesList />;
}
EOF

echo "✔ CRUD pages generated"

# -------------------------------------------------------------
# 7. Inject API handlers (server actions / Next APIs)
# -------------------------------------------------------------
echo
echo "7) Creating server API handlers..."

API_DIR="${WEB}/app/api/admin"

mkdir -p "${API_DIR}/users"
mkdir -p "${API_DIR}/roles"
mkdir -p "${API_DIR}/permissions"
mkdir -p "${API_DIR}/attributes"
mkdir -p "${API_DIR}/modules"

cat > "${API_DIR}/users/route.ts" << 'EOF'
import { createServerClientWrapper } from "~/lib/supabase/server";

export async function GET() {
  const supabase = createServerClientWrapper();
  const { data } = await supabase.from("users").select("*");
  return Response.json(data);
}
EOF

echo "✔ Basic API handlers created"

# -------------------------------------------------------------
# 8. Clear build caches
# -------------------------------------------------------------
echo
echo "8) Clearing caches..."

rm -rf "${WEB}/.next"
rm -rf "${ROOT}/node_modules/.cache"

echo "✔ Caches cleared"

# -------------------------------------------------------------
# 9. Final instructions
# -------------------------------------------------------------
echo
echo "============================================================"
echo "  Phase 2B Bootstrap Complete"
echo "============================================================"
echo "Run your local development server:"
echo
echo "    pnpm dev"
echo
echo "Then visit:"
echo "    http://localhost:3000/(app)/admin"
echo
echo "============================================================"
