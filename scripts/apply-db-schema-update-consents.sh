#!/usr/bin/env zsh
set -euo pipefail

# Generic DB migration runner for Supabase CLI (no `db execute` support).
#
# Usage:
#   zsh scripts/apply-db-schema-update-consents.sh supabase/migrations/2025120201_add_user_profile_names_and_consents.sql
#
# Behaviour:
#   - Verifies that the given SQL file exists.
#   - Runs `supabase db push` from the repo root, which applies all pending migrations.

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if [[ $# -lt 1 ]]; then
  echo "❌ Missing argument: SQL migration file path."
  echo
  echo "Usage:"
  echo "  $(basename "$0") path/to/migration.sql"
  echo
  echo "Example:"
  echo "  $(basename "$0") supabase/migrations/2025120201_add_user_profile_names_and_consents.sql"
  exit 1
fi

INPUT_PATH="$1"
SQL_FILE="$INPUT_PATH"

# Try as given
if [[ ! -f "$SQL_FILE" ]]; then
  # Try relative to repo root
  if [[ "$INPUT_PATH" != /* ]]; then
    ALT_FILE="${ROOT_DIR}/${INPUT_PATH}"
    if [[ -f "$ALT_FILE" ]]; then
      SQL_FILE="$ALT_FILE"
    fi
  fi
fi

if [[ ! -f "$SQL_FILE" ]]; then
  echo "❌ Migration SQL file not found:"
  echo "   ${INPUT_PATH}"
  echo "Checked:"
  echo "   ${INPUT_PATH}"
  echo "   ${ROOT_DIR}/${INPUT_PATH}"
  exit 1
fi

echo "✅ Found migration file:"
echo "   ${SQL_FILE}"
echo
echo "🚀 Running 'supabase db push' from repo root to apply pending migrations..."
echo

cd "${ROOT_DIR}"
supabase db push

echo
echo "✅ Migration(s) applied via supabase db push."
