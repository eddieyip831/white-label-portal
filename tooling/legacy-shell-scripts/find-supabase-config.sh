#!/usr/bin/env bash
set -e

ROOT="$HOME/baseframework"

echo "============================================================"
echo "    Searching for Supabase config.toml inside: $ROOT"
echo "============================================================"
echo
echo "➡️  Searching..."

FOUND_FILES=$(find "$ROOT" -type f -name "config.toml" 2>/dev/null)

if [ -z "$FOUND_FILES" ]; then
  echo "❌ No config.toml found anywhere under $ROOT"
  echo
  echo "➡️  You can force the Supabase CLI to write it into the correct folder with:"
  echo "    supabase link --project-ref <REF> --workdir ~/baseframework/portal"
  exit 1
fi

echo "✔ Found the following config.toml files:"
echo
echo "$FOUND_FILES"
echo

echo "============================================================"
echo "Suggested Next Steps"
echo "============================================================"
echo "If the file is NOT located at:"
echo "   ~/baseframework/portal/supabase/config.toml"
echo
echo "Then create the folder and move it manually:"
echo
echo "   mkdir -p ~/baseframework/portal/supabase"
echo "   mv <FOUND_FILE_PATH> ~/baseframework/portal/supabase/config.toml"
echo
echo "============================================================"
