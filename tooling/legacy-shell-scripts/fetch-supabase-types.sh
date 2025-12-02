#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo "  Supabase Type Generator (Access Token • 2025)"
echo "============================================================"
echo "ROOT DIR: $(pwd)"
echo ""

ROOT="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$ROOT/apps/web/.env.local"
OUT_DIR="$ROOT/types"
META_JSON="$OUT_DIR/metadata.json"
OUT_FILE="$OUT_DIR/supabase.ts"

echo "DEBUG: ROOT = $ROOT"
echo "DEBUG: ENV FILE = $ENV_FILE"
echo ""

# -------------------------------------------------------------
# 0. Validate environment file
# -------------------------------------------------------------
if [[ ! -f "$ENV_FILE" ]]; then
  echo "❌ ERROR: .env.local not found at:"
  echo "   $ENV_FILE"
  ls -l "$ROOT/apps/web" || true
  exit 1
else
  echo "✔ Found .env.local"
fi

echo ""
echo "===== DEBUG: .env.local contents ====="
cat "$ENV_FILE"
echo "======================================"
echo ""

# -------------------------------------------------------------
# 1. Load variables
# -------------------------------------------------------------
SUPABASE_URL=$(grep '^NEXT_PUBLIC_SUPABASE_URL=' "$ENV_FILE" | cut -d '=' -f2 || true)
ACCESS_TOKEN=$(grep '^SUPABASE_ACCESS_TOKEN=' "$ENV_FILE" | cut -d '=' -f2 || true)

echo "DEBUG: Extracted variables:"
echo "  SUPABASE_URL = '$SUPABASE_URL'"
echo "  ACCESS_TOKEN = '${ACCESS_TOKEN:0:5}...(hidden)'"
echo ""

if [[ -z "${SUPABASE_URL}" ]]; then
  echo "❌ ERROR: NEXT_PUBLIC_SUPABASE_URL could not be read"
  exit 1
fi

if [[ -z "${ACCESS_TOKEN}" ]]; then
  echo "❌ ERROR: SUPABASE_ACCESS_TOKEN missing"
  exit 1
fi

# Extract project-ref from URL
echo "DEBUG: Extracting project ref from:"
echo "  $SUPABASE_URL"
PROJECT_REF=$(echo "$SUPABASE_URL" | sed 's|https://||; s|\.supabase\.co||')

echo "DEBUG: PROJECT_REF computed as: '$PROJECT_REF'"
echo ""

if [[ "$PROJECT_REF" == NEXT_PUBLIC_SUPABASE_URL* ]]; then
  echo "❌ ERROR: PROJECT_REF extraction failed"
  echo "It still contains NEXT_PUBLIC_SUPABASE_URL="
  exit 1
fi

echo "✔ Using Project Ref: $PROJECT_REF"

# -------------------------------------------------------------
# 2. Download metadata (with debug)
# -------------------------------------------------------------
mkdir -p "$OUT_DIR"

METADATA_URL="https://api.supabase.com/v1/projects/$PROJECT_REF/metadata"

echo ""
echo "➡ REQUESTING METADATA"
echo "  URL: $METADATA_URL"
echo "  TOKEN (first 8 chars): ${ACCESS_TOKEN:0:8}..."

curl -v -sf \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "apikey: $ACCESS_TOKEN" \
  "$METADATA_URL" \
  -o "$META_JSON" || {
    echo ""
    echo "❌ curl failed — see above debug output"
    exit 1
}

echo ""
echo "✔ DOWNLOAD COMPLETE"
echo "Saved to: $META_JSON"
echo ""

# -------------------------------------------------------------
# 3. Validate metadata content
# -------------------------------------------------------------
if [[ ! -s "$META_JSON" ]]; then
  echo "❌ ERROR: metadata.json is empty"
  exit 1
else
  echo "✔ metadata.json is populated"
fi

# -------------------------------------------------------------
# 4. Generate TypeScript
# -------------------------------------------------------------
echo ""
echo "➡ Generating TypeScript types…"

echo "// AUTO-GENERATED — DO NOT EDIT" > "$OUT_FILE"
echo "export namespace Database {" >> "$OUT_FILE"
echo "" >> "$OUT_FILE"

jq -r '
  if .tables then
    .tables[] |
    "  export interface " + .name + " {\n" +
    (
      .columns[]
      | "    " + .name + ": " +
        (if .is_nullable then "string | null" else "string" end)
        + ";\n"
    ) +
    "  }\n"
  else
    "// ❌ No .tables[] found in metadata.json"
  end
' "$META_JSON" >> "$OUT_FILE"

echo "}" >> "$OUT_FILE"

echo ""
echo "🎉 TypeScript types generated → $OUT_FILE"
echo "============================================================"
