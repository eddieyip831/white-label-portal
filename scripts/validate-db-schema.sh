#!/usr/bin/env zsh
set -euo pipefail

# ----------------------------------------------------------------------
# CONFIG
# ----------------------------------------------------------------------
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BASELINE_SCHEMA_FILE="${ROOT_DIR}/docs/system/db-schema-baseline.sql"
CURRENT_SCHEMA_FILE="${ROOT_DIR}/docs/system/db-schema-current.sql"

# Format YYYYMMDD for backup file
DATE_TAG=$(date +"%Y%m%d")
BASELINE_BACKUP_FILE="${BASELINE_SCHEMA_FILE}.${DATE_TAG}.bak"

# ----------------------------------------------------------------------
# 1. Ensure baseline exists
# ----------------------------------------------------------------------
if [[ ! -f "${BASELINE_SCHEMA_FILE}" ]]; then
  echo "❌ Baseline schema file not found:"
  echo "   ${BASELINE_SCHEMA_FILE}"
  echo "   Please create it first using 'supabase db dump'."
  exit 1
fi

# ----------------------------------------------------------------------
# 2. Dump current schema
# ----------------------------------------------------------------------
echo "🧾 Dumping current DB schema to:"
echo "   ${CURRENT_SCHEMA_FILE}"

supabase db dump \
  --schema public \
  --data-only=false \
  --file "${CURRENT_SCHEMA_FILE}"

echo
echo "🔍 Comparing current schema with baseline..."
echo

# ----------------------------------------------------------------------
# 3. Compare schemas
# ----------------------------------------------------------------------
if diff -u "${BASELINE_SCHEMA_FILE}" "${CURRENT_SCHEMA_FILE}"; then
  echo
  echo "✅ DB schema matches baseline."
  exit 0
else
  echo
  echo "⚠️  DB schema differs from baseline."

  echo "📦 Creating backup of existing baseline before updating..."
  echo "   ${BASELINE_BACKUP_FILE}"

  cp "${BASELINE_SCHEMA_FILE}" "${BASELINE_BACKUP_FILE}"

  echo
  echo "⬆️ To promote CURRENT schema to new BASELINE, run:"
  echo
  echo "     cp \"${CURRENT_SCHEMA_FILE}\" \"${BASELINE_SCHEMA_FILE}\""
  echo
  echo "   (Previous baseline safely backed up as: ${BASELINE_BACKUP_FILE})"
  exit 1
fi
