#!/usr/bin/env bash

set -e

echo "============================================================"
echo "       NUCLEAR ROUTE CLEANER — Remove Ghost /admin"
echo "============================================================"

ROOT="$(pwd)"
NEXT_DIR="$ROOT/apps/web/.next/server/app"

echo "➡ Scanning routing cache at: $NEXT_DIR"
echo

if [ -d "$NEXT_DIR/admin" ]; then
  echo "❌ Ghost route detected: $NEXT_DIR/admin"
  echo "➡ Removing ghost admin folder..."
  rm -rf "$NEXT_DIR/admin"
  echo "✔ Removed"
else
  echo "✔ No ghost admin folder found"
fi

echo
echo "➡ Cleaning all Next.js + Turbopack caches…"
rm -rf "$ROOT/apps/web/.next"
rm -rf "$ROOT/apps/web/node_modules/.cache"
rm -rf "$ROOT/apps/web/.turbo"
rm -rf "$ROOT/.turbo"

echo "✔ Cache clean complete"
echo

echo "➡ Verifying no other ghost routes exist…"
ls "$ROOT/apps/web/app" | grep admin || echo "✔ No /admin folder in app/"

echo
echo "============================================================"
echo "       CLEANUP COMPLETE — Now run: pnpm dev"
echo "============================================================"
