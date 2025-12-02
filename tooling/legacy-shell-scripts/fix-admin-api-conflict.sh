#!/usr/bin/env bash

set -e

ROOT="apps/web/app"

echo "============================================================"
echo "  Fixing Admin Route Conflict — Next.js (2025)"
echo "============================================================"

if [ -d "$ROOT/api/admin" ]; then
  echo "➡ Renaming api/admin → api/admin-api"
  mv "$ROOT/api/admin" "$ROOT/api/admin-api"
  echo "✔ Done"
else
  echo "✔ No api/admin folder found (good)"
fi

echo
echo "➡ Cleaning .next and restarting..."
rm -rf apps/web/.next .turbo

echo "============================================================"
echo "  FIX COMPLETE — Now run: pnpm dev"
echo "============================================================"
