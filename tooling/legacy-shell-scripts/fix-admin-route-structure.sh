#!/bin/bash
set -e

echo "============================================================"
echo "   Fixing MakerKit Admin Route Structure (Next.js 15.x)"
echo "============================================================"

APP_ROOT="apps/web/app"
BAD_ADMIN="$APP_ROOT/(app)/admin"
GOOD_ADMIN="$APP_ROOT/admin"

echo ""
echo "➡️  Checking if broken admin folder exists..."
if [ ! -d "$BAD_ADMIN" ]; then
  echo "✔ No incorrect folder found. Nothing to fix."
  exit 0
fi

echo "✔ Incorrect folder found at: $BAD_ADMIN"

echo ""
echo "➡️  Creating correct folder (if missing): $GOOD_ADMIN"
mkdir -p "$GOOD_ADMIN"

echo ""
echo "➡️  Moving admin files to correct location..."
rsync -av --remove-source-files "$BAD_ADMIN/" "$GOOD_ADMIN/"

echo ""
echo "➡️  Cleaning up leftover (app)/admin folder..."
rmdir "$BAD_ADMIN" || true

echo "➡️  Checking if (app) is now empty..."
if [ -d "$APP_ROOT/(app)" ]; then
  REMAINING=$(ls -A "$APP_ROOT/(app)" | wc -l | tr -d ' ')
  if [ "$REMAINING" = "0" ]; then
    echo "✔ (app) is empty — removing"
    rmdir "$APP_ROOT/(app)"
  else
    echo "⚠ (app) still contains:"
    ls "$APP_ROOT/(app)"
  fi
fi

echo ""
echo "➡️  Fixing imports inside moved admin files..."
grep -Rl "\(app\)/admin" "$GOOD_ADMIN" | while read file; do
  sed -i '' 's#(app)/admin#admin#g' "$file"
done

echo "✔ Import paths cleaned."

echo ""
echo "➡️  Final cleanup of Next.js caches..."
rm -rf "$APP_ROOT/.next" || true
rm -rf ".turbo" || true

echo ""
echo "============================================================"
echo "         Admin Route Structure Fix Complete!"
echo "============================================================"
echo "Next: restart your dev server:"
echo ""
echo "   pnpm dev"
echo ""
echo "Then visit:"
echo "   http://localhost:3000/admin"
echo "============================================================"
