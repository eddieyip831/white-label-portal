#!/usr/bin/env bash
set -e

FILE="/Users/eddie/baseframework/portal/tsconfig.json"

echo "Testing grep against:"
echo "$FILE"
echo "-------------------------------------"

echo
echo "1) Raw grep:"
grep '"~/*"' "$FILE" || echo "NO MATCH"

echo
echo "2) Escaped grep:"
grep "\"~/*\"" "$FILE" || echo "NO MATCH"

echo
echo "3) Fixed string (-F):"
grep -F '"~/*"' "$FILE" || echo "NO MATCH"

echo
echo "4) Regex escaped (-E):"
grep -E '"~/\*"' "$FILE" || echo "NO MATCH"

echo
echo "5) Show the exact lines:"
grep -n '"paths"' "$FILE"
grep -n '~/' "$FILE"

echo
echo "Done."
