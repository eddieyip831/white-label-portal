#!/usr/bin/env bash
set -e

# Detect zsh and exit safely
if [ -n "$ZSH_VERSION" ]; then
    echo "❌ This script must be run with bash, not zsh."
    echo "Run using: bash extract_portal_snapshot.sh"
    exit 1
fi

OUTPUT="portal_snapshot"
ZIPFILE="$OUTPUT.zip"

echo "📦 Preparing portal snapshot..."

# Clean previous output
rm -rf "$OUTPUT" "$ZIPFILE"
mkdir -p "$OUTPUT"

# Copy required directories (without node_modules, .next, build artifacts)
copy_dir() {
    local src=$1
    local dest="$OUTPUT/$2"
    if [ -d "$src" ]; then
        mkdir -p "$dest"
        rsync -av --exclude="node_modules" \
                  --exclude=".next" \
                  --exclude="dist" \
                  --exclude="*.log" \
                  --exclude=".turbo" \
                  --exclude="build" \
                  "$src/" "$dest/"
    else
        echo "⚠️ Skipped: $src does not exist"
    fi
}

# Required project folders
copy_dir "apps/web/app"                "apps/web/app"
copy_dir "apps/web/lib"                "apps/web/lib"
copy_dir "apps/web/components"         "apps/web/components"
copy_dir "apps/web/modules"            "apps/web/modules"
copy_dir "apps/web/admin"              "apps/web/admin"

# Important root-level configs
FILES=(
  "next.config.js"
  "middleware.ts"
  "package.json"
  "turbo.json"
  "tsconfig.json"
  "apps/web/tsconfig.json"
  ".env.example"
)

for f in "${FILES[@]}"; do
    if [ -f "$f" ]; then
        mkdir -p "$OUTPUT/$(dirname "$f")"
        cp "$f" "$OUTPUT/$f"
    fi
done

# Create zip
zip -r "$ZIPFILE" "$OUTPUT" >/dev/null

echo "✅ Portal snapshot created: $ZIPFILE"
echo "Upload this zip in ChatGPT."

