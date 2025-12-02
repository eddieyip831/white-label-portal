#!/usr/bin/env bash

# ============================================================
# Scan + Safe Fix Script for MakerKit Option A → Option B
# ============================================================
# This script:
#   1. Scans the entire repo for invalid imports
#   2. Prints all affected files + line numbers
#   3. Asks for confirmation
#   4. Applies safe, Option-B replacements ONLY after approval
# ============================================================

ROOT="apps/web"
TARGET_FILES=$(mktemp)

echo "============================================================"
echo "🔍 SCANNING PROJECT FOR PROBLEMATIC MAKERKIT IMPORTS"
echo "============================================================"

# Patterns to search for
PATTERNS=(
    "@/components/"
    "@/lib/"
    "~/app/(marketing)"
    "~/app/(landing)"
    "~/app/(*)"
)

echo "➡ Searching for invalid imports..."

# Collect results
for PATTERN in "${PATTERNS[@]}"; do
    echo ""
    echo "Looking for: $PATTERN"
    grep -RIn "$PATTERN" "$ROOT" | tee -a "$TARGET_FILES"
done

echo ""
echo "============================================================"
echo "📄 SUMMARY OF OFFENDING FILES"
echo "============================================================"

sort -u "$TARGET_FILES" | sed 's/:/ → Line /'

echo ""
echo "============================================================"
echo "❗ REVIEW ABOVE LIST CAREFULLY"
echo "Only these files will be modified."
echo "============================================================"
echo ""

read -p "Proceed with automatic fixes? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "❌ Aborted. No changes applied."
    exit 0
fi

echo ""
echo "============================================================"
echo "🛠 APPLYING FIXES…"
echo "============================================================"

# Fix patterns
echo "➡ Rewriting '@/components/' → '~/components/'"
grep -Rl "@/components/" "$ROOT" | xargs sed -i '' 's|@/components/|~/components/|g'

echo "➡ Rewriting '@/lib/' → '~/lib/'"
grep -Rl "@/lib/" "$ROOT" | xargs sed -i '' 's|@/lib/|~/lib/|g'

echo "➡ Removing ~/app/(marketing)/ imports"
grep -Rl "~/app/(marketing)" "$ROOT" | xargs sed -i '' '/(marketing)/d'

echo "➡ Removing ~/app/(landing)/ imports"
grep -Rl "~/app/(landing)" "$ROOT" | xargs sed -i '' '/(landing)/d'

echo "➡ Removing ~/app/(*) wildcard imports"
grep -Rl "~/app/(*)" "$ROOT" | xargs sed -i '' '/(\*)/d'

echo ""
echo "============================================================"
echo "✔ FIX COMPLETE — OPTION B IMPORTS APPLIED"
echo "============================================================"
