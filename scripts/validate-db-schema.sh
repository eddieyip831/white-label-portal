#!/usr/bin/env zsh
set -euo pipefail

# Verify current DB schema against the baseline snapshot.
#
# Requirements:
# - Supabase CLI installed and configured (logged in, project linked or local).
# - Baseline schema file:
#     docs/system/db-schema-baseline.sql
#
# Behaviour:
# - Dumps the current DB schema to:
#     docs/system/db-schema-current.sql
# - Diffs current vs baseline.
# - Exits 0 if they match, 1 if they differ.

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BASELINE_SCHEMA_FILE="${ROOT_DIR}/docs/system/db-schema-baseline.sql"
CURRENT_SCHEMA_FILE="${ROOT_DIR}/docs/system/db-schema-current.sql"

if [[ ! -f "${BASELINE_SCHEMA_FILE}" ]]; then
  echo "❌ Baseline schema file not found:"
  echo "   ${BASELINE_SCHEMA_FILE}"
  echo "   Please create it first using 'supabase db dump'."
  exit 1
fi

echo "🧾 Dumping current DB schema to:"
echo "   ${CURRENT_SCHEMA_FILE}"

# Adjust flags if you need a different scope, but keep data-only=false.
supabase db dump \
  --schema public \
  --data-only=false \
  --file "${CURRENT_SCHEMA_FILE}"

echo
echo "🔍 Comparing current schema with baseline..."
echo

if diff -u "${BASELINE_SCHEMA_FILE}" "${CURRENT_SCHEMA_FILE}"; then
  echo
  echo "✅ DB schema matches baseline."
  exit 0
else
  echo
  echo "⚠️  DB schema differs from baseline."
  echo "   - Review the diff above."
  echo "   - If the changes are intentional and stable, update the baseline:"
  echo
  echo "     cp \"${CURRENT_SCHEMA_FILE}\" \"${BASELINE_SCHEMA_FILE}\""
  echo
  exit 1
fi
