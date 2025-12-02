#!/usr/bin/env bash
set -e

echo
echo "============================================================"
echo "   Route Group Import Autofix — Next.js 15 / MakerKit"
echo "============================================================"
echo

APP_DIR="apps/web/app"

echo "➡ Scanning for invalid imports ~/(group)/..."
FILES=$(grep -RIl "~/(.*)/" "$APP_DIR" || true)

if [ -z "$FILES" ]; then
  echo "✔ No invalid tilde route-group imports detected."
  exit 0
fi

echo "Found:"
echo "$FILES"
echo

for f in $FILES; do
  echo "➡ Fixing $f"
  # Replace "~/(group)/..." → "~/app/(group)/..."
  sed -E -i '' 's#~\/\(([^)]+)\)\/#~\/app\/(\1)\/#g' "$f"
done

echo
echo "➡ Clearing Next.js/Turbopack caches..."
rm -rf apps/web/.next || true
rm -rf node_modules/.cache || true

echo
echo "============================================================"
echo "   Import Rewrite Complete — Now run: pnpm dev"
echo "============================================================"
