#!/usr/bin/env bash

# ============================================================
# Portal Framework – Option B Repair Script (MakerKit Cleanup)
# ============================================================

# Safety checks
if [ -n "$ZSH_VERSION" ]; then
  echo "❌ ERROR: You are running this script with zsh."
  echo "Please run using:  bash fix-portal-structure.sh"
  exit 1
fi

if [ ! -d "apps/web/app" ]; then
  echo "❌ ERROR: Cannot find apps/web/app. Run this script from the project root."
  exit 1
fi

echo "➡ Ensuring Option B base folder structure..."

mkdir -p apps/web/app/auth
mkdir -p apps/web/app/admin
mkdir -p apps/web/app/public
mkdir -p apps/web/components
mkdir -p apps/web/lib
mkdir -p apps/web/modules

echo "➡ Removing stale MakerKit route-group folders..."

find apps/web/app -type d -name "(marketing)" -exec rm -rf {} +
find apps/web/app -type d -name "(landing)" -exec rm -rf {} +
find apps/web/app -type d -name "(dashboard-old)" -exec rm -rf {} +

# Remove empty _components folders under deleted groups
find apps/web/app -type d -name "_components" -empty -exec rm -rf {} +

echo "➡ Cleaning up MakerKit imports in error.tsx + global-error.tsx..."

FILES_TO_CLEAN=(
  "apps/web/app/error.tsx"
  "apps/web/app/global-error.tsx"
)

for file in "${FILES_TO_CLEAN[@]}"; do
  if [ -f "$file" ]; then
    # Remove imports referencing route groups
    sed -i '' -E 's|../*\([^)]*\)/_components[^"]*||g' "$file"
    sed -i '' -E 's|@/app/\([^)]*\)/_components[^"]*||g' "$file"
    sed -i '' -E 's/import [^;]*;//g' "$file"

    # Prepend a safe fallback import
    echo "import React from 'react';" | cat - "$file" > "$file.tmp" && mv "$file.tmp" "$file"
  fi
done

echo "➡ Creating FallbackError component..."

cat > apps/web/components/FallbackError.tsx << 'EOF'
"use client";

export default function FallbackError() {
  return (
    <div style={{ padding: 20 }}>
      <h1>Something went wrong.</h1>
      <p>This is a fallback error boundary for the portal framework.</p>
    </div>
  );
}
EOF

echo "➡ Generating clean error.tsx..."

cat > apps/web/app/error.tsx << 'EOF'
"use client";

import FallbackError from "@/components/FallbackError";

export default function Error({ error }: { error: Error }) {
  return <FallbackError />;
}
EOF

echo "➡ Generating clean global-error.tsx..."

cat > apps/web/app/global-error.tsx << 'EOF'
"use client";

import FallbackError from "@/components/FallbackError";

export default function GlobalError({ error }: { error: Error }) {
  return <FallbackError />;
}
EOF

echo "✅ Portal structure repaired using Option B."
echo "   MakerKit route-group conflicts removed."
echo "   Clean error boundaries generated."

