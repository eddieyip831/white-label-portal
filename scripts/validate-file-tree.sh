#!/usr/bin/env bash
set -euo pipefail

# Run from anywhere; resolve project root relative to this script
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

OUT_DIR="docs/system"
mkdir -p "$OUT_DIR"

SNAPSHOT="$OUT_DIR/file-tree-current.txt"
BASELINE="$OUT_DIR/file-tree-baseline.txt"

echo "📁 Generating current file-tree snapshot → $SNAPSHOT"

# We limit depth to keep the output stable and focused on routes
find apps/web/app -maxdepth 4 -type d | LC_ALL=C sort > "$SNAPSHOT"

if [[ -f "$BASELINE" ]]; then
  echo "🔍 Comparing against baseline: $BASELINE"
  echo
  if diff -u "$BASELINE" "$SNAPSHOT"; then
    echo
    echo "✅ File tree matches baseline."
  else
    echo
    echo "⚠️  Differences detected (see diff above)."
    echo "To create new baseline from the current state, run:"
    echo "  cp \"$SNAPSHOT\" \"$BASELINE\""
  fi
else
  echo
  echo "⚠️  No baseline file-tree found."
  echo "To create one from the current state, run:"
  echo "  cp \"$SNAPSHOT\" \"$BASELINE\""
fi
