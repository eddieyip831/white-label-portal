#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# Shell script audit (macOS / bash 3.2 compatible)
# - Scans the repo for *.sh files (excluding build and vendor dirs)
# - Summarises each script:
#     - path
#     - executable? (yes/no)
#     - size
#     - last modified
#     - first line (shebang / comment)
#     - whether referenced anywhere else in the repo
# - Outputs to docs/system/shell-scripts-audit.txt
# ---------------------------------------------------------------------------

# Resolve repo root.
# This script is expected to live in: <repo-root>/scripts/audit-shell-scripts.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -d "$SCRIPT_DIR/.git" ]; then
  # Script lives directly at repo root (rare)
  REPO_ROOT="$SCRIPT_DIR"
else
  # Script lives under /scripts → repo root is one level up
  REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
fi

OUT_DIR="$REPO_ROOT/docs/system"
OUT_FILE="$OUT_DIR/shell-scripts-audit.txt"

mkdir -p "$OUT_DIR"

echo "📁 Repo root: $REPO_ROOT"
echo "📝 Writing audit report to: $OUT_FILE"
echo

echo "🔍 Scanning for .sh files..."

# We'll stream over find results line-by-line (no mapfile)
TMP_LIST="$(mktemp)"
cd "$REPO_ROOT"

find . -type f -name "*.sh" \
  ! -path "*/.git/*" \
  ! -path "*/node_modules/*" \
  ! -path "*/.next/*" \
  ! -path "*/.turbo/*" \
  ! -path "*/dist/*" \
  ! -path "*/build/*" \
  | sort > "$TMP_LIST"

TOTAL="$(wc -l < "$TMP_LIST" | tr -d ' ')"

echo "   → Found $TOTAL shell script(s)."
echo

{
  echo "==================================================================="
  echo " SHELL SCRIPTS AUDIT"
  echo " Generated: $(date +"%Y-%m-%d %H:%M:%S")"
  echo " Repo root: $REPO_ROOT"
  echo "==================================================================="
  echo
  echo "Total .sh files: $TOTAL"
  echo

  if [ "$TOTAL" -eq 0 ]; then
    echo "No *.sh files found. Nothing to audit."
    rm -f "$TMP_LIST"
    exit 0
  fi

  # Read each file path from the temp list
  while IFS= read -r f; do
    # Normalise path (strip leading ./)
    REL_PATH="${f#./}"

    # macOS/BSD stat
    SIZE=$(stat -f "%z" "$REL_PATH" 2>/dev/null || echo "?")
    MTIME=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$REL_PATH" 2>/dev/null || echo "?")

    if [ -x "$REL_PATH" ]; then
      EXEC="yes"
    else
      EXEC="no"
    fi

    # First line (shebang / comment / etc.)
    FIRST_LINE=$(head -n 1 "$REL_PATH" 2>/dev/null || echo "")
    FIRST_LINE_CLEAN="$(echo "$FIRST_LINE" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

    BASENAME="$(basename "$REL_PATH")"

    # Check if this script is referenced elsewhere in the repo by basename
    # (exclude .git, node_modules, build artifacts and the script itself)
    REF_LINES=$(grep -R --line-number --fixed-string "$BASENAME" . \
      --exclude-dir=".git" \
      --exclude-dir="node_modules" \
      --exclude-dir=".next" \
      --exclude-dir=".turbo" \
      --exclude-dir="dist" \
      --exclude-dir="build" \
      --exclude="$REL_PATH" 2>/dev/null || true)

    if [ -n "$REF_LINES" ]; then
      REFERENCED="yes"
      REF_SUMMARY=$(echo "$REF_LINES" | head -n 5)
    else
      REFERENCED="no"
      REF_SUMMARY=""
    fi

    echo "-------------------------------------------------------------------"
    echo "File: $REL_PATH"
    echo "  Executable : $EXEC"
    echo "  Size       : $SIZE bytes"
    echo "  Modified   : $MTIME"
    echo "  First line : ${FIRST_LINE_CLEAN:-<empty>}"
    echo "  Referenced : $REFERENCED"
    if [ -n "$REF_SUMMARY" ]; then
      echo "  Reference sample:"
      echo "$REF_SUMMARY" | sed 's/^/    - /'
    fi
    echo

  done < "$TMP_LIST"

  echo "==================================================================="
  echo " END OF REPORT"
  echo "==================================================================="

} > "$OUT_FILE"

rm -f "$TMP_LIST"

echo "✅ Audit complete. Report written to:"
echo "   $OUT_FILE"
echo
echo "Next steps suggestion:"
echo "  1) Open the report and look for scripts with Referenced: no"
echo "  2) Decide whether to delete, move to tooling/legacy, or keep."
