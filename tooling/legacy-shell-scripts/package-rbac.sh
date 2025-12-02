#!/usr/bin/env bash

set -e

echo "============================================================"
echo "      Packaging RBAC Files for Upload to ChatGPT"
echo "============================================================"

ROOT="$(pwd)"
ZIP_NAME="rbac-upload-$(date +%Y%m%d-%H%M%S).zip"

TARGET_FILES=(
  "apps/web/lib/rbac"
  "apps/web/lib/admin/users.ts"
  "apps/web/app/(app)/admin/layout.tsx"
  "apps/web/app/(app)/admin/sidebar.tsx"
  "apps/web/app/(app)/admin/roles"
  "apps/web/app/(app)/admin/permissions"
  "apps/web/app/(app)/admin/attributes"
  "apps/web/app/(app)/admin/users"
)

echo "➡️  Checking folders/files..."

MISSING=0
INCLUDE=()

for path in "${TARGET_FILES[@]}"; do
  if [ -e "$ROOT/$path" ]; then
    echo "  ✔ Found: $path"
    INCLUDE+=("$path")
  else
    echo "  ✘ Missing: $path"
    MISSING=1
  fi
done

echo
echo "➡️  Creating ZIP archive..."

ZIP_PATH="$ROOT/$ZIP_NAME"

# Create zip
cd "$ROOT"
zip -r "$ZIP_PATH" "${INCLUDE[@]}" >/dev/null

echo
echo "============================================================"
echo "      RBAC ZIP FILE READY FOR UPLOAD"
echo "============================================================"
echo "📦 File saved at:"
echo "   $ZIP_PATH"
echo
echo "You can now upload this ZIP file to ChatGPT."
echo "============================================================"

exit 0
