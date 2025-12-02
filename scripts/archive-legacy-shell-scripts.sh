#!/usr/bin/env bash
set -euo pipefail

# Run this from repo root: bash scripts/archive-legacy-shell-scripts.sh

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ARCHIVE_DIR="$ROOT/tooling/legacy-shell-scripts"

echo "📁 Repo root: $ROOT"
echo "📦 Archive dir: $ARCHIVE_DIR"
mkdir -p "$ARCHIVE_DIR"

# Shell scripts we want to archive (NOT the two core scripts in scripts/)
LEGACY_SCRIPTS=(
  "a.sh"
  "cleanup-admin-duplicate.sh"
  "diagnose-portal.sh"
  "extract_portal_snapshot.sh"
  "fetch-supabase-types.sh"
  "find-sidebar.sh"
  "find-supabase-config.sh"
  "fix-admin-api-conflict.sh"
  "fix-admin-route-structure.sh"
  "fix-admin-sidebar-precise.sh"
  "fix-admin.sh"
  "fix-imports-option-b.sh"
  "fix-next-runtime.sh"
  "fix-portal-structure.sh"
  "fix-rbac-pages.sh"
  "fix-supabase-clients.sh"
  "hard-reset-next.sh"
  "package-rbac.sh"
  "phase2-bootstrap.sh"
  "phase2b-bootstrap.sh"
  "phase3-rbac-bootstrap.sh"
  "phase4-rbac-bootstrap.sh"
  "reset-web.sh"
  "scaffold-framework-structure.sh"
  "test-grep.sh"
  "verify-app-structure.sh"
  "verify-phase2a.sh"
  "verify-phase2b.sh"
  "verify-phase3.sh"
  "verify-rbac-sql.sh"
)

echo
echo "📂 Archiving legacy shell scripts..."
for rel in "${LEGACY_SCRIPTS[@]}"; do
  src="$ROOT/$rel"
  if [ -f "$src" ]; then
    echo "  → Moving $rel → tooling/legacy-shell-scripts/"
    mv "$src" "$ARCHIVE_DIR/"
  else
    echo "  ⚠️ Skipping (not found): $rel"
  fi
done

echo
echo "✅ Done. Legacy scripts are now under: tooling/legacy-shell-scripts/"
echo "   Active scripts kept in scripts/:"
echo "     - scripts/validate-file-tree.sh"
echo "     - scripts/audit-shell-scripts.sh"
