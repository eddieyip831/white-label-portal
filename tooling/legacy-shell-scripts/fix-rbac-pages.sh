#!/usr/bin/env bash

set -e

ROOT="apps/web/app/(app)/admin"

echo "=============================================================="
echo "   Fixing RBAC Pages — Converting to Server-Only Pattern"
echo "=============================================================="

fix_page() {
  PAGE_DIR="$ROOT/$1"
  PAGE_FILE="$PAGE_DIR/page.tsx"

  if [ ! -f "$PAGE_FILE" ]; then
    echo "⚠ $PAGE_FILE missing, skipping"
    return
  fi

  echo "➡ Fixing $PAGE_FILE"

  cat > "$PAGE_FILE" << 'EOF'
import { list } from "~/lib/rbac/__RBAC__"; // placeholder to be replaced by script

export default async function Page() {
  const data = await list();

  return (
    <div className="p-6">
      <pre>{JSON.stringify(data, null, 2)}</pre>
    </div>
  );
}
EOF
}

# Fix pages
fix_page "roles"
fix_page "permissions"
fix_page "attributes"
fix_page "modules"
fix_page "users"

echo "=============================================================="
echo "  DONE — Now fix each RBAC loader individually"
echo "=============================================================="
