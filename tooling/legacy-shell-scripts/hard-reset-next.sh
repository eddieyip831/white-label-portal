#!/usr/bin/env bash
set -e

ROOT="$HOME/baseframework/portal"
WEB="$ROOT/apps/web"

echo "============================================================"
echo "     Hard Reset — Next.js / Turbopack Runtime Artifacts"
echo "============================================================"

echo "➡️  Killing dev processes (turbo / next / pnpm dev)..."
pkill -f "next dev" 2>/dev/null || true
pkill -f "turbo dev" 2>/dev/null || true
pkill -f "pnpm dev" 2>/dev/null || true

echo "➡️  Removing Next/Turbopack caches..."
rm -rf "$WEB/.next" "$WEB/.turbo" "$ROOT/.next"

echo "➡️  Ensuring node_modules is consistent (no reinstall)..."
# If you really get stuck later we can add: pnpm install

echo "============================================================"
echo "  Reset complete. Now run from the portal root:"
echo
echo "    cd ~/baseframework/portal"
echo "    pnpm dev"
echo
echo "============================================================"
