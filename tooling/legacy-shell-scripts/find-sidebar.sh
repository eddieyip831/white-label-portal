#!/usr/bin/env bash
set -e

ROOT="$HOME/baseframework/portal"

echo "============================================================"
echo "           Searching for sidebar.tsx in portal"
echo "============================================================"

find "$ROOT" -type f -name "sidebar.tsx" -print

echo "============================================================"
echo "Done."
